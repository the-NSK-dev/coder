import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/file_item.dart';
import '../models/code_result.dart';
import '../models/verification_status.dart';

class ProjectFileService {
  /// Writes a list of FileItems to the specified project directory.
  Future<void> saveGeneratedFiles(String projectPath, List<FileItem> files) async {
    if (kIsWeb) return;
    final dir = Directory(projectPath);
    if (!await dir.exists()) await dir.create(recursive: true);
    for (var item in files) {
      final file = File('${dir.path}/${item.path}');
      if (!await file.parent.exists()) await file.parent.create(recursive: true);
      await file.writeAsString(item.content);
    }
  }

  Future<String> readFile(String filePath) async {
    if (kIsWeb) return '';
    final file = File(filePath);
    if (await file.exists()) return await file.readAsString();
    throw Exception('File not found: $filePath');
  }

  Future<void> updateFile(String filePath, String content) async {
    if (kIsWeb) return;
    await File(filePath).writeAsString(content);
  }

  Future<void> createFile(String filePath) async {
    if (kIsWeb) return;
    final file = File(filePath);
    if (!await file.exists()) await file.create(recursive: true);
  }

  Future<void> createFolder(String folderPath) async {
    if (kIsWeb) return;
    final dir = Directory(folderPath);
    if (!await dir.exists()) await dir.create(recursive: true);
  }

