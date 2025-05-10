set fish_greeting

eval "$(/opt/homebrew/bin/brew shellenv)"

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
set -x -g FZF_DEFAULT_COMMAND "rg --files --hidden"
set -x -g EDITOR "nvim"
set -x -g GEM_EDITOR "nvim"
set -x -g MANPAGER "nvim +Man!"

fish_add_path -a ~/go/bin

