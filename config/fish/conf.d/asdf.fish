if test (uname) = "Darwin" 
  source $(HOMEBREW_PREFIX)/opt/bin/asdf
else 
  source ~/.asdf/asdf.fish

  mkdir -p ~/.config/fish/completions; and ln -fs ~/.asdf/completions/asdf.fish ~/.config/fish/completions
end
