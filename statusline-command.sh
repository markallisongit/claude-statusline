#!/bin/bash
input=$(cat)

# Strip control characters (C0, DEL and C1) from text we print, so a crafted directory or branch name can't inject terminal escapes
clean() { jq -Rj 'gsub("\\p{Cc}"; "")'; }

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty' | clean)
model=$(echo "$input" | jq -r '.model.display_name // empty' | clean)
effort=$(echo "$input" | jq -r '.effort.level // empty' | clean)
ctx=$(echo "$input" | jq -r '.context_window.used_percentage // empty | round')
session_left=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty | 100 - . | round')
week_left=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty | 100 - . | round')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

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
segments+=("${c_user}$(whoami | clean)@$(hostname -s | clean)${reset}")
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
