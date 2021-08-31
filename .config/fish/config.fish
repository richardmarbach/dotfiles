if status is-interactive
    # Commands to run in interactive sessions can go here
end

if test -d (brew --prefix)"/share/fish/completions"
    set -gx fish_complete_path $fish_complete_path (brew --prefix)/share/fish/completions
end

if test -d (brew --prefix)"/share/fish/vendor_completions.d"
    set -gx fish_complete_path $fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
end

source /usr/local/opt/asdf/asdf.fish

source /usr/local/share/chruby/chruby.fish
source /usr/local/share/gem_home/gem_home.fish

if test -f '.ruby-version'
  chruby (cat .ruby-version)
end
# if test -d '.gem'
#     gem_home .
# else
#     gem_home "$HOME"
# end
