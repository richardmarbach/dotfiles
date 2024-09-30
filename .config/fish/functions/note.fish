function note
  set -l note (ls ~/notes | fzf)

  if test -z "$note"
    return 1
  end

  vim ~/notes/"$note"
end

