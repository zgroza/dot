#!/usr/bin/env zsh
# Self-contained test suite for zsh/base/08-jj-prompt.zsh.
# Bootstraps temporary jj repositories in /tmp and verifies prompt output and stderr.

emulate -L zsh
setopt pipefail no_unset

local script_dir=${0:A:h}
local target="${script_dir}/../base/08-jj-prompt.zsh"
[[ -r $target ]] || { print -u2 "Cannot read $target"; exit 2 }

local tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT

# Isolate jj/git config so tests don't depend on user dotfiles.
export HOME="$tmp/home"
export XDG_CONFIG_HOME="$tmp/config"
mkdir -p "$HOME" "$XDG_CONFIG_HOME/jj"
cat > "$XDG_CONFIG_HOME/jj/config.toml" <<'EOF'
[user]
name = "Test User"
email = "test@example.com"
EOF

# Load the module under test (without p10k loaded yet).
source "$target"

local -i passed=0 failed=0

run_worker() {
  local dir=$1
  local err_file="$tmp/worker.err"
  OUT=$(_jj_prompt_worker "$dir" 2>"$err_file")
  ERR=$(<"$err_file")
}

pass() {
  (( ++passed ))
  print -r -- "PASS: $1"
}

fail() {
  (( ++failed ))
  print -u2 -r -- "FAIL: $1"
  print -u2 -r -- "  detail: $2"
  [[ -n ${OUT:-} ]] && print -u2 -r -- "  stdout: ${(q+)OUT}"
  [[ -n ${ERR:-} ]] && print -u2 -r -- "  stderr: ${(q+)ERR}"
}

assert_no_err() {
  local name=$1
  if [[ -n $ERR ]]; then
    fail "$name" "expected empty stderr"
    return 1
  fi
  return 0
}

assert_contains() {
  local name=$1 needle=$2
  if [[ $OUT != *"$needle"* ]]; then
    fail "$name" "expected output to contain ${(q+)needle}"
    return 1
  fi
  return 0
}

assert_not_contains() {
  local name=$1 needle=$2
  if [[ $OUT == *"$needle"* ]]; then
    fail "$name" "expected output NOT to contain ${(q+)needle}"
    return 1
  fi
  return 0
}

# 1. Syntax check
if zsh -n "$target" 2>"$tmp/syntax.err"; then
  pass "zsh -n syntax check"
else
  fail "zsh -n syntax check" "$(<"$tmp/syntax.err")"
fi

# 2. Fresh repo: no bookmarks, empty working copy
{
  local repo="$tmp/fresh"
  jj git init "$repo" >/dev/null 2>&1
  run_worker "$repo"
  if assert_no_err "fresh repo" \
    && assert_contains "fresh repo (change id)" "%5F" \
    && assert_not_contains "fresh repo (no pencil on empty)" $'\Uf040' \
    && assert_not_contains "fresh repo (no diff counts)" "+1"; then
    pass "fresh empty repo without bookmarks"
  fi
}

# 3. Non-empty working copy without description -> pencil icon + added count
{
  local repo="$tmp/dirty"
  jj git init "$repo" >/dev/null 2>&1
  print "hello" > "$repo/a.txt"
  run_worker "$repo"
  if assert_no_err "dirty unnamed wc" \
    && assert_contains "dirty unnamed wc (pencil)" $'\Uf040 ' \
    && assert_contains "dirty unnamed wc (+1)" "%2F+1"; then
    pass "non-empty unnamed working copy shows pencil and +1"
  fi
}

# 4. Added, modified, deleted files + description with '%' and backslash
{
  local repo="$tmp/diff-and-escape"
  jj git init "$repo" >/dev/null 2>&1
  print "one" > "$repo/keep.txt"
  print "two" > "$repo/del.txt"
  jj commit -R "$repo" -m "base" >/dev/null 2>&1

  print "added" > "$repo/new.txt"
  print "changed" > "$repo/keep.txt"
  rm "$repo/del.txt"
  jj describe -R "$repo" -m 'fix 100% \n handling' >/dev/null 2>&1

  run_worker "$repo"
  if assert_no_err "diff + escape" \
    && assert_contains "diff + escape (escaped %)" 'fix 100%% \n handling' \
    && assert_contains "diff + escape (+1)" "%2F+1" \
    && assert_contains "diff + escape (-1)" "%196F-1" \
    && assert_contains "diff + escape (^1)" "%3F^1" \
    && assert_not_contains "diff + escape (no pencil)" $'\Uf040'; then
    pass "diff counts (+1/-1/^1) and %/backslash escaping in description"
  fi
}

