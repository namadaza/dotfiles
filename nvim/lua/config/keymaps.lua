-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

pcall(vim.keymap.del, "n", "<leader>/")
vim.keymap.set("n", "<leader>fz", LazyVim.pick("live_grep"), { desc = "Grep (Root Dir)" })
