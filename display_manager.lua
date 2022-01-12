DisplayManager = {}
DisplayManager.__index = DisplayManager

os.loadAPI("gui")

local color_data = {
    ["test01"] = colors.blue,
    ["test02"] = colors.yellow,
    ["test03"] = colors.orange,
    ["test04"] = colors.green
}

local function get_color(name)
    for id, color in pairs(color_data) do
        if id == name then
            return color
        end
    end
    return colors.gray
end

local function cut_text(text, count)
    local text_len = string.len(text)
    if text_len > count then
        text_len = count
        text = string.sub(text, 1, count)
    end
    return text
end

local function column_to_coordinate(column)
    local column_width = 15
    local start_width = (column - 1) * 16 + 3
    local end_width = start_width + column_width - 1

    local min_x = math.floor(start_width)
    local max_x = math.floor(end_width)

    return min_x, max_x
end

local function row__to_coordinate(row)
    local row_height = 3
    local start_height = (row - 1) * 4 + 2
    local end_height = start_height + row_height - 1

    local min_y = math.floor(start_height)
    local max_y = math.floor(end_height)

    return min_y, max_y
end

local function get_coordinates(column, row)
    local min_x, max_x = column_to_coordinate(column)
    local min_y, max_y = row__to_coordinate(row)
    return min_x, max_x, min_y, max_y
end

function DisplayManager:create(mon, modem, recive_channel, send_channel, mix_fluids)
    local fm = {}
    setmetatable(fm, DisplayManager)
    mix_fluids = mix_fluids or false
    fm.mon = mon
    fm.width, fm.height = mon.getSize()
    fm.data = nil
    fm.max_page = nil
    fm.page = 1
    fm.mix_fluids = mix_fluids
    fm.modem = modem
    fm.recive_channel = recive_channel
    fm.send_channel = send_channel
    fm.loop = true
    fm:wait_for_event()
    return fm
end

function DisplayManager:prase_data(data)
    local Fluid = require "fluid"

    local p_data = {}
    local page = 1
    local row = 1
    local column = 1

    for id, data in pairs(data) do
        local name = data["fluid"]
        local p_name = data["name"]

        name = cut_text(name, 13)

        local fl = Fluid:create(self.modem, name, p_name, get_color(name))

        if row > 4 then
            row = 1
            column = column + 1

            if column > 3 then
                column = 1
                page = page + 1
            end
        end

        fl:set_position(page, column, row)
        table.insert(p_data, fl)
        row = row + 1
    end
    return p_data, page
end

function DisplayManager:draw_data(page, data)
    if data and page then
        for id, data in pairs(data) do
            if data.page == page then
                local min_x, max_x, min_y, max_y = get_coordinates(data.column, data.row)
                gui.addButton(data.name, self, min_x, max_x, min_y, max_y, data:get_color(), colors.red, "switch",
                    data.name, data.active)
            end
        end
    end
end

function DisplayManager:draw_page()
    gui.clearAll()
    gui.addButton("X", self, self.width, self.width, 1, 1, colors.gray, colors.red, "", "close")

    self:draw_data(self.page, self.data)

    gui.addButton("<<", self, 2, 2 + 3, self.height, self.height, colors.gray, colors.red, "", "prev_page")
    gui.addButton("Leeren", self, (self.width / 2) - 2, (self.width / 2) + 5, self.height, self.height, colors.gray,
        colors.red, "", "clear")
    gui.addButton(">>", self, self.width - 4, self.width - 1, self.height, self.height, colors.gray, colors.red, "",
        "next_page")

    gui.screenButton()
end

function DisplayManager:draw_connection_page(add_text)
    add_text = add_text or ""
    gui.clearAll()
    self.mon.setTextColor(colors.gray)
    self.mon.setCursorPos((self.width/2) - 7, (self.height / 2) - 1)
	self.mon.write("Connecting ...")

    self.mon.setCursorPos((self.width/2) - (string.len(add_text) / 2), (self.height / 2) + 1)
    self.mon.write(add_text)

