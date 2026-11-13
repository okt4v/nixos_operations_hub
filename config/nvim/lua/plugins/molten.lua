return {
  {
    "3rd/image.nvim",
    lazy = true,
    opts = {
      backend = "kitty",
      max_width = 100,
      max_height = 20,
      max_height_window_percentage = math.huge,
      max_width_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
    },
  },
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    build = ":UpdateRemotePlugins",
    dependencies = { "3rd/image.nvim" },
    init = function()
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_auto_open_output = true
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = true
    end,
    keys = {
      { "<leader>mi", ":MoltenInit<CR>",                               desc = "Init kernel" },
      { "<leader>ml", ":MoltenEvaluateLine<CR>",                       desc = "Evaluate line" },
      { "<leader>mr", ":MoltenReevaluateCell<CR>",                     desc = "Re-evaluate cell" },
      { "<leader>mo", ":MoltenShowOutput<CR>",                         desc = "Show output" },
      { "<leader>mh", ":MoltenHideOutput<CR>",                         desc = "Hide output" },
      { "<leader>md", ":MoltenDelete<CR>",                             desc = "Delete cell" },
      { "<leader>mv", ":<C-u>MoltenEvaluateVisual<CR>gv", mode = "v", desc = "Evaluate visual" },
    },
  },
}
