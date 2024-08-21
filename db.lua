local sqlite = require("sqlite")

local M = {}

function M.init()
    os.remove("todua.db")
    M.db = sqlite.new("todua.db")
    if not M.db then
        error("Failed to connect to the database.")
    end

    local success, err = M.db:open()
    if not success then
        error("Failed to open DB connection: " .. err)
    end

    print("Connected to the database.")
end


function M.create_table()
    print("Creating table!")
    local create_table_query = [[
    CREATE TABLE IF NOT EXISTS notes(
        id INTEGER PRIMARY KEY,
        done INTEGER,
        note TEXT
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
        INSERT INTO notes (done, note)
        VALUES (%d, '%s');
    ]], done_int, note)
    local success, err = M.db:eval(insert_query)
    if not success then
        error("Failed to insert into table: ", err)
    end
end

function M.delete(id)
    local delete_query = "DELETE FROM notes WHERE id = " .. id .. ";"
    local success, err = M.db:eval(delete_query)
    if not success then
        error("Failed to delete from table: ", err)
    end
end

function M.finish(id)
    local finish_query = "UPDATE notes SET done = 1 WHERE id = " .. id .. ";"
    local success, err = M.db:eval(finish_query)
    if not success then
        error("Failed to update table: ", err)
    end
end

function M.select_all()
    local select_query = "SELECT * FROM notes;"
    local rows = M.db:eval(select_query)

    if not rows then
        error("Failed to select *")
    end

    local results = {}
    for _, note in pairs(rows) do
        table.insert(results, note)
    end

    return results
end

function M.close()
    M.db:close()
    print("Database closed")
end

return M
