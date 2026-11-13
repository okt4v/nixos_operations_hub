return {
  -- Notification backend — shows floating popups in the corner
  {
    "rcarriga/nvim-notify",
    lazy = true,
    opts = {
      timeout = 3000,
      render = "compact",
      stages = "static",   -- no slide animation
      top_down = false,    -- stack from bottom of corner upward
    },
  },

  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
    opts = {
      presets = {
        command_palette       = true,  -- cmdline + popupmenu docked at top center
        long_message_to_split = true,
        inc_rename            = false,
      },
      cmdline = {
        view = "cmdline_popup",
      },
      -- Route all messages (including errors) to floating popups, not the bottom bar
      messages = {
        view         = "notify",
        view_error   = "notify",
        view_warn    = "notify",
        view_history = "messages",
        view_search  = "virtualtext",
      },
      notify = {
        enabled = true,
        view    = "notify",
      },
      lsp = {
        -- blink.cmp and our LspAttach keymaps handle hover/signature
        hover     = { enabled = false },
        signature = { enabled = false },
        override  = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"]                = true,
        },
      },
      routes = {
        { filter = { event = "msg_show", kind = "", find = "written" }, opts = { skip = true } },
        { filter = { event = "msg_show", kind = "search_count" },       opts = { skip = true } },
      },
    },
  },
}
