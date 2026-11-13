return {
  -- Auto-close brackets, quotes, etc.
  {
    "echasnovski/mini.pairs",
    event = "InsertEnter",
    opts = {},
  },

  -- gc to comment / uncomment
  {
    "echasnovski/mini.comment",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },

  -- Surround motions: ys<motion><char> add, ds<char> delete, cs<old><new> change
  {
    "echasnovski/mini.surround",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      mappings = {
        add = "ys",
        delete = "ds",
        find = "sf",
        find_left = "sF",
        highlight = "sh",
        replace = "cs",
        update_n_lines = "sn",
      },
    },
  },

  -- Auto-detect indentation (tabs vs spaces, indent width) from the open file
  {
    "tpope/vim-sleuth",
    event = { "BufReadPost", "BufNewFile" },
  },

  -- Highlight TODO, FIXME, HACK, NOTE, etc. in comments
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    keys = {
      { "<leader>ft", "<cmd>TodoFzfLua<cr>", desc = "Search TODOs" },
    },
    opts = { signs = true },
  },

  -- Vertical indent guide lines
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      indent = { char = "│" },
      scope  = { enabled = false },
    },
  },

  -- s<char><char> to jump to any visible position on screen
  -- S to select via treesitter nodes
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "Flash treesitter" },
      { "r", mode = "o",               function() require("flash").remote() end,             desc = "Flash remote" },
      { "<C-s>", mode = { "c" },       function() require("flash").toggle() end,             desc = "Toggle flash search" },
    },
  },
}
