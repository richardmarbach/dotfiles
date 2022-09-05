local status_ok, git = pcall(require, "git")
if not status_ok then
  return
end

git.setup({
  keymaps = {
    -- Open blame window
    blame = "<leader>cb",
    -- Close blame window
    quit_blame = "q",
    -- Open blame commit
    blame_commit = "<CR>",
    -- Open file/folder in git repository
    browse = "<leader>co",
    -- Open pull request of the current branch
    open_pull_request = "<leader>cp",
    -- Create a pull request with the target branch is set in the `target_branch` option
    create_pull_request = "<leader>cn",
    -- Opens a new diff that compares against the current index
    diff = "<leader>cd",
    -- Close git diff
    diff_close = "<leader>cD",
    -- Revert to the specific commit
    revert = "<leader>cr",
    -- Revert the current file to the specific commit
    revert_file = "<leader>cR",
  },
  -- Default target branch when create a pull request
  target_branch = "master",
})
