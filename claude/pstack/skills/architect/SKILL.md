---
name: architect
description: "Sketch types, signatures, and module structure before code, then stay in the loop while implementation fills in. Use for 'architect this', 'design this', or non-trivial work where jumping to code would lock in the wrong shape."
---

# Architect

Design before implementing. Sketch types, function signatures, class shapes, and module boundaries with `not implemented` bodies and pseudocode. Compare structurally distinct candidates, then fill in code against the chosen sketch. If implementation proves the sketch wrong, throw it out and redesign.

Claude Code port of pstack's `architect`. The runner prompt, rationale template, and red-flag list in `references/` are upstream's. Principle files live in the `pstack` skill's `references/principles/`.

## Usage profile

Read `.pstack/config.md` in the repository root if it exists. Otherwise the profile is `balanced`.

- `lean` and `balanced`: the parent writes both candidates in Phase B, one after the other. Do not spawn subagents unless the user asks.
- `review-heavy`: spawn two `Plan` agents with the Agent tool in Phase B, in one message. Each returns its design package as text, and you save it to its own candidate path.

## Start

Keep a checklist with one entry per phase.

1. Ground
2. Sketch
3. Agree
4. Implement
5. Scrap

## Phase A: Ground the problem

Build a real mental model of every system the new code touches. Run the **how** skill over the relevant subsystems.

Naming a file isn't grounding. Produce the traced model `how` prescribes. If the design redefines ownership or layering, also run the **why** skill on the existing shape so the rationale becomes a constraint, not a guess.

Skip Phase A only when the work is genuinely greenfield with no surrounding system to integrate. Say so.

## Phase B: Sketch

Design it twice. Produce at least two structurally distinct candidates before choosing, even when the first looks sufficient. Whole-shape alternatives, not point fixes inside one shape. This is the **exhaust-the-design-space** principle made concrete.

Each candidate follows `references/runner-prompt.md` and produces a design package shaped per `references/rationale-template.md`. Write each to its own path, for example `<scratchpad>/architect-<slug>/candidate-<n>/`, using the session's scratchpad directory when one exists and `/tmp` otherwise. When the parent writes both, finish and save the first before starting the second, and make the second reject the first's central choice.

Screen every candidate against `references/design-red-flags.md`. Reject or revise shallow modules, information leakage, temporal decomposition, and pass-through methods.

Compare viable candidates on interface depth. Prefer the design that hides more complexity behind a smaller, simpler public surface. Pick a base, graft the best parts of the other, and record the decision in the rationale's "Synthesis decision" section.

## Phase C: Agree (opt-in)

Default: proceed directly to implementation with the chosen design. No human checkpoint.

Opt in to a checkpoint only when the user asks ("with checkpoint", "show me before implementing"). Then surface the design and pause for sign-off.

The sketch can ship as its own commit, the "scaffold first" mode of **foundational-thinking**. If the human pushes back on the shape, treat that as Phase A evidence. Re-ground and redo Phase B before writing more code.

## Phase D: Implement against the sketch

Replace `not implemented` bodies with code, pseudocode with logic. The sketch is the contract.

Deviations from the sketch are signal worth surfacing, not friction to absorb silently. If a function needs a parameter the sketch didn't anticipate, ask whether the sketch was wrong, the requirement was missed, or the implementation is overreaching.

## Phase E: Scrap when the architecture is wrong

If implementation keeps producing friction the sketch can't absorb, throw the sketch out. Don't bolt fixes onto a wrong design, per **redesign-from-first-principles** and **fix-root-causes**.

The signal is a *pattern*, not single instances:

- The same shape of workaround appearing repeatedly across unrelated code.
- Multiple unrelated edge cases that all need special-case branches.
- Types that need escape hatches (`any`, casts, optional fields always set in practice) to compile.
- The "we need a lock" reflex when the sketch said the state wasn't shared.
- Callers having to know the abstraction's internal rules to use it.

When you scrap: re-run **how** over what's been built, redesign as if the new constraints were day-one assumptions, subtract before adding (**subtract-before-you-add**), and return to Phase B.

## Outputs

The caller's usage is written first and the type sketch derived from it. One file with new types and signatures for small changes. Module map plus type definitions for larger work. The rationale ships alongside, shaped per `references/rationale-template.md`.
