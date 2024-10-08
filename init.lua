local M = {}
local DB = require('todua.db')

function M.init()
    DB.init()
    DB.create_table()
end

local ordered_notes
local priority_highlights = {"Normal", "String", "WarningMsg", "ErrorMsg", "Comment"}

local function remove_leading_whitespace(s)
    local i = 1
    local leading_whitespace = ""
    while s:sub(1, 1) == " " do
        s = s:sub(2, #s)
        leading_whitespace = leading_whitespace .. " "
        i = i + 1
    end
    return leading_whitespace, s
end

local function get_notes()
    ordered_notes = DB.select_all()
    table.sort(ordered_notes, function(a, b)
        return a.order_index < b.order_index
    end)
end

local function get_cur_note()
    return ordered_notes[vim.fn.line('.')]
end

local function view_notes(draw_ids)
    get_notes()
    local todo_table = {}
    local size = 0
    local longest = 0
    for _, row in pairs(ordered_notes) do
        local record = ""
        local is_header = row.note == string.upper(row.note)
        if not is_header then
            record = "  "
        end
        if draw_ids == true then
            record = record .. row.id .. " "
        end
        if not is_header then
            local leading_whitespace, new_string = remove_leading_whitespace(row.note)
            record = record .. leading_whitespace
            row.note = new_string
            -- record = record .. ""
            if row.done == 1 then
                record = record .. "\u{2714}"
            else
                record = record .. "\u{1F785}"
            end
            record = record .. "   "
        end
        record = record .. row.note

        local hl_group

        if row.done == 1 then
            hl_group = priority_highlights[5]
        else
            hl_group = priority_highlights[row.priority] or "Normal"
        end

        table.insert(todo_table, {text = record, hl = hl_group})

        longest = math.max(longest, string.len(record))
        size = size + 1
    end
    return todo_table, size, longest
end

local function add_note()
    local new_note = vim.fn.input("Note for new task: ")
    if #new_note > 0 then
        local i = DB.insert(false, new_note)
        M.todua_popup()
        vim.fn.cursor(i, 1)
    end
end

local function edit_note()
    local note = get_cur_note()
    if note then
        local new_note = vim.fn.input("New note for task: ")
        if #new_note > 0 then
            DB.edit(note.id, new_note)
        end
        M.todua_popup()
        vim.fn.cursor(note.order_index, 1)
    end
end

local function set_priority(priority)
    local note = get_cur_note()
    if note and priority > 0 and priority <= 4 then
        DB.set_priority(note.id, priority)
        M.todua_popup()
        vim.fn.cursor(note.order_index, 1)
    end
end

local function unfinish_note()
    local note = get_cur_note()
    if note then
        DB.unfinish(note.id)
        M.todua_popup()
        vim.fn.cursor(note.order_index, 1)
    end
end

local function finish_note()
    local note = get_cur_note()
    if note then
        DB.finish(note.id)
        M.todua_popup()
        vim.fn.cursor(note.order_index, 1)
    end
end

local function delete_note()
    local note = get_cur_note()
    if note then
        DB.delete(note.id)
        M.todua_popup()
        vim.fn.cursor(note.order_index, 1)
    end
end

local function quit()
    DB.close()
    vim.api.nvim_win_close(0, true)
end

local function move_up()
    local note = get_cur_note()
    if note then
        DB.move_up(note.id)
        M.todua_popup()
        vim.fn.cursor(note.order_index - 1, 1)
    end
end
local function move_down()
    local note = get_cur_note()
    if note and note.order_index < #ordered_notes then
        DB.move_down(note.id)
        M.todua_popup()
        vim.fn.cursor(note.order_index + 1, 1)
    end
end

function M.todua_popup()
    local todo_table, size, longest = view_notes()
    local commands = " (a)dd (e)dit (u)n(f)inish (k)up (j)down (d)elete (q)uit "
    table.insert(todo_table, {text = commands, hl = "Normal"})

    -- If the buffer doesn't exist or is invalid, create a new one
    if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
        M.buf = vim.api.nvim_create_buf(false, true)
    else
        -- If the buffer exists, clear and reuse it
        vim.api.nvim_buf_set_option(M.buf, 'modifiable', true)
        vim.api.nvim_buf_set_option(M.buf, 'readonly', false)
        vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, {})
    end

    -- Set lines and apply highlights
    for i, entry in ipairs(todo_table) do
        -- Set the line in the buffer
        vim.api.nvim_buf_set_lines(M.buf, i - 1, i, false, {entry.text})
        -- Apply the corresponding highlight
        vim.api.nvim_buf_add_highlight(M.buf, -1, entry.hl, i - 1, 0, -1)
    end

    -- Set the buffer as unmodifiable, scratch, and read-only
    vim.api.nvim_buf_set_option(M.buf, 'modifiable', false)
    -- vim.api.nvim_buf_set_option(M.buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(M.buf, 'readonly', true)

    local opts = {
        style = "minimal",
        relative = "editor",
        width = math.max(math.min(longest, 80), #commands),
        height = math.min(size + 1, 35),
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

    local keymaps = {
        q = quit,
        a = add_note,
        e = edit_note,
        f = finish_note,
        u = unfinish_note,
        d = delete_note,
        k = move_up,
        j = move_down,
        ['1'] = function() set_priority(1) end,
        ['2'] = function() set_priority(2) end,
        ['3'] = function() set_priority(3) end,
        ['4'] = function() set_priority(4) end,
    }

    for key, action in pairs(keymaps) do
        vim.api.nvim_buf_set_keymap(M.buf, 'n', key, '', {
            noremap = true,
            silent = true,
            nowait = true,
            callback = action
        })
    end
end

vim.api.nvim_create_user_command('Todua', M.todua_popup, {})

return M
