-- File explorer for neovim. Uses neo-tree.nvim with eager loading.
--
-- Why eager (lazy = false)?
-- The keys-based lazy-load was unreliable in this config — if anything in
-- the plugin discovery chain hiccups, the keys never get registered and
-- the explorer is silently broken with no error to grep for. Eager load
-- costs ~5ms at startup and means `:Neotree` is always available the
-- moment nvim is ready.
return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  lazy = false,
  priority = 100,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  -- Defining keys here still works, but with lazy = false the binding
  -- is registered at startup regardless of whether neo-tree's lazy-load
  -- triggers fire.
  keys = {
    { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "File explorer" },
    { "<leader>E", "<cmd>Neotree reveal<CR>", desc = "Reveal current file" },
  },
  cmd = { "Neotree" },
  opts = {
    filesystem = {
      follow_current_file = { enabled = true },
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
    window = {
      width = 35,
    },
  },
}
