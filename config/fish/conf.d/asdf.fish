if test (uname) = "Darwin" 
  source /usr/local/opt/asdf/asdf.fish
else 
  source ~/.asdf/asdf.fish

  mkdir -p ~/.config/fish/completions; and ln -fs ~/.asdf/completions/asdf.fish ~/.config/fish/completions
end
