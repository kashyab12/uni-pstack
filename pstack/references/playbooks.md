# Playbooks

Pick one playbook before implementation. Copy its steps into the todo list. A skipped step stays visible with `skip: <reason>`.

## Routing

- Investigation: read-only questions, how something works, why it exists, are we sure, should we choose A or B.
- Bug fix: reported defect to reproduce, root-cause, fix, and verify.
- Performance issue: measured slowness to trace and improve against a baseline.
- Hillclimb: sustained improvement of one metric over many attempts.
- Runtime forensics: live symptom such as leak, idle CPU spin, intermittent glitch.
- Trace forensics: existing `.cpuprofile`, trace, spindump, heap snapshot, or similar artifact.
- Feature: new or changed behavior.
- Refactoring: behavior-preserving rename, extract, inline, dedupe, move, or reshape.
- Prototype: throwaway artifact to decide a design or empirical fork.
- Visual parity: pixel-exact match between baseline and target.
- Skill authoring: create or edit `SKILL.md`.
- Eval: blind comparison of skill, prompt, or agent behavior variants.
- Autonomous run: long task to continue until a predicate is met.
- Session pickup: resume prior work from transcript, branch, note, or handoff.
- Pause safely: explicit pause or context-compaction handoff.
- Multi-phase plan: stacked phases or PRs.
- Figure it out: large migration, ambiguous ambitious work, or no narrower playbook fits.

## Investigation

1. Ground with source evidence. For code behavior, trace real files and call paths. For motivation, search commit history, PRs, issues, docs, chat, observability, and analytics when available.
2. Keep the throughput checkpoint as `n/a, read-only investigation`.
3. Produce cited output: overview, key concepts, how it works, where things live, gotchas, and recommendation when relevant.
4. Apply [writing.md](writing.md).

## Bug Fix

1. Reproduce on the matching surface. If direct repro fails, synthesize the trigger or instrument until the symptom is observable.
2. Binary-search the cause. Seed hypotheses from a `how` pass and history when useful. Eliminate with runtime evidence.
3. Plan the fix. If it crosses a function boundary, run Architect with medium reasoning. Delegate a clear, bounded implementation to a Codex worker with `gpt-5.6-sol`, low reasoning, and fast tier when supported. Use medium when the bug is ambiguous or high risk; never high or xhigh on `gpt-5.6-sol`.
4. Verify on the same surface. The original repro must pass.
5. Stage history so failing repro or test lands before the fix when practical.
6. Prepare PR or final response.

## Performance Issue

1. Capture baseline measurement or trace on the matching surface.
2. Ground hypotheses in the implementation and the trace.
3. Plan and implement the smallest measured fix. Use Architect if crossing boundaries.
4. Capture post-fix measurement and compare artifacts.
5. Cite the numbers in the final response or PR.

## Hillclimb

1. Define one metric, direction, target, and stop predicate.
2. Build and freeze the measurement harness. Capture baseline and regression gate.
3. Open a decision log with attempt id, hypothesis, change, before, after, delta, tests, verdict, note.
4. Ground hypotheses with a source pass.
5. Loop one hypothesis at a time. Change, measure, keep if it wins and stays green, otherwise revert.
6. One commit per accepted fix.
7. Stop only when predicate is met or remaining ideas are genuinely not worth cost.

## Runtime Forensics

1. Capture the live signal: CPU profile, heap snapshot, trace, logs, or instrumentation.
2. Reduce the artifact to a smoking gun in a subagent or script if large.
3. Prove the mechanism with live instrumentation or a minimal repro.
4. Map finding to source.
5. Return diagnosis, not a fix, unless asked to continue.

## Trace Forensics

1. Identify artifact format and load it with the right tool.
2. Transform large artifacts into queryable form where useful.
3. Narrow to the hot path, retainer chain, blocked thread, or crash mechanism.
4. Attribute to file, symbol, and line when the artifact permits.
5. Diff paired captures if available.
6. Return diagnosis and confidence.

## Feature

1. Run a `how` pass over the affected subsystem.
2. Run Architect for parallel design exploration, or keep `architect skipped: <reason>` in the todo list.
3. Write the throughput checkpoint:
   - blocking first steps,
   - independent workstreams,
   - shared mutable state,
   - smallest safe decomposition.
