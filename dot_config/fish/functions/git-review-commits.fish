function git-review-commits
    set -l since_date $argv[1]
    if test -z "$since_date"
        echo "Usage: git_review_commits YYYY-MM-DD"
        return 1
    end

    git log --since="$since_date" --reverse --pretty=format:"%h %s" | while read hash desc
        echo -e "\nCommit: $desc\n"
        git show $hash
        read -P "Press Enter to continue..."
    end
end
