-- Minimal Neovim config built around mini.nvim.
-- Single-file by design: edit this, run scripts/nvim-update-config.sh.

-- Leader must be set before any plugin maps it.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Plugins: cloned into pack/deps/start/ on first launch.
local function ensure_plugin(url, branch)
    local name = url:match('([^/]+)$'):gsub('%.git$', '')
    local path = vim.fn.stdpath('data') .. '/site/pack/deps/start/' .. name
    if (vim.uv or vim.loop).fs_stat(path) then return false end
    vim.notify('Installing ' .. name .. '...')
    local cmd = { 'git', 'clone', '--filter=blob:none' }
    if branch then vim.list_extend(cmd, { '--branch', branch }) end
    vim.list_extend(cmd, { url, path })
    vim.fn.system(cmd)
    vim.cmd('packadd ' .. name)
    return true
end

local installed_any = false
installed_any = ensure_plugin('https://github.com/nvim-mini/mini.nvim') or installed_any
installed_any = ensure_plugin('https://github.com/nvim-lua/plenary.nvim') or installed_any
installed_any = ensure_plugin('https://github.com/ThePrimeagen/harpoon', 'harpoon2') or installed_any
if installed_any then vim.cmd('helptags ALL') end

-- Sensible defaults: numbers, mouse, undofile, search behavior, window nav.
require('mini.basics').setup({
    options = { extra_ui = true },
    mappings = { windows = true },
})

require('mini.icons').setup()

-- Picker. Needs ripgrep on PATH for grep_live.
require('mini.pick').setup({
    mappings = {
        -- <C-v> pastes the system clipboard into the prompt (mini.pick blocks terminal paste by default).
        paste_clip = {
            char = '<C-v>',
            func = function()
                local q = MiniPick.get_picker_query() or {}
                for c in vim.fn.getreg('+'):gmatch('.') do table.insert(q, c) end
                MiniPick.set_picker_query(q)
            end,
        },
    },
})
vim.keymap.set('n', '<leader>ff', '<cmd>Pick files<cr>', { desc = 'Find files' })
vim.keymap.set('n', '<leader>fg', '<cmd>Pick grep_live<cr>', { desc = 'Live grep' })
vim.keymap.set('n', '<leader>fb', '<cmd>Pick buffers<cr>', { desc = 'Buffers' })
vim.keymap.set('n', '<leader>fh', '<cmd>Pick help<cr>', { desc = 'Help tags' })
vim.keymap.set('n', '<leader>fr', '<cmd>Pick resume<cr>', { desc = 'Resume picker' })

-- File explorer (buffer-based; opens at current file's dir).
require('mini.files').setup()
vim.keymap.set('n', '<leader>e', function()
    require('mini.files').open(vim.api.nvim_buf_get_name(0))
end, { desc = 'File explorer' })

-- Harpoon: pin files and jump to them by slot.
local harpoon = require('harpoon')
harpoon:setup()
vim.keymap.set('n', '<leader>a', function() harpoon:list():add() end, { desc = 'Harpoon add file' })
vim.keymap.set('n', '<leader>x', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Harpoon menu' })
vim.keymap.set('n', '<leader>1', function() harpoon:list():select(1) end, { desc = 'Harpoon file 1' })
vim.keymap.set('n', '<leader>2', function() harpoon:list():select(2) end, { desc = 'Harpoon file 2' })
vim.keymap.set('n', '<leader>3', function() harpoon:list():select(3) end, { desc = 'Harpoon file 3' })
vim.keymap.set('n', '<leader>4', function() harpoon:list():select(4) end, { desc = 'Harpoon file 4' })

require('mini.statusline').setup()

-- Text-editing niceties.
require('mini.surround').setup() -- sa/sd/sr/sf surround add/delete/replace/find
require('mini.pairs').setup()    -- auto-close brackets and quotes
require('mini.comment').setup()  -- gcc line, gc<motion> region
require('mini.ai').setup()       -- richer text objects: va) vi" etc.

require('mini.notify').setup()
vim.notify = require('mini.notify').make_notify()

-- Popup that shows available next keys mid-sequence (press <leader> to see it).
local miniclue = require('mini.clue')
miniclue.setup({
    triggers = {
        { mode = 'n', keys = '<Leader>' },
        { mode = 'x', keys = '<Leader>' },
        { mode = 'n', keys = 'g' },
        { mode = 'x', keys = 'g' },
        { mode = 'n', keys = "'" },
        { mode = 'n', keys = '`' },
        { mode = 'n', keys = '"' },
        { mode = 'i', keys = '<C-r>' },
        { mode = 'n', keys = '<C-w>' },
        { mode = 'n', keys = 'z' },
        { mode = 'x', keys = 'z' },
    },
    clues = {
        { mode = 'n', keys = '<Leader>f', desc = '+Find' },
        miniclue.gen_clues.g(),
        miniclue.gen_clues.marks(),
        miniclue.gen_clues.registers(),
        miniclue.gen_clues.windows(),
        miniclue.gen_clues.z(),
    },
    window = { delay = 300 },
})

vim.cmd.colorscheme('randomhue')

-- Indentation defaults (mini.basics doesn't touch these).
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.softtabstop = 2

-- Line numbers: absolute on current line, relative elsewhere.
vim.o.number = true
vim.o.relativenumber = true

-- Scrolloff keeps the cursor away from the screen edge.
vim.o.scrolloff = 4

-- Persist the signcolumn so text doesn't shift when diagnostics appear later.
vim.o.signcolumn = 'yes'

-- Sync yanks with the system clipboard (y/d/p use Cmd+C/V's buffer).
vim.o.clipboard = 'unnamedplus'

-- Ignore term256 colors for SSH
vim.opt.termguicolors = true
