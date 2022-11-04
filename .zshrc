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

# Screen life

function screen-list() {
    screen -list | sed 1d | sed '$ d' | sed -e 's/^[[:space:]]*//'
}

function screen-resume() {
  local active=$(screen-list | gwc -l)
  if [[ "$active" -gt 1 ]]; then
    local id=$(screen-list | fzf | gcut -d'.' -f1)
    if [[ -n "$id" ]]; then
      screen -r "$id"
    fi
  elif [[ "$active" -eq 1 ]]; then
    local id=$(screen-list | gcut -d'.' -f1)
    screen -r "$id"
  fi
}

alias screen='screen -q'
alias sr='screen-resume'

# Create notification
function notify() {
  /usr/bin/osascript -e "display notification \"$*\"" 
}

. $(brew --prefix)/opt/asdf/libexec/asdf.sh
