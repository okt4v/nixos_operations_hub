return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    ft = { "markdown" },
    -- Downloads a prebuilt server binary instead of running `npm install`.
    -- npm regenerated app/yarn.lock on every build, leaving the plugin repo
    -- dirty and blocking lazy.nvim from updating it.
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown preview" },
    },
    init = function()
      vim.g.mkdp_auto_close = 1      -- close browser tab when leaving the buffer
      vim.g.mkdp_browser = ""        -- use system default browser
    end,
  },
}
