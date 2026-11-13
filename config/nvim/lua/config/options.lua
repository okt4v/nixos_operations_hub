-- Pin to the nix-managed Python that has pynvim, so project venvs on PATH do not shadow it
vim.g.python3_host_prog = "/etc/profiles/per-user/oktav/bin/python3"

local opt = vim.opt

opt.number = true
opt.relativenumber = true

opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true

-- vim-sleuth auto-detects indent width per file; force 4 spaces for C/C++
-- regardless of what's already in the file, to match the clang-format width.
vim.g.sleuth_c_heuristics = 0
vim.g.sleuth_cpp_heuristics = 0

opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false

opt.termguicolors = true
opt.signcolumn = "yes"
opt.wrap = false
opt.scrolloff = 999
opt.cursorline = true

opt.undofile = true
opt.swapfile = false
opt.backup = false

opt.splitright = true
opt.splitbelow = true

opt.updatetime = 250
opt.timeoutlen = 300
opt.mouse = "a"
opt.clipboard = "unnamedplus"

vim.filetype.add({
  extension = {
    gd = "gdscript",
    gdscript3 = "gdscript",
    asm = "nasm",
    nasm = "nasm",
  },
  filename = {
    [".bashrc"] = "bash",
    [".zshrc"] = "bash",
    [".profile"] = "bash",
    [".bash_profile"] = "bash",
    [".bash_aliases"] = "bash",
    [".env"] = "bash",
    ["gitconfig"] = "gitconfig",
    [".gitconfig"] = "gitconfig",
    [".gitignore"] = "gitignore",
    [".gitattributes"] = "gitattributes",
  },
  pattern = {
    ["%.env%..*"] = "bash",
    [".*%.ignore"] = "gitignore",
  },
})
