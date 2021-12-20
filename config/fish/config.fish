if status is-interactive
    # Commands to run in interactive sessions can go here
end

if test -eq (uname) "Darwin"
  if test -d (brew --prefix)"/share/fish/completions"
      set -gx fish_complete_path $fish_complete_path (brew --prefix)/share/fish/completions
  end

  if test -d (brew --prefix)"/share/fish/vendor_completions.d"
      set -gx fish_complete_path $fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
  end

  source /usr/local/opt/asdf/asdf.fish
else 
  source ~/.asdf/asdf.fish

  mkdir -p ~/.config/fish/completions; and ln -fs ~/.asdf/completions/asdf.fish ~/.config/fish/completions
end

set fish_function_path $fish_function_path ~/.config/fish/plugins/plugin-foreign-env/functions
