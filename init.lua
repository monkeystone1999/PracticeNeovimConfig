-- Windows 환경에서 Neovide/Neovim 실행 시 MSVC 환경 변수 자동 주입
if vim.fn.has("win32") == 1 then
    -- vswhere를 이용해 비주얼 스튜디오 설치 경로 탐색
    local vswhere = '"' .. os.getenv("ProgramFiles(x86)") .. '\\Microsoft Visual Studio\\Installer\\vswhere.exe"'
    local handle = io.popen(vswhere .. ' -latest -property installationPath')
    if handle then
        local vs_path = handle:read("*l")
        handle:close()

        if vs_path and vs_path ~= "" then
            local vcvars_path = vs_path .. '\\VC\\Auxiliary\\Build\\vcvars64.bat'
            -- 배치 파일을 실행해 환경 변수 목록(set)을 추출한 뒤 Neovim 환경 변수(vim.env)에 주입
            local cmd = string.format('cmd.exe /c "%s" && set', vcvars_path)
            local env_handle = io.popen(cmd)
            if env_handle then
                for line in env_handle:lines() do
                    local key, val = string.match(line, "^([^=]+)=(.*)$")
                    if key and val then
                        vim.env[key] = val
                    end
                end
                env_handle:close()
            end
        end
    end
end

if vim.g.vscode then
else
    require("configs.options")
    require("custom.base_setup").setup()
    -- Bootstrap lazy.nvim
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not (vim.uv or vim.loop).fs_stat(lazypath) then
        local lazyrepo = "https://github.com/folke/lazy.nvim.git"
        local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
        if vim.v.shell_error ~= 0 then
            vim.api.nvim_echo({
                { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
                { out,                            "WarningMsg" },
                { "\nPress any key to exit..." },
            }, true, {})
            vim.fn.getchar()
            os.exit(1)
        end
    end
    vim.opt.rtp:prepend(lazypath)

    -- Make sure to setup `mapleader` and `maplocalleader` before
    -- loading lazy.nvim so that mappings are correct.
    -- This is also a good place to setup other settings (vim.opt)
    vim.g.mapleader = " "
    vim.g.maplocalleader = "\\"

    -- Setup lazy.nvim
    require("lazy").setup({
        rocks = { enabled = false },
        spec = {

            -- import your plugins
            { import = "plugins" },
        },
        -- Configure any other settings here. See the documentation for more details.
        -- colorscheme that will be used when installing plugins.
        install = { colorscheme = { "habamax" } },
        -- automatically check for plugin updates
        checker = { enabled = true },
    })
    require("custom.workspace.workspace_buffer").setup()
    -- require("custom.netrw").setup()
end
