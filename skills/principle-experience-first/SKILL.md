---
name: principle-experience-first
description: "Apply when product, UX, or feature-scope tradeoffs come up. Choose user delight over implementation convenience; ship fewer polished features over more rough ones."
---

# Experience First
## Uni-pstack Runtime Adapter

This is a portable port of upstream Cursor pstack. Apply these overrides before following the original workflow:

- Cursor Task or subagent calls mean Codex delegation. In Codex, use native Codex subagents. In Claude Code, launch Codex CLI workers using the installed pstack skill spawn-codex-worker script or direct codex exec.
- Replace upstream Composer, Claude Opus, and other panel defaults with Codex gpt-5.5 high reasoning plus the supported fast or priority tier for Codex work.
- In Claude Code only, if a task explicitly needs a Claude-only worker instead of Codex, use Fable 5 high. For Claude-only UI or UX judgment, use Fable 5 high for hard calls and medium for cheaper iteration. Do not apply Fable guidance inside Codex-hosted runs.
- Cursor-only commands such as loop, babysit, deslop, control-ui, and control-cli are conceptual cues. Use the host terminal, browser, review, subagent, and git tools directly.
- Cursor paths become host-appropriate project or user configuration paths. Preserve the workflow intent, not Cursor-specific storage.


The product is the experience. Every technical decision either helps or hurts it. When implementation convenience conflicts with user delight, choose delight.

- Say no to 1,000 things (every feature, control, and option must earn its place)
- Ship less, ship better (polished experience with three features beats rough one with ten)
- Prototype before committing (design decisions are cheaper in throwaway HTML than production code)
- Sweat the details (transitions, alignment, spacing, feedback, error states)
- Tighten the core loop (every feature should serve the central workflow or get out of the way)

The user is whoever consumes the work. For a UI that is the end user. For a library or an internal API it is the colleague who imports it. The engineer who maintains the code next is a user too. Weigh their experience the same way, and explain impact from their seat.

Foundations should serve the experience, not the other way around. Foundational thinking governs the *sequence* of work; this principle governs the *target*.
