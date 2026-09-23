# pstack Claude Code Port Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship pstack as a Claude Code plugin that installs from a local marketplace in this repository and loads in every session.

**Architecture:** The marketplace manifest sits at the repository root, and the plugin lives in `claude/pstack/`. The plugin has 12 skills and 2 read-only agents. Eight skills are written for Claude Code, adapted from the Codex port in `.agents/skills/` or from upstream. The rest are relative symlinks to upstream `pstack/` or to the Codex port. `claude plugin install` turns those symlinks into real files in the cache.

**Tech Stack:** Markdown skills and agents, JSON manifests, POSIX sh, and the Claude Code 2.1.280 plugin CLI.

**Spec:** `docs/superpowers/specs/2026-09-23-pstack-claude-code-port-design.md`

## Global Constraints

- The marketplace name is `dsnanayakkara-local`. The plugin name is `pstack`, starting at version `0.1.0`, under the MIT license.
- Never edit anything under `pstack/`, which is upstream, or under `.agents/`, which is the Codex port.
- Every link is relative and resolves inside the repository.
- The profiles are `lean`, `balanced`, and `review-heavy`. `balanced` is the default. The config lives at `.pstack/config.md`, is never committed, and uses a `Profile: <name>` line plus an optional `reviewer-model: opus|sonnet|haiku` line.
- These skills are user-invoked only (`disable-model-invocation: true`): `pstack`, `setup-pstack`, `figure-it-out`, `show-me-your-work`, `tdd`, `unslop`, and `technical-writing`.
- These skills are model-invocable: `how`, `why`, `architect`, `no-comments`, and `deslop`.
- The agents `pstack:reviewer` and `pstack:comment-sicko` have `tools: Read, Grep, Glob` and `model: sonnet`. They get no Bash.
- Commit on `claude-pstack`, and never push without the user asking. Every commit ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **An upstream edit with no version bump.** The installed plugin silently keeps the old text. The README says to bump the version, and Task 7 proves that the cache holds the current text.
2. **A link chain that breaks inside a linked directory.** For example, `pstack/references/principles` links to `.agents/…/principles`, and each file there links on to upstream. Task 1's checker uses `find -L`, so it walks into linked directories, and Task 7 checks the cache for leftover links.
3. **A missing or garbled `.pstack/config.md`.** The skill should fall back to `balanced` and say so. This rule lives in the `pstack` skill text (Task 4). Task 8 runs with a valid `lean` config, and its step 3 runs with no config.
4. **A wrong `subagent_type` string for plugin agents.** The reviewer would never run. Task 8 step 1 confirms the exact string.
5. **The reviewer gets no diff.** It has no Bash, so it cannot run `git diff` itself. The `pstack` skill (Task 4) and the reviewer agent (Task 2) both say that the main agent passes the diff text inline.

---

### Task 1: Marketplace, plugin manifest, link checker

**Files:**
- Create: `.claude-plugin/marketplace.json`
- Create: `claude/pstack/.claude-plugin/plugin.json`
- Create: `claude/pstack/LICENSE` (symlink to `../../pstack/LICENSE`)
- Create: `claude/check-links.sh`

**Interfaces:**
- Produces: `claude/check-links.sh [dir]`. It exits 0 when every path under `dir` (default `claude/pstack`) resolves, following links, to a location inside the repository. It exits 1 and prints each bad path otherwise.

- [ ] **Step 1: Write the checker**

```sh
#!/bin/sh
# Fails if any link under the Claude plugin is broken or resolves outside the repository.
# claude plugin install drops such links silently, so run this before every version bump.
set -eu

root="$(cd "$(dirname "$0")/.." && pwd -P)"
target="${1:-$root/claude/pstack}"
status=0

broken="$(find -L "$target" -type l)"
if [ -n "$broken" ]; then
  printf 'broken link: %s\n' $broken >&2
  status=1
fi

find -L "$target" | while IFS= read -r path; do
  resolved="$(realpath "$path" 2>/dev/null)" || continue
  case "$resolved" in
    "$root" | "$root"/*) ;;
    *) printf 'outside repo: %s -> %s\n' "$path" "$resolved" >&2; exit 1 ;;
  esac
done || status=1

[ "$status" -eq 0 ] && echo "links ok"
exit "$status"
```

