-- LSP keymaps on attach
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc)
      vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
    end
    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("gD", vim.lsp.buf.declaration, "Go to declaration")
    map("gI", vim.lsp.buf.implementation, "Go to implementation")
    map("gr", vim.lsp.buf.references, "References")
    map("K", vim.lsp.buf.hover, "Hover")
    map("<leader>rn", vim.lsp.buf.rename, "Rename")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
  end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Restore cursor position on file open
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("restore_cursor", { clear = true }),
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Resize splits when window is resized
vim.api.nvim_create_autocmd("VimResized", {
  group = vim.api.nvim_create_augroup("resize_splits", { clear = true }),
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- Macro recording indicator.
-- Macros work fine, but noice swallows the built-in "recording @q" message at
-- the bottom of the screen, so there's no feedback that recording started.
-- Show a persistent notification while recording, dismissed when it stops.
do
  local rec_group = vim.api.nvim_create_augroup("macro_recording", { clear = true })
  local rec_notif
  vim.api.nvim_create_autocmd("RecordingEnter", {
    group = rec_group,
    callback = function()
      rec_notif = vim.notify("Recording @" .. vim.fn.reg_recording(), vim.log.levels.WARN, {
        title = "Macro",
        timeout = false, -- stays up until recording ends
        keep = function() return true end,
      })
    end,
  })
  vim.api.nvim_create_autocmd("RecordingLeave", {
    group = rec_group,
    callback = function()
      local reg = vim.v.event.regname
      vim.notify("Recorded @" .. reg .. "  (replay with @" .. reg .. ")", vim.log.levels.INFO, {
        title = "Macro",
        replace = rec_notif,
        timeout = 1500,
      })
      rec_notif = nil
    end,
  })
end

-- The Farmer Was Replaced: in-game editor needs real tabs, and ruff would
-- convert them to spaces on save (see vim.b.tfwr check in plugins/formatting.lua).
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("tfwr", { clear = true }),
  pattern = "*/TheFarmerWasReplaced/*.py",
  callback = function(ev)
    vim.b[ev.buf].tfwr = true
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})
