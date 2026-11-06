return {
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup({
                ui = {
                    icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "✗",
                    },
                },
            })
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
            "williamboman/mason.nvim",
            "neovim/nvim-lspconfig",
        },
        config = function()
            local lspconfig = require("lspconfig")
            local mason_lspconfig = require("mason-lspconfig")

            -- 1. LSP 연결 시 단축키 설정
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspConfig", {}),
                callback = function(ev)
                    local opts = { buffer = ev.buf, silent = true }

                    opts.desc = "Go to definition"
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)

                    opts.desc = "Hover documentation"
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

                    opts.desc = "Rename symbol"
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

                    opts.desc = "Code action"
                    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)

                    opts.desc = "Go to references"
                    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)

                    opts.desc = "Show line diagnostics"
                    vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
                end,
            })

            -- 2. mason-lspconfig setup (handlers 옵션으로 통합)
            mason_lspconfig.setup({
                ensure_installed = { "lua_ls" },
                automatic_installation = true,
                handlers = {
                    -- 기본 핸들러: 설치된 일반 LSP 서버 적용
                    function(server_name)
                        lspconfig[server_name].setup({})
                    end,

                    -- lua_ls 전용 커스텀 옵션
                    ["lua_ls"] = function()
                        lspconfig.lua_ls.setup({
                            settings = {
                                Lua = {
                                    diagnostics = {
                                        globals = { "vim" },
                                    },
                                    workspace = {
                                        library = vim.api.nvim_get_runtime_file("", true),
                                        checkThirdParty = false,
                                    },
                                    telemetry = { enable = false },
                                },
                            },
                        })
                    end,
                },
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
    },
}
