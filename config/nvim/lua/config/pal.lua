-- Follow the system palette (~/.config/pal/current, flipped by `theme`).
return function()
  local f = io.open(vim.fn.expand("~/.config/pal/current/name"))
  local name = f and f:read("*l") or "dark"
  if f then f:close() end
  vim.o.background = name == "light" and "light" or "dark"
  vim.cmd.colorscheme(name == "light" and "catppuccin-latte" or "catppuccin-mocha")
end
