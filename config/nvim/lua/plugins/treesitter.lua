return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- Install all parsers on first install and when running :Lazy build nvim-treesitter
    build = ":TSInstall! python c cpp go bash json yaml toml lua markdown markdown_inline nasm gdscript godot_resource nix regex comment vim vimdoc html css javascript jsdoc",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      -- v1.0: setup() only accepts install_dir — ensure_installed/highlight/indent are gone
      require("nvim-treesitter").setup()

      -- Enable treesitter highlight for every filetype that has a parser.
      -- pcall silently skips filetypes with no parser installed.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter_highlight", { clear = true }),
        callback = function(ev)
          -- skip gdscript — custom indentexpr in after/ftplugin/gdscript.lua would conflict
          if vim.bo[ev.buf].filetype == "gdscript" then
            pcall(vim.treesitter.start, ev.buf, "gdscript")
            return
          end
          pcall(vim.treesitter.start, ev.buf)
        end,
      })
    end,
  },
}
