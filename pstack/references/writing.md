# Writing

Write cleanly on the first pass. Do not generate sloppy prose and rely on cleanup.

## Style

- Short declarative sentences.
- One thought per sentence.
- No fabricated links, citations, transcript references, PR statuses, or command outputs.
- Frame impact for the consumer first, then the maintainer.
- Keep every required section from the playbook, but cut filler.
- Use tables for real comparisons. Use bullets for parallel items.
- Say `unverified` or `inconclusive` when that is the state.

## Final Reply Shape

Adapt to the task, but preserve the facts:

```text
What changed or what I found.

Key decision:
<decision and reason>

Verification:
<commands, artifacts, runtime checks, screenshots, or why not run>

Open:
<risks, gaps, or next checks>
```

For a tiny task, collapse this into a short paragraph plus one verification line.

## PR And Commit Prose

- Small PRs do not need boilerplate headings.
- Commit subject states the change. Body explains why only when the subject is not enough.
- PR description names behavior, proof, and risk.
- Do not restate the diff file by file unless that helps review.

## Comments In Code

Keep comments only for non-obvious reasons the code cannot show. Delete narration such as `Phase 1`, `move the card`, or `assign the value`. Prefer assertions and test names that state the expected behavior.

## Bad Signals

Remove:

- "comprehensive", "robust", "seamless", and similar unverifiable claims,
- "should work" when unverified,
- passive summaries of worker self-reports,
- long apologies,
- generic best-practice language not tied to the code,
- citations to principles that did not change a decision.
