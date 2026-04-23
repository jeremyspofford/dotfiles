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
    -- nvim-treesitter v1.0 (the `main` branch) removed the `configs` module
    -- and changed the entire setup API. Pin to the `master` branch which
    -- still ships the legacy `require("nvim-treesitter.configs").setup{}`
    -- API. When you're ready to migrate to the new API, switch to `main`
    -- and rewrite the config.
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
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
