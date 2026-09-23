---
name: why
description: "Use for 'why does X work this way', 'why we picked Y', design rationale, regressions, postmortems, or data-backed thresholds. Queries each available evidence category (source control, issue tracker, long-form docs, team chat, observability, error tracking, analytics), then returns a cited read on decisions and tradeoffs. Use how for runtime behavior."
---

# Why

Investigate the motivation and intent behind code.

Companion to the `how` skill. `how` answers what the code does and how it works. `why` answers what forces led to its shape.

Codex port of pstack's `why`. The templates, epistemics framework, and source playbooks in `references/` are upstream's.

## Usage profile

Read `.pstack/config.md` in the repository root if it exists. Otherwise the profile is `balanced`.

- `lean` and `balanced`: run every investigation in the parent, one evidence category at a time. Do not spawn subagents unless the user asks.
- `review-heavy`: spawn one investigator per available category with `spawn_agent`, all at once.

The coverage map and the confidence separation are required in every profile. Only who does the searching changes.

## Operating Posture

Operate as a **careful, cautious, and precise investigator**. Be honest about what you know vs what you're inferring. Read `references/epistemics.md` for the full confidence framework and phrasing guide, and follow it in the final answer.

## Step 1. Understand the Target and the Question

Parse what the user is asking. The **target** is usually a chunk of code, a pattern, a feature, or a named design decision. The **question** is usually a design rationale, a tradeoff, a motivating edge case, an external constraint, dead code, or a broad history sweep.

If the target is vague, make your best guess from conversation context. State your interpretation briefly so the user can redirect, then proceed.

## Step 2. Establish the Code Anchor

Anchor the investigation in concrete code. You need:

- The relevant file path(s) and line range(s)
- The key symbols (function names, class names, constants)
- An initial commit list. The last few commits touching the target.
- PR numbers from merge commits (pattern `(#1234)` in the subject line)

```bash
git blame -L <start>,<end> <file>
git log --follow -p -- <file>
git log --oneline -20 -- <file>
git log -1 --format=%B <commit>
gh pr view <number> --json title,body,author,createdAt,mergedAt,labels,closingIssuesReferences,comments,reviews
```

Capture this as seed context (file paths, symbols, commits, PR numbers, linked ticket IDs).

## Step 3. Investigate each evidence category

### Discovery

List the MCP servers and tools available in this Codex session. Map each to one evidence category:

1. Source control history
2. Issue / ticket tracker
3. Long-form documents
4. Real-time team chat
5. Infrastructure observability
6. Error / exception tracking
7. Product analytics warehouse

Source control is always available through git and `gh`. Aim for a complete **coverage map**, not a minimal one. Document the null, don't skip the search.

### Per category

For each category with a matching tool, investigate using:

1. `references/investigator-prompt.md`
2. The matching playbook in `references/sources/` (see `references/source-playbook.md`), adapted to the available tool
3. `references/sources/incident-postmortem.md` **if the target code looks defensive** (null checks, retries, timeouts, rate limits, feature flags, OOM handlers)
4. The code anchor from Step 2
5. The user's original question

In `review-heavy`, each investigator is a `spawn_agent` subagent that owns exactly one category and is told not to edit files. Otherwise, you run the categories yourself and record each one's findings separately before moving on.

### When to skip a category

Only skip with an **explicit, written justification** that goes in "Sources Consulted":

- **No tool is available for that category.** Flag it as a gap, not a choice.
- **The source is provably irrelevant**, not just "probably irrelevant."

## Step 4. Synthesize

Write the answer from the per-category findings, following `references/synthesizer-prompt.md` and `references/epistemics.md`. Spot-check the citations you rely on most.

## Output Format

The Question, The Code in Question, What We Found, What We Can Reasonably Infer, Competing Hypotheses, What We Don't Know, Sources Consulted, Confidence Summary. Keep Sources Consulted as one line per category, including empty and skipped ones with the reason.

If the `why` question precedes changing this code, end with a Preserve / Change / Avoid / Risk constraint set for planning the change.

## Common Failure Modes to Avoid

- **Recency bias**. Assuming the most recent commit is authoritative. The current shape is often the accretion of many earlier decisions. Trace back.
