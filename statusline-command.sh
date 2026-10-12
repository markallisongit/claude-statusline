#!/bin/bash
# Claude Code status line for Linux. Windows: statusline-command.ps1

# Drop control bytes (C0, DEL and C1) so a crafted directory or branch name can't inject terminal escapes
clean() { LC_ALL=C tr -d '\000-\037\177' | LC_ALL=C sed $'s/\xc2[\x80-\x9f]//g'; }

# Text after the object key "$1" in JSON text "$2", or nothing if absent. A key is a string followed by a colon
after() { [[ $2 =~ \"$1\"[[:space:]]*: ]] || return 0; printf '%s' "${2#*"${BASH_REMATCH[0]}"}"; }

# Scalar value of key "$1" in JSON text "$2": string contents or bare number; nothing for null or absent
val() {
  local rest v
  rest=$(after "$1" "$2"); rest=${rest#"${rest%%[![:space:]]*}"}
  case $rest in
    \"*) rest=${rest#\"}; printf '%s' "${rest%%\"*}" ;;
    null*) ;;
    *) v=${rest%%[,\}]*}; printf '%s' "${v%"${v##*[![:space:]]}"}" ;;
  esac
}

# Keep only a plain decimal: bash arithmetic would evaluate anything else, including command substitutions
num() { [[ $1 =~ ^[0-9]+(\.[0-9]+)?$ ]] && printf '%s' "$1"; return 0; }

round() { printf '%.0f' "$1"; }

json=$(clean)

cwd=$(val current_dir "$(after workspace "$json")")
[ -n "$cwd" ] || cwd=$(val cwd "$json")
cwd=${cwd//\\\\/\\}
model=$(val display_name "$(after model "$json")")
effort=$(val level "$(after effort "$json")")
ctx=$(num "$(val used_percentage "$(after context_window "$json")")")
session_used=$(num "$(val used_percentage "$(after five_hour "$json")")")
week_used=$(num "$(val used_percentage "$(after seven_day "$json")")")
week_reset=$(num "$(val resets_at "$(after seven_day "$json")")")

[ -n "$ctx" ] && ctx=$(round "$ctx")
[ -n "$session_used" ] && session_left=$(( 100 - $(round "$session_used") ))
[ -n "$week_used" ] && week_left=$(( 100 - $(round "$week_used") ))
week_reset=${week_reset%%.*}

# Git branch (skip optional locks)
git_branch=''
if [ -n "$cwd" ] && GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null | clean)
fi

# Catppuccin Mocha palette (truecolor, tuned for dark backgrounds)
c_user=$'\033[1;38;2;203;166;247m'   # mauve
c_dir=$'\033[38;2;137;180;250m'      # blue
c_branch=$'\033[38;2;166;227;161m'   # green
c_model=$'\033[38;2;180;190;254m'    # lavender
c_effort=$'\033[38;2;250;179;135m'   # peach
c_ok=$'\033[38;2;148;226;213m'       # teal
c_warn=$'\033[38;2;249;226;175m'     # yellow
c_crit=$'\033[38;2;243;139;168m'     # red
c_label=$'\033[38;2;186;194;222m'   # subtext1
c_muted=$'\033[38;2;127;132;156m'    # overlay1
c_sep=$'\033[38;2;108;112;134m'      # overlay0
reset=$'\033[0m'
sep="${c_sep} | ${reset}"

segments=()
segments+=("${c_user}$(whoami | clean)@$(uname -n | cut -d. -f1 | clean)${reset}")
segments+=("${c_dir}${cwd}${reset}")

if [ -n "$git_branch" ]; then
  segments+=("${c_branch}${git_branch}${reset}")
fi

if [ -n "$model" ]; then
  segments+=("${c_model}${model}${reset}")
fi

if [ -n "$effort" ]; then
  segments+=("${c_effort}${effort}${reset}")
fi

if [ -n "$ctx" ]; then
  if [ "$ctx" -ge 80 ]; then
    ctx_color=$c_crit
  elif [ "$ctx" -ge 50 ]; then
    ctx_color=$c_warn
  else
    ctx_color=$c_ok
  fi
  segments+=("${ctx_color}ctx:${ctx}%${reset}")
fi

if [ -n "$session_left" ]; then
  segments+=("${c_label}S${c_muted}${session_left}%${reset}")
fi

if [ -n "$week_left" ]; then
  segments+=("${c_label}W${c_muted}${week_left}%${reset}")
fi

if [ -n "$week_reset" ]; then
  left=$(( week_reset - $(date +%s) ))
  if [ "$left" -gt 0 ]; then
    days=$(( left / 86400 ))
    hours=$(( left % 86400 / 3600 ))
    mins=$(( left % 3600 / 60 ))
    if [ "$days" -gt 0 ]; then
      left_str="${days}d${hours}h"
    elif [ "$hours" -gt 0 ]; then
      left_str="${hours}h${mins}m"
    else
      left_str="${mins}m"
    fi
    segments+=("${c_muted}${left_str} remaining${reset}")
  fi
fi

out=''
for seg in "${segments[@]}"; do
  out="${out:+$out$sep}$seg"
done
printf '%s\n' "$out"
