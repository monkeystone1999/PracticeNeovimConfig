vim.api.nvim_create_user_command("BufOnly", function()
    local current = vim.api.nvim_get_current_buf()

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if buf ~= current
            and vim.api.nvim_buf_is_valid(buf)
            and vim.bo[buf].buflisted
        then
            local ok, err = pcall(vim.api.nvim_buf_delete, buf, {
                force = false,
            })

            if not ok then
                vim.notify(
                    "Buffer deletion failed: " .. tostring(err),
                    vim.log.levels.WARN
                )
            end
        end
    end
end, {
    desc = "Delete all listed buffers except current",
})