4. Delegate bounded code-writing to a Codex worker, or use Arena when several shapes are plausible.
5. Verify on the matching surface.
6. Rebase into small ordered commits or leave a clear local diff.
7. Run Interrogate before shipping if the design is contested or high blast radius.

## Refactoring

1. Pin the behavior contract first with a characterization test, snapshot, equivalence harness, or concrete source trace.
2. Name the target shape. If it crosses a boundary, run Architect.
3. Subtract dead weight before adding new structure.
4. Move in behavior-preserving units, verifying after each.
5. Migrate callers and delete legacy APIs in the same wave when internal.
6. Prove behavior unchanged on the real artifact.
7. Confirm reader-load reduction. Revert cleanup that does not reduce load.

## Prototype

1. State the decision the prototype exists to answer.
2. Gather references when the design space is open.
3. Build throwaway in an isolated scratch dir.
4. If comparing alternatives, put them behind one switcher.
5. Verify by observing the relevant behavior or screenshots.
6. Recommend a direction. Treat prototype code as disposable.

## Visual Parity

1. Establish immutable baseline screenshots or target artifacts first.
2. State anti-shortcut rules: no harness tampering, no baseline edits, no restructuring only to pass diff.
3. Migrate one component or screen at a time.
4. Verify with image diff on the matching surface.
5. Report diff result for each component.

## Skill Authoring

1. Use the host's skill-creator guidance when available.
2. Keep frontmatter trigger text specific.
3. Keep `SKILL.md` lean; move conditional detail to references.
4. Validate frontmatter, referenced files, and install paths.
5. Forward-test complex skills in fresh agents without leaking expected answers.

## Eval

1. State the variant and success behavior.
2. Write a judge-only rubric.
3. Set up sanitized environments. Candidate prompts must look like organic user requests.
4. Run candidates blind in parallel.
5. Run one blinded judge after candidates finish.
6. Inspect transcripts or artifacts yourself.
7. Recommend promote, revise, or reject.

## Autonomous Run

1. Define done as a checkable predicate.
2. Pick a wake/check cadence: event watcher if there is an event, fixed heartbeat otherwise.
3. Each iteration makes the smallest evidence-backed change, verifies, commits if it advances, discards if not.
4. Log each iteration.
5. Stop only when predicate is met or a genuine dead end is evidenced.

## Session Pickup

1. Locate the prior trail: transcript, branch, PR, decision log, or resume note.
2. Reconstruct branch, diff, todos, decisions, and verified claims.
3. Diff done vs pending. Do not redo completed work unless evidence is missing.
4. Route remaining work to the matching playbook.
5. Verify inherited claims against the original goal.

## Pause Safely

1. Stop at a safe boundary. Cancel or let workers finish enough to report.
2. Do not cross irreversible lines to pause.
3. Make work durable with a WIP commit or explicit patch path if appropriate.
4. Write a resume note with intent, progress, verification, state, next action, key files, and gotchas.

## Multi-Phase Plan

1. Define phases as independently verifiable units.
2. Put riskiest unknowns first.
3. Build shared scaffold and verification before dependent work.
4. Use separate branches or worktrees for independent phases.
5. Land as stacked small PRs or ordered commits.

## Figure It Out

1. Frame done as a falsifiable predicate.
2. Quantify scope and blockers.
3. Pick rigor level based on reversibility and blast radius.
4. Design a custom workflow with atomic units, verification gates, and a decision trail.
5. Run each unit as an experiment: hypothesis, change, measure, keep or revert.
6. Verify the whole against the predicate.
7. Encode recurring corrections as structure.

## Architect

1. Ground the existing subsystem unless greenfield.
2. Sketch caller usage first, then types, signatures, modules, and invariants.
3. Use Arena for 2-3 design candidates when the shape is not obvious.
4. Implement against the sketch.
5. Scrap and redesign if repeated implementation friction shows the sketch is wrong.

## Arena

1. Frame artifact and rubric.
2. Fan out candidates to separate paths or worktrees.
3. Run a judge after candidates complete.
4. Parent reads all candidates and scores against rubric.
5. Pick a base, graft coherent strengths, reject the rest with reasons.
6. Verify the synthesized artifact.

## Interrogate

Use when a diff, design, or PR needs adversarial pressure.

1. Give reviewers the diff/design and the intended behavior.
2. Run several independent reviews with different lenses: correctness, architecture, type/data shape, and code quality.
3. Parent triages findings into fix, reject, or follow-up.
4. Verify fixes, and record why rejected findings were not real.
