local M = {}

local Entry = require("custom.bases.entry")

local buf = vim.api.nvim_create_buf(false, true)
local project_panel = require("custom.dashboard.panel_project")
local vim_panel = require("custom.dashboard.panel_vim_process")

local function full_screen()
    -- {{"vim_panel", "workspace_panel"}, "project_panel"}
end
local function half_screen()
    -- {{"project_panel", {"vim_panel" || "workspace_panel"}}}
end
local function quarter_screen()
    -- {"project_panel"}
end

local is_setup = false

function M.setup()
    vim_panel.setup()
    is_setup = true
    project_panel.setup()
    vim.api.nvim_create_autocmd("VimEnter", {
        callback = function(data)
            local entry_typ, path = Entry.detect_entry_type()
            if entry_typ == "empty" then
            elseif entry_typ == "dir" and path then
            elseif entry_typ == "file" then

            end
        end
    })
    vim.api.nvim_create_autocmd("VimResized", {
        callback = function(args)
            local cols = vim.o.columns
            local lines = vim.o.lines

            if cols < 85 then
                -- 📱 모바일/초소형 크기 ()
                quarter_screen()
            elseif cols >= 85 and cols < 170 then
                if lines >= 40 then
                    half_screen()
                else
                end
                quarter_screen()
                -- 💻 하프 화면 / 노트북 기본 화면 (코드 창 1개 + 작은 사이드바 가능)
            else
                full_screen()
                -- 🖥️ 데스크탑 전체 화면 (코드 창 2~3개 분할 가능, 모든 UI 요소 오픈)
            end
        end
    })
end

return M
