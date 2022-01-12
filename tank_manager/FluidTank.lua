local modem = peripheral.find("modem") or error("No modem attached", 0)
local version = "0.1.0"

local dx, dy = term.getSize()

local function clear_screen(row, colour)
    term.setBackgroundColour(colour or term.getBackgroundColour())
    term.setTextColour(colours.white)

    if row then
        term.setCursorPos(1, row)
        term.clearLine()
    else
        term.clear()
    end
    term.setCursorPos(1, 1)
end

local function write_center(text, y)
    clear_screen(y)

    local t = {}
    for i in string.gmatch(text, "%S+") do
        t[#t + 1] = i
    end
    local lines = {
        [1] = ""
    }
    local line = 1
    for i = 1, #t do
        if #tostring(lines[line] .. " " .. t[i]) > dx then
            lines[line] = lines[line] .. "\n"
            line = line + 1
            lines[line] = " " .. t[i]
        else
            lines[line] = lines[line] .. " " .. t[i]
        end
    end
    y = y or math.ceil(dy / 2 - #lines / 2)
    for i = 1, #lines do
        term.setCursorPos(dx / 2 - #lines[i] / 2, y + (i - 1))
        print(lines[i])
    end
end

local function get_file(file, y)
    local path = "https://raw.githubusercontent.com/Cloud500/fluid_manager_mc/main/tank_manager/"

    write_center("Downloading " .. file, y)
    local dl = http.get(path .. file)
    local h = dl.readAll()
    dl.close()

    local f = fs.open(file, "w")
    f.write(h)
    f.close()
    write_center(file .. " download complete", y)
end

local function check_file(file)
    for _, f in ipairs(fs.list("")) do
        if f == file then
            return true
        end
    end
    return false
end

local function manage_file(file, y)
    sleep(0.5)
    if not check_file(file) then
        write_center(file .. " not found, try Download", y)
        get_file(file, y)
    else
        write_center(file .. " found.", y)
    end
end

clear_screen(nil, colours.grey)
write_center("Fluid Manager v" .. version, 2)
sleep(0.5)
write_center("Check files ...", 4)
manage_file("tank_manager.lua", 5)
write_center("Check complete ...", 9)
sleep(1)
clear_screen()
write_center("Starting", 4)
local Manager = require "tank_manager"
mg = Manager:create(modem, 443, 444)
clear_screen(nil, colors.black)
