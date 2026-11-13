return {
  {
    "gbprod/yanky.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
    keys = {
      { "p",     "<Plug>(YankyPutAfter)",         mode = { "n", "x" }, desc = "Put after" },
      { "P",     "<Plug>(YankyPutBefore)",         mode = { "n", "x" }, desc = "Put before" },
      { "gp",    "<Plug>(YankyGPutAfter)",         mode = { "n", "x" }, desc = "GPut after" },
      { "gP",    "<Plug>(YankyGPutBefore)",        mode = { "n", "x" }, desc = "GPut before" },
      { "<C-p>", "<Plug>(YankyCycleForward)",                            desc = "Cycle yank forward" },
      { "<C-n>", "<Plug>(YankyCycleBackward)",                           desc = "Cycle yank backward" },
    },
  },
}
