local DB = require('sqlite')
local env, conn = DB.init()
DB.create_table(conn)


local function view_notes(draw_ids)
    local results = DB.select_all(conn)
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
        record = record .. " ]   " .. row.note .. "\n"
        io.write(record)
    end
end


local function add_note()
    io.write("Note for new task: ")
    DB.insert(conn, false, io.read())
end


local function delete_note()
    view_notes(true)
    io.write("Entry to delete: ")
    DB.delete(conn, io.read())
end

local function finish_note()
    view_notes(true)
    io.write("Note to finish: ")
    DB.finish(conn, io.read())
end


local function main()
    -- DB.insert(true, "done")
    -- DB.insert(false, "stinky2")
    local continue = true
    while continue do
        view_notes(false)
        print("(a)dd | (d)elete | (q)uit")

        io.write("What would you like to do? ")
        local action = io.read()

        if action == "v" then
            view_notes()
        elseif action == "a" then
            add_note()
        elseif action == "d" then
            delete_note()
        elseif action == "f" then
            finish_note()
        elseif action == "q" then
            continue = false
        end
    end
end
main()
