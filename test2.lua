Logger = require "/libs/log"
__logger = Logger(5, "FD", true, false)


--local monitor = peripheral.find("monitor") or __logger:error_exit("No monitor attached")
local modem = peripheral.find("modem") or __logger:error_exit("No modem attached", 0)

local CM = require "/libs/notcp"

local test = CM(modem, 23, 22)

local results = {}
for x = 1, 10 do
    local message_obj = test:build_message("display_manager", "test_type", "test_result", "XX " .. x)
    local dummy = test:receive_and_send_message(message_obj, "display_manager", "test_type", "test_action", 10)
    table.insert(results, dummy)
    x = x + 1
end
--print(textutils.serialize(results))
