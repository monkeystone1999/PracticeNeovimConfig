return {
    'Bekaboo/dropbar.nvim',
    -- 이미 Telescope 쪽에서 fzf-native를 설치하므로 의존성 선언을 생략해도 동작하지만,
    -- 명시적으로 적어두는 것도 좋습니다.
    dependencies = {
        'nvim-telescope/telescope-fzf-native.nvim'
    },
    config = function()
        local dropbar_api = require('dropbar.api')
        vim.keymap.set('n', '<Leader>;', dropbar_api.pick, { desc = 'Pick symbols in winbar' })
        vim.keymap.set('n', '[;', dropbar_api.goto_context_start, { desc = 'Go to start of current context' })
        vim.keymap.set('n', '];', dropbar_api.select_next_context, { desc = 'Select next context' })
    end
}
