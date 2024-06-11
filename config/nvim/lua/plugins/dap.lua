local function find_codelldb()
  local ok, registry = pcall(require, "mason-registry")

  if ok and registry.is_installed("codelldb") then
    local pkg = registry.get_package("codelldb")
    return table.concat({ pkg:get_install_path(), "extension", "adapter", "codelldb" }, "/")
  end

  return nil
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "leoluz/nvim-dap-go",
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
      "williamboman/mason.nvim",
      "julianolf/nvim-dap-lldb",
      "suketa/nvim-dap-ruby",
    },
    config = function()
      local dap = require("dap")
      local ui = require("dapui")

      require("dapui").setup()
      require("dap-go").setup()
      require("dap-lldb").setup({
        configurations = {
          c = {
            {
              name = "Launch Debugger",
              type = "lldb",
              request = "launch",
              cwd = "${workspaceFolder}",
              program = "build/bin/nvim",
              args = { "--clean", "--headless", "--cmd", [[4verb echo systemlist("cat", bufnr(""))]] },
              stopOnEntry = false,
            },
          },
        },
      })
      require("dap-ruby").setup()

      require("nvim-dap-virtual-text").setup({
        -- This just tries to mitigate the chance that I leak tokens here. Probably won't stop it from happening...
        display_callback = function(variable)
          local name = string.lower(variable.name)
          local value = string.lower(variable.value)
          if name:match("secret") or name:match("api") or value:match("secret") or value:match("api") then
            return "*****"
          end

          if #variable.value > 15 then
            return " " .. string.sub(variable.value, 1, 15) .. "... "
          end

          return " " .. variable.value
        end,
      })

      -- Handled by nvim-dap-go
      -- dap.adapters.go = {
      --   type = "server",
      --   port = "${port}",
      --   executable = {
      --     command = "dlv",
      --     args = { "dap", "-l", "127.0.0.1:${port}" },
      --   },
      -- }

      -- local elixir_ls_debugger = vim.fn.exepath("elixir-ls-debugger")
      -- if elixir_ls_debugger ~= "" then
      --   dap.adapters.mix_task = {
      --     type = "executable",
      --     command = elixir_ls_debugger,
      --   }
      --
      --   dap.configurations.elixir = {
      --     {
      --       type = "mix_task",
      --       name = "phoenix server",
      --       task = "phx.server",
      --       request = "launch",
      --       projectDir = "${workspaceFolder}",
      --       exitAfterTaskReturns = false,
      --       debugAutoInterpretAllModules = false,
      --     },
      --   }
      -- end

      -- local c_debugger = find_codelldb()
      -- if c_debugger ~= "" then
      --   dap.adapters.lldb = {
      --     type = "executable",
      --     command = c_debugger,
      --     env = {
      --       LLDB_LAUNCH_FLAG_LAUNCH_IN_TTY = "YES",
      --     },
      --   }
      -- end
      --
      -- dap.configurations.c = {
      --   {
      --     name = "Launch",
      --     type = "lldb",
      --     request = "launch",
      --     program = [[local/bin/nvim --clean --cmd '4verb echo systemlist("cat", bufnr(""))']],
      --     cwd = "${workspaceFolder}",
      --     stopOnEntry = false,
      --     runInTerminal = true,
      --   },
      -- }
      --
      vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint)
      vim.keymap.set("n", "<leader>gb", dap.run_to_cursor)

      -- Eval var under cursor
      vim.keymap.set("n", "<leader>?", function()
        require("dapui").eval(nil, { enter = true })
      end)

      vim.keymap.set("n", "<F1>", dap.continue)
      vim.keymap.set("n", "<F2>", dap.step_into)
      vim.keymap.set("n", "<F3>", dap.step_over)
      vim.keymap.set("n", "<F7>", dap.step_out)
      vim.keymap.set("n", "<F10>", dap.step_back)
      vim.keymap.set("n", "<F12>", dap.restart)

      dap.listeners.before.attach.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        ui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        ui.close()
      end
    end,
  },
}
