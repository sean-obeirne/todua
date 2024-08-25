local M = {}
local DB = require('todua.db')

function M.init()
    DB.init()
    DB.create_table()
end

local function view_notes(draw_ids)
    local results = DB.select_all()
    table.sort(results, function(a, b)
        return a.order_index < b.order_index
        end)
    local todo_table = {}
    local size = 0
    local longest = 0
    for _, row in pairs(results) do
        local record = ""
        local is_header = row.note == string.upper(row.note)
        if not is_header then
            record = "  "
        end
        if draw_ids == true then
            record = record .. row.id .. " "
        end
        if not is_header then
            record = record .. "[ "
            if row.done == 1 then
                record = record .. "\u{2714}"
            else
                record = record .. "\u{2718}"
            end
            record = record .. " ]   "
        end
        record = record .. row.note
        -- record = record .. " " .. row.order_index
        longest = math.max(longest, string.len(record))
        table.insert(todo_table, record)
        size = size + 1
    end
    return todo_table, size, longest
end

local function add_note()
    local note = vim.fn.input("Note for new task: ")
    if #note > 0 then
        DB.insert(false, note)
    end
    M.todua_popup()
end

local function unfinish_note()
    M.todua_popup(true)
    vim.cmd('redraw')
    local note = vim.fn.input("Note to unfinish: ")
    if #note > 0 then
        DB.unfinish(note)
    end
    M.todua_popup(false)
end

local function finish_note()
    M.todua_popup(true)
    vim.cmd('redraw')
    local note = vim.fn.input("Note to finish: ")
    if #note > 0 then
        DB.finish(note)
    end
    M.todua_popup(false)
end

local function delete_note()
    M.todua_popup(true)
    vim.cmd('redraw')
    local note = vim.fn.input("Note to delete: ")
    if #note > 0 then
        DB.delete(note)
    end
    M.todua_popup(false)
end

local function quit()
    DB.close()
    vim.api.nvim_win_close(0, true)
end

local function move_up()
    M.todua_popup(true)
    vim.cmd('redraw')
    local note = vim.fn.input("Note to move up: ")
    if #note > 0 then
        local loops = vim.fn.input("Up how many spots?: ")
        for j = 1, loops do
            DB.move_up(note)
        end
        -- if vim.fn.line('.') > 1 and vim.fn.line('.') ~= vim.fn.line('$') then
        -- end
    end
    M.todua_popup(false)
end
local function move_down()
    M.todua_popup(true)
    vim.cmd('redraw')
    local note = vim.fn.input("Note to move down: ")
    if #note > 0 then
        local loops = vim.fn.input("Down how many spots?: ")
        for j = 1, loops do
            DB.move_down(note)
        end
        -- if vim.fn.line('.') > 1 and vim.fn.line('.') ~= vim.fn.line('$') then
        -- end
    end
    M.todua_popup(false)
end

function M.todua_popup(show_numbers)
    show_numbers = show_numbers or false
    local todo_table, size, longest = view_notes(show_numbers)
    local commands = "(a)dd (u)n(f)inish (k)up (j)down (d)elete (q)uit"
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
    -- vim.api.nvim_buf_set_option(M.buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(M.buf, 'readonly', true)

    local opts = {
        style = "minimal",
        relative = "editor",
        width = math.max(math.min(longest, 80), 48),
        height = size + 1,
        col = vim.o.columns,
        -- col = 15,
        row = 0,
        border = "double",
    }

    -- Check if the window exists
    if M.win and vim.api.nvim_win_is_valid(M.win) then
        -- If the window exists, update its configuration (resize if needed)
        vim.api.nvim_win_set_config(M.win, opts)
    else
        -- If the window doesn't exist, create a new one
        M.win = vim.api.nvim_open_win(M.buf, true, opts)
    end

    vim.api.nvim_buf_set_keymap(M.buf, 'n', 'q', '', { noremap = true, silent = true,
        nowait = true, callback = quit
    })
    vim.api.nvim_buf_set_keymap(M.buf, 'n', 'a', '', { noremap = true, silent = true,
        nowait = true, callback = add_note
    })
    vim.api.nvim_buf_set_keymap(M.buf, 'n', 'f', '', { noremap = true, silent = true,
        nowait = true, callback = finish_note
    })
    vim.api.nvim_buf_set_keymap(M.buf, 'n', 'u', '', { noremap = true, silent = true,
        nowait = true, callback = unfinish_note
    })
    vim.api.nvim_buf_set_keymap(M.buf, 'n', 'd', '', { noremap = true, silent = true,
        nowait = true, callback = delete_note
    })
    vim.api.nvim_buf_set_keymap(M.buf, 'n', 'k', '', { noremap = true, silent = true,
        nowait = true, callback = move_up
    })
    vim.api.nvim_buf_set_keymap(M.buf, 'n', 'j', '', { noremap = true, silent = true,
        nowait = true, callback = move_down
    })
end

vim.api.nvim_create_user_command('Todua', M.todua_popup, {})

return M