  Future<void> deleteItem(String path, bool isDirectory) async {
    if (kIsWeb) return;
    if (isDirectory) {
      final dir = Directory(path);
      if (await dir.exists()) await dir.delete(recursive: true);
    } else {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> renameItem(String oldPath, String newPath, bool isDirectory) async {
    if (kIsWeb) return;
    if (isDirectory) {
      final dir = Directory(oldPath);
      if (await dir.exists()) await dir.rename(newPath);
    } else {
      final file = File(oldPath);
      if (await file.exists()) await file.rename(newPath);
    }
  }

  // ─────────────────────────────────────────────────────────
  // SAMPLE PROJECT — Coder Documentation Website
  //
  // This is a self-contained website that explains how Coder
  // works. It serves as both the sample project AND the
  // official documentation users see when they click
  // "Try the Sample Project".
  // ─────────────────────────────────────────────────────────

  /// Returns the sample project as a map of filename -> content.
  Map<String, String> getSampleProjectFiles() {
    return {
      // ── HTML ─────────────────────────────────────────────
      'index.html': r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="Coder — your AI engineering team powered by Band.ai, AIML API, and Featherless.">
  <title>Coder · Your AI Engineering Team</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="style.css">
</head>
<body>

  <!-- ── NAV ─────────────────────────────────────────── -->
  <nav class="nav">
    <div class="nav-inner">
      <div class="nav-logo">
        <span class="logo-icon">⟨/⟩</span>
        <span class="logo-text">Coder</span>
      </div>
      <div class="nav-links">
        <a href="#how">How it works</a>
        <a href="#agents">Agents</a>
        <a href="#stack">Tech Stack</a>
        <a href="#demo" class="nav-cta">Try Demo</a>
      </div>
    </div>
  </nav>

  <!-- ── HERO ─────────────────────────────────────────── -->
  <section class="hero">
    <div class="hero-glow glow-blue"></div>
    <div class="hero-glow glow-purple"></div>
    <div class="hero-content">
      <div class="hero-badge">
        <span class="badge-dot"></span>
        Powered by Band.ai · AIML API · Featherless
      </div>
      <h1 class="hero-title">
        Your entire<br>
        <span class="gradient-text">engineering team</span><br>
        in one app
      </h1>
      <p class="hero-sub">
        Coder coordinates four specialized AI agents — Planner, Engineer, Reviewer, and
        Verifier — through a shared <strong>Band.ai</strong> chat room. 
        Describe what you want to build. Watch the team build it.
      </p>
      <div class="hero-actions">
        <button class="btn-primary" onclick="scrollToSection('how')">How it works</button>
        <button class="btn-ghost" onclick="scrollToSection('demo')">See the demo</button>
      </div>
    </div>
    <div class="hero-visual">
      <div class="terminal">
        <div class="terminal-bar">
          <span class="dot red"></span>
          <span class="dot yellow"></span>
          <span class="dot green"></span>
          <span class="terminal-title">Coder · Band.ai Room</span>
        </div>
        <div class="terminal-body" id="terminal-body">
          <div class="msg user"><span class="msg-tag">You</span> Build a landing page with hero section and pricing.</div>
          <div class="msg agent planner"><span class="msg-tag">@Controller-Planner</span> Analyzing requirements…<br><span class="plan-step">✓ Plan: 4 steps, HTML/CSS/JS stack</span></div>
          <div class="msg agent engineer"><span class="msg-tag">@Engineer</span> Writing index.html…<br><span class="plan-step">✓ index.html written (148 lines)</span></div>
          <div class="msg agent reviewer"><span class="msg-tag">@Reviewer</span> Checking accessibility &amp; performance…<br><span class="plan-step">✓ All checks passed</span></div>
          <div class="msg agent verifier"><span class="msg-tag">@Verifier</span> Running final validation…<br><span class="plan-step">✓ Build complete — files written to disk</span></div>
        </div>
      </div>
    </div>
  </section>

  <!-- ── HOW IT WORKS ─────────────────────────────────── -->
  <section class="section" id="how">
    <div class="container">
      <div class="section-label">HOW IT WORKS</div>
      <h2 class="section-title">From prompt to production in four steps</h2>
      <p class="section-sub">Every build goes through the same four-agent pipeline, coordinated in real time via Band.ai.</p>

      <div class="steps">
        <div class="step">
          <div class="step-num">01</div>
          <div class="step-content">
            <h3>You describe the goal</h3>
            <p>Type your idea into the Coder chat bar — "Build a React dashboard with dark mode" or "Add authentication to my Node server." No specification files needed.</p>
          </div>
        </div>
        <div class="step-arrow">→</div>
        <div class="step">
          <div class="step-num">02</div>
          <div class="step-content">
            <h3>Planner creates a plan</h3>
            <p>The Controller-Planner agent breaks your request into atomic coding tasks and posts the plan into the Band.ai room, @mentioning the Engineer to begin.</p>
          </div>
        </div>
        <div class="step-arrow">→</div>
        <div class="step">
          <div class="step-num">03</div>
          <div class="step-content">
            <h3>Engineer writes the code</h3>
            <p>The Engineer agent receives the plan, calls its LLM, and generates complete files — no stubs, no placeholders. Files are written directly to your open project folder.</p>
          </div>
        </div>
        <div class="step-arrow">→</div>
        <div class="step">
          <div class="step-num">04</div>
          <div class="step-content">
            <h3>Reviewer + Verifier check it</h3>
            <p>The Reviewer audits code quality and standards compliance. The Verifier runs the final check. Three green checkmarks = code delivered.</p>
          </div>
        </div>
      </div>
    </div>
  </section>

  <!-- ── AGENTS ────────────────────────────────────────── -->
  <section class="section section-dark" id="agents">
    <div class="container">
      <div class="section-label">THE TEAM</div>
      <h2 class="section-title">Meet your four AI agents</h2>
      <p class="section-sub">Each agent is an independent Python process, connected to a shared Band.ai chat room via WebSocket. They communicate by @mentioning each other — just like a real Slack team.</p>

      <div class="agents-grid">
        <div class="agent-card card-blue">
          <div class="agent-icon">🧠</div>
          <div class="agent-name">Controller-Planner</div>
          <div class="agent-role">Architect</div>
          <p class="agent-desc">Reads your prompt, breaks it into a structured build plan, and assigns each step to the Engineer via @mention. Uses Claude or GPT-4 for complex reasoning.</p>
          <div class="agent-detail">Triggered by: <code>@Controller-Planner {your prompt}</code></div>
        </div>
        <div class="agent-card card-purple">
          <div class="agent-icon">⚡</div>
          <div class="agent-name">Engineer</div>
          <div class="agent-role">Code Generator</div>
          <p class="agent-desc">Receives the plan and generates complete, working files across any language — HTML, CSS, JS, React, Next.js, Java, Python, Node.js. No placeholders.</p>
          <div class="agent-detail">Triggered by: <code>@Engineer {task from plan}</code></div>
        </div>
        <div class="agent-card card-teal">
          <div class="agent-icon">🔍</div>
          <div class="agent-name">Reviewer</div>
          <div class="agent-role">Quality Auditor</div>
          <p class="agent-desc">Reads every generated file against your project's markdown standards files. Checks accessibility, security, performance, and code style before approving.</p>
          <div class="agent-detail">Triggered by: <code>@Reviewer {files to review}</code></div>
        </div>
        <div class="agent-card card-green">
          <div class="agent-icon">✅</div>
          <div class="agent-name">Verifier</div>
          <div class="agent-role">Final Validator</div>
          <p class="agent-desc">Runs the final end-to-end check. Confirms all planned steps were completed, all files exist, and the output meets the original requirements. Closes the loop.</p>
          <div class="agent-detail">Triggered by: <code>@Verifier {final check}</code></div>
        </div>
      </div>
    </div>
  </section>

  <!-- ── BAND.AI EXPLAINED ─────────────────────────────── -->
  <section class="section" id="band">
    <div class="container">
      <div class="section-label">BAND.AI ARCHITECTURE</div>
      <h2 class="section-title">Why Band.ai is the coordination layer</h2>

      <div class="band-grid">
        <div class="band-explain">
          <p>Band.ai is not a text generation API. It is <strong>messaging infrastructure for agent teams</strong>. Each agent in Coder is a small Python process that:</p>
          <ul class="band-list">
            <li><span class="li-icon">🔌</span> Connects to Band over a persistent WebSocket and stays running 24/7</li>
            <li><span class="li-icon">👂</span> Listens for @mentions of its name in the shared chat room</li>
            <li><span class="li-icon">🤖</span> Calls its own LLM (Anthropic / AIML API / Featherless) when triggered</li>
            <li><span class="li-icon">📢</span> Posts its response back into the room, @mentioning the next agent</li>
          </ul>
          <p>The Flutter app connects to the same room as a "human" participant. It posts your initial prompt and streams every agent reply to the activity feed in real time.</p>
        </div>
        <div class="band-diagram">
          <div class="diagram-room">
            <div class="room-label">Band.ai Chat Room</div>
            <div class="room-nodes">
              <div class="node node-user">Flutter App<br>(you)</div>
              <div class="node node-planner">Controller<br>Planner</div>
              <div class="node node-engineer">Engineer</div>
              <div class="node node-reviewer">Reviewer</div>
              <div class="node node-verifier">Verifier</div>
            </div>
            <div class="room-note">All connected via WebSocket · All talk via @mentions</div>
          </div>
        </div>
      </div>
    </div>
  </section>

  <!-- ── TECH STACK ────────────────────────────────────── -->
  <section class="section section-dark" id="stack">
    <div class="container">
      <div class="section-label">TECH STACK</div>
      <h2 class="section-title">Everything that powers Coder</h2>

      <div class="stack-grid">
        <div class="stack-card">
          <div class="stack-icon">📱</div>
          <div class="stack-name">Flutter</div>
          <div class="stack-desc">Cross-platform IDE shell (iOS, Android, Windows, macOS). Renders the chat UI, file manager, code editor, preview, and activity feed.</div>
        </div>
        <div class="stack-card">
          <div class="stack-icon">🔗</div>
          <div class="stack-name">Band.ai SDK</div>
          <div class="stack-desc">WebSocket-based agent coordination. Each Python agent process connects here. Flutter joins the same room via REST + WebSocket to send prompts and stream replies.</div>
        </div>
        <div class="stack-card">
          <div class="stack-icon">⚡</div>
          <div class="stack-name">AIML API</div>
          <div class="stack-desc">Primary LLM inference provider inside each Python agent. OpenAI-compatible endpoints — swap models without changing agent code.</div>
        </div>
        <div class="stack-card">
          <div class="stack-icon">🪶</div>
          <div class="stack-name">Featherless</div>
          <div class="stack-desc">Open-weight model hosting. Used when agents need a specific open model (Mistral, Llama, DeepSeek) for cost or capability reasons.</div>
        </div>
        <div class="stack-card">
          <div class="stack-icon">🐙</div>
          <div class="stack-name">GitHub API</div>
          <div class="stack-desc">One-tap push from the Coder file manager to any GitHub repo. Supports creating new repos, committing all generated files, and branch management.</div>
        </div>
        <div class="stack-card">
          <div class="stack-icon">🐍</div>
          <div class="stack-name">Python Agents</div>
          <div class="stack-desc">Each of the 4 agents is a small Python script using the Band SDK. Run all four locally with <code>docker compose up</code> or 4 terminal windows.</div>
        </div>
      </div>
    </div>
  </section>

  <!-- ── LANGUAGES ─────────────────────────────────────── -->
  <section class="section" id="languages">
    <div class="container">
      <div class="section-label">8 LANGUAGES</div>
      <h2 class="section-title">Full-stack support out of the box</h2>
      <p class="section-sub">The Engineer agent can write in any of these. The Reviewer checks each against language-specific standards files in your project.</p>
      <div class="lang-row">
        <div class="lang-chip">HTML</div>
        <div class="lang-chip">CSS</div>
        <div class="lang-chip">JavaScript</div>
        <div class="lang-chip">React JSX</div>
        <div class="lang-chip">Next.js TSX</div>
        <div class="lang-chip">Node.js</div>
        <div class="lang-chip">Java</div>
        <div class="lang-chip">Python</div>
      </div>
    </div>
  </section>

  <!-- ── FOOTER ─────────────────────────────────────────── -->
  <footer class="footer">
    <div class="footer-inner">
      <div class="footer-logo">
        <span class="logo-icon">⟨/⟩</span>
        <span class="logo-text">Coder</span>
      </div>
      <p class="footer-note">Built for the Band.ai × AIML API × Featherless Hackathon · 2026</p>
      <div class="footer-links">
        <a href="https://band.ai" target="_blank">Band.ai</a>
        <a href="https://aimlapi.com" target="_blank">AIML API</a>
        <a href="https://featherless.ai" target="_blank">Featherless</a>
      </div>
    </div>
  </footer>

  <script src="script.js"></script>
</body>
  const input = document.getElementById('demo-input');
  const output = document.getElementById('demo-output');
  const btn = document.getElementById('demo-run');
  const prompt = input.value.trim();
  if (!prompt) {
    input.focus();
    return;
  }

  output.innerHTML = '';
  btn.disabled = true;
  btn.textContent = 'Running…';

  demoResponses.forEach(({ cls, label, delay, text }) => {
    setTimeout(() => {
      const el = document.createElement('div');
      el.className = 'demo-msg ' + cls;
      el.innerHTML = '<strong>' + label + '</strong><br>' + text.replace('{n}', Math.floor(Math.random() * 4) + 3);
      output.appendChild(el);
    }, delay);
  });

  setTimeout(() => {
    btn.disabled = false;
    btn.textContent = 'Run →';
  }, 4200);
}

// Allow Enter key in demo input
document.addEventListener('DOMContentLoaded', () => {
  const inp = document.getElementById('demo-input');
  if (inp) {
    inp.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') runDemo();
    });
  }
});

// ── Intersection observer: fade-in sections ─────────────
document.addEventListener('DOMContentLoaded', () => {
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(e => {
      if (e.isIntersecting) {
        e.target.style.opacity = '1';
        e.target.style.transform = 'translateY(0)';
      }
    });
  }, { threshold: 0.1 });

  document.querySelectorAll('.agent-card, .stack-card, .step, .lang-chip').forEach(el => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(20px)';
    el.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
    observer.observe(el);
  });
});
''',

      // ── Supporting files ──────────────────────────────────
      'README.md': '''# Coder · Documentation Website

