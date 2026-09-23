# pstack Claude Code port: design

Date: 2026-09-23. Branch: `claude-pstack`, based on `codex-pstack`.

## Goal

Make pstack's workflow usable in Claude Code as a normal marketplace plugin. You install it once from a local marketplace in this repository, and it loads in every Claude Code session on the machine. Nothing is published to a remote marketplace.

The port follows the Codex port on `codex-pstack`. The upstream Cursor plugin in `pstack/` stays unchanged. The port links to upstream files instead of copying them, and it keeps subagent use cheap.

## Decisions already made

- It is a real Claude Code plugin, installed with `claude plugin install`. It is not loose files in `~/.claude/skills`.
- Skill scope is the Codex set plus the extras: `pstack`, `setup-pstack`, `how`, `why`, `architect`, `deslop`, `no-comments`, `figure-it-out`, `show-me-your-work`, `tdd`, `unslop`, and `technical-writing`. The 22 principles stay as references, not skills.
- `arena`, `interrogate`, `swarm`, and `reflect` are not ported. Neither is any other upstream skill not listed above.
- The usage profiles are the Codex ones: `lean`, `balanced` (the default), and `review-heavy`. Each repository stores its profile in `.pstack/config.md`, which is not committed.
- `figure-it-out` stays user-invoked only, as upstream has it. The `pstack` skill routes to it when no playbook fits.

## Measured install behavior

Measured on 2026-09-23 with Claude Code 2.1.280 and a throwaway local marketplace:

- `claude plugin install` from a local directory marketplace copies the plugin to `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`.
- A symlink that points elsewhere inside the marketplace directory becomes a regular file in the cache. That covers file links, whole skill-directory links, and a symlinked `SKILL.md`, and all of them register.
- A `SKILL.md` nested under `references/` does not register as a skill.
- `claude plugin update` compares the `version` field in `plugin.json`. The cache does not change until the version changes.
- `claude plugin details <plugin@marketplace>` lists the registered skills and agents and their token cost, with no model call.
- `claude plugin validate` does not follow symlinks.
- `uninstall` and `marketplace remove` leave the cache directory in place.

Because of these results, the marketplace manifest sits at the repository root. That keeps every link to `pstack/` and `.agents/` inside the marketplace.

## Layout

```
.claude-plugin/marketplace.json        name "dsnanayakkara-local"; one plugin: pstack, source ./claude/pstack
claude/check-links.sh                  fails on a broken link, or on a link that leaves the repository
claude/pstack/
  .claude-plugin/plugin.json           name "pstack", version 0.1.0, license MIT
  README.md
  agents/reviewer.md                   written
  agents/comment-sicko.md              written frontmatter; body reads the prompt path the caller passes
  skills/
    pstack/SKILL.md                    written
    pstack/references/{playbooks,principles,writing} -> .agents/skills/pstack/references/<same>
    setup-pstack/SKILL.md              written
    how/SKILL.md                       written; references -> pstack/skills/how/references
    why/SKILL.md                       written; references -> pstack/skills/why/references
    architect/SKILL.md                 written; references -> pstack/skills/architect/references
    no-comments/SKILL.md               written; references/comment-sicko.md -> pstack/agents/comment-sicko.md
    deslop/SKILL.md                    -> .agents/skills/deslop/SKILL.md
    figure-it-out/SKILL.md             written
    show-me-your-work/SKILL.md         written; references and scripts -> upstream
    tdd/SKILL.md                       -> pstack/skills/tdd/SKILL.md
    unslop/SKILL.md                    -> pstack/skills/unslop/SKILL.md
    technical-writing/SKILL.md         -> pstack/skills/technical-writing/SKILL.md
```

All links are relative. The Comment Sicko prompt lives under the `no-comments` skill, the same place the Codex port keeps it, and never under `agents/`, where it could register as a second agent. When `no-comments` spawns `pstack:comment-sicko`, it passes the prompt's absolute path, which it builds from the skill's base directory. The agent body says to read that file in full before doing anything. That way the agent doesn't depend on any path variable being expanded inside an agent file.

The principle links reuse the Codex port's `references/principles` directory. That directory already maps each upstream `principle-*/SKILL.md` to a short file name. The four playbooks exist only in the Codex port.

## Skills written for Claude Code

Each written skill is a Claude Code version of the Codex skill with the same name. These changes apply to all of them:

- Replace `spawn_agent` and `wait_agent` with the Agent tool and a named `subagent_type`.
- Replace `$pstack` invocation with `/pstack:<skill>`.
- Keep the usage-profile section. Read `.pstack/config.md` from the repository root, or default to `balanced`.
- When a skill needs a user-only skill, read that skill's file by relative path (for example `../show-me-your-work/SKILL.md`). Don't invoke it through the Skill tool.

Skill-specific changes:

