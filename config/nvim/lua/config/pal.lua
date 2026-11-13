-- Follow the system palette (~/.config/pal/current, flipped by `theme`).
return function()
  local f = io.open(vim.fn.expand("~/.config/pal/current/kind"))
  local kind = f and f:read("*l") or "dark"
  if f then f:close() end
  vim.o.background = kind
  vim.cmd.colorscheme(kind == "light" and "catppuccin-latte" or "blackorange")
end
