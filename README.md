# claude-statusline

Status line for Claude Code:

```
user@host | ~/project | main | Haiku 5.5 | xhigh | ctx:17% | S63% | W40% | 3d3h remaining
```

Shows user@host, directory, git branch, model, effort, context used, session and week usage left, and time until the weekly reset.

## Install

Needs `jq` and `git`.

**Linux**

```
sudo apt install jq        # or: sudo dnf install jq
git clone https://github.com/markallisongit/claude-statusline.git
bash claude-statusline/install.sh
```

**Windows**

Run these in Git Bash (from Git for Windows), not PowerShell. In PowerShell, `bash` can resolve to WSL's bash.

```
winget install jqlang.jq
git clone https://github.com/markallisongit/claude-statusline.git
bash claude-statusline/install.sh
```

The installer copies the script to `~/.claude/statusline-command.sh` and sets `statusLine` in `~/.claude/settings.json`. The previous settings are saved to `settings.json.bak`.

## Update

```
git -C claude-statusline pull && bash claude-statusline/install.sh
```
