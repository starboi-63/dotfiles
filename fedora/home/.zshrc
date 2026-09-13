typeset -U path
path=("$HOME/.local/bin" $path)
export PATH

if [[ -o interactive && -t 1 ]] && (( $+commands[fastfetch] )); then
  fastfetch
fi

plugins=(git)
source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/init.zsh"
export EDITOR=vim