end

function DisplayManager:draw_error_page(reason)
    gui.clearAll()
    self.mon.setTextColor(colors.red)
    self.mon.setCursorPos((self.width/2) - 4, (self.height / 2) - 1)
	self.mon.write("+Error+")

    self.mon.setCursorPos((self.width/2) - (string.len(reason) / 2), (self.height / 2) + 1)
    self.mon.write(reason)
end

function DisplayManager:wait_for_event()
    self:draw_connection_page("6")
    self.modem.open(self.recive_channel)
    local stay_alive_timer = os.startTimer(1)

    local connected = false
    local try = 1
    local tank_manager_alive = false
    self:send_message(self:get_data_message())
    while self.loop do
        local event = {os.pullEvent()}

        if event[1] == "monitor_touch" then
            local x = event[3]
            local y = event[4]
            gui.checkxy(x, y)
            gui.screenButton()
        elseif event[1] == "modem_message" then
            local message = event[5]
            print("Recive message")
            print(textutils.serialize(message))

            if message["type"] ~= nil then
                if message["type"] == "tank_control" then
                    if message["action"] == "set_data" then
                        self.data, self.max_page = self:prase_data(message["tank"])
                        self:draw_page()
                        connected = true
                        tank_manager_alive = true
                    end
                elseif message["type"] == "keep_alive" then
                    tank_manager_alive = true
                end
            end
        elseif event[1] == "timer" and event[2] == stay_alive_timer then
            if connected == false then
                if try < 6 then
                    try = try + 1
                    print("Next Connect Try")
                    self:draw_connection_page(7 - try)
                    self:send_message(self:get_data_message())
                    stay_alive_timer = os.startTimer(1)
                else
                    print("Error")
                    print("No connection to Tank manager")
                    self:draw_error_page("No connection to Tank manager")
                    self.modem.close(self.recive_channel)
                    break
                end
            end
            if connected == true and tank_manager_alive == true then
                tank_manager_alive = false
                stay_alive_timer = os.startTimer(11)
            elseif connected == true and tank_manager_alive == false then
                print("Error")
                print("Connection to Tank manager lost")
                    self:draw_error_page("Connection to Tank manager lost")
                self.modem.close(self.recive_channel)
                break
            end
        end
    end
end


function DisplayManager:next_page()
    self.page = self.page + 1
    if self.page > self.max_page then
        self.page = self.max_page
    end
    self:draw_page()
end

function DisplayManager:prev_page()
    self.page = self.page - 1
    if self.page < 1 then
        self.page = 1
    end
    self:draw_page()
end

function DisplayManager:clear()
    for id, data in pairs(self.data) do
        if data.active then
            data:deactivate()
        end
    end
    self:draw_page()
end

function DisplayManager:deactivate_all_exept(name)
    for id, data in pairs(self.data) do
        if data.name ~= name and data.active then
            data:deactivate()
            if self.page == data.page then
                gui.buttonState(data.name, false)
            end
        end
    end
end

function DisplayManager:click(event)
    if event == "next_page" then
        self:next_page()
    elseif event == "prev_page" then
        self:prev_page()
    elseif event == "clear" then
        self:clear()
    elseif event == "close" then
        self.loop = false
        gui.clearAll()
    end
    for id, data in pairs(self.data) do
        if data.name == event then
            if data.active then
                data:deactivate()
            else
                if not self.mix_fluids then
                    self:deactivate_all_exept(data.name)
                end
                data:activate()
            end
        end
    end
end

function DisplayManager:send_message(message)
    --[[
        Sens a message over the network

        message => message to send
    ]]
    self.modem.open(self.send_channel)
    self.modem.transmit(self.send_channel, self.recive_channel, message)
    self.modem.close(self.send_channel)
    print("Send message")
    print(textutils.serialize(message))
end

function DisplayManager:get_data_message()
    local message = {}
    message["type"] = "tank_control"
    message["action"] = "get_data"
    message["tank"] = ""
    return message
end

return DisplayManager
