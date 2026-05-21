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
    -- Pin nvim-treesitter to the known-good commit that still exposes
    -- require("nvim-treesitter.configs").setup(...). A newer checkout on this
    -- mini-pc drifted forward and removed that module, which breaks startup.
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    commit = "cf12346a3414fa1b06af75c79faebe7f76df080a",
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
