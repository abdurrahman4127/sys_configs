-- lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end

vim.opt.rtp:prepend(lazypath)

-- editor stuff
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.statuscolumn = "%=%{v:relnum ? v:relnum : v:lnum}  "
vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })

vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 5

vim.opt.mouse = "a"

-- cursor
vim.opt.guicursor = "n-v-c:block,i:ver25,r:hor20"

-- indentation
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.smarttab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

-- search
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.scrolloff = 5

-- don't leave junk files everywhere
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- shortcuts
vim.keymap.set("n", "<C-s>", "<cmd>write<CR>", { silent = true })
vim.keymap.set("n", "<C-f>", "/", { silent = false })
vim.keymap.set("n", "<C-q>", "<cmd>confirm qall<CR>", { silent = true })

-- undo/redo
vim.keymap.set("n", "<C-z>", "u", { silent = true })
vim.keymap.set("n", "<C-y>", "<C-r>", { silent = true })

-- move between panes
vim.keymap.set("n", "<C-h>", "<C-w>h", { silent = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { silent = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { silent = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { silent = true })


-- plugins
require("lazy").setup({

    "nvim-tree/nvim-web-devicons",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",

    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",

        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons",
        },

        config = function()
            require("neo-tree").setup({
                filesystem = {
                    follow_current_file = {
                        enabled = true,
                    },
                    hijack_netrw_behavior = "open_default",
                },

                window = {
                    position = "left",
                    width = 32,
                },
            })

            vim.keymap.set(
                "n",
                "<C-n>",
                "<cmd>Neotree toggle left<CR>",
                { silent = true }
            )
        end,
    },
})
