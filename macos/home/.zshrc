plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  yarn
  web-search
  jsontools
  macports
  node
  macos
  sudo
  thor
  docker
)
source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/init.zsh"

typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
neofetch

alias arm="env /usr/bin/arch -arm64 /bin/zsh --login"
alias intel="env /usr/bin/arch -x86_64 /bin/zsh --login"
export PATH="/Applications/ArmGNUToolchain/14.2.rel1/arm-none-eabi/bin/:$PATH"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/tanishmakadia/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/tanishmakadia/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/tanishmakadia/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/tanishmakadia/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Runs nnn and adopts its final directory.
n() {
  if [[ "${NNNLVL:-0}" -ne 0 ]]; then
    print "nnn is already running"
    return
  fi

  export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
  export NNN_FIFO=/tmp/nnn.fifo
  export NNN_PLUG='f:finder;d:diffs;p:preview-tui'
  command nnn "$@"

  if [[ -f "$NNN_TMPFILE" ]]; then
    source "$NNN_TMPFILE"
    rm -f -- "$NNN_TMPFILE" > /dev/null
  fi
}

export NVM_DIR="$HOME/.nvm"
[[ ! -s "$NVM_DIR/nvm.sh" ]] || source "$NVM_DIR/nvm.sh"
[[ ! -s "$NVM_DIR/bash_completion" ]] || source "$NVM_DIR/bash_completion"
