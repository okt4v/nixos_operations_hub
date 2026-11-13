local themes = {
  "blackorange",
  "catppuccin", "catppuccin-mocha", "catppuccin-latte", "catppuccin-frappe", "catppuccin-macchiato",
  "kanagawa", "kanagawa-wave", "kanagawa-dragon", "kanagawa-lotus",
  "tokyonight", "tokyonight-night", "tokyonight-storm", "tokyonight-day",
  "gruvbox",
}

return {
  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    keys = {
      { "<leader>ff", function() require("fzf-lua").files() end,                desc = "Find files" },
      { "<leader>fg", function() require("fzf-lua").live_grep() end,            desc = "Live grep" },
      { "<leader>fb", function() require("fzf-lua").buffers() end,              desc = "Buffers" },
      { "<leader>fr", function() require("fzf-lua").oldfiles() end,             desc = "Recent files" },
      { "<leader>fs", function() require("fzf-lua").lsp_document_symbols() end, desc = "LSP symbols" },
      { "<leader>fw", function() require("fzf-lua").lsp_workspace_symbols() end, desc = "Workspace symbols" },
      { "<leader>fd", function() require("fzf-lua").diagnostics_document() end, desc = "Document diagnostics" },
      {
        "<leader>th",
        function()
          require("fzf-lua").fzf_exec(themes, {
            prompt = "Theme> ",
            actions = {
              ["default"] = function(selected)
                if selected[1] then
                  vim.cmd("colorscheme " .. selected[1])
                end
              end,
            },
          })
        end,
        desc = "Pick theme",
      },
    },
    opts = {
      winopts = {
        height = 0.85,
        width = 0.80,
      },
    },
  },
}
