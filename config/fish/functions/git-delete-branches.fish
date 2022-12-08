function git-delete-branches
  git branch |
    grep --invert-match '\*' |
    grep --invert-match 'master|main' |
    cut -c 3- |
    fzf --multi --preview="git l {} --" |
    gxargs --no-run-if-empty git branch --delete --force
end

