---
name: automate-me
description: "Use for \"automate me\", \"create/update/refresh my -mode skill\", \"turn/capture my preferences or working style into a skill\", or wanting agents to follow how the user works. Drafts or revises a personal -mode skill via create-skill + unslop, optionally pulling fresh evidence from recent transcripts."
---

# Automate me
## Uni-pstack Runtime Adapter

This is a portable port of upstream Cursor pstack. Apply these overrides before following the original workflow:

- Cursor Task or subagent calls mean Codex delegation. In Codex, use native Codex subagents. In Claude Code, launch Codex CLI workers using the installed pstack skill spawn-codex-worker script or direct codex exec.
- Replace upstream Composer, Claude Opus, and other panel defaults with Codex gpt-5.5 high reasoning plus the supported fast or priority tier for Codex work.
- In Claude Code only, if a task explicitly needs a Claude-only worker instead of Codex, use Fable 5 high. For Claude-only UI or UX judgment, use Fable 5 high for hard calls and medium for cheaper iteration. Do not apply Fable guidance inside Codex-hosted runs.
- Cursor-only commands such as loop, babysit, deslop, control-ui, and control-cli are conceptual cues. Use the host terminal, browser, review, subagent, and git tools directly.
- Cursor paths become host-appropriate project or user configuration paths. Preserve the workflow intent, not Cursor-specific storage.


A guided flow for turning the user's working conventions into a skill agents will follow. The output is one `-mode` skill tailored to them (e.g. `jay-mode`, `priya-mode`).

This skill orchestrates three parts: an inline mining pass (see step 1), the host's skill authoring guidance, and the **unslop** skill for prose discipline. In Codex, use the installed `skill-creator` skill and its validator when available. In Claude Code, follow Claude Code's current skill format and validate with whatever local checker exists.

## Flow

### 0. Check for an existing skill

Look for `*-mode/SKILL.md` matching the user's handle in host-appropriate skill roots. In Codex, check `${CODEX_HOME:-$HOME/.codex}/skills/` and any project skill directory the user named. In Claude Code, check `~/.claude/skills/` and project `.claude/skills/`. If one exists, confirm intent with a structured question tool when available, or one concise chat question otherwise, unless the user already said "update my skill" or similar:

- Update the existing skill (default for repeat runs)
- Start fresh (rare; ask why before doing it)

Update mode changes the rest of the flow:
- Step 1 mines only history since the skill was last edited (`git log -1 --format=%cI <path>`).
- Step 2 asks what's changed or missing, not what to capture from zero.
- Step 4 edits the existing file in place. Preserve sections the user hasn't contradicted; revise ones with new evidence; add new sections only for genuinely new rules.

### 1. Mine their history

Locate the active workspace's transcript or history source before fanning out. Use only the host-provided path for this workspace. Do not glob global product history directories such as `~/.cursor/projects/*/`, unrelated Codex threads, or unrelated Claude projects. That crosses workspace boundaries and reads private chats from unrelated projects.

Survey recent agent conversations within that scope for recurring patterns. Run multiple parallel subagents across slices of history (e.g. last 2-4 weeks, split into 3 slices so each has enough material). Each slice mining subagent reads transcripts from the workspace-scoped path the parent provides, looks for the signals below, and returns a short structured list of patterns it saw with evidence pointers. Default signals worth hunting:

- Response preferences (length, tone, format, "dumb it down" corrections)
- Delegation habits (subagents, models, specialized workflows, parallelism)
- Verification posture (what "done" means; unit tests vs live repro; reviewers)
- Code and prose discipline (style, principles cited, lint/format tools)
- Process conventions (worktrees, commits, PRs, review/merge tooling)
- Meta preferences (fixing skills mid-task, proposing new ones)

Cross-check across slices before elevating a signal. Patterns seen in 2+ slices are high-confidence; lone signals are weak and usually get dropped.

### 2. Ask the user directly

Mining misses intent that hasn't come up yet. Use a structured multi-choice question tool when available rather than asking the user to type from scratch. Lower cognitive load, higher hit rate.

