#!/bin/bash
# Installs the statusline for the current user. Needs jq.
set -euo pipefail

command -v jq > /dev/null || { echo "jq is required: install it first" >&2; exit 1; }

src_dir=$(cd "$(dirname "$0")" && pwd)
claude_dir="$HOME/.claude"
settings="$claude_dir/settings.json"

mkdir -p "$claude_dir"
cp "$src_dir/statusline-command.sh" "$claude_dir/statusline-command.sh"

# Git Bash on Windows: pin its bash.exe so the command never resolves to WSL's bash
cmd="bash ~/.claude/statusline-command.sh"
case "$(uname -s)" in
  MINGW*|MSYS*) cmd="\"$(cygpath -m "$(command -v bash)")\" ~/.claude/statusline-command.sh" ;;
esac

[ -f "$settings" ] || echo '{}' > "$settings"
cp "$settings" "$settings.bak"
tmp=$(mktemp)
jq --arg cmd "$cmd" '.statusLine = {type: "command", command: $cmd}' "$settings" > "$tmp"
cat "$tmp" > "$settings"
rm -f "$tmp"

echo "Installed to $claude_dir. statusLine: $cmd"
echo "Previous settings saved to $settings.bak"
