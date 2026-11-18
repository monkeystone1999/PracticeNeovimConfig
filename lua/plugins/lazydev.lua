
return {
    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = {
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        },
    },

    {
        "saghen/blink.cmp",
        version = "1.*",
        dependencies = {
            "saghen/blink.lib",
        },
        build = function()
            require("blink.cmp").build():pwait()
        end,
        opts = {
            keymap = {
                preset = "none",

                -- Completion / Snippet navigation
                ["<Tab>"] = {
                    "select_next",
                    "snippet_forward",
                    "fallback",
                },

                ["<S-Tab>"] = {
                    "select_prev",
                    "snippet_backward",
                    "fallback",
                },

                -- Accept completion
                ["<CR>"] = {
                    "accept",
                    "fallback",
                },

                -- Completion menu
                ["<C-Space>"] = {
                    "show",
                    "show_documentation",
                    "hide_documentation",
                },

                ["<C-e>"] = {
                    "hide",
                    "fallback",
                },

                -- Navigation
                ["<Up>"] = {
                    "select_prev",
                    "fallback",
                },

                ["<Down>"] = {
                    "select_next",
                    "fallback",
                },

                ["<C-p>"] = {
                    "select_prev",
                    "fallback_to_mappings",
                },

                ["<C-n>"] = {
                    "select_next",
                    "fallback_to_mappings",
                },

                -- Signature help
                ["<C-k>"] = {
                    "show_signature",
                    "hide_signature",
                    "fallback",
                },
            },

            completion = {
                list = {
                    selection = {
                        preselect = false,
                    },
                },
            },

            sources = {
                default = {
                    "lazydev",
                    "lsp",
                    "path",
                    "snippets",
                    "buffer",
                },
                providers = {
                    lazydev = {
                        name = "LazyDev",
                        module = "lazydev.integrations.blink",
                        score_offset = 100,
                    },
                },
            },
        },
    },
}

