return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/nvim-nio",
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-go",
    },
    keys = {
      { "<leader>tn", function() require("neotest").run.run() end,                       desc = "Run nearest test" },
      { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end,     desc = "Run file tests" },
      { "<leader>ts", function() require("neotest").summary.toggle() end,                desc = "Test summary" },
      { "<leader>to", function() require("neotest").output_panel.toggle() end,           desc = "Test output" },
      { "<leader>tx", function() require("neotest").run.stop() end,                      desc = "Stop test" },
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-python")({
            runner = "pytest",
            python = function()
              -- use venv python if one is active, otherwise fall back to system python
              local venv = os.getenv("VIRTUAL_ENV")
              if venv then
                return venv .. "/bin/python"
              end
              return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
            end,
          }),
          require("neotest-go"),
        },
      })
    end,
  },
}
