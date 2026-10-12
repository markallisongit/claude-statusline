# claude-statusline

Status line for Claude Code:

```
user@host | ~/project | main | Haiku 5.5 | xhigh | ctx:17% | S63% | W40% | 3d3h remaining
```

Shows user@host, directory, git branch, model, effort, context used, session and week usage used (matches `/usage`), and time until the weekly reset.

## Install

No packages to install. `git` is optional and only shows the branch.

**Linux** needs `bash` and either `curl` or `wget`:

```
curl -fsSL https://raw.githubusercontent.com/markallisongit/claude-statusline/main/install.sh | bash
```

Without curl, use `wget -qO- <same URL> | bash`.

Or clone and run:

```
git clone https://github.com/markallisongit/claude-statusline.git
bash claude-statusline/install.sh
```

**Windows** needs Windows PowerShell 5.1 or later, which Windows 10 and 11 include. In PowerShell:

```
irm https://raw.githubusercontent.com/markallisongit/claude-statusline/main/install.ps1 | iex
```

The installers write to your Claude Code config folder, `~/.claude`:

| | Script | `statusLine` command in `settings.json` |
|---|---|---|
| Linux | `~/.claude/statusline-command.sh` | `bash ~/.claude/statusline-command.sh` |
| Windows | `%USERPROFILE%\.claude\statusline-command.ps1` | `"<Windows>\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "<path>"` |

The previous settings are saved to `settings.json.bak`. Other settings are kept.

## Update

Re-run the install command for your platform.
