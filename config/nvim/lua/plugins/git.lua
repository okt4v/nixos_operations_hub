return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add          = { text = "│" },
        change       = { text = "│" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "~" },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local map = function(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end
        -- j/k instead of ]/[ — German keyboard friendly
        map("n", "<leader>hj", gs.next_hunk,                                    "Next hunk")
        map("n", "<leader>hk", gs.prev_hunk,                                    "Prev hunk")
        map("n", "<leader>hs", gs.stage_hunk,                                   "Stage hunk")
        map("n", "<leader>hr", gs.reset_hunk,                                   "Reset hunk")
        map("n", "<leader>hp", gs.preview_hunk,                                 "Preview hunk")
        map("n", "<leader>hb", function() gs.blame_line({ full = true }) end,   "Blame line")
        map("n", "<leader>hd", gs.diffthis,                                     "Diff this")
      end,
    },
  },

  -- Full diff viewer and file history browser
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>",          desc = "Diff view (branch)" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>",         desc = "Close diff view" },
    },
    opts = {},
  },
}
