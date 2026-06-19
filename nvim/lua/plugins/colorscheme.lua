local colorscheme = "gruvbox"

return {
  {
    "navarasu/onedark.nvim",
    priority = 1000,
    opts = {
      style = "darker",
    },
    config = function(_, opts)
      require("onedark").setup(opts)
    end,
  },
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = true,
    opts = {
      contrast = "hard",
      transparent_mode = false,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = colorscheme,
    },
  },
}
