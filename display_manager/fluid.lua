Fluid = {}
Fluid.__index = Fluid

os.loadAPI("gui")

function Fluid:create(modem, name, p_name, color)
    local fluid = {}
    setmetatable(fluid, Fluid)
    fluid.page = 0
    fluid.row = 0
    fluid.column = 0
    fluid.name = name
    fluid.color = color
    fluid.active = false
    fluid.p_name = p_name
    fluid.modem = modem
    return fluid
end

function Fluid:set_position(page, column, row)
    self.page = page
    self.row = row
    self.column = column
end

function Fluid:get_color()
    return self.color
end

function Fluid:send_message(state)
    local message = {}
    message["type"] = "tank_control"
    message["action"] = state
    message["tank"] = self.p_name

    self.modem.open(443)
    self.modem.transmit(443, 444, message)
    self.modem.close(443)
end

function Fluid:activate()
    self.active = true
    self:send_message("open")
end

function Fluid:deactivate()
        self.active = false
        self:send_message("close")
    end

function Fluid:set_state(state)
    if state ~= self.active then
        if state == true then
            self:activate()
        end
        if state == false then
            self:deactivate()
        end
    end
end

return Fluid