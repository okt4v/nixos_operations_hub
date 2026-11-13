return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cf",
        function() require("conform").format({ async = true }) end,
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        python     = { "ruff_format", "ruff_organize_imports" },
        c          = { "clang_format" },
        cpp        = { "clang_format" },
        -- clangd reads .clang-format in the project root.
        -- For C++: add `set(CMAKE_EXPORT_COMPILE_COMMANDS ON)` for CMake,
        -- or run `bear -- make` once for Makefile projects, so clangd
        -- resolves cross-file completions from included .hpp headers.
        lua        = { "stylua" },
        go         = { "gofmt" },
        json       = { "prettier" },
        yaml       = { "prettier" },
        markdown   = { "prettier" },
        html       = { "prettier" },
        css        = { "prettier" },
        javascript = { "prettier" },
        bash       = { "shfmt" },
        sh         = { "shfmt" },
        nix        = { "nixfmt" },
      },
      format_on_save = function(bufnr)
        if vim.b[bufnr].tfwr then return end -- set in config/autocmds.lua
        return { timeout_ms = 500, lsp_fallback = true }
      end,
      formatters = {
        ["clang-format"] = {
          -- use project .clang-format if present, else fall back to 4-space indent
          prepend_args = { "-style=file", "-fallback-style={BasedOnStyle: LLVM, IndentWidth: 4, UseTab: Never}" },
        },
      },
    },
  },
}
