return {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    config = function()
        local notify = require("notify")

        notify.setup({
            stages = "fade_in_slide_out", -- 애니메이션 효과 (fade, slide, static, compact 중 선택)
            timeout = 3000,               -- 알림이 화면에 머무는 시간 (밀리초 단위)
            render = "wrapped-compact",   -- 텍스트 렌더링 스타일
            max_width = 50,               -- 알림 창의 최대 너비
        })

        -- Neovim 기본 알림(vim.notify)을 nvim-notify로 연결
        vim.notify = notify
    end
}
