tank_type = "fluidtank:tiletank"
target_tank_type = "tconstruct:tank"

TankManager = {}
TankManager.__index = TankManager


local function split(source, sep)
    --[[
        Splits a string on the seperator character

        source => string to split
        sep => splitted character

        Return list of split strings
    ]]
    local result, i = {}, 1
    while true do
        local a, b = source:find(sep)
        if not a then break end
        local candidat = source:sub(1, a - 1)
        if candidat ~= "" then 
            result[i] = candidat
        end i=i+1
        source = source:sub(b + 1)
    end
    if source ~= "" then 
        result[i] = source
    end
    return result
end

-- ####################################################################
-- For debug only
-- ####################################################################
local function create_test_tank(fluid)
    local tank = {}
    tank.tanks = function()
        local data = {}
        data["0"] = {}
        data["0"]['name'] = fluid
        data["0"]['amount'] = 24000
        return data
    end
    tank.pushFluid = function(name)
        print("Push to " .. name)
    end
    tank.pullFluid = function(name)
        print("Pull from " .. name)
    end
    return tank
end

local function get_test_tank(fluid)
    local tank = create_test_tank(fluid)
    local tbl = {}
    tbl['name'] = fluid .. "_tank"
    tbl['fluid'] = fluid
    tbl['tank'] = tank
    return tbl
end

local function get_test_tanks()
    list = {"minecraft:wasser", "minecraft:lava", "tc:eisen", "tc:gold", "minecraft:milch"}

    local tmp_tanks = {}
    for id, name in pairs(list) do
        name = split(name, ":")[#split(name, ":")]
        local tbl = get_test_tank(name)
        tmp_tanks[name .. "_tank"] = tbl
        -- table.insert(tmp_tanks, tbl)
    end
    return tmp_tanks
end

local function get_test_target()
    return "target_tank"
end
-- ####################################################################
-- ####################################################################

local function get_tanks()
    --[[
    Fetch the tanks from peripheral list.
    Retun table of all (not empty) tanks from the peripheral list
    tank_data:
        ["name"]  => Peripheral name
        ['fluid'] => Stored fluid name
        ['tank']  => Tank object
    ]]

    local tank_list = {}
    for id, tank_name in pairs(peripheral.getNames()) do
        if peripheral.getType(tank_name) == tank_type then
            local tank = peripheral.wrap(tank_name)
            local fluid_name = tank.tanks()[1]['name'] or nill
            if fluid_name ~= nil then
                fluid_name = split(fluid_name, ":")[#split(fluid_name, ":")]

            local tank_data = {}
            tank_data['name'] = tank_name
            tank_data['fluid'] = fluid_name
            tank_data['tank'] = tank
            -- table.insert(tank_list, tank_data)
            tank_list[tank_name] = tank_data
            end
        end
    end
    return tank_list
end

local function get_target()
    --[[
        Fetch the target tank name from the peripheral list

        Returns name of the target tank
    ]]
    for id, name in pairs(peripheral.getNames()) do
        if peripheral.getType(name) == target_tank_type then
            return name
        end
    end
end

function TankManager:create(modem, recive_channel, send_channel)
    --[[
        Create function of the manager, stores all relevant variables.
        
        modem => Modem object
        recive_channel => Channel to recive messages
        send_channel => Channel to send messages
    ]]
    local tm = {}
    setmetatable(tm, TankManager)
    tm.modem = modem
    tm.recive_channel = recive_channel
    tm.send_channel = send_channel
    tm.tanks = get_tanks()
    tm.target = get_target()
    -- tm.tanks = get_test_tanks()
    -- tm.target = get_test_target()
    tm:wait_for_transmission()
    return tm
end

function TankManager:tank_action(action, tank_name)
    --[[
        Preform the tank functions (pushFluid or pullFluid) for the given action

        action => "open" or "close"
        tank_name => name of the tank to preform the action
    ]]
    if action == "open" then
        self.tanks[tank_name]["tank"].pushFluid(self.target)
    elseif action == "close" then
        self.tanks[tank_name]["tank"].pullFluid(self.target)
    end
end


function TankManager:format_get_data_message()
    --[[
        build the message to send the tank data to the display manager.

        Return the message with all tank informations
            message[id]   => tank name
                ["name"]  => tank name
                ["fluid"] => fluid name
    ]]
    local message = {}
    message["type"] = "tank_control"
    message["action"] = "set_data"
    message["tank"] = {}

    for id, tank in pairs(self.tanks) do
        local tank_data = {}
        tank_data["name"] = id
        tank_data["fluid"] = tank['fluid']
        message["tank"][id] = tank_data
    end
    return message
end

function TankManager:send_message(message)
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

function TankManager:wait_for_transmission()
    --[[
        Hande the transmission functions, wait for commands.
    ]]
    self.modem.open(self.recive_channel)
    local stay_alive_timer = os.startTimer(10)
    while true do
        local event = {os.pullEvent()}

        if event[1] == "modem_message" then
            print("Recive message")
            local message = event[5]
            print(textutils.serialize(message))

            if message["type"] ~= nil then
                if message["type"] == "tank_control" then
                    if message["action"] == "get_data" then
                        self:send_message(self:format_get_data_message())
                    end
                    if message["action"] == "open" then
                        self:tank_action("open", message["tank"])
                    end
                    if message["action"] == "close" then
                        self:tank_action("close", message["tank"])
                    end
                end
            end
        elseif event[1] == "timer" and event[2] == stay_alive_timer then
            local message = {}
            message["type"] = "keep_alive"
            message["action"] = ""
            message["tank"] = ""
            self:send_message(message)
            stay_alive_timer = os.startTimer(10)
        end
    end
    self.modem.close(self.recive_channel)
end

return TankManager