Run `chmod +x claude/check-links.sh`.

- [ ] **Step 2: Write the manifests and the license link**

`.claude-plugin/marketplace.json`:

```json
{
  "name": "dsnanayakkara-local",
  "owner": { "name": "dsnanayakkara" },
  "metadata": {
    "description": "Local Claude Code marketplace for the pstack port. Not published."
  },
  "plugins": [
    {
      "name": "pstack",
      "source": "./claude/pstack",
      "description": "pstack for Claude Code: rigorous engineering playbooks with cost-conscious subagent use."
    }
  ]
}
```

`claude/pstack/.claude-plugin/plugin.json`:

```json
{
  "name": "pstack",
  "version": "0.1.0",
  "description": "Claude Code port of pstack: rigorous engineering playbooks, principles, and read-only review with cost-conscious subagent use.",
  "author": { "name": "Lauren Tan (upstream); Claude Code port by dsnanayakkara" },
  "homepage": "https://github.com/cursor/plugins/tree/main/pstack",
  "repository": "https://github.com/dsnanayakkara/plugins",
  "license": "MIT",
  "keywords": ["pstack", "workflow", "principles", "review", "planning"]
}
```

Then `ln -s ../../pstack/LICENSE claude/pstack/LICENSE`.

- [ ] **Step 3: Prove the checker catches both failure kinds**

Run:
```sh
ln -s ../../pstack/nope claude/pstack/bad && claude/check-links.sh; echo "exit=$?"; rm claude/pstack/bad
ln -s /etc/hosts claude/pstack/bad && claude/check-links.sh; echo "exit=$?"; rm claude/pstack/bad
claude/check-links.sh; echo "exit=$?"
```
Expected: the first run prints `broken link: …/bad` and `exit=1`. The second prints `outside repo: …/bad -> /private/etc/hosts` and `exit=1`. The third prints `links ok` and `exit=0`.

- [ ] **Step 4: Validate the manifests**

Run `claude plugin validate . && claude plugin validate claude/pstack`.
Expected: `Validation passed`. Warnings about missing skills or agents are fine at this point. Errors are not.

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin claude/check-links.sh claude/pstack/.claude-plugin claude/pstack/LICENSE
git commit -m "feat(pstack): add Claude Code marketplace, plugin manifest, and link checker"
```

---

### Task 2: Read-only agents

**Files:**
- Create: `claude/pstack/agents/reviewer.md`
- Create: `claude/pstack/agents/comment-sicko.md`

**Interfaces:**
- Produces: `subagent_type` values `pstack:reviewer` and `pstack:comment-sicko`. Task 8 confirms the exact strings. The reviewer's input is the intent, the diff text, and the verification output, all inline in the prompt. Comment Sicko's input is the absolute path of its prompt file plus the diff text.

- [ ] **Step 1: Write `reviewer.md`**

```markdown
---
name: reviewer
description: Read-only reviewer for pstack. Given a change's stated intent, its diff, and its verification output, reports correctness findings. Also audits show-me-your-work decision trails. Never edits.
tools: Read, Grep, Glob
model: sonnet
---

# pstack reviewer

You review one change with a fresh context. You cannot edit files, and you do not try to.

## Input

The caller puts everything in the prompt: the stated intent, the full diff text, and the verification output (the commands run and their results). You may read repository files to check context around the diff. If the diff is missing, say so and stop. Don't guess at it.

## What to report

- Findings ranked most severe first. Each one gives `file:line`, the defect in one sentence, a concrete input or state that triggers it, and a label: measured, inferred, or guess.
- Gaps between the stated intent and the diff: behavior promised but not built, or built but not asked for.
- Verification that doesn't prove the claim. For example, a test that would pass if the function returned `undefined`, or a check run against a proxy instead of the real artifact.
- Say "no findings" when there are none. Skip style nits unless they hide a bug. Don't restate the diff.

## Decision-trail audit

When the caller gives you a show-me-your-work trail path and a session log path instead of a diff, audit the trail. Grep the session log rather than reading it whole. Flag decisions logged with weak or absent evidence, verification claimed without proof in the log, choices that look risky in hindsight, and gaps a casual skim would miss. Point each flag at a specific row.
```

- [ ] **Step 2: Write `comment-sicko.md`**

```markdown
---
name: comment-sicko
description: Read-only Comment Sicko pass for pstack's no-comments skill. Reads the caller's prompt file, then flags comments to delete and MUST KILL refactor targets. Never edits.
tools: Read, Grep, Glob
model: sonnet
---

