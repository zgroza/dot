(( $+commands[jj] )) || return 0

# jj prompt logic is heavily inspired by https://github.com/indirect/dotfiles (MIT license),
# partly just copied from there.
#
# 1. THE WORKER LOGIC
#    Calculates the status string. Runs inside a background process.
function jj_status_logic() {
  emulate -L zsh
  [[ -n "$1" ]] && cd "$1"

  local grey='%244F'
  local green='%2F'
  local blue='%39F'
  local red='%196F'
  local yellow='%3F'
  local cyan='%6F'
  local magenta='%5F'

  ## jj_add (Snapshot)
  jj --at-operation=@ debug snapshot 2>/dev/null

  ## jj_at (Branch & Bookmark detection)
  local branch=$(jj --ignore-working-copy --at-op=@ --no-pager log --no-graph --limit 1 -r "
    coalesce(
      heads(::@ & (bookmarks() | remote_bookmarks() | tags())),
      heads(@:: & (bookmarks() | remote_bookmarks() | tags())),
      trunk()
    )" -T "separate(' ', bookmarks, tags)" 2> /dev/null | cut -d ' ' -f 1)

  if [[ -n $branch ]]; then
    [[ $branch =~ "\*$" ]] && branch=${branch::-1}

    local VCS_STATUS_COMMITS_AFTER=$(jj --ignore-working-copy --at-op=@ --no-pager log --no-graph -r "$branch..@ & (~empty() | merges())" -T '"n"' 2> /dev/null | wc -c | tr -d ' ')
    local VCS_STATUS_COMMITS_BEFORE=$(jj --ignore-working-copy --at-op=@ --no-pager log --no-graph -r "@..$branch & (~empty() | merges())" -T '"n"' 2> /dev/null | wc -c | tr -d ' ')
    local counts=($(jj --ignore-working-copy --at-op=@ --no-pager bookmark list -r $branch -T '
      if(remote,
        separate(" ",
          name ++ "@" ++ remote, 
          coalesce(tracking_behind_count.exact(), tracking_behind_count.lower()),
          coalesce(tracking_ahead_count.exact(), tracking_ahead_count.lower()),
          if(tracking_behind_count.exact(), "0", "+"),
          if(tracking_ahead_count.exact(), "0", "+"),
        ) ++ "\n"
      )
    '))

    local VCS_STATUS_LOCAL_BRANCH=$branch
    local VCS_STATUS_COMMITS_AHEAD=$counts[2]
    local VCS_STATUS_COMMITS_BEHIND=$counts[3]
    local VCS_STATUS_COMMITS_AHEAD_PLUS=$counts[4]
    local VCS_STATUS_COMMITS_BEHIND_PLUS=$counts[5]
  fi

  local status_color=${green}
  (( VCS_STATUS_COMMITS_AHEAD )) && status_color=${cyan}
  (( VCS_STATUS_COMMITS_BEHIND )) && status_color=${magenta}
  (( VCS_STATUS_COMMITS_AHEAD && VCS_STATUS_COMMITS_BEHIND )) && status_color=${red}

  local res
  local where=${(V)VCS_STATUS_LOCAL_BRANCH}
  (( $#where > 32 )) && where[13,-13]="…"
  res+="${status_color}${where//\%/%%}" 

  (( VCS_STATUS_COMMITS_BEFORE )) && res+="‹${VCS_STATUS_COMMITS_BEFORE}"
  (( VCS_STATUS_COMMITS_AFTER )) && res+="›${VCS_STATUS_COMMITS_AFTER}"
  
  ## jj_remote
  # ⇣42 if behind the remote.
  (( VCS_STATUS_COMMITS_BEHIND )) && res+=" ${green}⇣${VCS_STATUS_COMMITS_BEHIND}"
  (( VCS_STATUS_COMMITS_BEHIND_PLUS )) && res+="${VCS_STATUS_COMMITS_BEHIND_PLUS}"
  # ⇡42 if ahead of the remote; no leading space if also behind the remote: ⇣42⇡42.
  (( VCS_STATUS_COMMITS_AHEAD && !VCS_STATUS_COMMITS_BEHIND )) && res+=" "
  (( VCS_STATUS_COMMITS_AHEAD  )) && res+="${green}⇡${VCS_STATUS_COMMITS_AHEAD}"
  (( VCS_STATUS_COMMITS_AHEAD_PLUS )) && res+="${VCS_STATUS_COMMITS_AHEAD_PLUS}"

  ## jj_change
  IFS="#" local change=($(jj --ignore-working-copy --at-op=@ --no-pager log --no-graph --limit 1 -r "@" -T '
    separate("#", change_id.shortest(4).prefix(), coalesce(change_id.shortest(4).rest(), "\0"),
      commit_id.shortest(4).prefix(),
      coalesce(commit_id.shortest(4).rest(), "\0"),
      concat(
        if(conflict, "💥"),
        if(divergent, "🚧"),
        if(hidden, "👻"),
        if(immutable, "🔒"),
      ),
    )'))
  local VCS_STATUS_CHANGE=($change[1] $change[2])
  local VCS_STATUS_COMMIT=($change[3] $change[4])
  local VCS_STATUS_ACTION=$change[5]
  
  res+=" ${magenta}${VCS_STATUS_CHANGE[1]}${grey}${VCS_STATUS_CHANGE[2]}"
  [[ -n $VCS_STATUS_ACTION      ]] && res+=" ${red}${VCS_STATUS_ACTION}"

  ## jj_desc
  local VCS_STATUS_MESSAGE=$(jj --ignore-working-copy --at-op=@ --no-pager log --no-graph --limit 1 -r "@" -T "coalesce(description.first_line(), if(!empty, '\Uf040 '))")
  [[ -n $VCS_STATUS_MESSAGE ]] && res+=" ${green}${VCS_STATUS_MESSAGE}"
   
  ## jj_status
  local VCS_STATUS_CHANGES=($(jj log --ignore-working-copy --at-op=@ --no-graph --no-pager -r @ -T "diff.summary()" 2> /dev/null | awk 'BEGIN {a=0;d=0;m=0} /^A / {a++} /^D / {d++} /^M / {m++} /^R / {m++} /^C / {a++} END {print(a,d,m)}'))
  (( VCS_STATUS_CHANGES[1] )) && res+=" %F{green}+${VCS_STATUS_CHANGES[1]}"
  (( VCS_STATUS_CHANGES[2] )) && res+=" %F{red}-${VCS_STATUS_CHANGES[2]}"
  (( VCS_STATUS_CHANGES[3] )) && res+=" ${yellow}^${VCS_STATUS_CHANGES[3]}"

  echo "$res"
}

# 2. ASYNC INFRASTRUCTURE
typeset -g jj_async_fd
typeset -g _jj_worker_pwd=""

# Callback: Triggered when the background process finishes
function jj_async_callback() {
  local fd=$1
  local output

  if [[ -n "$fd" ]]; then
     if read -r -u "$fd" output; then
        typeset -g p10k_jj_status="$output"
     else
        typeset -g p10k_jj_status=""
     fi
     
     # Cleanup
     zle -F "$fd" 2>/dev/null
     exec {fd}<&-
     jj_async_fd=""

     p10k display -r
  fi
}

# Starter: Spawns the worker if not already running for this dir
function jj_async_start() {
  # Avoid restarting if already running for the current directory
  [[ -n "$jj_async_fd" && "$PWD" == "$_jj_worker_pwd" ]] && return
  # If directory changed, clear prompt
  [[ "$PWD" != "$_jj_worker_pwd" ]] && typeset -g p10k_jj_status="" && p10k display -r

  # If running for a DIFFERENT directory, kill the current worker
  if [[ -n "$jj_async_fd" ]]; then
    zle -F "$jj_async_fd" 2>/dev/null
    exec {jj_async_fd}<&-
    jj_async_fd=""
  fi

  _jj_worker_pwd="$PWD"
  
  # Spawn background worker
  exec {jj_async_fd}< <( jj_status_logic "$PWD" )
  zle -F "$jj_async_fd" jj_async_callback
}

# Hook to Hide Standard Git Segment
function p10k-on-pre-prompt() {
  emulate -L zsh -o extended_glob
  if [[ -n ./(../)#(.jj)(#qN/) || -n ./(../)#.git/.jj(#qN/) ]]; then
    p10k display '*/vcs'=hide
  else
    p10k display '*/vcs'=show
    # Cleanup async worker if we leave the repo
    if [[ -n "$jj_async_fd" ]]; then
        zle -F "$jj_async_fd" 2>/dev/null
        exec {jj_async_fd}<&-
        jj_async_fd=""
    fi
  fi
}

# The Prompt Segment Function
function prompt_jj() {
  emulate -L zsh -o extended_glob
  
  # 1. Check if we are in a JJ repo
  if [[ -z ./(../)#(.jj)(#qN/) && -z ./(../)#.git/.jj(#qN/) ]]; then
     return
  fi

  # 2. Trigger the async worker (idempotent)
  jj_async_start

  p10k segment -f grey -c '${p10k_jj_status}' -e -t '${p10k_jj_status}'
  p10k segment -f grey -c '${${p10k_jj_status:-1}:#$p10k_jj_status}' -e -t '…'
}
