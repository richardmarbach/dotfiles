if test (uname) = "Darwin" 
  source /opt/homebrew/asdf/bin/asdf
else 
  source ~/.asdf/asdf.fish

  mkdir -p ~/.config/fish/completions; and ln -fs ~/.asdf/completions/asdf.fish ~/.config/fish/completions
end
