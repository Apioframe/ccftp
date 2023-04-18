local args = {...}
local modem = peripheral.find("modem")
local api = require("ftpapi")

function mysplit (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

function hiddenread()
    term.setCursorBlink(true)
    local input = ""
    function a()
        while true do
            local event, key, is_held = os.pullEvent("key")
            key = keys.getName(key)
            if key == "backspace" then
                input = string.sub(input, 1, #input-1)
            else
                if key == "enter" then
                    term.setCursorBlink(false)
                    break
                end
            end
            os.sleep(0)
        end
    end
    function b()
        while true do
            local event, key = os.pullEvent("char")
            input = input..key
            os.sleep(0)
        end
    end
    parallel.waitForAny(a,b)
    local x,y = term.getCursorPos()
    term.setCursorPos(1,y+1)
    return input
end

local spi = mysplit(args[1], "@")
local username = spi[1]
local port = tonumber(spi[2])
local id = math.random(1000, 9999)

function receive(filter, timeout)
    local event, side, channel, replyChannel, message, distance
    function m()
        while true do
            local revent, rside, rchannel, rreplyChannel, rmessage, rdistance = os.pullEvent("modem_message")
            if filter(rside, rchannel, rreplyChannel, rmessage, rdistance) then
                event, side, channel, replyChannel, message, distance = revent, rside, rchannel, rreplyChannel, rmessage, rdistance
                break
            end
        end
    end
    function s()
        os.sleep(timeout)
    end
    if timeout ~= nil then
        parallel.waitForAny(m, s)
    else
        m()
    end
    return event, side, channel, replyChannel, message, distance
end

modem.transmit(port, port, {
    mode = "INFO",
    author = id
})

local event, side, channel, replyChannel, message = receive(function(side, channel, replyChannel, message)
    return (message.target == id)
end,5)

if event ~= nil then
    io.write(username.."@"..port.."'s password: ")
    local password = hiddenread()
else
    print("Timed out")
end