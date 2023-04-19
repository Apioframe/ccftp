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

modem.open(port)

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

function ftpreceive(filter)
    local event, side, channel, replyChannel, message = receive(function(side, channel, replyChannel, message)
        return (message.target == id) and filter(side, channel, replyChannel, message)
    end,5)
    if message and (message.mode ~= "ERR") then
        return true, message
    else
        if (message == nil) or (message.err == nil) then
            message = {}
            message.err = "Timed out"
        end
        return false, message.err
    end
end

modem.transmit(port, port, {
    mode = "INFO",
    author = id
})

local mevent = receive(function(side, channel, replyChannel, message)
    return (message.target == id)
end,5)

local authKey = ""

function commandHandler()
    local dir = "/"
    while true do
        io.write(username.."@"..port.."#"..dir..">")
        local cmd = io.read()
        local parsed = mysplit(cmd, " ")
        if parsed[1] == "exit" then
            print("Connection closed")
            return
        elseif parsed[1] == "ping" then
            modem.transmit(port, port, {
                mode = "INFO",
                author = id
            })

            local mmevent = receive(function(side, channel, replyChannel, message)
                return (message.target == id)
            end,5)
            if mmevent ~= nil then
                print("Ping: IDKms")
            else
                print("Connection closed")
                return
            end
        elseif parsed[1] == "cd" then
            dir = "/"..fs.combine(dir, parsed[2] and parsed[2] or "")
        elseif parsed[1] == "ls" then
            modem.transmit(port, port, {
                mode = "LS",
                dir = dir,
                token = authKey,
                author = id
            })
            local ok, data = ftpreceive(function(side, channel, replyChannel, message)
                return (message.mode == "LS") or (message.mode == "ERR")
            end)
            if ok then
                for k,v in ipairs(data.data) do
                    print(v)
                end
            else
                print(data)
            end
        end
    end
end

if mevent ~= nil then
    io.write(username.."@"..port.."'s password: ")
    local password = hiddenread()
    local w,h = term.getSize()
    local x,y = term.getCursorPos()
    if h+1 == y then
        print()
    end
    modem.transmit(port, port, {
        mode = "AUTH",
        username = username,
        password = password,
        author = id
    })
    local ok, data = ftpreceive(function(side, channel, replyChannel, message) 
        return (message.mode == "AUTH") or (message.mode == "ERR")
    end)
    if ok then
        authKey = data.token
        commandHandler()
    else
        print(data)
    end
else
    print("Timed out")
end