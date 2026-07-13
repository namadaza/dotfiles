return {
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        always_show_bufferline = true,
        truncate_names = false,
        custom_filter = function(bufnr)
          return bufnr == vim.api.nvim_get_current_buf()
        end,
        name_formatter = function(buf)
          if buf.path == "" then
            return "[No Name]"
          end

          local relative = vim.fn.fnamemodify(buf.path, ":.")
          return relative ~= "" and relative or buf.path
        end,
      },
    },
  },
}
