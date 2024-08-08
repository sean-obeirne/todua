local sqlite3 = require("luasql.sqlite3")

local M = {}

function M.init()
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
        return
    end
    
end

function M.insert(conn, id, done, note)

    local insert_query = [[
        INSERT INTO notes (id, done, note)
        VALUES (1, 0, 'Hello Mikayla');
    ]]

    local insert_table_result, insert_table_error = conn:execute(insert_query)
    if not insert_table_result then
        print("Failed to insert into table:", insert_table_error)
        return
    end
end

function M.select_all(conn)
    local select_query = "SELECT * FROM notes;"

    local cursor = conn:execute(select_query)
    local row = cursor:fetch({}, "a")

    local results = {}

    while row do
        row = cursor:fetch(row, "a")
        table.insert(results, row)
    end

    return results
end

function M.close(env, conn)
    conn:close()
    env:close()
end

return M
