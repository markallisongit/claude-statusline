#!/bin/bash
# Installs the statusline for the current user on Linux. Windows: install.ps1
set -euo pipefail

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) echo "On Windows, run install.ps1 in PowerShell instead" >&2; exit 1 ;;
esac

raw=https://raw.githubusercontent.com/markallisongit/claude-statusline/main

claude_dir="$HOME/.claude"
settings="$claude_dir/settings.json"

# curl, or wget where curl is missing
fetch() { if command -v curl > /dev/null; then curl -fsSL "$1" -o "$2"; else wget -qO "$2" "$1"; fi; }

mkdir -p "$claude_dir"

# Copy from a checkout only when run as a file. Piped installs fetch it; never trust the cwd
src=${BASH_SOURCE[0]:-}
if [ -n "$src" ] && [ -f "$src" ]; then
  cp "$(dirname "$src")/statusline-command.sh" "$claude_dir/statusline-command.sh"
else
  fetch "$raw/statusline-command.sh" "$claude_dir/statusline-command.sh"
fi

cmd="bash ~/.claude/statusline-command.sh"

[ -f "$settings" ] || echo '{}' > "$settings"
cp "$settings" "$settings.bak"

# Text edit, not a JSON round trip, so every other byte of settings.json is kept
new="\"statusLine\": {\"type\": \"command\", \"command\": \"${cmd//\"/\\\"}\"}"
text=$(cat "$settings")
compact=$(printf '%s' "$text" | tr -d '[:space:]')
if [ -z "$compact" ] || [ "$compact" = '{}' ]; then
  text="{$new}"
elif [[ $text == *'"statusLine"'* ]]; then
  rest=${text#*\"statusLine\"}; rest=${rest#*:}; rest=${rest#"${rest%%[![:space:]]*}"}
  [[ $rest == \{* ]] || { echo "statusLine in $settings is not an object: fix it by hand" >&2; exit 1; }
  pre=${text%%\"statusLine\"*}
  post=${text#*\"statusLine\"}; post=${post#*\}}
  text="$pre$new$post"
else
  text=${text/\{/\{$'\n'  $new,}
fi
printf '%s\n' "$text" > "$settings"

echo "Installed to $claude_dir. statusLine: $cmd"
echo "Previous settings saved to $settings.bak"
