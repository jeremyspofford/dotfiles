-- Workbench baseline: no plugin downloads or client-specific configuration.
vim.opt.number = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true
vim.g.mapleader = " "
vim.opt.signcolumn = "yes"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.undofile = true
vim.opt.updatetime = 250
vim.opt.cursorline = true
vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 8
vim.opt.wildmode = "longest:full,full"
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.inccommand = "split"
vim.cmd.colorscheme("habamax")
vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
vim.keymap.set("n", "<leader>e", "<cmd>Explore<cr>", { desc = "Browse files" })
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { desc = "Copy to system clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>p", '"+p', { desc = "Paste from system clipboard" })
for _, direction in ipairs({ "h", "j", "k", "l" }) do
  vim.keymap.set("n", "<C-" .. direction .. ">", "<C-w>" .. direction, { desc = "Move between splits" })
end
