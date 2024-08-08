local db = require('sqlite')
local env, conn = db.init()
db.create_table(conn)

local function parse_record(row)
    print(row.id)
    local status = "\u{2718}"
    if row.done == 1 then status = "\u{2714}" end
    io.write("  [ " .. status .. " ]    " .. row.note)
    print(row.note)
end

local function view_notes()
    results = db.select_all(conn)
    for row in results do
        parse_record(row)
    end
end

local function add_notes()
    print("We are adding notes!")
end

local function delete_notes()
    print("We are deleting notes!")
end


local function main()
    local continue = true
    while continue do
        print("Welcome!")
        print("  (v) view notes")
        print("  (a) add notes")
        print("  (d) delete notes")
        print("  (q) to quit")

        io.write("What would you like to do? ")
        action = io.read()

        if action == "v" then
            view_notes()
        elseif action == "a" then
            add_notes()
        elseif action == "d" then
            delete_notes()
        elseif action == "q" then
            continue = false
        end
    end
end
main()
