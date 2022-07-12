local fn = vim.fn
local exec = vim.api.nvim_command

local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
  PACKER_BOOTSTRAP = fn.system({
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/wbthomason/packer.nvim",
    install_path,
  })
  print("Installing packer close and reopen Neovim...")
  vim.cmd([[packadd packer.nvim]])
end

vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]])

local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

packer.init()

return packer.startup(function(use)
  -- Packer can manage itself
  use("wbthomason/packer.nvim")

  -- Helpers
  use({ "nvim-lua/plenary.nvim" })

  -- Case changing library
  use({ "johmsalas/text-case.nvim" })

  -- Personal wiki integration
  use({ "mickael-menu/zk-nvim" })

  -- Debug protocol
  use({ "mfussenegger/nvim-dap" })

  -- Git integration
  use({ "sindrets/diffview.nvim" })
  use({ "lewis6991/gitsigns.nvim" })

  -- Neovim lua dev
  use({ "folke/lua-dev.nvim" })

  -- Lua Docs
  use({ "milisims/nvim-luaref" })
  use({ "nanotee/luv-vimdocs" })

  -- Color scheme
  use({ "ellisonleao/gruvbox.nvim" })

  -- Better splitting and joining
  use({ "AndrewRadev/splitjoin.vim" })
  -- Surround text objects with stuff
  use({ "kylechui/nvim-surround" })

  -- Alternate file configuration
  -- use({ "tpope/vim-projectionist" })

  -- Comment lines
  use({ "numToStr/Comment.nvim" })
  -- Context aware commenting
  use({ "JoosepAlviste/nvim-ts-context-commentstring" })

  -- Autocomplete html
  -- use({ "mattn/emmet-vim" })

  -- AST awareness
  use({ "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" })
  use({ "nvim-treesitter/playground" })
  use({ "nvim-treesitter/nvim-treesitter-textobjects" })

  -- Easier lsp configuration
  use({ "neovim/nvim-lspconfig" })
  use({ "williamboman/nvim-lsp-installer" })
  use({ "jose-elias-alvarez/null-ls.nvim" })

  -- Better formatting support
  use({ "mhartington/formatter.nvim" })

  -- Snippets
  use({ "L3MON4D3/LuaSnip" })

  -- Autocompletion
  use({
    "hrsh7th/nvim-cmp",
    requires = {
      { "hrsh7th/cmp-nvim-lsp" },
      { "hrsh7th/cmp-buffer" },
      { "hrsh7th/cmp-path" },
      { "saadparwaiz1/cmp_luasnip" },
      { "richardmarbach/cmp-github" },
    },
  })

  -- Ruby refactorings and helpers
  use({ "richardmarbach/extract-ruby-constant" })

  -- Fuzzy finder
  use({
    "nvim-telescope/telescope.nvim",
    requires = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-telescope/telescope-fzf-native.nvim", run = "make" },
      { "nvim-telescope/telescope-file-browser.nvim" },
      { "kyazdani42/nvim-web-devicons" },
    },
  })

  -- Nicer status line
  use({ "hoob3rt/lualine.nvim" })

  -- Better rust integration
  use({ "simrat39/rust-tools.nvim" })

  -- Test runner integration
  use({ "vim-test/vim-test" })
end)
