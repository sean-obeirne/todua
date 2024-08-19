local sqlite3 = require("luasql.sqlite3")

local M = {}

function M.init()
    -- os.remove("db-todua.db")
    local env = sqlite3.sqlite3()
    local conn = env:connect("db-todua.db")

    if not conn or not env then
        print("Failed to connect to the database.")
        return
    end
    print("Connected to the database.")
    return env, conn
end


function M.create_table(conn)
    local create_table_query = [[
    CREATE TABLE IF NOT EXISTS notes(
        id INTEGER PRIMARY KEY,
        done INTEGER,
        note TEXT
    );
    ]]

    local create_table_result, create_table_error = conn:execute(create_table_query)
    if not create_table_result then
        print("Failed to create table:", create_table_error)
        return 1
    end

end

function M.insert(conn, done, note)

    local done_int = done and 1 or 0

    local insert_query = string.format([[
        INSERT INTO notes (done, note)
        VALUES (%d, '%s');
    ]], done_int, note)

    local insert_table_result, insert_table_error = conn:execute(insert_query)
    if not insert_table_result then
        print("Failed to insert into table:", insert_table_error)
        return 1
    end
end

function M.delete(conn, id)
    local delete_query = "DELETE FROM notes WHERE id = " .. id .. ";"
    conn:execute(delete_query)
end

function M.finish(conn, id)
    local finish_query = "UPDATE notes SET done = 1 WHERE id = " .. id .. ";"
    conn:execute(finish_query)
end

function M.select_all(conn)
    local select_query = "SELECT * FROM notes;"

    local cursor = conn:execute(select_query)


    local results = {}

    while true do
        local row = cursor:fetch({}, "a")
        if not row then break end
        table.insert(results, row)
    end

    return results
end

function M.close(env, conn)
    conn:close()
    env:close()
end

return M
