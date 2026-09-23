---
name: setup-pstack
description: Configure pstack's Claude Code usage profile for delegation and review. Use for /pstack:setup-pstack.
disable-model-invocation: true
---

# Set up pstack for Claude Code

Configure the pstack skill's repository-local delegation policy. This is the Claude Code equivalent of pstack setup: it does not configure Cursor models or write `~/.cursor/rules/pstack-models.mdc`.

## Steps

1. Identify the repository root and read `.pstack/config.md` if it exists. If it does not, treat the current profile as `balanced`.
2. Offer these profiles and explain their impact in one line each:
   - `lean`: parent implements and self-reviews; `how`, `why`, `architect`, and `no-comments` run in the parent; no subagents unless the user explicitly asks.
   - `balanced`: parent implements; one read-only reviewer on non-trivial diffs (intent + diff + verification output only); two design candidates only for new data shapes or public APIs, written by the parent; `how`, `why`, `architect`, and `no-comments` run in the parent; no other panels unless asked.
   - `review-heavy`: parent implements; `pstack:reviewer` on every change; `how` explorers and `why` investigators run as `Explore` agents, `architect` runners as `Plan` agents, and Comment Sicko as `pstack:comment-sicko`.
3. Ask which profile the user wants. Recommend `balanced` for small personal projects. Keep the existing choice if the user asks to inspect or preserve it.
4. After the user selects a profile, write `.pstack/config.md` in the repository with the selected profile and its exact policy from step 2. Preserve unrelated content if the file already exists. The first line is `# pstack usage profile` and the second is `Profile: <name>`.
5. Unless the profile is `lean`, ask which model the reviewer should use: `sonnet` (the default, cheaper), `opus` (more rigor, higher cost), or `haiku` (cheapest, weakest). Write `reviewer-model: <value>` under the `Profile:` line only when the user picks something other than `sonnet`. When the choice is `sonnet` or the profile is `lean`, remove any `reviewer-model:` line already in the file, so an old `opus` choice doesn't keep costing more.
6. If `git check-ignore -q .pstack/config.md` fails, append `.pstack/` to the file `git rev-parse --git-path info/exclude` prints (it works in worktrees, where `.git` is a file) so the file stays out of commits without touching `.gitignore`.
7. Report the selected profile, the reviewer model, the repository-local path, and that the profile applies to `/pstack:pstack` work in this repository. Do not claim that Claude Code settings or model access changed.

Do not change Claude Code settings, Cursor rules, model access, or billing settings. Do not spawn agents while configuring this file.
