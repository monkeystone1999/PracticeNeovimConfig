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
        "p00f/clangd_extensions.nvim",
        lazy = true,
        config = function()
            require("clangd_extensions").setup({
                ast = {
                    role_icons = {
                        type = "",
                        declaration = "",
                        expression = "",
                        specifier = "",
                        statement = "",
                        ["template argument"] = "",
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
            "p00f/clangd_extensions.nvim",
        },
        config = function()
            local lspconfig = require("lspconfig")
            local mason_lspconfig = require("mason-lspconfig")

            -- 1. LSP 연결 시 공통 및 언어별 단축키 설정
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
                callback = function(ev)
                    local opts = { buffer = ev.buf, silent = true }

                    opts.desc = "Go to definition"
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)

                    opts.desc = "Go to declaration"
                    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

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

                    -- Inlay Hints 토글 (Neovim 0.10+)
                    if vim.lsp.inlay_hint then
                        opts.desc = "Toggle Inlay Hints"
                        vim.keymap.set("n", "<leader>th", function()
                            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
                        end, opts)
                    end

                    -- clangd 연결 시 C/C++ 전용 단축키 바인딩
                    local client = vim.lsp.get_client_by_id(ev.data.client_id)
                    if client and client.name == "clangd" then
                        pcall(require, "clangd_extensions")

                        opts.desc = "Switch Source/Header (C/C++)"
                        vim.keymap.set("n", "<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", opts)

                        opts.desc = "Show AST (C/C++)"
                        vim.keymap.set("n", "<leader>cA", "<cmd>ClangdAST<cr>", opts)

                        opts.desc = "Symbol Info (C/C++)"
                        vim.keymap.set("n", "<leader>ci", "<cmd>ClangdSymbolInfo<cr>", opts)

                        opts.desc = "Type Hierarchy (C/C++)"
                        vim.keymap.set("n", "<leader>cth", "<cmd>ClangdTypeHierarchy<cr>", opts)
                    end
                end,
            })

            -- 2. mason-lspconfig setup (lua_ls, clangd, neocmake 자동 설치 및 핸들러 등록)
            mason_lspconfig.setup({
                ensure_installed = {
                    "lua_ls",
                    "clangd",
                    "neocmake",
                },
                automatic_installation = true,
                handlers = {
                    -- 기본 핸들러: 설치된 일반 LSP 서버(neocmake 등) 자동 적용
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
                                        checkThirdParty = false,
                                    },
                                    telemetry = { enable = false },
                                },
                            },
                        })
                    end,

                    -- clangd 전용 C/C++ 커스텀 옵션
                    ["clangd"] = function()
                        lspconfig.clangd.setup({
                            cmd = {
                                "clangd",
                                "--background-index",
                                "--clang-tidy",
                                "--header-insertion=iwyu",
                                "--completion-style=detailed",
                                "--function-arg-placeholders",
                                "--fallback-style=llvm",
                            },
                            init_options = {
                                usePlaceholders = true,
                                completeUnimported = true,
                                clangdFileStatus = true,
                            },
                            capabilities = {
                                offsetEncoding = { "utf-16" },
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
