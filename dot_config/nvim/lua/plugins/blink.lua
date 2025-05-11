return {
  {
    "saghen/blink.cmp",
    build = "cargo build --release",
    version = "1.*",
    keys = {
      {
        "<C-x><C-o>",
        function()
          require("blink.cmp").show()
        end,
        mode = "i",
      },
    },
    ---@type blink.cmp.Config
    opts = {
      keymap = { preset = "default" },
      completion = {
        ghost_text = { enabled = true },
        trigger = { show_on_keyword = false, show_on_trigger_character = false },
      },
      sources = {
        default = { "lsp", "path", "snippets", "copilot" },
        providers = {
          lazydev = { module = "lazydev.integrations.blink", score_offset = 100 },
          lsp = { fallbacks = {} }, -- fallback to buffer
          copilot = {
            name = "copilot",
            module = "blink-cmp-copilot",
            score_offset = 100,
            async = true,
          },
        },
        per_filetype = {
          lua = { inherit_defaults = true, "lazydev" },
        },
      },
      signature = { enabled = true },
      fuzzy = { implementation = "prefer_rust_with_warning" },
      snippets = { preset = "luasnip" },
    },
    opts_extend = { "sources.default" },
  },
  {
    "zbirenbaum/copilot.lua",
    config = function()
      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
    end,
  },
  {
    "giuxtaposition/blink-cmp-copilot",
  },
  -- {
  --   "hrsh7th/nvim-cmp",
  --   event = "InsertEnter",
  --   dependencies = {
  --     { "hrsh7th/cmp-buffer" },
  --     { "hrsh7th/cmp-path" },
  --     { "hrsh7th/cmp-nvim-lua" },
  --     { "hrsh7th/cmp-nvim-lsp" },
  --     { "saadparwaiz1/cmp_luasnip" },
  --     -- { "codecompanion.nvim" },
  --     {
  --       "zbirenbaum/copilot.lua",
  --       config = function()
  --         require("copilot").setup()
  --       end,
  --     },
  --     {
  --       "zbirenbaum/copilot-cmp",
  --       config = function()
  --         require("copilot_cmp").setup()
  --       end,
  --     },
  --   },
  --   -- stylua: ignore
  --   keys = {
  --     { "<C-x><C-o>", function() require("cmp").complete() end, mode = "i", },
  --   },
  --   opts = function()
  --     local cmp = require("cmp")
  --     local luasnip = require("luasnip")
  --     vim.opt.completeopt = { "menu", "menuone", "noselect" }
  --
  --     local cmp_select_opts = { behavior = cmp.SelectBehavior.Select }
  --
  --     return {
  --       preselect = cmp.PreselectMode.None,
  --       completion = {
  --         completeopt = "menu,menuone,noinsert",
  --       },
  --       snippet = {
  --         expand = function(args)
  --           luasnip.lsp_expand(args.body)
  --         end,
  --       },
  --       sources = {
  --         { name = "path" },
  --         { name = "nvim_lsp", keyword_length = 1 },
  --         { name = "codecompanion" },
  --         { name = "copilot" },
  --         { name = "buffer", keyword_length = 3 },
  --         { name = "luasnip", keyword_length = 2 },
  --       },
  --       window = {
  --         documentation = vim.tbl_deep_extend("force", cmp.config.window.bordered(), {
  --           max_height = 15,
  --           max_width = 60,
  --         }),
  --       },
  --       formatting = {
  --         fields = { "abbr", "menu", "kind" },
  --         format = function(entry, item)
  --           local short_name = {
  --             nvim_lsp = "LSP",
  --             nvim_lua = "nvim",
  --           }
  --
  --           local menu_name = short_name[entry.source.name] or entry.source.name
  --
  --           item.menu = string.format("[%s]", menu_name)
  --           return item
  --         end,
  --       },
  --       mapping = {
  --         -- confirm selection
  --         -- ["<CR>"] = cmp.mapping.confirm({ select = false, behavior = cmp.ConfirmBehavior.Replace }),
  --         ["<C-y>"] = cmp.mapping.confirm({ select = true, behavior = cmp.ConfirmBehavior.Replace }),
  --
  --         -- navigate items on the list
  --         ["<Up>"] = cmp.mapping.select_prev_item(cmp_select_opts),
  --         ["<Down>"] = cmp.mapping.select_next_item(cmp_select_opts),
  --         ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select_opts),
  --         ["<C-n>"] = cmp.mapping.select_next_item(cmp_select_opts),
  --
  --         -- scroll up and down in the completion documentation
  --         ["<C-f>"] = cmp.mapping.scroll_docs(5),
  --         ["<C-u>"] = cmp.mapping.scroll_docs(-5),
  --
  --         -- toggle completion
  --         ["<C-e>"] = cmp.mapping(function(fallback)
  --           if cmp.visible() then
  --             cmp.abort()
  --             fallback()
  --           else
  --             cmp.complete()
  --           end
  --         end),
  --
  --         -- go to next placeholder in the snippet
  --         ["<C-l>"] = cmp.mapping(function(fallback)
  --           if luasnip.expand_or_jumpable() then
  --             luasnip.expand_or_jump()
  --           else
  --             fallback()
  --           end
  --         end, { "i", "s" }),
  --
  --         -- go to previous placeholder in the snippet
  --         ["<C-h>"] = cmp.mapping(function(fallback)
  --           if luasnip.jumpable(-1) then
  --             luasnip.jump(-1)
  --           else
  --             fallback()
  --           end
  --         end, { "i", "s" }),
  --
  --         -- cycle through luasnip choices
  --         ["<C-,>"] = cmp.mapping(function(fallback)
  --           if luasnip.choice_active() then
  --             luasnip.change_choice(1)
  --           else
  --             fallback()
  --           end
  --         end, { "i", "s" }),
  --
  --         -- when menu is visible, navigate to next item
  --         -- when line is empty, insert a tab character
  --         -- else, activate completion
  --         -- ["<Tab>"] = cmp.mapping(function(fallback)
  --         --   local col = vim.fn.col(".") - 1
  --         --
  --         --   if cmp.visible() then
  --         --     cmp.select_next_item(cmp_select_opts)
  --         --   elseif col == 0 or vim.fn.getline("."):sub(col, col):match("%s") then
  --         --     fallback()
  --         --   else
  --         --     cmp.complete()
  --         --   end
  --         -- end, { "i", "s" }),
  --
  --         -- when menu is visible, navigate to previous item on list
  --         -- else, revert to default behavior
  --         -- ["<S-Tab>"] = cmp.mapping(function(fallback)
  --         --   if cmp.visible() then
  --         --     cmp.select_prev_item(cmp_select_opts)
  --         --   else
  --         --     fallback()
  --         --   end
  --         -- end, { "i", "s" }),
  --       },
  --       experimental = {
  --         ghost_text = {
  --           hl_group = "LspCodeLens",
  --         },
  --       },
  --     }
  --   end,
  --   config = function(_, opts)
  --     local cmp = require("cmp")
  --     cmp.setup(opts)
  --
  --     cmp.setup.filetype("gitcommit", {
  --       sources = {
  --         { name = "path" },
  --         { name = "nvim_lsp", keyword_length = 3 },
  --         { name = "buffer", keyword_length = 3 },
  --         { name = "luasnip", keyword_length = 2 },
  --       },
  --     })
  --   end,
  -- },
}
