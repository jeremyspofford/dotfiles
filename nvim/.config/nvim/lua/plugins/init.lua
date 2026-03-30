return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash", "dockerfile", "json", "lua", "markdown",
          "python", "terraform", "typescript", "vim", "vimdoc", "yaml",
        },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
}
