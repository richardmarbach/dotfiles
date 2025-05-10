# My Dotfiles

Bootstrap:

```bash
# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 1Password - Enable developer mode and link cli in options
brew install 1password 1password-cli

# Install dot file manager
brew install chezmoi

chezmoi init https://github.com/richardmarbach/dotfiles
```
