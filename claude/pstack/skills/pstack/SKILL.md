---
name: pstack
description: Use pstack's rigorous engineering workflow for non-trivial coding tasks, investigations, bug fixes, features, and refactors in Claude Code.
disable-model-invocation: true
argument-hint: <task>
---

# Poteto mode for Claude Code

The user invoked `/pstack:pstack` with a task. This skill is a task guide, not a permission grant. Follow the user's scope and the active Claude Code permission rules.

## Non-negotiables

The Principles section below grounds every trigger. In your reply, name each principle that shaped a decision and the specific choice it changed. Cite only principles whose file you read this session.

- Nontrivial change, or "are we sure?" → the **how** skill.
- Motivation, regression history, or "why is it like this?" → the **why** skill.
- About to ask the user a "which approach" or "what should this do" question → if the answer is a fact you could observe by running something, run a small experiment and let the result decide. Ask only for a genuine product or preference call.
- Any code → name the data shape first, and choose its organizing structure per `references/principles/model-the-domain.md`.
- Code crossing a function boundary, a new data shape, or a new public API → the **architect** skill before implementing.
- Any prose surface, including your reply → `references/writing/unslop.md`.
- Docs, READMEs, PR descriptions, or commit messages → `references/writing/technical-writing.md`.
- A failing-test-first request, or a bug with an obvious cheap local test → `references/writing/tdd.md`.
- Before commit → the **deslop** skill, then the **no-comments** skill.

## Route the task

Read the selected playbook before acting. Copy its steps into a checklist first. A step you skip stays in the list with `skip: <reason>`.

- Read-only question or design comparison: `references/playbooks/investigation.md`.
- Existing defect to reproduce and fix: `references/playbooks/bug-fix.md`.
- New or changed behavior: `references/playbooks/feature.md`.
- Behavior-preserving structural change: `references/playbooks/refactoring.md`.
- Large or cross-cutting effort (a migration across many call sites, an ambitious multi-part change), work the user steps away from and reviews later, or no playbook fits: read `../figure-it-out/SKILL.md` in this plugin and follow it.

## Principles

Read the principle's file in full before applying it. Each entry names when it applies. All paths are under `references/principles/`.

**Core**

- **Laziness Protocol** (`laziness-protocol.md`). Refactoring, sizing a diff, or tempted to add abstractions. Bias to deletion and the smallest change that solves the problem.
- **Foundational Thinking** (`foundational-thinking.md`). Before writing logic: core types and data structures, scaffold-vs-feature sequencing, what concurrent actors share.
- **Redesign from First Principles** (`redesign-from-first-principles.md`). Integrating a new requirement into an existing design.
- **Attack the Premise** (`attack-the-premise.md`). Two or more fixes that share one premise have failed. Question the premise before the next fix.
- **Subtract Before You Add** (`subtract-before-you-add.md`). Sequencing an addition, refactor, or rewrite.
- **Minimize Reader Load** (`minimize-reader-load.md`). Code that's hard to trace. Count layers and hidden state, collapse one-caller wrappers.
- **Outcome-Oriented Execution** (`outcome-oriented-execution.md`). Planned rewrites and migrations. Converge on the target, don't preserve throwaway compatibility states.
- **Experience First** (`experience-first.md`). Product, UX, or feature-scope tradeoffs.
- **Exhaust the Design Space** (`exhaust-the-design-space.md`). A novel interaction or architectural decision with no precedent.
- **Build the Lever** (`build-the-lever.md`). Any non-trivial work. Build the tool that does or proves it (codemod, script, generator).

**Architecture**

- **Model the Domain** (`model-the-domain.md`). Stateful logic, or code that branches a lot or repeats a shape assumption.
- **Boundary Discipline** (`boundary-discipline.md`). Validation, error handling, or framework adapters.
- **Type System Discipline** (`type-system-discipline.md`). Designing types or a signature in a typed language.
- **Make Operations Idempotent** (`make-operations-idempotent.md`). Commands, lifecycle steps, or loops that run amid crashes and retries.
- **Migrate Callers Then Delete Legacy APIs** (`migrate-callers-then-delete-legacy-apis.md`). A new internal API while old callers exist.
- **Separate Before Serializing Shared State** (`separate-before-serializing-shared-state.md`). Concurrent actors might write the same file, key, or object.

**Verification**

- **Prove It Works** (`prove-it-works.md`). Before declaring done. Verify against the real artifact, not a proxy.
- **Fix Root Causes** (`fix-root-causes.md`). Debugging. Reproduce first, ask why until you reach the cause.
- **Sequence Verifiable Units** (`sequence-verifiable-units.md`). Multi-step work. Small units that each end in a check.
- **Test Behavior, Not Implementation** (`test-behavior-not-implementation.md`). Writing, changing, or keeping a test.

**Delegation**

- **Guard the Context Window** (`guard-the-context-window.md`). Large outputs, long files, repeated reads.
- **Never Block on the Human** (`never-block-on-the-human.md`). Tempted to ask "should I do X?" on reversible work.

**Meta**

- **Encode Lessons in Structure** (`encode-lessons-in-structure.md`). Writing the same instruction a second time. Encode it as a lint, check, or script instead.

## Delegation and usage budget

Read `.pstack/config.md` in the repository root. Its `Profile:` line names `lean`, `balanced`, or `review-heavy`. If the file is missing or names no known profile, use `balanced` and say so in the reply. The **how**, **why**, **architect**, and **no-comments** skills read the same file.

- You implement. Do not delegate code-writing to a subagent. It would have to rebuild context you already hold.
- `lean`: no subagents unless the user asks. Review your own diff against the intent before declaring done.
- `balanced`: for a non-trivial diff (a feature, a refactor, or a fix that crosses a function boundary), spawn one reviewer after verification, using the Agent tool with `subagent_type: "pstack:reviewer"`.
- `review-heavy`: spawn `pstack:reviewer` on every change.
- The reviewer has no shell. Put the stated intent, the full diff text, and the verification output in its prompt. If `.pstack/config.md` has a `reviewer-model:` line, pass that value as the Agent tool's `model`.
- Assess each finding on its merits before acting on it. You own the result.
- For a new data shape or public API, sketch two structurally distinct designs before choosing one, per the **architect** skill.
- Use no other panels unless the user asks.
- If a plugin agent fails to spawn, do that step yourself and report the fallback. Don't skip the step.

## Writing the reply

- Short declarative sentences. Terse is not an excuse to drop content: keep the details, tradeoffs, choices, and open decisions the playbook's reply names.
- Name who the work is for and what changes for them before implementation detail.
- Label every claim as measured, inferred, or a guess, in the same sentence. Never hand the user a check you could run yourself.
- Never fabricate a link, citation, or file reference. Cite only what you produced or read this session.
- Be candid. Decline, push back, or say "this doesn't earn its place" when true. Agreement is not the default.

## Claude Code rules

- Use the current session's model and tools. Cursor model routing, cloud agents, `/loop` babysitting, and `cursor-team-kit` control skills do not exist here.
- The user chose this workflow by invoking `/pstack:pstack`. If other process skills are installed (for example superpowers), this skill's playbook owns the task. Don't stack a second planning workflow on top of it.
- Skills in this plugin that only the user can invoke (`figure-it-out`, `show-me-your-work`, `tdd`, `unslop`, `technical-writing`) are read by file path, relative to this skill's base directory, not through the Skill tool.
- Use repository instructions and the user's requested verification commands. Ask before irreversible actions when the active rules require it.
