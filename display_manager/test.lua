Logger = require "/libs/log"
__logger = Logger(5, "FD", true, false)


--local monitor = peripheral.find("monitor") or __logger:error_exit("No monitor attached")
local modem = peripheral.find("modem") or __logger:error_exit("No modem attached", 0)

local CM = require "/libs/notcp"

local test = CM(modem, 22, 23)

local results = {}
for x = 1, 10 do
    local message_obj = test:build_message("test_target", "test_type", "test_action", "X ".. x)
    local dummy = test:send_and_receive_message(message_obj, "test_target", "test_type", "test_result", 10)
    table.insert(results, dummy)
    x = x + 1
end
--print(textutils.serialize(results))
--
--MyClass = require "test_class"
--
--local image1 = MyClass()
--image1:printData()
--image1:do_things("sdsds")