- **pstack.** It has `disable-model-invocation: true` and `argument-hint: <task>`. It routes large, cross-cutting, or unattended work, and work that fits no playbook, to `figure-it-out`. It drops the Codex-only rules. It names the reviewer as `pstack:reviewer`.
- **setup-pstack.** It has `disable-model-invocation: true`. It offers the three profiles and writes `.pstack/config.md`. It optionally writes `reviewer-model: opus|sonnet|haiku`. It changes no Claude Code settings and spawns no agents.
- **how, why, architect.** These are model-invocable. In `review-heavy`, `how` explorers and `why` investigators run as built-in `Explore` agents. `architect` runners run as built-in `Plan` agents that return the design package as text, and the main agent saves each candidate to its own path.
- **no-comments.** It is model-invocable. In `review-heavy`, the pass runs as `pstack:comment-sicko`. Otherwise the main agent reads the prompt and applies it.
- **figure-it-out.** It has `disable-model-invocation: true`. Compared with upstream, it reads the Principles section of `../pstack/SKILL.md` instead of `poteto-mode`, and it runs `architect` without `arena`. Fan-out follows the usage profile, and the audit trail uses `../show-me-your-work/SKILL.md`.
- **show-me-your-work.** It has `disable-model-invocation: true`. The transcript audit greps the current session log under `~/.claude/projects/<project>/` instead of Cursor's `agent-transcripts/`, and it never reads another session's log. The cross-model review becomes a `pstack:reviewer` pass on the trail in `review-heavy`. In `lean` and `balanced`, the main agent audits the trail. The Attention section names the reviewer as `pstack:reviewer (<model>)` or `self`.

The linked skills (`deslop`, `tdd`, `unslop`, `technical-writing`) run unchanged. Upstream already marks `tdd`, `unslop`, and `technical-writing` as user-invoked only. `deslop` stays model-invocable.

## Agents

| Agent | tools | model | Input |
|---|---|---|---|
| `pstack:reviewer` | `Read, Grep, Glob` | `sonnet` | The stated intent, the diff, and the verification output. It returns findings and edits nothing. |
| `pstack:comment-sicko` | `Read, Grep, Glob` | `sonnet` | The diff or the files in scope. It reports kills and `MUST KILL` flags. |

Neither agent gets Bash, because Bash can write files. The main agent passes in the diff and the verification output. When `.pstack/config.md` has a `reviewer-model` line, the skill passes that value as the Agent tool's `model` override.

## Profiles

| | lean | balanced (default) | review-heavy |
|---|---|---|---|
| Reviewer on non-trivial diffs | none; self-review | one `pstack:reviewer` | `pstack:reviewer` on every change |
| Comment pass | main agent | main agent | `pstack:comment-sicko` |
| how, why, architect | main agent | main agent | `Explore` and `Plan` fan-out |
| Two design candidates | main agent, only for new data shapes or public APIs | same | two `Plan` runners |
| show-me-your-work audit | self | self | `pstack:reviewer` |

In every profile, the main agent writes the code.

## Error handling

- `.pstack/config.md` is missing or has no recognized profile. Use `balanced` and say so in the reply.
- A plugin agent fails to spawn. Run that step in the main agent and report the fallback. Don't skip the step.
- `check-links.sh` exits non-zero when a link is broken or leaves the repository. Run it before every version bump.

## Verification

Structural checks, with no model calls:

1. `claude/check-links.sh` passes.
2. `claude plugin validate` passes on `claude/pstack/` and on the repository root marketplace.
3. `claude plugin marketplace add <repo>`, then `claude plugin install pstack@dsnanayakkara-local`.
4. `claude plugin details pstack@dsnanayakkara-local` lists exactly the 12 skills and 2 agents. Record the always-on token cost.
5. The cached copy contains no symlinks (`find <cache> -type l` prints nothing). One principle file, one playbook, and the Comment Sicko prompt have content.

Behavior checks: two headless runs on Sonnet in a throwaway git repository in the scratchpad.

6. Tell `pstack:reviewer` to edit a file. The file must be unchanged. This run also confirms the `subagent_type` string for plugin agents.
7. With `.pstack/config.md` set to `lean`, run `/pstack:pstack` on a trivial task. It names the profile and the playbook, and spawns no subagents. Also check whether bare `/pstack` resolves.

## Install and update (README content)

```
claude plugin marketplace add /path/to/plugins-fork
claude plugin install pstack@dsnanayakkara-local
```

After any change, including an upstream sync, bump `version` in `claude/pstack/.claude-plugin/plugin.json`. Then run `claude plugin update pstack@dsnanayakkara-local` and restart Claude Code. Uninstalling leaves `~/.claude/plugins/cache/dsnanayakkara-local/` behind. Delete it by hand.

## Out of scope

- Publishing to a remote marketplace.
- Syncing the Codex and Claude versions of the shared skills (Approach C). Revisit this if the two versions drift.
- Making `figure-it-out` model-invocable. Revisit with `claude plugin eval` if needed.
- A version-bump script. Add one only when manual bumps become a chore.

## Git

Commit on `claude-pstack`. Push only to `fork`, and only when the user asks.
