local sqlite = require("sqlite")

local M = {}
local ORDER_I = 1

function M.init()
    -- os.remove("todua.db")
    M.db = sqlite.new("~/.config/nvim/lua/todua/todua.db")
    if not M.db then
        error("Failed to connect to the database.")
    end

    local success, err = M.db:open()
    if not success then
        error("Failed to open DB connection: " .. err)
    end

    local table_status = M.db:eval("SELECT name FROM sqlite_master WHERE type='table' AND name='notes';")
    if type(table_status) == "table" and #table_status > 0 then
        ORDER_I = M.db:eval("SELECT COUNT(*) AS count FROM notes;")[1].count + 1
    else
        ORDER_I = 1
    end
end

function M.hacky_query()
    local query
    -- query = "UPDATE notes SET priority = 1 WHERE priority IS NULL"
    query = ""
    if query ~= "" then
        M.db:eval(query)
    end
end

function M.create_table()
    M.hacky_query()
    local create_table_query = [[
    CREATE TABLE IF NOT EXISTS notes(
        id INTEGER PRIMARY KEY,
        done INTEGER,
        note TEXT,
        order_index INTEGER,
        priority INTEGER
    );
    ]]
    local success, err = M.db:eval(create_table_query)
    if not success then
        error("Failed to create table: ", err)
    end
end

function M.insert(done, note)
    local done_int = done and 1 or 0

    local insert_query = string.format([[
        INSERT INTO notes (done, note, order_index, priority)
        VALUES (%d, '%s', %d, %d);
    ]], done_int, note, ORDER_I, 0)
    local success, err = M.db:eval(insert_query)
    if not success then
        error("Failed to insert into table: ", err)
    end
    ORDER_I = ORDER_I + 1
    return ORDER_I - 1 -- return order index of created note
end

function M.edit(id, new_note)
    local edit_query = "UPDATE notes SET note = '" .. new_note .. "' WHERE id = " .. id .. ";"
    local success, err = M.db:eval(edit_query)
    if not success then
        error("Failed to update table: ", err)
    end
end

function M.delete(id)
    local entry = M.db:eval("SELECT order_index FROM NOTES WHERE id = " .. id .. ";")
    if not entry or type(entry) ~= "table" or #entry == 0 then
        error("Failed to get deletable order_index from table")
    end

    local delete_query = "DELETE FROM notes WHERE id = " .. id .. ";"
    local success, err = M.db:eval(delete_query)
    if not success then
        error("Failed to delete from table: ", err)
    end

    local fix_proceeding = "UPDATE notes SET order_index = order_index - 1 WHERE order_index > " .. entry[1].order_index .. ";"
    success, err = M.db:eval(fix_proceeding)
    if not success then
        error("Failed to delete from table: ", err)
    end
end

function M.set_priority(id, priority)
    local priority_query = "UPDATE notes SET priority = " .. priority .. " WHERE id = " .. id .. " AND NOT priority = 5;"
    local success, err = M.db:eval(priority_query)
    if not success then
        error("Failed to update table: ", err)
    end
end

function M.finish(id)
    local finish_query = "UPDATE notes SET done = 1, priority = 5 WHERE id = " .. id .. ";"
    local success, err = M.db:eval(finish_query)
    if not success then
        error("Failed to update table: ", err)
    end
end

function M.unfinish(id)
    local unfinish_query = "UPDATE notes SET done = 0, priority = 0 WHERE id = " .. id .. ";"
    local success, err = M.db:eval(unfinish_query)
    if not success then
        error("Failed to update table: ", err)
    end
end

function M.move_up(id)
    local current_order = M.db:eval(string.format("SELECT order_index FROM notes WHERE id = %d;", id))[1].order_index
    if current_order > 1 then
        M.db:eval(string.format("UPDATE notes SET order_index = order_index + 1 WHERE order_index = %d - 1;", current_order))
        M.db:eval(string.format("UPDATE notes SET order_index = order_index - 1 WHERE id = %d;", id))
    end
end

function M.move_down(id)
    local current_order = M.db:eval(string.format("SELECT order_index FROM notes WHERE id = %d;", id))[1].order_index
    if current_order < ORDER_I - 1 then
        M.db:eval(string.format("UPDATE notes SET order_index = order_index - 1 WHERE order_index = %d + 1;", current_order))
        M.db:eval(string.format("UPDATE notes SET order_index = order_index + 1 WHERE id = %d;", id))
    end
end

function M.select_all()
    M.init()

    local select_query = "SELECT * FROM notes;"
    local rows = M.db:eval(select_query)

    local results = {}

    if not rows or type(rows) ~= "table" then
        return results
    end

    for _, note in pairs(rows) do
        table.insert(results, note)
    end

    return results
end

function M.close()
    M.db:close()
end

return M
