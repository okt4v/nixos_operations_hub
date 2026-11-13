return {
  -- Saves and restores sessions automatically per working directory
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>qs", function() require("persistence").load() end,               desc = "Restore session (cwd)" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
      { "<leader>qd", function() require("persistence").stop() end,               desc = "Don't save session on exit" },
    },
  },

  -- Distraction-free writing / reading mode
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    keys = {
      { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen mode" },
    },
    opts = {
      window = { width = 90 },
      plugins = {
        gitsigns     = { enabled = false },
        tmux         = { enabled = false },
        kitty        = { enabled = true, font = "+2" },
      },
    },
  },
}
