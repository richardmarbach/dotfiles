function p
  set -l proj (ls ~/projects | fzf)

  if test -n $proj
    cd ~/projects/$proj
  end
end

