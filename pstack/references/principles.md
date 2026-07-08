# Principles

Read this at the start of every multi-step pstack task. Name only the principles that actually changed a decision.

## Core

### Laziness Protocol

Bias toward deletion and the smallest change that solves the problem. Avoid abstractions, layers, signal threading, and compatibility code that do not earn their place. If a human maintainer would find the result exhausting, simplify.

### Foundational Thinking

Get the data structures, core types, ownership, and concurrency shape right before logic. Scaffold that helps every later phase comes before feature work. Subtraction comes before scaffolding.

### Redesign From First Principles

When integrating a new requirement, design as if that requirement existed on day one. Do not bolt a special case onto the old shape. Propagate the choice through callers, types, docs, and tests.

### Subtract Before You Add

Remove dead weight, redundant validators, orphan references, and one-caller wrappers before adding new structure. A smaller base usually makes the next design obvious.

### Minimize Reader Load

Optimize for how quickly a future reader can answer where a value comes from and what can change it. Collapse layers that do not earn their keep. Shrink mutable state scope.

### Outcome-Oriented Execution

During a planned migration or rewrite, converge on the intended end state. Do not preserve throwaway intermediate compatibility unless it is required by an external contract.

### Experience First

The user is the person who consumes the work: end user, library caller, reviewer, or future maintainer. Choose their experience over implementation convenience.

### Exhaust The Design Space

For novel UI or architectural choices with no clear precedent, build or sketch 2-3 alternatives before committing. Compare concrete artifacts, not vibes.

### Build The Lever

For non-trivial edits, migrations, analyses, or checks, build the tool that does or proves the work: script, codemod, generator, query, harness, or delegate skill. The lever is the rerunnable artifact.

## Architecture

### Boundary Discipline

Validate at system boundaries: CLI args, config, network, external APIs, files. Trust internal typed data. Keep business logic pure and framework shells thin.

### Type System Discipline

Make illegal states unrepresentable. Brand semantic primitives. Parse external data at boundaries. Avoid casts that lie to the compiler. Exhaust variants. Derive types from authoritative schemas.

### Make Operations Idempotent

Commands, lifecycle steps, and processing loops must converge to the same end state after retries, restarts, or partial prior runs. Ask what happens if it runs twice or crashes halfway.

### Migrate Callers Then Delete Legacy APIs

When a new internal API is the right shape, inventory callers, migrate them, and delete the old API in the same wave. Avoid parallel old/new paths.

### Separate Before Serializing Shared State

When concurrent actors might write the same file, branch, key, or object, eliminate sharing first. Give workers independent ownership. Use structural serialization only when one shared writer is a real invariant.

## Verification

### Prove It Works

Verify the real artifact directly. Run the feature, inspect the output, compare screenshots, query the data, or exercise the integration. Builds and type checks are necessary but not sufficient.

### Fix Root Causes

For debugging, reproduce first, trace symptoms to mechanism, and fix there. Instrument when stuck. Do not silence crashes with guards unless the guard is the root-cause boundary.

### Sequence Work Into Verifiable Units

Break multi-step work into small units that each end in a check. Verify before advancing. Deliver commits in an order that proves the story: baseline, failing repro, fix, cleanup.

## Delegation

### Guard The Context Window

Large outputs, traces, broad searches, and repeated reads go to subagents or scripts. Keep reduced findings in the main thread.

### Never Block On The Human

Proceed on reversible work. Ask only for irreversible actions, external messages, destructive operations, or genuine product preference that cannot be observed.

## Meta

### Encode Lessons In Structure

When the same correction appears twice, encode it as a lint, schema, test, script, metadata flag, or skill. Textual reminders are the weakest guardrail.
