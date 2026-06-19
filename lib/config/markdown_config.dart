class MarkdownConfig {
  /// User-uploaded project spec/requirement .md files that do NOT match
  /// a language name go here.
  static List<String> userMarkdownFiles = [];

  /// Auto-maintained shared memory, rewritten after each agent step.
  static String projectContextMarkdown = '''
# Project Context

## User Requirements
(no file uploaded yet)

## Current Plan
(not yet generated)

## File Manifest
(not yet generated)

## Verification Log
### Step 1 — Supporter (Syntax)
Status: pending

### Step 2 — Engineer Self-Review (Standards)
Status: pending

### Step 3 — Reviewer (UI/UX/Functional)
Status: pending

## Retry Count: 0
''';

  /// Reset the project context to its initial state.
  static void reset() {
    userMarkdownFiles.clear();
    projectContextMarkdown = '''
# Project Context

## User Requirements
(no file uploaded yet)

## Current Plan
(not yet generated)

## File Manifest
(not yet generated)

## Verification Log
### Step 1 — Supporter (Syntax)
Status: pending

### Step 2 — Engineer Self-Review (Standards)
Status: pending

### Step 3 — Reviewer (UI/UX/Functional)
Status: pending

## Retry Count: 0
''';
  }
}
