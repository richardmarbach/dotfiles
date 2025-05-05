function p
  set -l proj (find ~/projects ~/gigs -mindepth 1 -type d -maxdepth 1  | fzf)

  if test -n $proj
    cd ~/projects/$proj
  end
end

