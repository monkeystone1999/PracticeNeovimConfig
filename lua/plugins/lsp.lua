
return {
    -- Mason: LSP 서버 바이너리 설치 및 관리
    {
        "mason-org/mason.nvim",
        opts = {
            ui = {
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗",
                },
            },
        },
    },

    -- clangd 확장 기능
    {
        "p00f/clangd_extensions.nvim",
        ft = { "c", "cpp", "objc", "objcpp" },
        opts = {
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
        },
    },

    -- Neovim Native LSP 설정 데이터
    {
        "neovim/nvim-lspconfig",
    },

    -- Mason과 Native LSP 연결
    {
        "mason-org/mason-lspconfig.nvim",
        dependencies = {
            "mason-org/mason.nvim",
            "neovim/nvim-lspconfig",
            "p00f/clangd_extensions.nvim",
            "saghen/blink.cmp",
        },
        config = function()
            local capabilities = require("blink.cmp").get_lsp_capabilities()

            -- 모든 LSP 서버에 Blink completion capabilities 적용
            vim.lsp.config("*", {
                capabilities = capabilities,
            })

            -- Lua Language Server
            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        diagnostics = {
                            globals = { "vim" },
                        },
                        workspace = {
                            checkThirdParty = false,
                        },
                        telemetry = {
                            enable = false,
                        },
                    },
                },
            })

            -- C / C++ Language Server
            vim.lsp.config("clangd", {
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
                capabilities = require("blink.cmp").get_lsp_capabilities({
                    offsetEncoding = { "utf-16" },
                }),
            })

            -- LSP Attach 단축키
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspConfig", {
                    clear = true,
                }),
                callback = function(ev)
                    local opts = {
                        buffer = ev.buf,
                        silent = true,
                    }

                    -- Navigation
                    opts.desc = "Go to definition"
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)

                    opts.desc = "Go to declaration"
                    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

                    opts.desc = "Hover documentation"
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

                    opts.desc = "Go to references"
                    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)

                    -- Refactoring
                    opts.desc = "Rename symbol"
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

                    opts.desc = "Code action"
                    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)

                    -- Diagnostics
                    opts.desc = "Show line diagnostics"
                    vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

                    -- Inlay Hints
                    opts.desc = "Toggle Inlay Hints"
                    vim.keymap.set("n", "<leader>th", function()
                        local enabled = vim.lsp.inlay_hint.is_enabled({
                            bufnr = ev.buf,
                        })

                        vim.lsp.inlay_hint.enable(not enabled, {
                            bufnr = ev.buf,
                        })
                    end, opts)

                    -- clangd-specific mappings
                    local client = vim.lsp.get_client_by_id(ev.data.client_id)

                    if client and client.name == "clangd" then
                        opts.desc = "Switch Source/Header (C/C++)"
                        vim.keymap.set(
                            "n",
                            "<leader>ch",
                            "<cmd>ClangdSwitchSourceHeader<cr>",
                            opts
                        )

                        opts.desc = "Show AST (C/C++)"
                        vim.keymap.set(
                            "n",
                            "<leader>cA",
                            "<cmd>ClangdAST<cr>",
                            opts
                        )

                        opts.desc = "Symbol Info (C/C++)"
                        vim.keymap.set(
                            "n",
                            "<leader>ci",
                            "<cmd>ClangdSymbolInfo<cr>",
                            opts
                        )

                        opts.desc = "Type Hierarchy (C/C++)"
                        vim.keymap.set(
                            "n",
                            "<leader>cth",
                            "<cmd>ClangdTypeHierarchy<cr>",
                            opts
                        )
                    end
                end,
            })

            -- Mason LSP integration
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "lua_ls",
                    "clangd",
                    "neocmake",
                },
                automatic_enable = true,
            })
        end,
    },
}

