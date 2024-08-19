local DB = require('sqlite')
local env, conn = DB.init()
DB.create_table(conn)

local function parse_record(row)
    local status = "\u{2718}"
    if row.done == 1 then status = "\u{2714}" end
    io.write("  [ " .. status .. " ]    " .. row.note .. "\n")
end

local function view_notes()
    local results = DB.select_all(conn)
    for _, row in pairs(results) do
        parse_record(row)
    end
end

local function add_notes(done, note)
    DB.insert(conn, done, note)
end

local function delete_notes()
    print("We are deleting notes!")
end


local function main()
    -- DB.insert(true, "done")
    -- DB.insert(false, "stinky2")
    add_notes(false, "laundry")
    local continue = true
    while continue do
        print("Welcome!")
        print("  (v) view notes")
        print("  (a) add notes")
        print("  (d) delete notes")
        print("  (q) to quit")

        io.write("What would you like to do? ")
        local action = io.read()

        if action == "v" then
            view_notes()
        elseif action == "a" then
            io.write("Note for new task: ")
            add_notes(false, io.read())
        elseif action == "d" then
            io.write("Note for task to delete: ")
            delete_notes()
        elseif action == "q" then
            continue = false
        end
    end
end
main()
