# pstack for Claude Code

pstack makes Claude Code work more carefully. Before it changes code, it reproduces the bug, reads how the code works, and checks its work at the end. It is a Claude Code version of [pstack](../../pstack/README.md), Lauren Tan's plugin for Cursor.

You set it up once. After that, it works in every project on your computer.

## What you need

- Claude Code installed. Run `claude --version` to check.
- Git.

## Set it up

### 1. Download this repository

Choose a folder where it can stay. Claude Code reads the plugin from this folder every time, so don't delete or move it later.

```sh
git clone -b claude-pstack https://github.com/dsnanayakkara/plugins.git ~/pstack-plugins
```

### 2. Tell Claude Code where the plugin is

```sh
claude plugin marketplace add ~/pstack-plugins
```

You should see `Successfully added marketplace: dsnanayakkara-local`.

### 3. Install the plugin

```sh
claude plugin install pstack@dsnanayakkara-local
```

You should see `Successfully installed plugin: pstack@dsnanayakkara-local`.

### 4. Check that it worked

```sh
claude plugin details pstack@dsnanayakkara-local
```

You should see `Skills (12)` and `Agents (2)`. If Claude Code is already open, restart it.

### 5. Stop the permission questions (optional)

pstack reads its guide files from the folder in step 1. That folder is outside your projects, so Claude Code asks for permission each time. To allow it once and for all, open `~/.claude/settings.json` and add the folder to `permissions.allow`. Use the full path, starting with `//`:

```json
{
  "permissions": {
    "allow": ["Read(//Users/you/pstack-plugins/**)"]
  }
}
```

Replace `/Users/you/pstack-plugins` with the real path. Run `echo ~/pstack-plugins` to print it. If the file already has a `permissions` section, add the line to its `allow` list.

## Use it

Open Claude Code in any project and type:

```
/pstack fix the login test that fails on Mondays
```

pstack picks the right plan for the task. The first line of its reply names the profile it used and the plan it chose.

Other commands you can type:

| Command | What it does |
|---|---|
| `/pstack:setup-pstack` | Choose how many helper agents pstack may use in this project. |
| `/pstack:figure-it-out` | Plan a large or unusual job step by step. |
| `/pstack:show-me-your-work` | Keep a log of decisions for a long job. |
| `/pstack:tdd` | Write a failing test first, then fix the bug. |
| `/pstack:unslop` | Remove AI-sounding phrases from text. |
| `/pstack:technical-writing` | Write or review docs, READMEs, and commit messages. |

Claude also uses `how`, `why`, `architect`, `no-comments`, and `deslop` on its own when a task needs them.

## Choose a profile (optional)

A profile controls how many extra agents pstack starts, which controls how much it costs. If you do nothing, every project uses `balanced`.

| Profile | What happens | Cost |
|---|---|---|
| `lean` | Claude does everything itself and checks its own work. | Lowest |
| `balanced` | Claude does the work. One reviewer checks bigger changes. | Low |
| `review-heavy` | A reviewer checks every change, and helpers explore the code in parallel. | Highest |

To change it, run `/pstack:setup-pstack` in the project. This saves your choice in `.pstack/config.md` and keeps that file out of git.

The reviewer can only read files. It can never change your code. It runs on Sonnet by default. `/pstack:setup-pstack` can switch it to Opus (more careful, costs more) or Haiku (cheapest).

## Get updates

```sh
cd ~/pstack-plugins
git pull
```

Changes take effect the next time you start Claude Code. You don't need to reinstall.

## Remove it

```sh
claude plugin uninstall pstack@dsnanayakkara-local
claude plugin marketplace remove dsnanayakkara-local
rm -rf ~/.claude/plugins/cache/dsnanayakkara-local
```

Then delete the folder from step 1 if you no longer need it.

## If something goes wrong

- **`/pstack` does nothing, or says it doesn't know the command.** Restart Claude Code and repeat step 4.
- **"Path is outside allowed working directories".** Do step 5. For scripts that run `claude -p`, add `--add-dir ~/pstack-plugins` instead.
- **You moved or deleted the folder from step 1.** Run step 2 again with the new path.

## For maintainers

Most skill files are links into `pstack/` (the original Cursor plugin) and `.agents/` (the Codex version). Don't edit those two folders. After you move or rename files, run `claude/check-links.sh` to catch broken links. Bump `version` in `.claude-plugin/plugin.json` when you cut a release.

Not included: `arena`, `interrogate`, `swarm`, and `reflect`. They run several models at once, which costs more. Cursor-only skills are also left out.
