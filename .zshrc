# Setup path
export PATH="$HOME/bin:$PATH"

# More history
HISTFILE=~/.history
HISTSIZE=1000
SAVEHIST=$HISTSIZE

setopt notify
unsetopt autocd beep
bindkey -e

zstyle :compinstall filename '/Users/richard/.zshrc'

# Use brew autocompletions
FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
autoload -Uz compinit
compinit

# Colorize terminal
alias ls="ls -G"
alias ll="ls -Gl"
alias la="ls -Gla"

# Prevent wget from using HSTS
alias wget='wget --no-hsts'

# Use neovim as vi
alias vim='nvim'
alias vi='vim'
export EDITOR='vi'

# Don't consider .,- or _ to be part of a word
export WORDCHARS='*?[]~&;!$%^<>'

# Disable ^S
unsetopt flowcontrol

function p() {
    local proj=$(ls ~/projects | fzf)

    if [[ -n "$proj" ]]; then
        cd ~/projects/"$proj"
    fi
}

# Create notification
function notify() {
  /usr/bin/osascript -e "display notification \"$*\"" 
}
