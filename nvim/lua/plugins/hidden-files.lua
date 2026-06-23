return {
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>e", "<leader>fE", desc = "Explorer Snacks (cwd)", remap = true },
    },
    opts = {
      picker = {
        sources = {
          files = {
            hidden = true,
            ignored = false,
          },
          grep = {
            hidden = true,
            ignored = false,
          },
          explorer = {
            hidden = true,
            ignored = true,
          },
        },
      },
    },
  },
}
