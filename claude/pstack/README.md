# pstack for Claude Code

Claude Code port of [pstack](../../pstack/README.md), Lauren Tan's engineering workflow plugin for Cursor. It keeps pstack's process rules (reproduce before fixing, pin behavior before refactoring, label evidence) and spends little on subagents by default.

## Install

Nothing is published. The marketplace is this repository.

    claude plugin marketplace add /path/to/this/repo
    claude plugin install pstack@dsnanayakkara-local

The plugin then loads in every Claude Code session on this machine.

## Use

- `/pstack:pstack <task>` runs the workflow. It picks a playbook (investigation, bug fix, feature, refactoring) or routes to `/pstack:figure-it-out`.
- `/pstack:setup-pstack` picks a usage profile for the current repository.
- `how`, `why`, `architect`, `no-comments`, and `deslop` also run on their own when a task matches.
- `figure-it-out`, `show-me-your-work`, `tdd`, `unslop`, and `technical-writing` run only when you type them.

## Profiles

`.pstack/config.md` in a repository sets the profile. It is kept out of git.

| | lean | balanced (default) | review-heavy |
|---|---|---|---|
| Reviewer | none; self-review | `pstack:reviewer` on non-trivial diffs | on every change |
| how, why, architect | main agent | main agent | `Explore` and `Plan` subagents |
| Comment pass | main agent | main agent | `pstack:comment-sicko` |

Both agents are read-only (`Read`, `Grep`, `Glob`) and default to Sonnet. Set `reviewer-model:` in the config to change it.

## Update

Most skill files are links into `pstack/` (upstream) and `.agents/` (the Codex port). An install copies them into the cache, and updates compare only the version. After any change, including an upstream sync:

    claude/check-links.sh
    # bump "version" in claude/pstack/.claude-plugin/plugin.json
    claude plugin update pstack@dsnanayakkara-local

Then restart Claude Code. Uninstalling leaves `~/.claude/plugins/cache/dsnanayakkara-local/` behind, so delete it by hand.

## Not ported

`arena`, `interrogate`, `swarm`, and `reflect` rely on multi-model panels, which this port leaves out to save cost. Cursor-only skills are also left out. The 22 principles are references inside `pstack`, not standalone skills.
