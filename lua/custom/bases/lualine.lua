local M = {}

-- 1) 현재 활성 Workspace 이름 (없으면 현재 작업 폴더명) 표시 컴포넌트
local function workspace_component()
    local ok, ws = pcall(require, "custom.bases.workspace")
    if ok and ws.current_workspace and ws.current_workspace ~= "" then
        return "󰉋 WS: " .. ws.current_workspace
    end
    local cwd = vim.fn.fnamemodify(vim.fn.getcwd(0), ":t")
    return "󰉋 " .. (cwd ~= "" and cwd or "root")
end

-- 2) 매크로 녹화 상태 표시 컴포넌트 (cmdheight = 0 환경에서 매우 유용)
local function macro_recording()
    local reg = vim.fn.reg_recording()
    if reg == "" then
        return ""
    end
    return "󰑋 Rec @" .. reg
end

-- 3) 현재 버퍼에 연결된 활성 LSP 서버 목록 표시 컴포넌트
local function lsp_clients()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if not clients or #clients == 0 then
        return "󰅚 No LSP"
    end
    local names = {}
    for _, client in ipairs(clients) do
        table.insert(names, client.name)
    end
    return "󰒋 " .. table.concat(names, ", ")
end

function M.get_opts()
    return {
        options = {
            theme = "horizon",
            globalstatus = true,
            disabled_filetypes = {
                statusline = {},
            },
        },
        sections = {
            lualine_a = { "mode" },
            lualine_b = { "branch", "diff", "diagnostics" },
            -- dropbar.nvim과 중복되는 기본 "filename"을 제거하고 유용한 상태 정보 배치
            lualine_c = {
                { workspace_component, color = { gui = "bold" } },
                { macro_recording, color = { fg = "#ff9e64", gui = "bold" } },
                "searchcount",
            },
            lualine_x = {
                { lsp_clients },
                "filesize",
                "encoding",
                "fileformat",
                "filetype",
            },
            lualine_y = { "progress" },
            lualine_z = { "location" },
        },
        inactive_sections = {
            lualine_a = {},
            lualine_b = {},
            lualine_c = { workspace_component },
            lualine_x = { "location" },
            lualine_y = {},
            lualine_z = {},
        },
    }
end

function M.setup()
    local ok, lualine = pcall(require, "lualine")
    if ok then
        lualine.setup(M.get_opts())
    end

    -- 매크로 녹화 시작/종료 시 상태바 즉시 갱신
    vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
        callback = function()
            local loaded, ll = pcall(require, "lualine")
            if loaded then
                ll.refresh()
            end
        end,
    })
end

return M
