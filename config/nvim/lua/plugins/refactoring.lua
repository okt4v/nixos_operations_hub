return {
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "lewis6991/async.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    event = { "BufReadPost", "BufNewFile" },
    keys = {
      -- Select from all available refactors for the context
      { "<leader>rs", function() require("refactoring").select_refactor() end, mode = { "n", "x" }, desc = "Select refactor" },
      -- Extract visually selected code into a new function
      { "<leader>rf", function() require("refactoring").refactor("Extract Function") end,  mode = "x", desc = "Extract function" },
      -- Extract visually selected expression into a variable
      { "<leader>rv", function() require("refactoring").refactor("Extract Variable") end,  mode = "x", desc = "Extract variable" },
      -- Inline the variable under cursor back into its usages
      { "<leader>ri", function() require("refactoring").refactor("Inline Variable") end,   mode = { "n", "x" }, desc = "Inline variable" },
    },
    opts = {},
  },
}
