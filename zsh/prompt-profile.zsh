# Prompt latency profiler for zsh. Sourced by zshrc when ZSH_PROMPT_PROFILE is
# set. Wraps every registered precmd and chpwd hook with a timer and logs any
# prompt whose hooks took longer than ZSH_PROMPT_PROFILE_MS (default 30) ms.
#
#   ZSH_PROMPT_PROFILE=1 exec zsh        # start a profiled shell
#   tail -f ~/.cache/zsh-prompt-profile.log
#
# Each log line: time, total ms, cwd, then every hook that took over 1 ms.
# Hooks are wrapped by copying the original function and redefining the name,
# so hooks that add or remove themselves from the hook arrays keep working.

zmodload zsh/datetime

typeset -g  __prof_log=${XDG_CACHE_HOME:-$HOME/.cache}/zsh-prompt-profile.log
typeset -g  __prof_threshold=${ZSH_PROMPT_PROFILE_MS:-30}
typeset -gA __prof_rec
typeset -gF __prof_start

mkdir -p ${__prof_log:h}

function __prof_wrap() {
  local f=$1
  (( $+functions[$f] )) || return 0
  (( $+functions[__prof_orig_$f] )) && return 0   # already wrapped
  functions -c $f __prof_orig_$f
  eval "function $f() {
    local -F __s=\$EPOCHREALTIME
    __prof_orig_$f \"\$@\"
    local __r=\$?
    __prof_rec[$f]=\$(( (EPOCHREALTIME - __s) * 1000 ))
    return \$__r
  }"
}

function __prof_begin() { __prof_start=$EPOCHREALTIME }

function __prof_end() {
  local -F total=$(( (EPOCHREALTIME - __prof_start) * 1000 ))
  if (( total > __prof_threshold )); then
    local k line; line="$(strftime '%H:%M:%S' $EPOCHSECONDS) total=${total%.*}ms cwd=${PWD/#$HOME/~}"
    for k in ${(k)__prof_rec}; do
      (( __prof_rec[$k] > 1 )) && line+=" ${k}=${__prof_rec[$k]%.*}"
    done
    print -r -- $line >> $__prof_log
  fi
  __prof_rec=()
}

local f
for f in $precmd_functions $chpwd_functions; do __prof_wrap $f; done
precmd_functions=(__prof_begin $precmd_functions __prof_end)

print -P "%F{yellow}[prompt-profile] logging prompts slower than ${__prof_threshold} ms to ${__prof_log}%f"
