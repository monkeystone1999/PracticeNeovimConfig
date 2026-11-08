local M = {}

local Entry = require("custom.bases.entry")

local buf = vim.api.nvim_create_buf(false, true)

local function Layout()

end

function M.setup()
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

            if cols < 85 then
                -- 📱 모바일/초소형 크기 (좌우 분할 불가, 탐색기 등 사이드바 모두 숨겨야 함)
                setup_compact_ui()
            elseif cols >= 85 and cols < 170 then
                -- 💻 하프 화면 / 노트북 기본 화면 (코드 창 1개 + 작은 사이드바 가능)
                setup_standard_ui()
            else
                -- 🖥️ 데스크탑 전체 화면 (코드 창 2~3개 분할 가능, 모든 UI 요소 오픈)
                setup_wide_ui()
            end
        end
    })
end

return M

-- FHD 전체화면 Row : 210, Columns = 51
-- Half 좌우 Row : 105 , Columns = 51
