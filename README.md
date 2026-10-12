# claude-statusline

Status line for Claude Code:

```
user@host | ~/project | main | Haiku 5.5 | xhigh | ctx:17% | S63% | W40% | 3d3h remaining
```

Shows user@host, directory, git branch, model, effort, context used, session and week usage left, and time until the weekly reset.

## Install

**Linux** needs `bash`. The one-liner also needs `curl`. `git` is optional and only shows the branch.

```
curl -fsSL https://raw.githubusercontent.com/markallisongit/claude-statusline/main/install.sh | bash
```

or clone and run:

```
git clone https://github.com/markallisongit/claude-statusline.git
bash claude-statusline/install.sh
```

**Windows** needs Git for Windows, which Claude Code already requires. In PowerShell:

```
winget install Git.Git
irm https://raw.githubusercontent.com/markallisongit/claude-statusline/main/install.ps1 | iex
```

Open a new terminal after installing Git.

The installer copies the script to `~/.claude/statusline-command.sh` and sets `statusLine` in `~/.claude/settings.json`. The previous settings are saved to `settings.json.bak`.

## Update

Re-run the install command for your platform.