# 5. Bookmark with slash (`feat/foo`), commits_after (`›2`), commits_before (`‹1`)
{
  local repo="$tmp/slashes-and-offsets"
  jj git init "$repo" >/dev/null 2>&1
  print "v1" > "$repo/f.txt"
  jj commit -R "$repo" -m "c1" >/dev/null 2>&1
  jj bookmark create -R "$repo" -r @- "feat/foo" >/dev/null 2>&1

  print "v2" > "$repo/f.txt"
  jj commit -R "$repo" -m "c2" >/dev/null 2>&1
  print "v3" > "$repo/f.txt"
  jj describe -R "$repo" -m "c3" >/dev/null 2>&1

  run_worker "$repo"
  if assert_no_err "slash bookmark + after" \
    && assert_contains "slash bookmark name" "feat/foo›2"; then
    pass "bookmark with '/' and commits_after (›2)"
  fi

  # Test commits_before (‹1): edit parent when only a descendant bookmark exists
  jj bookmark delete -R "$repo" "feat/foo" >/dev/null 2>&1
  jj bookmark create -R "$repo" -r @ "child/bm" >/dev/null 2>&1
  jj edit -R "$repo" @- >/dev/null 2>&1
  run_worker "$repo"
  if assert_no_err "commits_before" \
    && assert_contains "commits_before (‹1)" "child/bm‹1"; then
    pass "commits_before (‹1) when behind bookmark"
  fi
}

# 6. Long bookmark name truncation (> 32 chars)
{
  local repo="$tmp/long-bm"
  jj git init "$repo" >/dev/null 2>&1
  print "x" > "$repo/x"
  jj commit -R "$repo" -m "init" >/dev/null 2>&1
  jj bookmark create -R "$repo" -r @- "very-long-feature-branch-name-exceeding-32-chars" >/dev/null 2>&1
  run_worker "$repo"
  if assert_no_err "long bookmark" \
    && assert_contains "long bookmark truncated" "very-long-fe…ing-32-chars"; then
    pass "long bookmark name truncated with ellipsis"
  fi
}

# 7. Colocated git + bare origin remote: synced, ahead, behind, diverged, conflicted (`main??`)
{
  local origin="$tmp/origin.git"
  local repo_a="$tmp/repo-a"
  local repo_b="$tmp/repo-b"
  git init --bare "$origin" >/dev/null 2>&1

  jj git init --colocate "$repo_a" >/dev/null 2>&1 || { fail "setup repo_a" "jj git init failed"; }
  jj git remote add -R "$repo_a" origin "$origin" >/dev/null 2>&1 || { fail "setup repo_a" "remote add failed"; }
  print "init" > "$repo_a/f.txt"
  jj commit -R "$repo_a" -m "init" >/dev/null 2>&1
  jj bookmark create -R "$repo_a" -r @- main >/dev/null 2>&1
  jj git push -R "$repo_a" --bookmark main >/dev/null 2>&1 || { fail "setup repo_a" "initial push failed"; }

  # 7a. Synced with origin -> green main, no arrows
  run_worker "$repo_a"
  if assert_no_err "remote synced" \
    && assert_contains "remote synced (green main)" "%2Fmain" \
    && assert_not_contains "remote synced (no ahead)" "⇡" \
    && assert_not_contains "remote synced (no behind)" "⇣"; then
    pass "colocated repo synced with origin"
  fi

  # Clone second repo for remote divergence tests
  jj git clone --colocate "$origin" "$repo_b" >/dev/null 2>&1

  # 7b. Ahead of origin by 2 -> cyan main + ⇡2 (verifies @git does not shadow @origin)
  print "a1" > "$repo_a/a1.txt"
  jj commit -R "$repo_a" -m "a1" >/dev/null 2>&1
  print "a2" > "$repo_a/a2.txt"
  jj commit -R "$repo_a" -m "a2" >/dev/null 2>&1
  jj bookmark set -R "$repo_a" main -r @- >/dev/null 2>&1
  run_worker "$repo_a"
  if assert_no_err "remote ahead" \
    && assert_contains "remote ahead (cyan main)" "%6Fmain" \
    && assert_contains "remote ahead (⇡2)" "⇡2" \
    && assert_not_contains "remote ahead (no behind)" "⇣"; then
    pass "colocated repo ahead of origin (cyan, ⇡2)"
  fi

  # 7c. Push from repo_b to create a conflicted bookmark (`main??`) in repo_a on fetch
  print "b1" > "$repo_b/b1.txt"
  jj commit -R "$repo_b" -m "b1" >/dev/null 2>&1
  jj bookmark set -R "$repo_b" main -r @- >/dev/null 2>&1
  jj git push -R "$repo_b" --bookmark main >/dev/null 2>&1

  jj git fetch -R "$repo_a" >/dev/null 2>&1
  run_worker "$repo_a"
  if assert_no_err "conflicted bookmark (main??)" \
    && assert_contains "conflicted bookmark label" "main??"; then
    pass "conflicted bookmark (main??) parses with zero stderr"
  fi

  # 7d. Behind origin: reset repo_b's main back 1 commit after repo_b pushed another commit
  local repo_c="$tmp/repo-c"
  jj git clone --colocate "$origin" "$repo_c" >/dev/null 2>&1
  print "b2" > "$repo_b/b2.txt"
  jj commit -R "$repo_b" -m "b2" >/dev/null 2>&1
  jj bookmark set -R "$repo_b" main -r @- >/dev/null 2>&1
  jj git push -R "$repo_b" --bookmark main >/dev/null 2>&1

  # Move repo_c main to an older commit, then fetch -> behind by 1
  jj bookmark track -R "$repo_c" main@origin >/dev/null 2>&1
  jj bookmark set -R "$repo_c" main -r @- --allow-backwards >/dev/null 2>&1
  # Create a local commit on repo_c so we test diverged (1 ahead, 1 behind)
  print "c1" > "$repo_c/c1.txt"
  jj commit -R "$repo_c" -m "c1" >/dev/null 2>&1
  jj bookmark set -R "$repo_c" main -r @- >/dev/null 2>&1
  jj git fetch -R "$repo_c" >/dev/null 2>&1
  # Resolve conflict on main to the local c1 commit so main is tracked & diverged (1 ahead, 1 behind)
  jj bookmark set -R "$repo_c" main -r @- >/dev/null 2>&1
  run_worker "$repo_c"
  if assert_no_err "remote diverged" \
    && assert_contains "remote diverged (red main)" "%196Fmain" \
    && assert_contains "remote diverged (⇣1⇡1)" "⇣1%2F⇡1"; then
    pass "colocated repo diverged from origin (red, ⇣1⇡1)"
  fi
}

