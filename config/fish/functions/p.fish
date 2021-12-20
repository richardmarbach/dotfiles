function p
  set -l proj (ls ~/projects | fzf)

  if test -n $proj
    cd ~/projects/$proj

    if test -e ".ruby-version"
      chruby (cat .ruby-version)
    end
  end
end

