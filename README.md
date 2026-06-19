# Coder

AI-powered agentic IDE for Windows. Multiple AI agents collaborate via Band.ai to build real software projects.

## Features

- File explorer, multi-tab code editor, syntax highlighting
- Band.ai agent pipeline (Controller-Planner → Engineer → Reviewer → Verifier)
- Live localhost preview (static HTML and npm dev servers)
- GitHub push integration
- Optional three-step verification toggle

## Prerequisites

- Flutter SDK 3.11+
- Windows 10+ (primary target)
- [Band.ai](https://band.ai) account with four agents configured — see [docs/BAND_SETUP.md](docs/BAND_SETUP.md)
- Node.js (for React/Vite project previews)
- Git (for GitHub push)

## Quick Start

```powershell
cd coder-screen
flutter pub get
flutter run -d windows
```

## Configuration

Open **Settings** in the app to configure:

- Band.ai User API Key and Room ID
- AIML API Key (demo/fallback mode)
- Verification toggle
- GitHub connection

## Build for Windows

```powershell
flutter build windows --release
```

Output: `build\windows\x64\runner\Release\`

## Architecture

- **Flutter** — desktop IDE UI, filesystem, preview, GitHub
- **Band.ai** — agent coordination via WebSocket room
- **External agents** — Python processes on Band.ai (Planner, Engineer, Reviewer, Verifier)

## Web Demo

The web build runs in limited demo mode (no real filesystem). Use Windows desktop for full functionality.
