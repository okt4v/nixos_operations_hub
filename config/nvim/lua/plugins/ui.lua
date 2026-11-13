return {
  -- Themes (all lazy=false so they're available for :colorscheme)
  { "bjarneo/aether.nvim",       lazy = false, priority = 1000 },
  { "catppuccin/nvim",           name = "catppuccin", lazy = false, priority = 900 },
  { "rebelot/kanagawa.nvim",     lazy = false, priority = 900 },
  { "folke/tokyonight.nvim",     lazy = false, priority = 900 },
  { "ellisonleao/gruvbox.nvim",  lazy = false, priority = 900 },

  -- Welcome screen: Enter = fuzzy file search
  {
    "echasnovski/mini.starter",
    version = false,
    event = "VimEnter",
    config = function()
      local starter = require("mini.starter")
      starter.setup({
        items = {
          { name = "Find files",   action = "FzfLua files",     section = "" },
          { name = "Recent files", action = "FzfLua oldfiles",  section = "" },
          { name = "Live grep",    action = "FzfLua live_grep", section = "" },
          { name = "New file",     action = "enew",             section = "" },
          { name = "Quit",         action = "qa",               section = "" },
        },
        header = "",
        footer = "",
        content_hooks = {
          starter.gen_hook.adding_bullet("  "),
          starter.gen_hook.aligning("center", "center"),
        },
      })
    end,
  },

  -- Minimal status line
  {
    "echasnovski/mini.statusline",
    event = "VeryLazy",
    opts = { use_icons = true },
  },

  -- Render hex colour codes (#ff8c00) in their actual colour inline
  {
    "brenoprata10/nvim-highlight-colors",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      render = "background",
      enable_named_colors = false,
      enable_tailwind = false,
    },
  },

  -- Show available keybinds after pressing leader (or any prefix key)
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      delay = 400,
      spec = {
        { "<leader>d",  group = "diagnostics" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git diff" },
        { "<leader>h", group = "git hunks" },
        { "<leader>m", group = "molten/notebook" },
        { "<leader>q", group = "session" },
        { "<leader>r", group = "refactor" },
        { "<leader>t", group = "test" },
      },
    },
  },
}
