---@param on_attach fun(client, buffer)
local function setup_on_attach(on_attach)
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local buffer = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client.name == "copilot" then
        return
      end
      on_attach(client, buffer)
    end,
  })
end

return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      {
        "folke/neodev.nvim",
        opts = { experimental = { pathStrict = true } },
      },
      "mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "b0o/SchemaStore.nvim",
      {
        "simrat39/rust-tools.nvim",
        dependencies = { "nvim-lspconfig" },
        opt = {},
        config = function(_, opts)
          require("rust-tools").setup(opts)
        end,
      },
    },
    ---@class PluginLspOpts
    opts = {
      -- options for vim.diagnostic.config()
      diagnostics = {
        virtual_text = false,
        signs = true,
        update_in_insert = false,
        underline = true,
        severity_sort = true,
        float = {
          focusable = false,
          style = "minimal",
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
      },
      ---@type lspconfig.options
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
            },
          },
        },
        -- ruby_lsp = {
        --   init_options = {
        --     enabledFeatures = {
        --       semanticHighlighting = false,
        --     },
        --   },
        -- },
        -- rubocop = { mason = false },
        solargraph = {
          init_options = {
            formatting = false,
          },
          settings = {
            solargraph = {
              diagnostics = true,
            },
          },
        },
        -- biome = {},
        jsonls = {
          -- lazy-load schemastore when needed
          on_new_config = function(new_config)
            new_config.settings.json.schemas = new_config.settings.json.schemas or {}
            vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
          end,
          settings = {
            json = {
              format = {
                enable = true,
              },
              validate = { enable = true },
            },
          },
        },
      },
      setup = {},
    },
    ---@param opts PluginLspOpts
    config = function(plugin, opts)
      require("plugins.lsp.format").setup()

      -- setup formatting and keymaps
      setup_on_attach(function(client, buffer)
        require("plugins.lsp.keymaps").on_attach(client, buffer)
      end)

      -- diagnostics
      -- for name, icon in pairs(diagnostic_signs) do
      for name, icon in pairs(require("config.icons").diagnostics) do
        name = "DiagnosticSign" .. name
        vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
      end
      vim.diagnostic.config(opts.diagnostics)

      local servers = opts.servers
      local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

      local function setup(server)
        local server_opts = servers[server] or {}
        server_opts.capabilities = capabilities
        if opts.setup[server] then
          if opts.setup[server](server, server_opts) then
            return
          end
        elseif opts.setup["*"] then
          if opts.setup["*"](server, server_opts) then
            return
          end
        end
        require("lspconfig")[server].setup(server_opts)
      end

      local mlsp = require("mason-lspconfig")
      local available = mlsp.get_available_servers()

      local ensure_installed = {} ---@type string[]
      for server, server_opts in pairs(servers) do
        if server_opts then
          server_opts = server_opts == true and {} or server_opts
          -- run manual setup if mason=false or if this is a server that cannot be installed with mason-lspconfig
          if server_opts.mason == false or not vim.tbl_contains(available, server) then
            setup(server)
          else
            ensure_installed[#ensure_installed + 1] = server
          end
        end
      end

      require("mason-lspconfig").setup({ ensure_installed = ensure_installed })
      require("mason-lspconfig").setup_handlers({ setup })
    end,
  },

  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        sql = { "pg_format" },
        -- javascript = { "prettierd" },
        -- javascriptreact = { "prettierd" },
        -- typescript = { "prettierd" },
        -- typescriptreact = { "prettierd" },
        yaml = { "prettierd" },
        -- json = { "prettierd" },
        -- jsonc = { "prettierd" },
        css = { "prettierd" },
        scss = { "prettierd" },
        html = { "prettierd" },
        ruby = { "rubocop" },
        python = { "black" },
      },
      default_format_opts = {
        lsp_format = "fallback",
      },
      formatters = {
        rubocop = {
          command = "bin/rubocop",
        },
      },
    },
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost" },
    config = function()
      local lint = require("lint")

      local severity_map = {
        ["fatal"] = vim.diagnostic.severity.ERROR,
        ["error"] = vim.diagnostic.severity.ERROR,
        ["warning"] = vim.diagnostic.severity.WARN,
        ["convention"] = vim.diagnostic.severity.HINT,
        ["refactor"] = vim.diagnostic.severity.INFO,
        ["info"] = vim.diagnostic.severity.INFO,
      }

      ---@diagnostic disable-next-line: missing-fields
      lint.linters["haml-lint"] = {
        cmd = "bundle",
        stdin = false,
        ignore_exitcode = true,
        args = { "exec", "haml-lint", "--reporter", "json" },
        parser = function(output)
          local diagnostics = {}
          local decoded = vim.json.decode(output)

          if not decoded or not decoded.files or not decoded.files[1] then
            return diagnostics
          end

          local offences = decoded.files[1].offenses

          for _, off in pairs(offences) do
            table.insert(diagnostics, {
              source = "haml-lint",
              lnum = off.location.line - 1,
              col = 0,
              end_lnum = off.location.line - 1,
              end_col = 0,
              severity = severity_map[off.severity],
              message = off.message,
              code = off.linter_name,
            })
          end

          return diagnostics
        end,
      }

      lint.linters_by_ft = {
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        haml = { "haml-lint" },
      }
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
        group = vim.api.nvim_create_augroup("AutoLint", {}),
        callback = function()
          require("lint").try_lint()
        end,
      })
    end,
  },

  -- cmdline tools and lsp servers
  {

    "williamboman/mason.nvim",
    cmd = "Mason",
    opts = {
      ensure_installed = {},
    },
    ---@param opts MasonSettings | {ensure_installed: string[]}
    config = function(_, opts)
      require("mason").setup(opts)
      local mr = require("mason-registry")
      for _, tool in ipairs(opts.ensure_installed) do
        local p = mr.get_package(tool)
        if not p:is_installed() then
          p:install()
        end
      end
    end,
  },
}
