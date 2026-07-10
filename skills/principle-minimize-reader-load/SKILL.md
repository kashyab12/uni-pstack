---
name: principle-minimize-reader-load
description: "Apply when reviewing or shaping code that's hard to trace. Count layers between question and answer, and hidden state in the reader's head; collapse one-caller wrappers and shrink mutable scope."
---

# Minimize Reader Load
## Uni-pstack Runtime Adapter

This is a portable port of upstream Cursor pstack. Apply these overrides before following the original workflow:

- Cursor Task or subagent calls mean Codex delegation. In Codex, use native Codex subagents. In Claude Code, launch Codex CLI workers using the installed pstack skill spawn-codex-worker script or direct codex exec.
- Replace upstream Composer, Claude Opus, and other panel defaults with Codex gpt-5.6-sol and task-appropriate reasoning: medium for routine implementation and exploration; high for judgment, synthesis, and high-risk work. Use the supported fast or priority tier.
- Claude-only fallback model policy lives in the installed pstack delegation reference. Do not infer Claude model choices from this skill.
- Cursor-only commands such as loop, babysit, deslop, control-ui, and control-cli are conceptual cues. Use the host terminal, browser, review, subagent, and git tools directly.
- Cursor paths become host-appropriate project or user configuration paths. Preserve the workflow intent, not Cursor-specific storage.


Maintainability is the work a reader must do to understand code. Track two axes:
1. **Layers to trace.** How many indirections sit between the question and the answer.
2. **State to hold.** How much hidden or mutable context the reader must keep in their head.

**Why:** Code is read far more than it is written. LOC, cyclomatic complexity, and "clean architecture" are proxies. Reader load is the thing that matters. The two axes are independent. A flat file with 50 globals can be as hard to reason about as a 6-layer adapter stack. Guard both. This is the human analog of [Guard the Context Window](../principle-guard-the-context-window/SKILL.md): working memory is finite for readers too.

**The pattern:**
- **Collapse layers** that do not earn their keep: wrappers with one caller, adapters with no second implementation, indirection introduced for a future that never came. Inline them.
- **Shrink state scope:** prefer pure functions (returns over mutations), locals over fields, fields over module state, and module state over globals. Derive instead of sync.
- **Name the invariant at the boundary,** not in every consumer, so the reader learns it once.
- Before adding a layer or a piece of state, ask: does this reduce reader load somewhere else by at least as much?

**The test:** Can a new reader answer "where does X come from?" and "what can change X?" in under 30 seconds? If not, cut layers or cut state.
