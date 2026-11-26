function chezmoi-work --wraps=chezmoi --description 'chezmoi for the private work dotfiles source'
    chezmoi --source ~/.local/share/chezmoi-work \
        --persistent-state ~/.config/chezmoi/chezmoi-work-state.boltdb $argv
end
