(( $+commands[jj] && $+commands[jq] )) || return 0

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
  local branch_json
  branch_json=$(jj log --no-pager --no-graph --limit 1 -r "
    coalesce(
      heads(::@ & (bookmarks() | remote_bookmarks() | tags())),
      heads(@:: & (bookmarks() | remote_bookmarks() | tags())),
      trunk()
    )" -T 'json({
      "commit_id" => commit_id,
      "unsynced" => local_bookmarks.filter(|b| !b.synced()).len(),
      "bookmarks" => bookmarks,
      "tags" => tags,
    }) ++ "\n"' 2>/dev/null)

  local branch_commit="" branch=""
  local -i unsynced=0
  if [[ -n $branch_json ]]; then
    eval "$(jq -r '
      ((.bookmarks + .tags)[0] // null) as $ref
      | (if $ref == null then ""
         else $ref.name
            + (if $ref.remote then "@\($ref.remote)" else "" end)
            + (if (($ref.target // []) | length) > 1 then "??" else "" end)
         end) as $branch
      | "branch_commit=\(.commit_id | @sh); unsynced=\(.unsynced); branch=\($branch | @sh)"
    ' <<< "$branch_json" 2>/dev/null)"
  fi

  local -i commits_after=0 commits_before=0 ahead=0 behind=0
  local ahead_plus="" behind_plus=""
  if [[ -n $branch && -n $branch_commit ]]; then
    commits_after=$(jj log $_jj_ro --count -r "${branch_commit}..@ & (~empty() | merges())" 2>/dev/null)
    commits_before=$(jj log $_jj_ro --count -r "@..${branch_commit} & (~empty() | merges())" 2>/dev/null)

    if (( unsynced )); then
      local remote_json
      remote_json=$(jj bookmark list $_jj_ro -r "$branch_commit" -T '
        if(remote && remote != "git" && tracked, json({
          "ahead_lower" => tracking_behind_count.lower(),
          "ahead_upper" => tracking_behind_count.upper(),
          "behind_lower" => tracking_ahead_count.lower(),
          "behind_upper" => tracking_ahead_count.upper(),
        }) ++ "\n")
      ' 2>/dev/null)

      if [[ -n $remote_json ]]; then
        eval "$(jq -rs '
          .[0] // empty
          | "ahead=\(.ahead_lower); behind=\(.behind_lower)"
          + "; ahead_plus=\(if .ahead_upper == .ahead_lower then "" else "+" end | @sh)"
          + "; behind_plus=\(if .behind_upper == .behind_lower then "" else "+" end | @sh)"
        ' <<< "$remote_json" 2>/dev/null)"
      fi
    fi
  fi

  # Single query for `@`: change_id, status flags, empty bit, description, diff counts.
  local wc_json
  wc_json=$(jj log $_jj_ro --no-graph --limit 1 -r '@' -T 'json({
    "prefix" => change_id.shortest(4).prefix(),
    "rest" => change_id.shortest(4).rest(),
    "conflict" => conflict,
    "divergent" => divergent,
    "hidden" => hidden,
    "immutable" => immutable,
    "empty" => empty,
    "desc" => description.first_line(),
    "added" => diff.files().filter(|f| f.status() == "added" || f.status() == "copied").len(),
    "deleted" => diff.files().filter(|f| f.status() == "removed").len(),
    "modified" => diff.files().filter(|f| f.status() == "modified" || f.status() == "renamed").len(),
  }) ++ "\n"' 2>/dev/null)

  local change_prefix="" change_rest="" action="" desc=""
  local -i is_empty=1 added=0 deleted=0 modified=0
  if [[ -n $wc_json ]]; then
    eval "$(jq -r '
      "change_prefix=\(.prefix | @sh)"
      + "; change_rest=\(.rest | @sh)"
      + "; action=\((
          (if .conflict then "💥" else "" end)
          + (if .divergent then "🚧" else "" end)
          + (if .hidden then "👻" else "" end)
          + (if .immutable then "🔒" else "" end)
        ) | @sh)"
      + "; is_empty=\(if .empty then 1 else 0 end)"
      + "; desc=\(.desc | @sh)"
      + "; added=\(.added); deleted=\(.deleted); modified=\(.modified)"
    ' <<< "$wc_json" 2>/dev/null)"
  fi

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
  elif (( ! is_empty )); then
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
typeset -g _jj_prompt_stale=""
typeset -g p10k_jj_status=""

function _jj_prompt_in_repo() {
  emulate -L zsh -o extended_glob
  [[ -n ./(../)#(.jj)(#qN/) || -n ./(../)#.git/.jj(#qN/) ]]
}

function _jj_prompt_dim() {
  emulate -L zsh -o extended_glob
  local s=$1
  # Preserve literal escaped `%%` while stripping color codes (`%<N>F`), then
  # render the whole string in grey (`%244F`).
  s=${s//\%\%/$'\x01'}
  s=${s//\%[0-9]##F/}
  s=${s//$'\x01'/\%\%}
  REPLY="%244F${s}"
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
    if read -r -u "$fd" output && [[ -n $output ]]; then
      p10k_jj_status=$output
      local REPLY=""
      _jj_prompt_dim "$output"
      _jj_prompt_stale=$REPLY
    else
      p10k_jj_status=""
      _jj_prompt_stale=""
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
    _jj_prompt_stale=""
    _jj_prompt_cancel
  elif [[ -n $_jj_prompt_stale ]]; then
    # Dim the previously rendered status while the background refresh runs.
    p10k_jj_status=$_jj_prompt_stale
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
    _jj_prompt_stale=""
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
