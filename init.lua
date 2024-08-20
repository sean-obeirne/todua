local DB = require('sqlite')
local env, conn = DB.init()
DB.create_table(conn)

local M = {}

function M.todua_popup()
    local todo_list = {
        "TODO List:",
        "1. Implement plugin structure",
        "2. Create pop-up window",
        "3. Add todo items dynamically"
    }

    local width = 20
    local height = 8

    local buf = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, todo_list)

    local opts = {
        style = "minimal",
        relative = "editor",
        width = width,
        height = height,
        col = vim.o.columns,
        -- col = 15,
        row = 0,
        border = "double",
    }

    vim.api.nvim_open_win(buf, true, opts)
end

vim.api.nvim_create_user_command('Todua', M.todua_popup, {})

return M
