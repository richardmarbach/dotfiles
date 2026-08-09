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

    if not herdr workspace list >/dev/null 2>&1
        # No server yet: start one rooted at the selected folder.
        pushd "$selected"
        herdr
        popd
        return $status
    end

    set workspaces (herdr workspace list 2>/dev/null)

    set existing (echo $workspaces | jq -r --arg label "$selected_name" --arg cwd "$selected" '.result.workspaces[] | select(.label == $label or .worktree.checkout_path == $cwd or .worktree.repo_root == $cwd) | .workspace_id' | head -n1)

    if test -z "$existing"
        set existing (herdr workspace create --cwd "$selected" --label "$selected_name" --focus 2>/dev/null | jq -r '.result.workspace.workspace_id // empty')
    else
        herdr workspace focus "$existing" >/dev/null
    end

    # Inside herdr the focus/create above is all that is needed; never nest.
    if test -z "$HERDR_ENV"
        herdr
    end
end
