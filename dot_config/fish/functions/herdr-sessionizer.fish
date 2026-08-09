function herdr-sessionizer
    if test (count $argv) -eq 1
        set selected "$argv[1]"
    else
        set selected (fd --type d --type symlink --max-depth 1 . ~/projects ~/ ~/gigs | fzf)
    end

    if test -z "$selected"
        return 0
    end

    set selected (realpath "$selected")
    set selected_name (basename "$selected" | tr . _)

    if not pgrep -qf 'herdr'
        herdr
        return 0
    end

    set existing (herdr pane list 2>/dev/null | jq -r --arg cwd "$selected" '.result.panes[] | select(.cwd == $cwd) | .workspace_id' | head -n1)

    if test -z "$existing"
        set existing (herdr workspace list 2>/dev/null | jq -r --arg label "$selected_name" '.result.workspaces[] | select(.label == $label) | .workspace_id' | head -n1)
    end

    if test -n "$existing"
        herdr workspace focus "$existing" >/dev/null
    else
        herdr workspace create --cwd "$selected" --label "$selected_name" --focus >/dev/null
    end

    if test -z "$HERDR_ENV"
        herdr
    end
end
