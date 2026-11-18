(( $+commands[jj] )) || return 0

# jj prompt segment for Powerlevel10k, originally inspired by
# https://github.com/indirect/dotfiles (MIT license).

# 1. WORKER (runs in a background subshell; prints one formatted p10k status line)
function _jj_prompt_worker() {
  emulate -L zsh
  [[ -n $1 ]] && cd "$1" || return 1

  local grey='%244F' green='%2F' red='%196F' yellow='%3F' cyan='%6F' magenta='%5F'
  local -a _jj_ro=(--ignore-working-copy --no-pager)

  # First query snapshots the working copy (no --ignore-working-copy) and finds
  # the nearest bookmark/tag/trunk commit. Capturing commit_id ensures downstream
  # revsets never break on conflicted bookmarks (`main??`) or names with `/`.
  local branch_raw
  branch_raw=$(jj log --no-pager --no-graph --limit 1 -r "
    coalesce(
      heads(::@ & (bookmarks() | remote_bookmarks() | tags())),
      heads(@:: & (bookmarks() | remote_bookmarks() | tags())),
      trunk()
    )" -T '
      commit_id ++ "\x1f" ++
      local_bookmarks.filter(|b| !b.synced()).len() ++ "\x1f" ++
      separate(" ", bookmarks, tags)
    ' 2>/dev/null)

  local -a branch_fields=("${(@ps:\x1f:)branch_raw}")
  local branch_commit=${branch_fields[1]}
  local -i unsynced=${branch_fields[2]:-0}
  local branch=${branch_fields[3]%% *}

  local -i commits_after=0 commits_before=0 ahead=0 behind=0
  local ahead_plus="" behind_plus=""
  if [[ -n $branch && -n $branch_commit ]]; then
    branch=${branch%\*}

    commits_after=$(jj log $_jj_ro --count -r "${branch_commit}..@ & (~empty() | merges())" 2>/dev/null)
    commits_before=$(jj log $_jj_ro --count -r "@..${branch_commit} & (~empty() | merges())" 2>/dev/null)

    if (( unsynced )); then
      local -a counts
      counts=($(jj bookmark list $_jj_ro -r "$branch_commit" -T '
        if(remote && remote != "git" && tracked,
          separate(" ",
            name ++ "@" ++ remote,
            coalesce(tracking_behind_count.exact(), tracking_behind_count.lower()),
            coalesce(tracking_ahead_count.exact(), tracking_ahead_count.lower()),
            if(tracking_behind_count.exact(), "0", "+"),
            if(tracking_ahead_count.exact(), "0", "+"),
          ) ++ "\n"
        )
      ' 2>/dev/null))

      ahead=${counts[2]:-0}
      behind=${counts[3]:-0}
      ahead_plus=${counts[4]}
      behind_plus=${counts[5]}
    fi
  fi

  # Single query for `@`: change_id, status flags, empty bit, description, diff counts.
  local wc_raw
  wc_raw=$(jj log $_jj_ro --no-graph --limit 1 -r '@' -T '
    change_id.shortest(4).prefix() ++ "\x1f" ++
    change_id.shortest(4).rest() ++ "\x1f" ++
    concat(
      if(conflict, "💥"),
      if(divergent, "🚧"),
      if(hidden, "👻"),
      if(immutable, "🔒"),
    ) ++ "\x1f" ++
    if(empty, "1", "0") ++ "\x1f" ++
    description.first_line() ++ "\x1f" ++
    diff.files().filter(|f| f.status() == "added" || f.status() == "copied").len() ++ "\x1f" ++
    diff.files().filter(|f| f.status() == "removed").len() ++ "\x1f" ++
    diff.files().filter(|f| f.status() == "modified" || f.status() == "renamed").len()
  ' 2>/dev/null)

  local -a wc=("${(@ps:\x1f:)wc_raw}")
  local change_prefix=${wc[1]}
  local change_rest=${wc[2]}
  local action=${wc[3]}
  local is_empty=${wc[4]}
  local desc=${wc[5]}
  local -i added=${wc[6]:-0}
  local -i deleted=${wc[7]:-0}
  local -i modified=${wc[8]:-0}

  # Format prompt string.
  local status_color=$green
  (( ahead )) && status_color=$cyan
  (( behind )) && status_color=$magenta
  (( ahead && behind )) && status_color=$red

  local res=""
  if [[ -n $branch ]]; then
    local where=${(V)branch}
    (( $#where > 32 )) && where[13,-13]="…"
    res+="${status_color}${where//\%/%%}"
    (( commits_before )) && res+="‹${commits_before}"
    (( commits_after )) && res+="›${commits_after}"
  fi

  if (( behind )); then
    res+=" ${green}⇣${behind}"
    [[ $behind_plus == "+" ]] && res+="+"
  fi
  if (( ahead )); then
    (( ! behind )) && res+=" "
    res+="${green}⇡${ahead}"
    [[ $ahead_plus == "+" ]] && res+="+"
  fi

  res+=" ${magenta}${change_prefix}${grey}${change_rest}"
  [[ -n $action ]] && res+=" ${red}${action}"

  if [[ -n $desc ]]; then
    res+=" ${green}${desc//\%/%%}"
  elif [[ $is_empty == "0" ]]; then
    res+=" ${green}"$'\Uf040 '
  fi

  (( added )) && res+=" ${green}+${added}"
  (( deleted )) && res+=" ${red}-${deleted}"
  (( modified )) && res+=" ${yellow}^${modified}"

  print -r -- "$res"
}

# 2. ASYNC & POWERLEVEL10K PLUMBING
typeset -g _jj_prompt_fd=""
typeset -g _jj_prompt_pwd=""
typeset -g p10k_jj_status=""

function _jj_prompt_in_repo() {
  emulate -L zsh -o extended_glob
  [[ -n ./(../)#(.jj)(#qN/) || -n ./(../)#.git/.jj(#qN/) ]]
}

function _jj_prompt_cancel() {
  local fd=${1:-$_jj_prompt_fd}
  if [[ -n $fd ]]; then
    zle -F "$fd" 2>/dev/null
    exec {fd}<&- 2>/dev/null
    [[ $fd == $_jj_prompt_fd ]] && _jj_prompt_fd=""
  fi
}

function _jj_prompt_callback() {
  local fd=$1 output=""
  [[ -n $fd ]] || return

  if [[ $fd == $_jj_prompt_fd ]]; then
    if read -r -u "$fd" output; then
      p10k_jj_status=$output
    else
      p10k_jj_status=""
    fi
    _jj_prompt_cancel "$fd"
    p10k display -r
  else
    _jj_prompt_cancel "$fd"
  fi
}

function _jj_prompt_start() {
  # Avoid restarting if a worker is already in flight for this directory.
  [[ -n $_jj_prompt_fd && $PWD == $_jj_prompt_pwd ]] && return

  if [[ $PWD != $_jj_prompt_pwd ]]; then
    p10k_jj_status=""
    _jj_prompt_cancel
  fi

  _jj_prompt_pwd=$PWD
  exec {_jj_prompt_fd}< <( _jj_prompt_worker "$PWD" )
  zle -F "$_jj_prompt_fd" _jj_prompt_callback
}

# Must be self-contained: Powerlevel10k serializes this function's body verbatim
# into its instant-prompt cache and executes it before 08-jj-prompt.zsh loads.
function p10k-on-pre-prompt() {
  emulate -L zsh -o extended_glob
  if [[ -n ./(../)#(.jj)(#qN/) || -n ./(../)#.git/.jj(#qN/) ]]; then
    p10k display '*/vcs'=hide
  else
    p10k display '*/vcs'=show
    (( $+functions[_jj_prompt_cancel] )) && _jj_prompt_cancel
    _jj_prompt_pwd=""
    p10k_jj_status=""
  fi
}

function prompt_jj() {
  _jj_prompt_in_repo || return
  _jj_prompt_start
  p10k segment -f grey -c '${p10k_jj_status}' -e -t '${p10k_jj_status}'
  p10k segment -f grey -c '${${p10k_jj_status:-1}:#$p10k_jj_status}' -e -t '…'
}

# Register `jj` right after `vcs` so ~/.p10k.zsh does not need manual edits.
if (( $+POWERLEVEL9K_LEFT_PROMPT_ELEMENTS )) && (( ! ${POWERLEVEL9K_LEFT_PROMPT_ELEMENTS[(I)jj(|_joined)]} )); then
  () {
    local idx=${POWERLEVEL9K_LEFT_PROMPT_ELEMENTS[(i)vcs(|_joined)]}
    if (( idx <= $#POWERLEVEL9K_LEFT_PROMPT_ELEMENTS )); then
      POWERLEVEL9K_LEFT_PROMPT_ELEMENTS[idx+1,idx]=(jj)
    else
      POWERLEVEL9K_LEFT_PROMPT_ELEMENTS+=(jj)
    fi
  }
  (( $+functions[p10k] )) && p10k reload
fi
