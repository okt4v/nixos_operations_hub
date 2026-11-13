return {
  -- Snippet engine — needed for GDScript snippets defined in after/ftplugin/gdscript.lua
  {
    "L3MON4D3/LuaSnip",
    dependencies = { "rafamadriz/friendly-snippets" },
    build = "make install_jsregexp",
    event = { "InsertEnter" },
    ft = { "gdscript", "nasm" }, -- also load when these files are opened (for ftplugin snippets)
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
      -- own snippets (LaTeX math etc.) live in ~/.config/nvim/snippets
      require("luasnip.loaders.from_vscode").lazy_load({ paths = { vim.fn.stdpath("config") .. "/snippets" } })
    end,
  },

  -- Completion engine
  -- Shift+Enter accepts; Enter always inserts a newline.
  -- Requires a terminal with Kitty keyboard protocol (Kitty, Ghostty, WezTerm).
  {
    "saghen/blink.cmp",
    dependencies = { "L3MON4D3/LuaSnip" },
    event = { "InsertEnter" },
    version = "*",
    opts = {
      keymap = {
        preset = "none",
        ["<Tab>"]   = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        ["<Down>"]  = { "select_next", "fallback" },
        ["<Up>"]    = { "select_prev", "fallback" },
        ["<S-CR>"]  = { "accept", "fallback" },
        ["<CR>"]    = { "fallback" },
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"]   = { "hide", "fallback" },
        ["<C-b>"]   = { "scroll_documentation_up", "fallback" },
        ["<C-f>"]   = { "scroll_documentation_down", "fallback" },
      },
      appearance = {
        nerd_font_variant = "mono",
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      snippets = {
        preset = "luasnip",
      },
      completion = {
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
      },
      signature = { enabled = true },
    },
  },
}
