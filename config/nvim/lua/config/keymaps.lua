local map = vim.keymap.set

-- :Hub [recipe] — run a hub recipe (no argument: the menu) in a split
vim.api.nvim_create_user_command("Hub", function(o)
  vim.cmd("botright split | terminal hub " .. o.args)
  vim.cmd.startinsert()
end, { nargs = "*" })
map("n", "<leader>hh", "<cmd>Hub<cr>", { desc = "Hub menu" })
map("n", "<leader>hs", "<cmd>botright split | terminal pj -s<cr>i", { desc = "Set project status" })
map("n", "<leader>hc", function()
  vim.ui.input({ prompt = "capture> " }, function(text)
    if text and text ~= "" then vim.fn.system({ "cap", text }) end
  end)
end, { desc = "Quick capture" })

-- :Ask <question> — local model (bin/ask) in a split
vim.api.nvim_create_user_command("Ask", function(o)
  vim.cmd("split | terminal ask " .. vim.fn.shellescape(o.args))
end, { nargs = "+" })

-- Window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- File explorer
map("n", "<leader>e", vim.cmd.Ex, { desc = "File explorer" })

-- Better indenting in visual mode
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Move lines
map("n", "<A-j>", ":m .+1<CR>==", { silent = true })
map("n", "<A-k>", ":m .-2<CR>==", { silent = true })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { silent = true })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { silent = true })

-- Diagnostics (no brackets — German keyboard friendly)
map("n", "<leader>dj", function() vim.diagnostic.jump({ count = 1 }) end,  { desc = "Next diagnostic" })
map("n", "<leader>dk", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Prev diagnostic" })
map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Diagnostic float" })

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Buffer navigation
map("n", "<S-h>", ":bprevious<CR>", { silent = true, desc = "Prev buffer" })
map("n", "<S-l>", ":bnext<CR>", { silent = true, desc = "Next buffer" })
