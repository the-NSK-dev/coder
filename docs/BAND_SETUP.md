# Band.ai Agent Setup for Coder

Coder connects to your Band.ai chat room where four external agents collaborate to build software. Flutter joins the room as a participant — agents run on Band.ai (not in this repo).

## Prerequisites

- Band.ai account at [app.band.ai](https://app.band.ai)
- AIMLAPI keys configured on Planner and Reviewer agents
- Featherless keys configured on Engineer and Verifier agents

## Step 1 — Create External Agents

On [app.band.ai/agents](https://app.band.ai/agents), create four **External Agent** entries with these exact display names:

| Agent Name | Model Provider | Role |
|------------|----------------|------|
| `Controller-Planner` | AIMLAPI | Plans architecture and file structure |
| `Engineer` | Featherless | Generates working code files |
| `Reviewer` | AIMLAPI | Reviews syntax, imports, dependencies |
| `Verifier` | Featherless | Verifies requirements, UX, functionality |

Each agent's API key and model config live in Band — Coder never stores agent keys.

## Step 2 — Create a Chat Room

1. Go to [app.band.ai/chats](https://app.band.ai/chats)
2. Create a new room
3. Add all four agents to the room
4. Copy the **Room ID** from the URL: `app.band.ai/chats/<roomId>`

## Step 3 — Get Your User API Key

1. Open Band account settings → API Keys
2. Copy your **personal user API key** (lets Coder join the room)

## Step 4 — Configure Coder

Open **Settings** in Coder and enter:

- **User API Key** — your Band account API key
- **Room ID** — the chat room ID from Step 2

Or edit `lib/config/app_config.dart` for development defaults.

## Step 5 — Start Agents

Start each agent process on Band.ai (or your hosted environment) before triggering a build from Coder.

## Step 6 — Test the Pipeline

1. Open a folder in Coder
2. Send: `Build a modern React ecommerce website`
3. Coder posts `@Controller-Planner Build a modern React ecommerce website` to the room
4. Watch agents respond in chat via WebSocket
5. Files appear in the file tree after Engineer completes
6. Verification dots update when Reviewer and Verifier run (if enabled in Settings)

## Verification Toggle

In **Settings → Verification**:

- **ON**: Planner → Engineer → Reviewer → Verifier
- **OFF**: Planner → Engineer only (faster builds)

## @Mention Flow

Agents coordinate via @mentions in the Band room:

```
User → @Controller-Planner Build a React app
Controller-Planner → (JSON plan) @Engineer Create these files
Engineer → (file blocks) @Reviewer Review generated files
Reviewer → Pass/Fail @Verifier Verify requirements
Verifier → Pass/Fail
```

Coder listens to all messages and materializes Engineer output as files on disk.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "No agent available" | Enter Band API key + Room ID in Settings |
| Agents don't respond | Ensure all 4 agents are running and in the room |
| Files not appearing | Check Engineer output uses markdown fences with file paths |
| Preview not loading | For React projects, install Node.js; static HTML works out of the box |

## Windows Build

```powershell
flutter build windows --release
```

Requires Git, Node.js (for React previews), and Band.ai agent setup above.
