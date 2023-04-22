local args = {...}
local modem = peripheral.find("modem")
local sga69 = require("sga69")

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

function uploadFile(file, target)
    local handle = fs.open(file, "rb")
    local function sendFile()
        local prevHash = ""
        local fend = handle.seek("end")
        handle.seek("set", 0)
        local i = 1
        while true do
            local part = handle.read(parts)
            if not part then break end
            local hash = sga69(part, 32, 16)
            modem.transmit(port, port, {
                mode = "DATA",
                token = authKey,
                file = target,
                data = part,
                hash = hash,
                prevHash = prevHash,
                author = id
            })
            prevHash = hash
            if i % 50 == 0 then
                local percent = (handle.seek("cur") / fend) * 100
                print((math.floor(percent*100)/100).."% ("..handle.seek("cur").."/"..fend..")")
                os.sleep(0.1)
            end
            i = i + 1
        end
        os.sleep(0.1)
        local percent = (handle.seek("cur") / fend) * 100
        print((math.floor(percent*100)/100).."% ("..handle.seek("cur").."/"..fend..")")
        modem.transmit(port, port, {
            mode = "END",
            token = authKey,
            file = target,
            author = id
        })
        print("Verifying...")
        local ok, data = ftpreceive(function(side, channel, replyChannel, message)
            return (message.mode == "DONE") or (message.mode == "RESEND")
        end)
        if data.mode == "RESEND" then
            print("Resending...")
            sendFile()
        end
    end
    sendFile()
    handle.close()
end

function listenFile(target, fill)
    local hashs = {}
    while true do
        local ok, data = ftpreceive(function(side, channel, replyChannel, message)
            return (message.mode == "DATA") or (message.mode == "END") or (message.mode == "PERCENT")
        end)
        if data.mode == "DATA" then
            local h = fs.open(target, "ab")
            h.write(data.data)
            table.insert(hashs, {
                data=data.data,
                globall=data.hash,
                msgprevHash=data.prevHash,
            })
            h.close()
        elseif data.mode == "PERCENT" then
            print(data.percent)
        elseif data.mode == "END" then
            local resend = false
            local prevHash = ""
            print("Verifying...")
            for k,v in ipairs(hashs) do
                local hash = sga69(v.data, 32, 16)
                if (hash ~= v.globall or prevHash ~= v.msgprevHash) then
                    resend = true
                    break
                end
                prevHash = hash
                if k % 100 == 0 then
                    os.sleep(0.1)
                end
            end
            if not resend then
                break
            else
                sendGet(fill, target)
                resend = false
            end
        end
    end
end

function sendGet(fil, tget)
    modem.transmit(port, port, {
        mode = "GET",
        file = fil,
        token = authKey,
        author = id
    })
    local ok, data = ftpreceive(function(side, channel, replyChannel, message)
        return (message.mode == "GET") or (message.mode == "ERR")
    end)
    if ok then
        print("Waiting for file transfer...")
        listenFile(tget, fil)
    else
        print(data)
    end
end

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
            if #parsed == 2 then 
                dir = "/"..fs.combine(dir, parsed[2] and parsed[2] or "")
            else
                print("Usage: cd <path>")
            end
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
        elseif parsed[1] == "put" then
            if #parsed == 3 then 
                if fs.exists(parsed[2]) then
                    modem.transmit(port, port, {
                        mode = "PUT",
                        file = fs.combine(dir, parsed[3]),
                        token = authKey,
                        author = id
                    })
                    local ok, data = ftpreceive(function(side, channel, replyChannel, message)
                        return (message.mode == "PUT") or (message.mode == "ERR")
                    end)
                    if ok then
                        print("Uploading accepted...")
                        uploadFile(parsed[2], parsed[3])
                    else
                        print(data)
                    end
                else
                    print("File not exists")
                end
            else
                print("Usage: put <localpath> <targetpath>")
            end
        elseif parsed[1] == "del" then
            if #parsed == 2 then 
                modem.transmit(port, port, {
                    mode = "DEL",
                    file = fs.combine(dir, parsed[2]),
                    token = authKey,
                    author = id
                })
                local ok, data = ftpreceive(function(side, channel, replyChannel, message)
                    return (message.mode == "DEL") or (message.mode == "ERR")
                end)
                if ok then
                    print("Success")
                else
                    print(data)
                end
            else
                print("Usage: del <path>")
            end
        elseif parsed[1] == "get" then
            if #parsed == 3 then 
                sendGet(fs.combine(dir, parsed[2]), parsed[3])
            else
                print("Usage: get <targetpath> <localpath>")
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