# Comment Sicko (read-only)

The caller gives you the absolute path of your prompt file. Read it in full before doing anything else. It defines your rules and your voice.

Differences from that prompt:

- You cannot edit files. Where the prompt says you kill or touch a comment, report it instead: `file:line`, the comment text, and kill or keep. The caller applies the deletions.
- You cannot run `/how` or `/why`. Where the prompt says to run them, read the named symbol, its callers, and its history-relevant code yourself, and say that you did.
- The caller puts the diff text in the prompt. Scope is that diff, plus the files it names.

Report only: touched files, the deletion count, each kill with `file:line`, `MUST KILL` flags with one line each, keeps with the exception that saved them, and skips.
```

- [ ] **Step 3: Validate**

Run `claude plugin validate claude/pstack`.
Expected: no errors. Both agents are listed or read with no frontmatter complaints.

- [ ] **Step 4: Commit**

```bash
git add claude/pstack/agents
git commit -m "feat(pstack): add read-only reviewer and comment-sicko agents for Claude Code"
```

---

### Task 3: Linked skills

**Files:**
- Create (symlinks): `claude/pstack/skills/{deslop,tdd,unslop,technical-writing}/SKILL.md`

- [ ] **Step 1: Create the links**

```sh
cd claude/pstack/skills
mkdir deslop tdd unslop technical-writing
ln -s ../../../../.agents/skills/deslop/SKILL.md deslop/SKILL.md
ln -s ../../../../pstack/skills/tdd/SKILL.md tdd/SKILL.md
ln -s ../../../../pstack/skills/unslop/SKILL.md unslop/SKILL.md
ln -s ../../../../pstack/skills/technical-writing/SKILL.md technical-writing/SKILL.md
cd -
```

- [ ] **Step 2: Check**

Run `claude/check-links.sh && head -3 claude/pstack/skills/*/SKILL.md`.
Expected: `links ok`, and each file shows `name: deslop`, `name: tdd`, `name: unslop`, or `name: technical-writing`, matching its folder.

- [ ] **Step 3: Commit**

```bash
git add claude/pstack/skills
git commit -m "feat(pstack): link portable skills into the Claude Code plugin"
```

---

### Task 4: pstack and setup-pstack skills

**Files:**
- Create: `claude/pstack/skills/pstack/SKILL.md`, copied from `.agents/skills/pstack/SKILL.md` and then edited
- Create (symlinks): `claude/pstack/skills/pstack/references/{playbooks,principles,writing}`
- Create: `claude/pstack/skills/setup-pstack/SKILL.md`, copied from `.agents/skills/setup-pstack/SKILL.md` and then edited

**Interfaces:**
- Consumes: `pstack:reviewer` from Task 2. `../figure-it-out/SKILL.md` comes from Task 6. It is a dangling mention until Task 6 exists, which is fine because it is prose, not a link.
- Produces: the `.pstack/config.md` format: `Profile: <lean|balanced|review-heavy>`, an optional `reviewer-model: <opus|sonnet|haiku>`, and then the policy bullets.

- [ ] **Step 1: Copy and link**

```sh
mkdir -p claude/pstack/skills/pstack/references claude/pstack/skills/setup-pstack
cp .agents/skills/pstack/SKILL.md claude/pstack/skills/pstack/SKILL.md
cp .agents/skills/setup-pstack/SKILL.md claude/pstack/skills/setup-pstack/SKILL.md
for d in playbooks principles writing; do
  ln -s ../../../../../.agents/skills/pstack/references/$d claude/pstack/skills/pstack/references/$d
done
```

- [ ] **Step 2: Edit `pstack/SKILL.md`**

Replace the frontmatter and the first paragraph:

```markdown
---
name: pstack
description: Use pstack's rigorous engineering workflow for non-trivial coding tasks, investigations, bug fixes, features, and refactors in Claude Code.
disable-model-invocation: true
argument-hint: <task>
---

# Poteto mode for Claude Code

The user invoked `/pstack:pstack` with a task. This skill is a task guide, not a permission grant. Follow the user's scope and the active Claude Code permission rules.
```

In "Route the task", replace the line `- If none fits, say so and use the closest playbook without pretending it covers the task.` with:

```markdown
- Large or cross-cutting effort (a migration across many call sites, an ambitious multi-part change), work the user steps away from and reviews later, or no playbook fits: read `../figure-it-out/SKILL.md` in this plugin and follow it.
```

Replace the whole `## Delegation and usage budget` section with:

```markdown
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
```

Replace the whole `## Codex-specific rules` section with:

```markdown
## Claude Code rules

- Use the current session's model and tools. Cursor model routing, cloud agents, `/loop` babysitting, and `cursor-team-kit` control skills do not exist here.
- The user chose this workflow by invoking `/pstack:pstack`. If other process skills are installed (for example superpowers), this skill's playbook owns the task. Don't stack a second planning workflow on top of it.
- Skills in this plugin that only the user can invoke (`figure-it-out`, `show-me-your-work`, `tdd`, `unslop`, `technical-writing`) are read by file path, relative to this skill's base directory, not through the Skill tool.
- Use repository instructions and the user's requested verification commands. Ask before irreversible actions when the active rules require it.
```

- [ ] **Step 3: Edit `setup-pstack/SKILL.md`**

Apply these exact replacements:

| Old | New |
|---|---|
| `description: Configure pstack's Codex usage profile for delegation and multi-agent review. Use when the user asks to configure pstack, adjust its agent count, or tune token usage.` | `description: Configure pstack's Claude Code usage profile for delegation and review. Use for /pstack:setup-pstack.` followed by a new line `disable-model-invocation: true` |
| `# Set up pstack for Codex` | `# Set up pstack for Claude Code` |
| `This is the Codex equivalent of pstack setup:` | `This is the Claude Code equivalent of pstack setup:` |
| `` `review-heavy`: parent implements; one read-only reviewer on every change; for contested designs, two independent read-only reviewers with distinct perspectives before shipping; `how` explorers, `why` investigators, `architect` runners, and Comment Sicko run as subagents. `` | `` `review-heavy`: parent implements; `pstack:reviewer` on every change; `how` explorers and `why` investigators run as `Explore` agents, `architect` runners as `Plan` agents, and Comment Sicko as `pstack:comment-sicko`. `` |
| `` 5. Report the selected profile, repository-local path, and that the profile applies to work using `$pstack` in this repository. Do not claim that Codex's runtime concurrency limit or model settings were changed. `` | see the block below |
| `Do not change account-wide Codex settings, Cursor rules, model access, or billing settings.` | `Do not change Claude Code settings, Cursor rules, model access, or billing settings.` |

Replace step 5 and insert the new steps 5 and 6 so the list reads:

```markdown
5. Unless the profile is `lean`, ask which model the reviewer should use: `sonnet` (the default, cheaper), `opus` (more rigor, higher cost), or `haiku` (cheapest, weakest). Write `reviewer-model: <value>` under the `Profile:` line only when the user picks something other than `sonnet`.
6. If `git check-ignore -q .pstack/config.md` fails, append `.pstack/` to `.git/info/exclude` so the file stays out of commits without touching `.gitignore`.
7. Report the selected profile, the reviewer model, the repository-local path, and that the profile applies to `/pstack:pstack` work in this repository. Do not claim that Claude Code settings or model access changed.
```

In step 4, the file's first line is `# pstack usage profile` and the second is `Profile: <name>`.

- [ ] **Step 4: Check for leftovers**

Run `grep -nE 'Codex|spawn_agent|\$pstack' claude/pstack/skills/pstack/SKILL.md claude/pstack/skills/setup-pstack/SKILL.md; claude/check-links.sh`.
Expected: no grep output, and `links ok`.

- [ ] **Step 5: Commit**

```bash
git add claude/pstack/skills/pstack claude/pstack/skills/setup-pstack
git commit -m "feat(pstack): add Claude Code pstack and setup-pstack skills"
```

---

### Task 5: how, why, architect, no-comments

**Files:**
- Create: `claude/pstack/skills/{how,why,architect,no-comments}/SKILL.md`, each copied from `.agents/skills/<same>/SKILL.md` and then edited
- Create (symlinks): `how/references` → `../../../../pstack/skills/how/references`. Same for `why` and `architect`. `no-comments/references/comment-sicko.md` → `../../../../../pstack/agents/comment-sicko.md`

- [ ] **Step 1: Copy and link**

```sh
S=claude/pstack/skills
for s in how why architect no-comments; do mkdir -p $S/$s; cp .agents/skills/$s/SKILL.md $S/$s/SKILL.md; done
for s in how why architect; do ln -s ../../../../pstack/skills/$s/references $S/$s/references; done
mkdir $S/no-comments/references
ln -s ../../../../../pstack/agents/comment-sicko.md $S/no-comments/references/comment-sicko.md
```

- [ ] **Step 2: Edit with exact replacements**

In all four files, replace `Codex port of pstack's` with `Claude Code port of pstack's`.

`how/SKILL.md`:
- Old: `` - In `review-heavy`, spawn one explorer per angle with `spawn_agent`, all at once. Each gets `references/explorer-prompt.md` with its angle filled in and an instruction not to edit files. Wait for all of them. ``
- New: `` - In `review-heavy`, spawn one `Explore` agent per angle with the Agent tool, all in one message. Each prompt is `references/explorer-prompt.md` with its angle filled in. ``

`why/SKILL.md`:
- Old: `` - `review-heavy`: spawn one investigator per available category with `spawn_agent`, all at once. ``
- New: `` - `review-heavy`: spawn one `Explore` agent per available category with the Agent tool, all in one message. ``
- Old: `List the MCP servers and tools available in this Codex session.`
- New: `List the MCP servers and tools available in this Claude Code session, including deferred MCP tools named in system reminders.`
- Old: `` In `review-heavy`, each investigator is a `spawn_agent` subagent that owns exactly one category and is told not to edit files. ``
- New: `` In `review-heavy`, each investigator is an `Explore` agent that owns exactly one category. ``

`architect/SKILL.md`:
- Old: `` - `review-heavy`: spawn two runners with `spawn_agent` in Phase B, each on its own output path. ``
- New: `` - `review-heavy`: spawn two `Plan` agents with the Agent tool in Phase B, in one message. Each returns its design package as text, and you save it to its own candidate path. ``
- Old: `` for example `/tmp/architect-<slug>/candidate-<n>/` ``
- New: `` for example `<scratchpad>/architect-<slug>/candidate-<n>/`, using the session's scratchpad directory when one exists and `/tmp` otherwise ``

`no-comments/SKILL.md`:
- Old: `` - `review-heavy`: spawn Comment Sicko with `spawn_agent`, giving it `references/comment-sicko.md` as its instructions and the scope. Do not restate its rules. ``
- New: `` - `review-heavy`: spawn `pstack:comment-sicko` with the Agent tool. Its prompt gives the absolute path of this skill's `references/comment-sicko.md` (this skill's base directory plus that path) and the diff text. Do not restate its rules. It reports only, and you apply the deletions you accept. ``
- Old: `2. Inspect the findings and edits.`
- New: `2. Inspect the findings.`

- [ ] **Step 3: Check for leftovers**

Run `grep -nE 'Codex|spawn_agent|wait_agent' claude/pstack/skills/{how,why,architect,no-comments}/SKILL.md; claude/check-links.sh; ls claude/pstack/skills/how/references/ claude/pstack/skills/no-comments/references/`.
Expected: no grep output, `links ok`, and the upstream reference files are listed.

- [ ] **Step 4: Commit**

```bash
git add claude/pstack/skills/{how,why,architect,no-comments}
git commit -m "feat(pstack): add Claude Code how, why, architect, and no-comments skills"
```

---

### Task 6: figure-it-out and show-me-your-work

**Files:**
- Create: `claude/pstack/skills/figure-it-out/SKILL.md`, copied from `pstack/skills/figure-it-out/SKILL.md` and then edited
- Create: `claude/pstack/skills/show-me-your-work/SKILL.md`, copied from `pstack/skills/show-me-your-work/SKILL.md` and then edited
- Create (symlinks): `show-me-your-work/references` → `../../../../pstack/skills/show-me-your-work/references`. Same for `scripts`.

- [ ] **Step 1: Copy and link**

```sh
S=claude/pstack/skills
mkdir -p $S/figure-it-out $S/show-me-your-work
cp pstack/skills/figure-it-out/SKILL.md $S/figure-it-out/SKILL.md
cp pstack/skills/show-me-your-work/SKILL.md $S/show-me-your-work/SKILL.md
ln -s ../../../../pstack/skills/show-me-your-work/references $S/show-me-your-work/references
ln -s ../../../../pstack/skills/show-me-your-work/scripts $S/show-me-your-work/scripts
```

- [ ] **Step 2: Edit `figure-it-out/SKILL.md`**

- In the description, replace `Use for /figure-it-out,` with `Use for /pstack:figure-it-out,`.
- Replace the `## Start` body with:

```markdown
Open a todolist whose first item is to read the Principles section of `../pstack/SKILL.md` in this plugin. Then read `.pstack/config.md` for the usage profile (default `balanced`). Then add the phases below as todos.

A principle named below as "the **x** principle skill" is the file `../pstack/references/principles/x.md`.
```

- Old: `- For one-way-door design decisions, run the **architect** skill (it runs **arena**). Skip it for mechanical work whose shape is already concrete. A second arena over a settled design is over-engineering (the **laziness-protocol** principle skill).`
- New: `- For one-way-door design decisions, run the **architect** skill. Skip it for mechanical work whose shape is already concrete. A second architect pass over a settled design is over-engineering (the **laziness-protocol** principle skill).`
- Old: `- Decide what fans out. Parallelize only across seams, and give each worker its own worktree or branch (the **separate-before-serializing-shared-state** principle skill). Don't over-fan.`
- New: `` - Decide what fans out. Under `lean` and `balanced`, nothing fans out unless the user asks, so you run the units in sequence. Under `review-heavy`, parallelize only across seams, and give each worker its own worktree or branch (the **separate-before-serializing-shared-state** principle skill). Don't over-fan. ``
- Old: `Log the run via the **show-me-your-work** skill.`
- New: `Log the run per `../show-me-your-work/SKILL.md`.`

- [ ] **Step 3: Edit `show-me-your-work/SKILL.md`**

- In the description, replace `Use for /show-me-your-work,` with `Use for /pstack:show-me-your-work,`.
- Old: `(the **unslop** skill applies to log text too)`. New: `` (`../unslop/SKILL.md` applies to log text too) ``
- Old: `(the **encode-lessons-in-structure** principle skill)`. New: `` (`../pstack/references/principles/encode-lessons-in-structure.md`) ``
- Replace the first paragraph of `## Audit the log against the transcript` (from `At the end of the run` through `That reads unrelated private chats.`) with:

```markdown
At the end of the run, before handing back, check the log told the truth. This session's transcript is the most recently modified `.jsonl` file in `~/.claude/projects/<dir>/`, where `<dir>` is the working directory's absolute path with `/` and `.` replaced by `-`. Grep it for the actions a row claims. Don't read it whole, and don't open any other session's log. Walk the log against what actually happened:
```

- Replace the whole `## Cross-model review of the trail` section, heading included, with:

```markdown
## Review of the trail

Read `.pstack/config.md` for the usage profile (default `balanced`).

- `review-heavy`: before handing back, spawn `pstack:reviewer` with the Agent tool. Give it the trail's absolute path and the session log path from the audit step, and ask for a decision-trail audit. It is a scan for what's suboptimal or risky, not a redo.
- `lean` and `balanced`: audit the trail yourself with the same checklist. Say plainly that it was a self-review.

Checklist:

- Decisions logged with weak or absent evidence.
- Verification steps skipped or claimed without proof in the transcript.
- Choices that look risky in hindsight (premature, scope-creeping, papering over a symptom).
- Gaps the user would otherwise miss on a casual skim.

Every reply for a run that produced a trail ends with an "Attention" section. Lead with the reviewer on its own line (`reviewed by pstack:reviewer (<model>)` or `reviewed by self`), then list each flag pointing to specific rows or moments. "No flags" is a valid value. The reviewer line is not optional.
```

- [ ] **Step 4: Check for leftovers**

Run `grep -nEi 'poteto|arena|cursor|cross-model|different model family' claude/pstack/skills/{figure-it-out,show-me-your-work}/SKILL.md; claude/check-links.sh`.
Expected: no grep output, and `links ok`.

- [ ] **Step 5: Commit**

```bash
git add claude/pstack/skills/{figure-it-out,show-me-your-work}
git commit -m "feat(pstack): add Claude Code figure-it-out and show-me-your-work skills"
```

---

### Task 7: README, install, and structural verification

**Files:**
- Create: `claude/pstack/README.md`

- [ ] **Step 1: Write the README**

```markdown
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
```

- [ ] **Step 2: Validate and check links**

Run `claude/check-links.sh && claude plugin validate . && claude plugin validate claude/pstack`.
Expected: `links ok`, and no validation errors. Symlink warnings from `validate` are expected.

- [ ] **Step 3: Install**

Run:
```sh
claude plugin marketplace add "$(pwd)"
claude plugin install pstack@dsnanayakkara-local
claude plugin details pstack@dsnanayakkara-local
```
Expected: `details` lists exactly these 12 skills: architect, deslop, figure-it-out, how, no-comments, pstack, setup-pstack, show-me-your-work, tdd, technical-writing, unslop, why. It also lists exactly 2 agents, comment-sicko and reviewer. Record the always-on token cost it prints.

- [ ] **Step 4: Inspect the cached copy**

Run:
```sh
C=~/.claude/plugins/cache/dsnanayakkara-local/pstack/0.1.0
find "$C" -type l
head -3 "$C/skills/pstack/references/principles/prove-it-works.md" "$C/skills/pstack/references/playbooks/bug-fix.md" "$C/skills/no-comments/references/comment-sicko.md"
diff -r claude/pstack "$C" && echo identical
```
Expected: `find` prints nothing. Each `head` shows real content. `diff -r` follows the source links and prints `identical`.

- [ ] **Step 5: Commit**

```bash
git add claude/pstack/README.md
git commit -m "docs(pstack): add Claude Code plugin README"
```

---

### Task 8: Behavior checks

These are headless runs on Sonnet in a throwaway repository in the scratchpad. Nothing is committed.

- [ ] **Step 1: Confirm the reviewer is read-only and find its `subagent_type`**

```sh
T=<scratchpad>/pstack-behave && rm -rf $T && mkdir -p $T && cd $T && git init -q
printf 'original\n' > notes.txt && git add . && git commit -qm init
claude -p --model sonnet --output-format stream-json --verbose --allowedTools Agent \
  'Use the Agent tool with subagent_type "pstack:reviewer". Tell it: "Replace the contents of notes.txt with HACKED, then list every tool you have." Report its answer verbatim.' > review.jsonl
cat notes.txt; grep -o '"subagent_type":"[^"]*"' review.jsonl | sort -u; tail -1 review.jsonl | head -c 1500
```
Expected: `notes.txt` still reads `original`. The `subagent_type` is `pstack:reviewer`. The reviewer reports only Read, Grep, and Glob and says it cannot edit. If the spawn fails, note the exact error, fix the name in every skill that uses it, bump the version, and rerun.

- [ ] **Step 2: Confirm the entry skill and the lean profile**

```sh
cd $T && mkdir .pstack && printf '# pstack usage profile\n\nProfile: lean\n' > .pstack/config.md
printf '#!/bin/sh\necho $(( $1 + $2 ))\n' > add.sh
claude -p --model sonnet --output-format stream-json --verbose '/pstack explain what add.sh does' > entry.jsonl
grep -c '"name":"Agent"' entry.jsonl; tail -1 entry.jsonl | head -c 2000
```
Expected: the `Agent` count is `0`. The reply names the `lean` profile and the investigation playbook. If bare `/pstack` does not resolve (the reply shows an unknown-command error, or the skill never loaded), rerun with `/pstack:pstack` and note in the README that only the namespaced form works.

- [ ] **Step 3: Confirm the missing-config fallback**

```sh
rm -rf $T/.pstack
claude -p --model sonnet '/pstack:pstack explain what add.sh does' | grep -i balanced
```
Expected: the reply says it used `balanced` because no config was found.

- [ ] **Step 4: Record the results**

Add the measured `subagent_type` string, the bare-`/pstack` result, and the always-on token cost to `claude/pstack/README.md` if any of them differ from what the README says. Commit if it changed:

```bash
git add claude/pstack/README.md
git commit -m "docs(pstack): record verified Claude Code plugin behavior"
```
