# Coder - Project Status & Handover (Hackathon V1)

---

## What I Worked On

### Screens Completed
| Screen | Route | Status | Reference Matched |
|---|---|---|---|
| Splash Screen | `/` | ✅ Done | Yes — exact image match |
| Main Chat Screen | `/chat` | ✅ Done | Yes — exact image match |
| Profile Screen | `/profile` | ✅ Done | Yes — exact image match |

### Technical Foundations
- **Responsive Scale System:** All screens use `final s = (sw / 390).clamp(0.85, 1.3);` for consistent mobile-first scaling across devices.
- **Routing:** `go_router` handles `/` → `/chat` → `/profile` navigation. Splash auto-transitions after 2 seconds.
- **Design System:** Dark theme (`#000000`), Electric Blue accent (`#3B82F6`), subtle borders, clamped proportions.
- **Assets:** `logo-center.png`, `sponsor-1.png`, `sponsor-2.png`, `sponsor-3.png` integrated and sized.

---

## What is Not Working Yet
- **Editor, Files, Preview, GitHub buttons** in the top nav bar — icons are present but not wired to screens.
- **Send button** — present but does not trigger any agent flow.
- **AI name dropdown** — visual only, no model selection logic.
- **Theme toggle** on Profile — switches state locally but does not change the app theme.
- **Agent cards** on Profile — tappable but do not open model selection.
- **AI Integrations** — `BandAIService` and `AIMLAPIService` are not connected.
- **State Management** — no Provider/Riverpod in place yet.
- **Agent Workflow Visualization** — the core product differentiator is not yet built.

---

## What Needs to be Continued

### Priority 1 — Remaining UI Screens
Build these screens following the same design system and responsive scale:
- [ ] Code Editor Screen
- [ ] File Explorer Screen
- [ ] Preview Screen
- [ ] GitHub Push Screen

### Priority 2 — Wire Navigation
- [ ] Connect Editor button → Code Editor Screen
- [ ] Connect Files button → File Explorer Screen
- [ ] Connect Preview button → Preview Screen
- [ ] Connect GitHub button → GitHub Push Screen

### Priority 3 — State Management
- [ ] Add Provider or Riverpod
- [ ] Create project state (current project, files, chat history)
- [ ] Wire AI model selection from Profile screen

### Priority 4 — Agent Workflow
- [ ] Implement the agent pipeline visualization (Controller → Engineer → Review → Self-Review → Verifier → Preview → GitHub Push)
- [ ] Connect to Band AI and AIMLAPI endpoints
- [ ] Show real-time agent communication in the chat

### Priority 5 — Polish
- [ ] Splash screen transition animation (fade/slide)
- [ ] Loading states and error handling
- [ ] Desktop responsive layout (1440px breakpoint)

---

## How to Continue

### Design Rules
- **Always use** `final s = (sw / 390).clamp(0.85, 1.3);` at the top of every screen's `build()` method.
- **Scale everything** with `* s` — font sizes, padding, icon sizes, container dimensions.
- **Colors:** Background `#000000`, accent `#3B82F6`, borders `white @ 6-8% opacity`, cards `#0A0A0F`.
- **Corner radii:** Cards `16*s`, buttons `12*s`, pills `20*s`.

### Adding a New Screen
1. Create `lib/screens/your_screen.dart`
2. Use the same scale pattern
3. Add route in `lib/main.dart` GoRouter config
4. Wire the nav button in `main_chat_screen.dart`

### Running the App
```bash
cd c:\Users\monika\Downloads\NSK\coder-screen
flutter run -d chrome
```
Press `R` for hot restart, `r` for hot reload.

---

## Where to Continue the Full Project Work

| Item | Path |
|---|---|
| **Workspace** | `c:\Users\monika\Downloads\NSK\coder-screen` |
| **Entry Point** | `lib/main.dart` — routing config |
| **Screens** | `lib/screens/` — all screen files |
| **Assets** | `assets/` — logos, sponsor images, reference images |
| **Dependencies** | `pubspec.yaml` — currently: flutter, cupertino_icons, go_router |
| **Reference Images** | `assets/flash-screen.png` and user-provided screenshots |
