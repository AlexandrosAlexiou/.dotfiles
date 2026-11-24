# Don't set default aliases
export FORGIT_NO_ALIASES=1

# Call git-forgit directly to avoid loading its plugin during startup.
FORGIT="$HOME/.oh-my-zsh/custom/plugins/forgit/bin/git-forgit"
alias fadd='$FORGIT add'
alias fbd='$FORGIT branch_delete'
alias fblame='$FORGIT blame'
alias fcb='$FORGIT checkout_branch'
alias fcc='$FORGIT checkout_commit'
alias fcf='$FORGIT checkout_file'
alias fclean='$FORGIT clean'
alias fcp='$FORGIT cherry_pick_from_branch'
alias fct='$FORGIT checkout_tag'
alias fdiff='$FORGIT diff'
alias ffixup='$FORGIT fixup'
alias fignore='$FORGIT ignore'
alias flog='$FORGIT log'
alias frebase='$FORGIT rebase'
alias freset='$FORGIT reset_head'
alias frevert='$FORGIT revert_commit'
alias fstash='$FORGIT stash_show'

# Forgit custom copy command
export FORGIT_COPY_CMD='xclip -selection clipboard'

# Forgit fzf custom settings
export FORGIT_FZF_DEFAULT_OPTS="
    --ansi
    --bind='?:toggle-preview'
    --bind='ctrl-a:toggle-all'
    --bind='ctrl-s:toggle-sort'
    --bind='alt-w:toggle-preview-wrap'
    --bind='ctrl-u:preview-page-up'
    --bind='ctrl-d:preview-page-down'
    --height='80%'
    --tabstop=4
    --multi
    --layout=reverse
    --border
    --cycle
    --preview-window='right:60%:nohidden:wrap'
    --preview='bat --style=full --color=always {}'
"
