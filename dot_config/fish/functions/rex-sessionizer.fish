function rex-sessionizer
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

    set session (rex ls --json | jq -r --arg label "$selected_name" '.sessions[] | select(.label == $label) | .session_id' | head -n1)

    if test -z "$session"
        set session (rex new "$selected_name" -c "$selected" --json | jq -r '.session_id // empty')
    end

    if test -z "$session"
        echo "rex-sessionizer: could not create session for $selected" >&2
        return 1
    end

    rex do session.select session_id="$session"
end
