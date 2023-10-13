function tmux-sessionizer
    if test (count $argv) -eq 1
        set selected "$argv[1]"
    else
        set selected (fd --type d --type symlink --max-depth 1  . ~/projects ~/ | fzf)
    end

    if test -z "$selected"
        return 0
    end

    set selected_name (basename "$selected" | tr . _)
    set tmux_running (pgrep tmux)

    if test -z "$TMUX"
        and test -z "$tmux_running"
        tmux new-session -s "$selected_name" -c "$selected"
        return 0
    end

    if ! tmux has-session -t="$selected_name" 2> /dev/null
        tmux new-session -ds "$selected_name" -c "$selected"
    end

    if test -z "$TMUX"
        tmux attach-session -t "$selected_name"
        return 0
    end

    tmux switch-client -t "$selected_name"
end
