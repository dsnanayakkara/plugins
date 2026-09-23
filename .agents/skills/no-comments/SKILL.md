---
name: no-comments
description: "Run the Comment Sicko pass over a diff, fix accepted findings, and offer encodings for claimed constraints. Use before review or when asked to strip unnecessary comments."
---

# No comments

Run Comment Sicko over the scope. Act on accepted findings.

Codex port of pstack's `no-comments`. Comment Sicko's rules are upstream's, in `references/comment-sicko.md`.

## Usage profile

Read `.pstack/config.md` in the repository root if it exists. Otherwise the profile is `balanced`.

- `lean` and `balanced`: run the pass in the parent. Read `references/comment-sicko.md` in full and apply it as a separate pass after implementation is done.
- `review-heavy`: spawn Comment Sicko with `spawn_agent`, giving it `references/comment-sicko.md` as its instructions and the scope. Do not restate its rules.

## Scope

Use the caller's files or diff. Otherwise use the current diff against the base branch, default `main`, including the working tree.

## Steps

1. Run the pass per the usage profile.
2. Inspect the findings and edits. Reject application-code edits, scope escapes, and flags that treat kept intentional code as guilty. A keep survives only with proof it is about something we cannot change. Before accepting thin `IMPORTANT` or `do not remove` kills or keeps, run **how** or **why** on their symbol. If a kill is ambiguous, do not restore. If a keep is refuted or still ambiguous, delete it.
3. Fix trivial accepted flags directly by deleting a dead path, dropping a parameter, or using the real API. If any fix needs a new shape, run **architect** once for the accepted set and stop at the sketch.
4. Implement the smallest root-cause fix in scope. Remove every named workaround. If the root cause is out of scope, land the smallest in-scope fix and report the rest open. Never bolt on symptom guards.
5. Constraint comments (`do not remove`, `talk to X before changing`) about things we cannot change stay. For the rest, offer the cheapest in-scope type, runtime check, test, or lint that enforces the constraint. Wait for the user's approval. If approved, encode then delete. Otherwise delete and report the constraint open.
6. Report the deletion count, restored comments, fixes, encoding offers, encodings, unenforced constraints, and other open work.
