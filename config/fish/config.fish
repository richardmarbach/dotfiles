set fish_greeting

if status is-interactive
    # Commands to run in interactive sessions can go here
end

if test (uname) = "Darwin"
  if test -d (brew --prefix)"/share/fish/completions"
      set -gx fish_complete_path $fish_complete_path (brew --prefix)/share/fish/completions
  end

  if test -d (brew --prefix)"/share/fish/vendor_completions.d"
      set -gx fish_complete_path $fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
  end
end

set fish_function_path $fish_function_path ~/.config/fish/plugins/plugin-foreign-env/functions

set -x -g RIPGREP_CONFIG_PATH ~/.config/rg/config
