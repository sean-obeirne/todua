local M = {}

local DB = require('todua.db')
DB.init()
DB.create_table()
-- print("Table created!")
DB.insert(false, "helloo")
DB.insert(false, "World!")
-- print("insert done")
print(DB.select_all()[0])
-- print("selected")
local todua_popup

local function view_notes(draw_ids)
    local results = DB.select_all()
    local todo_table = {}
    local size = 0
    local longest = 0
    for _, row in pairs(results) do
        local record = "  "
        if draw_ids == true then
            record = record .. row.id .. " "
        end
        record = record .. "[ "
        if row.done == 1 then
            record = record .. "\u{2714}"
        else
            record = record .. "\u{2718}"
        end
        record = record .. " ]   " .. row.note
        longest = math.max(longest, string.len(record))
        table.insert(todo_table, record)
        size = size + 1
    end
    return todo_table, size, longest
end

local function add_note()
    local note = vim.fn.input("Note for new task: ")
    DB.insert(false, note)
    M.todua_popup()
end

local function finish_note()
    -- view_notes(true)
    local note = vim.fn.input("Note to finish: ")
    DB.finish(note)
    M.todua_popup()
end

local function delete_note()
    -- view_notes(true)
    local note = vim.fn.input("Note to delete: ")
    DB.delete(note)
    M.todua_popup()
end


function M.todua_popup()
    -- print(view_notes(false))


    local todo_table, size, longest = view_notes(false)
    local commands = "(a)dd (d)elete (q)uit (f)inish"
    table.insert(todo_table, commands)

    -- M.buf = vim.api.nvim_create_buf(false, true)
    -- If the buffer doesn't exist or is invalid, create a new one
    if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
        M.buf = vim.api.nvim_create_buf(false, true)
    else
        -- If the buffer exists, clear and reuse it
        vim.api.nvim_buf_set_option(M.buf, 'modifiable', true)
        vim.api.nvim_buf_set_option(M.buf, 'readonly', false)
        vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, {})
    end

    vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, todo_table)

    -- Set the buffer as unmodifiable, scratch, and read-only
    vim.api.nvim_buf_set_option(M.buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(M.buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(M.buf, 'readonly', true)

    local opts = {
        style = "minimal",
        relative = "editor",
        width = math.max(math.min(longest, 80), 30),
        height = size + 1,
        col = vim.o.columns,
        -- col = 15,
        row = 0,
        border = "double",
    }

    -- M.win = vim.api.nvim_open_win(M.buf, true, opts)
    -- Check if the window exists
    if M.win and vim.api.nvim_win_is_valid(M.win) then
        -- If the window exists, update its configuration (resize if needed)
        vim.api.nvim_win_set_config(M.win, opts)
    else
        -- If the window doesn't exist, create a new one
        M.win = vim.api.nvim_open_win(M.buf, true, opts)
    end

    vim.api.nvim_buf_set_keymap(M.buf, 'n', 'q', ':q<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(M.buf, 'n', 'a', '', { noremap = true, silent = true,
        callback = add_note
    })
    vim.api.nvim_buf_set_keymap(M.buf, 'n', 'f', '', { noremap = true, silent = true,
        callback = finish_note
    })
    vim.api.nvim_buf_set_keymap(M.buf, 'n', 'd', '', { noremap = true, silent = true,
        callback = delete_note
    })
end

vim.api.nvim_create_user_command('Todua', M.todua_popup, {})

return M
