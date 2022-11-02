if test (uname) = "Darwin" 
  source $HOMEBREW_PREFIX/opt/asdf/share/fish/vendor_completions.d/asdf.fish
else 
  source ~/.asdf/asdf.fish

  mkdir -p ~/.config/fish/completions; and ln -fs ~/.asdf/completions/asdf.fish ~/.config/fish/completions
end
