local monitor = peripheral.find("monitor") or error("No monitor attached", 0)
monitor.setTextScale(1)

local function fll_mon(width, height)
    odd = false
    for x = 1, width do
        for y = 1, height do
            monitor.setCursorPos(x, y)
            if odd then
                monitor.write("O")
            else
                monitor.write("I")
            end
            if odd then
                odd = false
            else
                odd = true
            end
        end
    end
end

--8 Text max
min_width = 12
min_height = 6

button = { ["width"] = 10, ["height"] = 3 }

local GUI = require "/libs/gui"
gui = GUI(monitor)


function hallo_world(data)
    print("Hallo " .. data)
end

function get_max_buttons()
    local width, height = monitor.getSize()
    if width >= min_width and height >= min_height then
        local max_columns = math.floor((width - 1) / (button["width"] + 1))
        local max_rows = math.floor((height - 2) / (button["height"] + 1))
        for column = 1, max_columns do
            for row = 1, max_rows do
                local x_coord = (column - 1) * (button["width"] + 1) + 2
                local y_coord = (row - 1) * (button["height"] + 1) + 2
                local b = gui:create_button(column .. row, column .. row, x_coord, y_coord, 10, 3, colors.white, colors.red, colors.blue, "button", false)
                b:add_event(hallo_world, column .. row)
                gui:add_button("lay1", b)
            end
        end
    end
end




local TEST = require "/test_class"
test = TEST("nicht die Mama")

local width, height = monitor.getSize()
fll_mon(width, height)
while true do
    gui:clear()
    get_max_buttons()
    gui:draw_layout("lay1")




    local event = {os.pullEvent()}
    if event[1] == "monitor_touch" then
        gui:click(event[3], event[4])
    end
end