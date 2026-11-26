-- stevearc/conform.nvim : 포매터 통합 (파일 이름은 confirm.lua 이지만 conform.nvim 설정)
-- 포매터 바이너리는 :Mason 에서 설치 (stylua, clang-format, ruff, prettierd/prettier, gersemi)
return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
        {
            "<leader>cf",
            function()
                require("conform").format({ async = true, lsp_format = "fallback" })
            end,
            mode = { "n", "x" },
            desc = "Format buffer / selection (Conform)",
        },
        {
            "<leader>tf",
            function()
                vim.g.disable_autoformat = not vim.g.disable_autoformat
                vim.notify("Format on save: " .. (vim.g.disable_autoformat and "OFF" or "ON"),
                    vim.log.levels.INFO, { title = "Conform" })
            end,
            desc = "Toggle format on save (Conform)",
        },
    },
    ---@module "conform"
    ---@type conform.setupOpts
    opts = {
        formatters_by_ft = {
            lua = { "stylua" },
            c = { "clang-format" },
            cpp = { "clang-format" },
            cmake = { "gersemi" },
            python = { "ruff_organize_imports", "ruff_format" },
            javascript = { "prettierd", "prettier", stop_after_first = true },
            typescript = { "prettierd", "prettier", stop_after_first = true },
            html = { "prettierd", "prettier", stop_after_first = true },
            css = { "prettierd", "prettier", stop_after_first = true },
            json = { "prettierd", "prettier", stop_after_first = true },
            markdown = { "prettierd", "prettier", stop_after_first = true },
            -- 포매터가 지정되지 않은 파일타입: 줄 끝 공백만 제거
            ["_"] = { "trim_whitespace" },
        },
        default_format_opts = {
            lsp_format = "fallback", -- 포매터가 없으면 LSP 포맷 사용 (clangd 등)
        },
        -- 저장 시 자동 포맷 (<leader>tf 로 전역 토글, vim.b.disable_autoformat = true 로 버퍼별 끄기)
        format_on_save = function(bufnr)
            if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                return
            end
            return { timeout_ms = 500 }
        end,
        notify_on_error = true,
    },
    init = function()
        -- gq 연산자가 conform 을 사용하도록 설정
        vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

        -- :FormatDisable[!] / :FormatEnable  (! = 현재 버퍼만)
        vim.api.nvim_create_user_command("FormatDisable", function(args)
            if args.bang then
                vim.b.disable_autoformat = true
            else
                vim.g.disable_autoformat = true
            end
        end, { bang = true, desc = "Disable format on save (! = buffer only)" })
        vim.api.nvim_create_user_command("FormatEnable", function()
            vim.b.disable_autoformat = false
            vim.g.disable_autoformat = false
        end, { desc = "Enable format on save" })
    end,
}
