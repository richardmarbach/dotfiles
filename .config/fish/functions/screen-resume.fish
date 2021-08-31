function screen-list
  screen -list | sed 1d | sed '$ d' | sed -e 's/^[[:space:]]*//'
end

function screen-resume
  set -l active (screen-list | gwc -l)

  if test "$active" -gt 1
    set -l id (screen-list | fzf | gcut -d'.' -f1)
    if test -n "$id"
      screen -r "$id"
    end
  else if test "$active" -eq 1
    set -l id (screen-list | gcut -d'.' -f1) 
    screen -r "$id"
  else
    echo "No active screens"
    return 1
  end
end
