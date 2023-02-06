function git-ch-branch
  git branch |
    grep --invert-match '\*' |
    cut -c 3- |
    fzf --preview="git l {} --" |
    gxargs --no-run-if-empty git checkout
end
