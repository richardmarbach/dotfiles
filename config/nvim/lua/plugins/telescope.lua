return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-file-browser.nvim",
    -- Fuzzy Finder Algorithm which dependencies local dependencies to be built. Only load if `make` is available
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make", cond = vim.fn.executable("make") == 1 },
  },
  config = function()
    require("telescope").setup({
      defaults = {
        extensions = {
          file_browser = {
            hijack_netrw = true,
          },
        },
      },
    })

    -- Enable telescope fzf native, if installed
    pcall(require("telescope").load_extension, "fzf")

    -- Enable filebrowser
    pcall(require("telescope").load_extension, "file_browser")
  end,
  keys = {
    -- See `:help telescope.builtin`
    {
      "<leader>?",
      function()
        require("telescope.builtin").oldfiles()
      end,
      { desc = "[?] Find recently opened files" },
    },
    {
      "<leader><space>",
      function()
        require("telescope.builtin").buffers()
      end,
      { desc = "[ ] Find existing buffers" },
    },
    {

      "<leader>/",
      function()
        -- You can pass additional configuration to telescope to change theme, layout, etc.
        require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
          winblend = 10,
          previewer = false,
        }))
      end,
      { desc = "[/] Fuzzily search in current buffer]" },
    },

    {

      "<leader>sp",
      function()
        require("telescope.builtin").find_files({ hidden = true })
      end,
      { desc = "[S]earch [P]roject Files" },
    },
    {
      "<leader>sh",
      function()
        require("telescope.builtin").help_tags()
      end,
      { desc = "[S]earch [H]elp" },
    },
    {
      "<leader>sr",
      function()
        require("telescope.builtin").resume()
      end,
      { desc = "[S]earch [R]esume" },
    },
    {
      "<leader>sw",
      function()
        require("telescope.builtin").grep_string()
      end,
      { desc = "[S]earch current [W]ord" },
    },
    {
      "<leader>sg",
      function()
        require("telescope.builtin").live_grep()
      end,
      { desc = "[S]earch by [G]rep" },
    },
    {
      "<leader>sd",
      function()
        require("telescope.builtin").diagnostics()
      end,
      { desc = "[S]earch [D]iagnostics" },
    },
    {

      "<leader>sf",
      function()
        require("telescope").extensions.file_browser.file_browser({ hidden = true, files = false })
      end,
      { desc = "[S]earch [F]olders" },
    },

    {

      "<leader>se",
      function()
        require("telescope").extensions.file_browser.file_browser({
          hidden = true,
          cwd = require("telescope.utils").buffer_dir(),
        })
      end,
      { desc = "Browse files in current folder" },
    },
  },
}
