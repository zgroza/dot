record_screen_to_file() {
  wf-recorder -g "$(slurp)" -f "$@"
}

run_in_nice_augroup () {
  command="echo 15 | tee /proc/self/autogroup; $@"
  setsid -w zsh -c "$command"
}
