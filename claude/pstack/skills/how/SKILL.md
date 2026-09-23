---
name: how
description: "Use for \"how does X work\", code walkthroughs before changing something, and placement / ownership / layering questions (\"where should this live\", \"which package owns this\", \"is this the right layer\"). Explains subsystem architecture, runtime flow, onboarding mental models. Use why for motivation."
---

# How

Explore the codebase to answer "how does X work?" questions. Produce architectural explanations at the level of a senior engineer onboarding onto a subsystem, enough to build a working mental model, not so much that it reads like annotated source code.

Claude Code port of pstack's `how`. The prompt templates in `references/` are upstream's.

## Usage profile

Read `.pstack/config.md` in the repository root if it exists. Otherwise the profile is `balanced`.

- `lean` and `balanced`: explore and explain in the parent, following the templates yourself. Do not spawn subagents unless the user asks.
- `review-heavy`: use the parallel explorer path in Step 2a for complex questions.

## Step 1. Assess Complexity

If the scope is ambiguous, state your interpretation and explore. The user can redirect.

- **Simple** (a single module, a small utility, a narrow question such as "how does function X work"): go to Step 2b.
- **Complex** (a subsystem spanning multiple files or services, a cross-cutting feature, a full architectural overview): go to Step 2a.

When in doubt, take the simple path.

## Step 2a. Explore (complex questions)

Decompose the question into 2 to 4 exploration angles, each a distinct slice of the subsystem.

- In `review-heavy`, spawn one `Explore` agent per angle with the Agent tool, all in one message. Each prompt is `references/explorer-prompt.md` with its angle filled in.
- Otherwise, work through each angle yourself in turn and record findings in the explorer template's shape.

Then go to Step 3.

## Step 2b. Direct Explain (simple questions)

Explore and explain in one pass, following `references/explainer-prompt.md` without the explorer-findings section. Go to Step 4.

## Step 3. Synthesize

Write one explanation from all angle findings, following `references/explainer-prompt.md`.

## Step 4. Present

Present the explanation. Cite only files you or an explorer actually read.

## Output Format

The explanation uses the sections defined in `references/explainer-prompt.md`, dropping any that do not apply: Overview, Key Concepts, How It Works, Where Things Live, Gotchas.
