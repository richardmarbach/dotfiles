local M = {}

local fn = vim.fn
local exec = vim.api.nvim_command

function M.init()
  local install_path = fn.stdpath('data')..'/site/pack/packer/opt/packer.nvim'
  if fn.empty(fn.glob(install_path)) == 1 then
    exec("!git clone https://github.com/wbthomason/packer.nvim "..install_path)
  end
  vim.cmd [[packadd packer.nvim]]
  vim.cmd 'autocmd BufWritePost plugins.lua PackerCompile'

  M.setup()
end


function M.setup()
  local packer = require('packer')

  packer.init({
    config = {
      compile_path = fn.stdpath('config') .. '/lua/packer_compiled.lua'
    }
  })
  packer.startup(M.plugins())
end

function M.plugins()
  return function()
    -- Color scheme
    use { 'jonathanfilip/vim-lucius' }

    -- Remove search highliting on exit
    use { 'romainl/vim-cool' }
    -- Better splitting and joining
    use { 'AndrewRadev/splitjoin.vim' }
    -- Surround text objects with stuff
    use { 'tpope/vim-surround' }

    -- Comment lines
    use { 'tpope/vim-commentary' }
    -- Context aware commenting
    use { 'JoosepAlviste/nvim-ts-context-commentstring' }

    -- More powerful dot operator
    use { 'tpope/vim-repeat' }

    -- Autocomplete html
    use { 'mattn/emmet-vim' }

    -- AST awareness
    use { 'nvim-treesitter/nvim-treesitter' }
    use { 'nvim-treesitter/nvim-treesitter-textobjects' }

    -- Easier lsp configuration
    use { 'neovim/nvim-lspconfig' }

    -- Autocompletion
    use { 
      'hrsh7th/nvim-cmp',
      requires = {
        {'hrsh7th/cmp-nvim-lsp'},
        {'hrsh7th/cmp-buffer'},
        {'hrsh7th/cmp-path'},
      }
    }

    -- Fuzzy finder
    use { 
      'nvim-telescope/telescope.nvim',
      requires = {
        {'nvim-lua/plenary.nvim' },
        {'nvim-telescope/telescope-fzf-native.nvim', run = 'make'}
      }

    }

    -- Nicer status line
    use { 'hoob3rt/lualine.nvim' }
  end
end

return M
