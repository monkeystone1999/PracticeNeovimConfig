return {
    {
        "obsidian-nvim/obsidian.nvim",
        version = "*", -- use latest release, remove to use latest commit
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
            "MeanderingProgrammer/render-markdown.nvim",
        },
        ---@module 'obsidian'
        ---@type obsidian.config
        opts = function()
            local workspace = require("custom.bases.workspace")
            return {
                legacy_commands = false, -- this will be removed in 4.0.0
                -- render-markdown.nvim 과 마크다운 UI 렌더링이 중복/충돌하지 않도록 내장 UI 비활성화
                ui = {
                    enable = false,
                },
                -- 워크스페이스 루트(README.md 포함)를 볼트로 사용하되, 새 노트는 하위 docs/ 폴더에 생성
                notes_subdir = "docs",
                new_notes_location = "notes_subdir",
                -- custom.bases.workspace 에 등록된 모든 워크스페이스를 자동으로 Obsidian 볼트로 등록
                workspaces = workspace.get_obsidian_workspaces(),
                picker = {
                    name = "telescope.nvim",
                },
            }
        end,
        config = function(_, opts)
            local obsidian = require("obsidian")
            local workspace = require("custom.bases.workspace")

            obsidian.setup(opts)

            -- 런타임 중 워크스페이스가 추가/변경되거나 :WorkspaceInitDocs 실행 시 Obsidian에 즉시 재반영
            workspace.set_obsidian_sync_callback(function()
                opts.workspaces = workspace.get_obsidian_workspaces()
                obsidian.setup(opts)
            end)
        end,
    },
    {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown" },
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons",
        },
        ---@module 'render-markdown'
        ---@type render.md.UserConfig
        opts = {},
    },
}
