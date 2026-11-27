return {
    -- vim.ui.select (LSP 코드 액션 <leader>ca, CMake 타겟/빌드타입 선택 등)를 Telescope 드롭다운으로 통합
    {
        "nvim-telescope/telescope-ui-select.nvim",
        event = "VeryLazy",
        dependencies = {
            "nvim-telescope/telescope.nvim",
        },
        config = function()
            require("telescope").load_extension("ui-select")
        end,
    },
    {
        "nvim-telescope/telescope.nvim",
        opts = function(_, opts)
            opts.extensions = opts.extensions or {}
            opts.extensions["ui-select"] = {
                require("telescope.themes").get_dropdown({}),
            }
        end,
    },
}
