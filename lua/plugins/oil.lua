return {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
        default_file_explorer = true,
        float = {
            padding = 2,
            max_width = 90,
            max_height = 30,
            border = "rounded",
            win_options = {
                winblend = 0,
            },
        },
        columns = { "icon" },
        keymaps = {
            ["g?"] = "actions.show_help",
            ["<CR>"] = "actions.select",
            ["<C-s>"] = "actions.select_vsplit",
            ["<C-h>"] = "actions.select_split",
            ["<C-t>"] = "actions.select_tab",
            ["<C-p>"] = "actions.preview",
            ["<C-c>"] = "actions.close",
            ["<C-l>"] = "actions.refresh",
            ["-"] = "actions.parent",
            ["_"] = "actions.open_cwd",
            ["`"] = "actions.cd",
            ["~"] = "actions.tcd",
            ["g."] = "actions.toggle_hidden",
        },
        view_options = {
            show_hidden = true,
        }
    },
    keys = {
        { "<leader>e", "<cmd>lua require('oil').open_float()<cr>", desc = "Open parent directory with Oil" }
    }
}