Shape: one or two questions with 4-6 options each, `allow_multiple: true` for category questions. Start broad ("Which areas matter most?"), then follow up on selected areas with specific options. After the structured rounds, one free-form chat question catches anything the options missed.

Don't dump 20 questions. Two structured rounds plus one open question is usually enough.

### 3. Cluster findings

Group the combined signals into sections. Common ones (use only what applies):

- **Response style**: length, tone, format.
- **Autonomy**: how much to do without asking; MCP tool use.
- **Understand first**: which skills to reach for when scoping or investigating a change.
- **Subagents**: default, parallelism, model-to-task, specialized workflows.
- **Prose / code discipline**: principles, lint tools, style guides.
- **Review and verify**: repro posture, verification skills, live-testing tools.
- **Process**: git worktrees, commits, PRs, review/merge tooling.
- **Skills**: skill-authoring habits, fix-the-skill-first, proposing new skills.

The **poteto-mode** skill shows the shape. Read it for granularity. Don't copy its content; the user's rules are not the same as poteto-mode's.

### 4. Draft the skill

Use the host's skill authoring guidance to author the skill. In Codex, read and follow `skill-creator` before writing. Placement:

- Path: use the user's requested skill root. If absent, default to `${CODEX_HOME:-$HOME/.codex}/skills/<handle>-mode/` in Codex and `~/.claude/skills/<handle>-mode/` in Claude Code. For a committed Claude Code project skill, use `.claude/skills/<handle>-mode/`.
- Handle: the user's first name or chosen identifier.
- Frontmatter `description`: trigger on their name + `/<handle>-mode` + "work in their style", not on generic keywords like "write code" or "review PR".
- Frontmatter formatting: follow the host's YAML rules. For Codex skills, only `name` and `description` belong in frontmatter. Keep `description` as one YAML scalar; quote it or use `description: >-` with indented continuation lines when punctuation or wrapping requires it.
- Trigger control: mode skills are heavy and opinionated, so write a narrow description that triggers on the user's name and explicit mode invocation. Do not add Cursor-only frontmatter such as `disable-model-invocation`.

### 5. Iterate on prose

Apply the **unslop** skill and the host skill-authoring guidelines to every line. Both apply to any agent-read prose, not just skills.

Show the draft to the user and take feedback. Expect multiple iterations. Cut ruthlessly; a mode skill is not a manual.

### 6. Land it

Work in a worktree off main. Commit and open a PR so the user can review it. Don't push to main directly.

## Guardrails

- **Don't overfit to one conversation.** A preference stated once and contradicted another time is noise. Require multiple instances before codifying it.
- **Don't be clever.** Restating other skills' contents, inventing metaphors, or writing "poetic" prose for an agent reader is cost without benefit. Keep it operational.
- **Reference, don't inline.** Other skills the user relies on should appear as path references, not pasted excerpts. Same for any principle docs they maintain elsewhere.
- **Keep sections minimal.** Only add a section if the user has a specific, non-default rule there. "Communicate clearly" is not a section. "Short paragraphs. Tables when comparing options. Bullets only when items are genuinely parallel." is.
- **Name conventions generic.** Use "the user" or "the human" in imperatives, not the author's first name. Others may read or adopt the skill.
- **Don't force symmetry.** If a user has no process rules worth writing down, skip the Process section entirely. Sparse is fine; bloated is not.

## Evaluation

A `-mode` skill is subjective output. A `create-skill`-style test/iterate benchmark loop isn't useful here. Vibe-check with the user: does it read like them? Did it miss anything? Then ship.

Run a description-optimization loop only if the skill's trigger accuracy turns out to be a problem in practice.

## When not to use

- User wants a task-specific skill (not working conventions): use the host skill-creation workflow alone, no mining required.
- User wants to capture one narrow workflow (e.g. "how I write commit messages"): that's a regular skill, not a mode skill.

## Reference files

- The **poteto-mode** skill: example of the output shape.
- The **unslop** skill: prose discipline for every line.
- Host skill authoring guidance: Codex `skill-creator`, or Claude Code's current skill authoring instructions.