This is the sample project included with Coder.

It is a single-page documentation website that explains:
- What Coder is and how it works
- How the 4 AI agents (Planner, Engineer, Reviewer, Verifier) collaborate
- How Band.ai provides the messaging/coordination layer
- The full tech stack (Flutter · Band.ai · AIML API · Featherless · GitHub)

## Files
- `index.html` — main documentation page
- `style.css`  — dark-theme styles
- `script.js`  — terminal animation + interactive demo

## Run locally
Open `index.html` in any browser — no build step needed.

## Powered by
- [Band.ai](https://band.ai) — agent coordination via WebSocket chat rooms
- [AIML API](https://aimlapi.com) — LLM inference inside each Python agent
- [Featherless](https://featherless.ai) — open-weight model hosting
''',

      'tailwind.config.js': '''// Tailwind config for Coder projects that use Tailwind
module.exports = {
  content: ["./*.{html,js,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        coderBlue:   "#3B6FE8",
        coderPurple: "#8B5FE8",
      },
    },
  },
  plugins: [],
};''',

      'src/App.jsx': r'''// Sample React component — generated by Coder's Engineer agent
import React, { useState } from 'react';

export default function App() {
  const [count, setCount] = useState(0);

  return (
    <div style={{ padding: 24, fontFamily: 'Inter, sans-serif', background: '#000', color: '#fff', minHeight: '100vh' }}>
      <h1 style={{ color: '#3B6FE8' }}>Coder · React Component</h1>
      <p>The Engineer agent generated this. State is working:</p>
      <button
        onClick={() => setCount(c => c + 1)}
        style={{
          background: 'linear-gradient(135deg, #3B6FE8, #8B5FE8)',
          color: '#fff',
          border: 'none',
          padding: '12px 24px',
          borderRadius: 10,
          cursor: 'pointer',
          marginTop: 16,
          fontSize: 15,
          fontWeight: 600,
        }}
      >
        Clicked {count} times
      </button>
    </div>
  );
}''',

      'app/page.tsx': r'''// Next.js App Router — generated by Coder's Engineer agent
export const metadata = {
  title: 'Coder · Next.js Demo',
  description: 'Generated by the Coder Engineer agent',
};

export default function Page() {
  return (
    <main style={{ padding: 40, fontFamily: 'Inter, sans-serif', background: '#000', color: '#fff', minHeight: '100vh' }}>
      <h1 style={{ color: '#3B6FE8', marginBottom: 16 }}>Coder · Next.js Page</h1>
      <p style={{ color: '#888899', lineHeight: 1.7 }}>
        This file was generated by the Engineer agent using the Next.js App Router pattern.
        The Reviewer agent checked it against the project's TypeScript and Next.js standards files.
      </p>
    </main>
  );
}''',

      'server.js': r'''// Node.js backend — generated by Coder's Engineer agent
const http = require('http');

const server = http.createServer((req, res) => {
  const data = {
    service: 'Coder API',
    message: 'Generated by the Engineer agent, reviewed by the Reviewer agent.',
    timestamp: new Date().toISOString(),
    agent_pipeline: ['Controller-Planner', 'Engineer', 'Reviewer', 'Verifier'],
  };
  res.writeHead(200, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
  res.end(JSON.stringify(data, null, 2));
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`Coder API server running on port ${PORT}`));''',

      'src/main/java/com/coder/Main.java': r'''package com.coder;

/**
 * Coder — Java backend sample
 * Generated by the Engineer agent.
 */
public class Main {
    private static final String[] AGENTS = {
        "Controller-Planner",
        "Engineer",
        "Reviewer",
        "Verifier"
    };

    public static void main(String[] args) {
        System.out.println("=== Coder Agent Pipeline ===");
        for (int i = 0; i < AGENTS.length; i++) {
            System.out.printf("Step %d: @%s%n", i + 1, AGENTS[i]);
        }
        System.out.println("Build complete. Files written to project directory.");
    }
}''',
    };
  }

  /// Generates a CodeResult for in-memory web use.
  CodeResult getSampleCodeResult() {
    final filesMap = getSampleProjectFiles();
    final fileItems = filesMap.entries.map((e) => FileItem(
      name: e.key,
      path: e.key,
      content: e.value,
      step1: VerificationStatus.passed,
      step2: VerificationStatus.passed,
      step3: VerificationStatus.passed,
    )).toList();

    return CodeResult(
      projectName: 'Coder Sample Project',
      version: 'v1.0',
      files: fileItems,
      currentFilePath: 'index.html',
    );
  }

  /// Writes the sample project to disk (for desktop/mobile).
  Future<String> generateTestProject(String baseDir) async {
    final projectDir = Directory('$baseDir/coder-docs-website');
    if (!await projectDir.exists()) {
      await projectDir.create(recursive: true);
    }

    final files = getSampleProjectFiles();

    for (var entry in files.entries) {
      final file = File('${projectDir.path}/${entry.key}');
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      await file.writeAsString(entry.value);
    }

    return projectDir.path;
  }
}