# 8. Working copy file conflict -> 💥 flag
{
  local repo="$tmp/conflict"
  jj git init "$repo" >/dev/null 2>&1
  print "base" > "$repo/c.txt"
  jj commit -R "$repo" -m "base" >/dev/null 2>&1
  print "left" > "$repo/c.txt"
  jj commit -R "$repo" -m "left" >/dev/null 2>&1
  local left_rev=$(jj log -R "$repo" --no-pager --no-graph -r @- -T 'commit_id')
  jj new -R "$repo" @-- >/dev/null 2>&1
  print "right" > "$repo/c.txt"
  jj commit -R "$repo" -m "right" >/dev/null 2>&1
  local right_rev=$(jj log -R "$repo" --no-pager --no-graph -r @- -T 'commit_id')
  jj new -R "$repo" "$left_rev" "$right_rev" >/dev/null 2>&1

  run_worker "$repo"
  if assert_no_err "wc conflict" \
    && assert_contains "wc conflict icon (💥)" "💥"; then
    pass "working copy conflict shows 💥"
  fi
}

# 9. _jj_prompt_in_repo detection
{
  local repo="$tmp/in-repo"
  jj git init "$repo" >/dev/null 2>&1
  mkdir -p "$repo/a/b/c"
  if (cd "$repo" && _jj_prompt_in_repo) \
    && (cd "$repo/a/b/c" && _jj_prompt_in_repo) \
    && (cd "$tmp" && ! _jj_prompt_in_repo); then
    pass "_jj_prompt_in_repo (root, nested subdir, outside)"
  else
    fail "_jj_prompt_in_repo" "detection mismatch"
  fi
}

# 10. Auto-registration in POWERLEVEL9K_LEFT_PROMPT_ELEMENTS
{
  local ok=1
  local case_out
  for spec in \
    "insert_after_vcs|(dir vcs newline prompt_char)|dir vcs jj newline prompt_char|1" \
    "already_present|(dir vcs jj newline prompt_char)|dir vcs jj newline prompt_char|0" \
    "no_vcs|(dir newline prompt_char)|dir newline prompt_char jj|1"; do
    local -a parts=("${(@s:|:)spec}")
    case_out=$(zsh -fc "
      reloaded=0
      p10k() { [[ \$1 == reload ]] && reloaded=1; }
      typeset -ga POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=${parts[2]}
      source ${(q)target}
      print -r -- \"\$POWERLEVEL9K_LEFT_PROMPT_ELEMENTS|\$reloaded\"
    " 2>&1)
    if [[ $case_out != "${parts[3]}|${parts[4]}" ]]; then
      fail "auto-register (${parts[1]})" "got ${(q+)case_out}, expected ${(q+)${parts[3]}|${parts[4]}}"
      ok=0
    fi
  done
  (( ok )) && pass "POWERLEVEL9K_LEFT_PROMPT_ELEMENTS auto-registration"
}

# 11. p10k-on-pre-prompt must be self-contained for p10k instant prompt
{
  local repo="$tmp/in-repo"
  local body=$functions[p10k-on-pre-prompt]
  local ip_out
  ip_out=$(zsh -fc "
    p10k() { print -r -- \"\$*\"; }
    p10k-on-pre-prompt() { ${body} }
    cd ${(q)repo} && p10k-on-pre-prompt
    cd ${(q)tmp} && p10k-on-pre-prompt
  " 2>&1)
  local expected=$'display */vcs=hide\ndisplay */vcs=show'
  if [[ $ip_out == $expected ]]; then
    pass "p10k-on-pre-prompt is self-contained for p10k instant prompt"
  else
    fail "p10k-on-pre-prompt instant prompt" "got ${(q+)ip_out}, expected ${(q+)expected}"
  fi
}

print -r -- ""
print -r -- "Results: ${passed} passed, ${failed} failed"
(( failed == 0 ))
