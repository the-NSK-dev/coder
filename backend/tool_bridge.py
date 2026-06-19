import asyncio
import json
import os
import re
import base64
from pathlib import Path
from dotenv import load_dotenv
import websockets
import httpx
from playwright.async_api import async_playwright

load_dotenv()

BAND_API_KEY = os.getenv("BAND_USER_API_KEY")
ROOM_ID = os.getenv("BAND_ROOM_ID")
WS_URL = os.getenv("BAND_WS_URL")
REST_BASE = "https://app.band.ai/api/v1"

COMMAND_PATTERN = re.compile(r"^/(\w+)\s+(\{.*\})$")


class ToolBridge:
    def __init__(self):
        self.playwright = None
        self.browser = None

    async def start_browser(self):
        self.playwright = await async_playwright().start()
        self.browser = await self.playwright.chromium.launch(headless=True)

    async def stop_browser(self):
        if self.browser:
            await self.browser.close()
        if self.playwright:
            await self.playwright.stop()

    # ── TOOL: /screenshot ─────────────────────────────────
    async def screenshot(self, args: dict) -> dict:
        url = args.get("url", "http://localhost:3000")
        page = await self.browser.new_page(viewport={"width": 1280, "height": 800})
        try:
            await page.goto(url, wait_until="networkidle", timeout=15000)
            img_bytes = await page.screenshot(full_page=True)
            b64 = base64.b64encode(img_bytes).decode()
            return {"ok": True, "image_base64": b64[:200] + "...[truncated for chat]",
                     "full_image_saved": self._save_screenshot(img_bytes)}
        except Exception as e:
            return {"ok": False, "error": str(e)}
        finally:
            await page.close()

    def _save_screenshot(self, img_bytes: bytes) -> str:
        out_dir = Path("backend/screenshots")
        out_dir.mkdir(exist_ok=True)
        out_path = out_dir / "latest_preview.png"
        out_path.write_bytes(img_bytes)
        return str(out_path)

    # ── TOOL: /check_console_errors ───────────────────────
    async def check_console_errors(self, args: dict) -> dict:
        url = args.get("url", "http://localhost:3000")
        errors = []
        page = await self.browser.new_page()
        page.on("console", lambda msg: errors.append(msg.text) if msg.type == "error" else None)
        page.on("pageerror", lambda exc: errors.append(str(exc)))
        try:
            await page.goto(url, wait_until="networkidle", timeout=15000)
            await page.wait_for_timeout(1500)  # let async errors surface
            return {"ok": True, "errors": errors, "error_count": len(errors)}
        except Exception as e:
            return {"ok": False, "error": str(e)}
        finally:
            await page.close()

    # ── TOOL: /read_file ───────────────────────────────────
    def read_file(self, args: dict) -> dict:
        path = args.get("path", "")
        try:
            content = Path(path).read_text(encoding="utf-8")
            return {"ok": True, "path": path, "content": content}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    # ── TOOL: /write_file ──────────────────────────────────
    def write_file(self, args: dict) -> dict:
        path = args.get("path", "")
        content = args.get("content", "")
        try:
            p = Path(path)
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(content, encoding="utf-8")
            return {"ok": True, "path": path}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    # ── TOOL: /read_directory ──────────────────────────────
    def read_directory(self, args: dict) -> dict:
        path = args.get("path", ".")
        try:
            entries = []
            for item in Path(path).iterdir():
                if item.name.startswith(".") or item.name == "node_modules":
                    continue
                entries.append({"name": item.name, "is_dir": item.is_dir()})
            return {"ok": True, "path": path, "entries": entries}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    # ── TOOL: /run_command ─────────────────────────────────
    async def run_command(self, args: dict) -> dict:
        cmd = args.get("cmd", "")
        cwd = args.get("cwd", ".")
        try:
            proc = await asyncio.create_subprocess_shell(
                cmd, cwd=cwd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=60)
            return {
                "ok": proc.returncode == 0,
                "stdout": stdout.decode(errors="ignore")[-2000:],
                "stderr": stderr.decode(errors="ignore")[-2000:],
                "exit_code": proc.returncode,
            }
        except asyncio.TimeoutError:
            return {"ok": False, "error": "Command timed out after 60s"}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    # ── DISPATCH ────────────────────────────────────────────
    async def dispatch(self, command: str, args: dict) -> dict:
        handlers = {
            "screenshot": self.screenshot,
            "check_console_errors": self.check_console_errors,
            "read_file": lambda a: self.read_file(a),
            "write_file": lambda a: self.write_file(a),
            "read_directory": lambda a: self.read_directory(a),
            "run_command": self.run_command,
        }
        handler = handlers.get(command)
        if handler is None:
            return {"ok": False, "error": f"Unknown command: /{command}"}
        result = handler(args)
        if asyncio.iscoroutine(result):
            result = await result
        return result


async def post_message(content: str):
    async with httpx.AsyncClient() as client:
        await client.post(
            f"{REST_BASE}/rooms/{ROOM_ID}/messages",
            headers={"Authorization": f"Bearer {BAND_API_KEY}",
                     "Content-Type": "application/json"},
            json={"content": content},
        )


async def main():
    bridge = ToolBridge()
    await bridge.start_browser()
    print("Tool Bridge started. Listening to Band room for commands...")

    uri = f"{WS_URL}?api_key={BAND_API_KEY}&room_id={ROOM_ID}"
    async with websockets.connect(uri) as ws:
        async for raw in ws:
            data = json.loads(raw)
            if data.get("type") != "message":
                continue

            content = data.get("content", "").strip()
            sender = data.get("sender", "unknown")
            match = COMMAND_PATTERN.match(content)
            if not match:
                continue  # not a tool command, ignore

            command, args_json = match.groups()
            try:
                args = json.loads(args_json)
            except json.JSONDecodeError:
                await post_message(f"@{sender} Error: invalid JSON in /{command}")
                continue

            print(f"Executing /{command} for @{sender} with args={args}")
            result = await bridge.dispatch(command, args)
            reply = f"@{sender} /{command} result:\n```json\n{json.dumps(result, indent=2)}\n```"
            await post_message(reply)

    await bridge.stop_browser()


if __name__ == "__main__":
    asyncio.run(main())
