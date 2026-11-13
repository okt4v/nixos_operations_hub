return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {},
  },

  -- All formatters are installed via Nix (home.packages), so no auto-install needed.
  -- mason-tool-installer is kept only for manual :MasonInstall usage.
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    event = "VeryLazy",
    opts = { ensure_installed = {} },
  },

  -- Provides default server definitions (cmd, filetypes, root patterns).
  -- In Neovim 0.11+ we configure via vim.lsp.config() and enable via vim.lsp.enable()
  -- rather than require('lspconfig').server.setup().
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- Give blink.cmp capabilities to every server
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, blink = pcall(require, "blink.cmp")
      if ok then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end
      vim.lsp.config("*", { capabilities = capabilities })

      -- lua_ls: teach it the neovim runtime so it knows vim.* globals
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
              checkThirdParty = false,
              library = vim.api.nvim_get_runtime_file("", true),
            },
            diagnostics = { globals = { "vim" } },
            telemetry = { enable = false },
          },
        },
      })

      -- texlab: zathura forward search + chktex on save
      vim.lsp.config("texlab", {
        settings = {
          texlab = {
            build = {
              executable = "latexmk",
              args = { "-pdf", "-synctex=1", "-interaction=nonstopmode", "-file-line-error", "%f" },
              onSave = false,
            },
            forwardSearch = {
              executable = "zathura",
              args = { "--synctex-forward", "%l:1:%f", "%p" },
            },
            chktex = { onOpenAndSave = true, onEdit = false },
          },
        },
      })

      -- asm_lsp: also handle .nasm / .asm extensions
      vim.lsp.config("asm_lsp", {
        filetypes = { "asm", "vmasm", "nasm" },
      })

      -- nil_ls: NOT installed via Mason (its build needs the `nix` binary and
      -- fails to compile on systems without it). Installed instead with
      -- `nix profile install nixpkgs#nil`. Prefer a nil on PATH, else the
      -- per-user nix profile path.
      vim.lsp.config("nil_ls", {
        cmd = { vim.fn.executable("nil") == 1 and "nil" or vim.fn.expand("~/.nix-profile/bin/nil") },
        settings = {
          ["nil"] = {
            formatting = { command = { "nixfmt" } },
          },
        },
      })

      -- clangd: let it query the Nix gcc-wrapper so it inherits libstdc++/glibc
      -- headers plus the -isystem paths Nix injects via NIX_CFLAGS_COMPILE
      -- (glfw, libGL). Requires nvim launched from a dir where direnv has
      -- loaded the nix shell (so NIX_CFLAGS_COMPILE is in clangd's env).
      vim.lsp.config("clangd", {
        cmd = { "clangd", "--query-driver=/nix/store/*/bin/*g++*,/nix/store/*/bin/*gcc*" },
      })

      -- Enable all servers (mason-lspconfig handles the mason-installed ones;
      -- gdscript is enabled manually — it connects to a running Godot on port 6005)
      vim.lsp.enable({
        "pyright", "clangd", "gopls", "bashls",
        "jsonls", "yamlls", "taplo", "lua_ls", "texlab", "asm_lsp",
        "html", "cssls", "ts_ls", "emmet_language_server",
        "nil_ls",
        "gdscript",
      })

      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })
    end,
  },

  -- All LSP servers are installed via Nix (home.packages), so no auto-install needed.
  -- mason-lspconfig is kept only for the :Mason UI.
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      ensure_installed = {},
      automatic_enable = false,
    },
  },
}
