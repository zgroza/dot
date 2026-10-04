# Drains any keys pressed while meow wasn't listening.
_meow_flush() {
  local k
  while read -s -k 1 -t 0 k; do :; done
}

# Meows in a random English voice every 1-300 seconds.
# While waiting: n skips 10 seconds ahead, q quits.
meow() {
  zmodload zsh/datetime zsh/mathfunc

  local -a voices
  local voice key saved_stty
  local -i delay
  local -F end left

  voices=("${(@f)$(say -v '?' | grep -E '\ben[_-][A-Z]{2}\b' | sed -E 's/[[:space:]]+en[_-][A-Z]{2}[[:space:]]+#.*//')}")

  saved_stty=$(stty -g 2>/dev/null)
  {
    stty -echo
    while true; do
      voice=${voices[RANDOM % ${#voices[@]} + 1]}
      delay=$(( RANDOM % 300 + 1 ))
      echo "$(date '+%H:%M:%S') voice: $voice | sleeping: ${delay}s"
      say -v "$voice" "Meow"
      _meow_flush                             # discard keys mashed during the meow
      end=$(( EPOCHREALTIME + delay ))
      while (( (left = end - EPOCHREALTIME) > 0 )); do
        printf '\r\033[K  next meow in %2ds' $(( int(ceil(left)) ))
        read -s -k 1 -t $(( left < 1 ? left : 1 )) key || continue
        case $key in
          q) break 2 ;;
          n) (( end -= 10 )) ;;
        esac
        _meow_flush
      done
      printf '\r\033[K'
    done
  } always {
    # Also runs on Ctrl-C, so echo comes back either way.
    printf '\r\033[K'
    [[ -n "$saved_stty" ]] && stty "$saved_stty" 2>/dev/null
  }
}
