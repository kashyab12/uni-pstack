---
name: typescript-best-practices
description: TypeScript best practices. Use when reading or editing any .ts or .tsx file.
---

# TypeScript best practices
## Uni-pstack Runtime Adapter

This is a portable port of upstream Cursor pstack. Apply these overrides before following the original workflow:

- Cursor Task or subagent calls mean Codex delegation. In Codex, use native Codex subagents. In Claude Code, launch Codex CLI workers using the installed pstack skill spawn-codex-worker script or direct codex exec.
- Replace upstream Composer, Claude Opus, and other panel defaults with Codex gpt-5.6-sol high reasoning plus the supported fast or priority tier for Codex work.
- Claude-only fallback model policy lives in the installed pstack delegation reference. Do not infer Claude model choices from this skill.
- Cursor-only commands such as loop, babysit, deslop, control-ui, and control-cli are conceptual cues. Use the host terminal, browser, review, subagent, and git tools directly.
- Cursor paths become host-appropriate project or user configuration paths. Preserve the workflow intent, not Cursor-specific storage.


Apply the **type-system-discipline** principle skill first; this skill grounds it in TypeScript syntax.

| Rule | Summary |
|------|---------|
| Discriminated unions | Model variants with a `kind` literal discriminant so impossible states can't be represented. No optional-field bags. |
| Branded types | Brand primitives with `& { readonly __brand: "X" }` so they can't be mixed up. Validate once at creation. |
| `unknown` over `any` | External data is `unknown`. `any` disables type checking everywhere it touches. |
| No `as` casts | Every `as` is a runtime crash waiting. Cast only after validation. |
| Narrowing hierarchy | Discriminant switch > `in` operator > `typeof`/`instanceof` > user-defined type guard > `as`. |
| Type guards | Must verify the claim. A lying guard is worse than `as` because the bug hides behind a name that says it's safe. Name them `isX` or `hasX`. |
| Exhaustiveness | Inline `const _exhaustive: never = x;` in default arms so the compiler errors when a new variant is added. |
| `satisfies` over `as` | Validates the value without widening literal types. |
| Boundary validation | Validate where data crosses in; trust types inside. See the **boundary-discipline** principle skill. |
| Schema-derived types | Reach for `Pick`/`Omit`/`Parameters`/`ReturnType`/`Awaited`/`typeof` before declaring a new interface. |
| Object args | Pass objects, not positional, so argument order is self-documenting. Skip on hot paths (per-frame render, tokenizers, parsers). |

Examples: `references/patterns.md`.
