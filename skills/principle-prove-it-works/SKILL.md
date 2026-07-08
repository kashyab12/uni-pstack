---
name: principle-prove-it-works
description: "Apply after completing a task, before declaring done. Verify against the real artifact (run the feature, read the actual value, inspect the diff), not a proxy, self-report, or 'it compiles.'"
---

# Prove It Works
## Uni-pstack Runtime Adapter

This is a portable port of upstream Cursor pstack. Apply these overrides before following the original workflow:

- Cursor Task or subagent calls mean Codex delegation. In Codex, use native Codex subagents. In Claude Code, launch Codex CLI workers using the installed pstack skill spawn-codex-worker script or direct codex exec.
- Replace upstream Composer, Claude Opus, and other panel defaults with Codex gpt-5.5 high reasoning plus the supported fast or priority tier for Codex work.
- In Claude Code only, if a task explicitly needs a Claude-only worker instead of Codex, use Fable 5 high. For Claude-only UI or UX judgment, use Fable 5 high for hard calls and medium for cheaper iteration. Do not apply Fable guidance inside Codex-hosted runs.
- Cursor-only commands such as loop, babysit, deslop, control-ui, and control-cli are conceptual cues. Use the host terminal, browser, review, subagent, and git tools directly.
- Cursor paths become host-appropriate project or user configuration paths. Preserve the workflow intent, not Cursor-specific storage.


Verify every task output by checking the real thing directly. Do not infer from proxies, self-reports, or "it compiles."

**Why:** Unverified work has unknown correctness. Indirect verification (file mtimes, output freshness, agent self-reports, cached screenshots) feels cheaper than direct observation. Acting on a wrong inference costs far more than checking the source.

**Pattern:** After completing any task, ask: "how do I prove this actually works?"

Check the real thing, not a proxy:
- Check process liveness directly, not indirectly through derived state
- Read the actual value, not a cached or derived representation
- When verification fails, suspect the observation method before suspecting the system

Code and features:
1. Build it (necessary but not sufficient)
2. Run it and exercise the actual feature path
3. Check the full chain: does data flow from input to output?
4. For integrations, test the full communication path end-to-end

Delegation: trust artifacts, not self-reports.
When verifying delegated work, inspect the actual output artifact (git diff, file contents, runtime behavior), not the delegate's summary. Agents report what they intended, not always what happened.

## Script the check when you can

The strongest proof is a deterministic script that re-runs the same comparison, not a one-time eyeball. Write the script, run it, and keep its output as an artifact a reviewer can re-run instead of trusting your word. A script comparing the old and new compiled output catches what a glance misses.

Keep the artifact visible for the human. Commit it only for large or complex work where the trail has to be auditable later, like a big port or migration (the **show-me-your-work** skill). Most work just needs it visible, not committed.
