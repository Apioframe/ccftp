local modem = peripheral.find("modem")
local sga69 = require("sga69")

local conf = fs.open("ftp.conf", "r")
local confd = textutils.unserialise(conf.readAll())
local port = confd.port
local users = confd.users
local parts = confd.parts
conf.close()

modem.open(port)

function genString(len)
    local abc = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    local out = ""
    for i=1,len,1 do
        local n = math.random(1, #abc)
        out = out..abc:sub(n,n)
    end
    return out
end

local authed = {}

function getUsernameFromToken(token)
    for k,v in pairs(authed) do
        if v == token then
            return k
        end
    end
end

local checksums = {}
local queu = {}

function main()
    while true do
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        if message.mode == "AUTH" then
            if users[message.username] and (users[message.username].password == message.password) then
                local token = genString(32)
                modem.transmit(port, port, {
                    mode = "AUTH",
                    token = token,
                    target = message.author
                })
                authed[message.username] = token
            else
                modem.transmit(port, port, {
                    mode = "ERR",
                    err = "Invalid User or Password",
                    target = message.author
                })
            end
        elseif message.mode == "HELLO" then
            modem.transmit(port, port, {
                mode = "HELLO",
                target = message.author
            })
        elseif message.mode == "LS" then
            if getUsernameFromToken(message.token) ~= nil then
                if fs.exists(message.dir) and fs.isDir(message.dir) then
                    local dirr = fs.list(message.dir)
                    modem.transmit(port, port, {
                        mode = "LS",
                        data = dirr,
                        target = message.author
                    })
                else
                    modem.transmit(port, port, {
                        mode = "ERR",
                        err = "Dir not exists",
                        target = message.author
                    })
                end
            else
                modem.transmit(port, port, {
                    mode = "ERR",
                    err = "Not authenticated",
                    target = message.author
                })
            end
        elseif message.mode == "PUT" then
            if getUsernameFromToken(message.token) ~= nil then
                if not fs.exists(message.file) then
                    checksums[message.file] = {}
                    modem.transmit(port, port, {
                        mode = "PUT",
                        target = message.author
                    })
                else
                    modem.transmit(port, port, {
                        mode = "ERR",
                        err = "File already exists",
                        target = message.author
                    })
                end
            else
                modem.transmit(port, port, {
                    mode = "ERR",
                    err = "Not authenticated",
                    target = message.author
                })
            end
        elseif message.mode == "DATA" then
            if getUsernameFromToken(message.token) ~= nil then
                local h = fs.open(message.file, "ab")
                h.write(message.data)
                table.insert(checksums[message.file], {
                    data=message.data,
                    globall=message.hash,
                    msgprevHash=message.prevHash,
                })
                h.close()
            else
                modem.transmit(port, port, {
                    mode = "ERR",
                    err = "Not authenticated",
                    target = message.author
                })
            end
        elseif message.mode == "DEL" then
            if getUsernameFromToken(message.token) ~= nil then
                if fs.exists(message.file) then
                    fs.delete(message.file)
                    modem.transmit(port, port, {
                        mode = "DEL",
                        target = message.author
                    })
                else
                    modem.transmit(port, port, {
                        mode = "ERR",
                        err = "File not exists",
                        target = message.author
                    })
                end
            else
                modem.transmit(port, port, {
                    mode = "ERR",
                    err = "Not authenticated",
                    target = message.author
                })
            end
        elseif message.mode == "MKDIR" then
            if getUsernameFromToken(message.token) ~= nil then
                if not fs.exists(message.file) then
                    fs.makeDir(message.file)
                    modem.transmit(port, port, {
                        mode = "MKDIR",
                        target = message.author
                    })
                else
                    modem.transmit(port, port, {
                        mode = "ERR",
                        err = "File already exists",
                        target = message.author
                    })
                end
            else
                modem.transmit(port, port, {
                    mode = "ERR",
                    err = "Not authenticated",
                    target = message.author
                })
            end
        elseif message.mode == "END" then
            if getUsernameFromToken(message.token) ~= nil then
                local resend = false
                local prevHash = ""
                print("Verifying...")
                for k,v in ipairs(checksums[message.file]) do
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
                    modem.transmit(port, port, {
                        mode = "DONE",
                        target = message.author
                    })
                else
                    modem.transmit(port, port, {
                        mode = "RESEND",
                        target = message.author
                    })
                    resend = false
                end
            else
                modem.transmit(port, port, {
                    mode = "ERR",
                    err = "Not authenticated",
                    target = message.author
                })
            end
        elseif message.mode == "GET" then
            if getUsernameFromToken(message.token) ~= nil then
                if fs.exists(message.file) then
                    table.insert(queu, {
                        file = message.file,
                        target = message.author
                    })
                    modem.transmit(port, port, {
                        mode = "GET",
                        target = message.author
                    })
                end
            else
                modem.transmit(port, port, {
                    mode = "ERR",
                    err = "Not authenticated",
                    target = message.author
                })
            end
        elseif message.mode == "ISEXISTS" then
            if fs.exists(message.file) then
                modem.transmit(port, port, {
                    mode = "EXISTS",
                    exists = true,
                    target = message.author
                })
            else
                modem.transmit(port, port, {
                    mode = "EXISTS",
                    exists = false,
                    target = message.author
                })
            end
        elseif message.mode == "ISDIR" then
            if fs.isDir(message.file) then
                modem.transmit(port, port, {
                    mode = "DIR",
                    dir = true,
                    target = message.author
                })
            else
                modem.transmit(port, port, {
                    mode = "DIR",
                    dir = false,
                    target = message.author
                })
            end
        else
            modem.transmit(port, port, {
                mode = "ERR",
                err = "Invalid mode",
                target = message.author
            })
        end
    end
end

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
                data = part,
                hash = hash,
                prevHash = prevHash,
                target = target
            })
            prevHash = hash
            if i % 50 == 0 then
                local percent = (handle.seek("cur") / fend) * 100
                print((math.floor(percent*100)/100).."% ("..handle.seek("cur").."/"..fend..")")
                modem.transmit(port, port, {
                    mode = "PERCENT",
                    percent = (math.floor(percent*100)/100).."% ("..handle.seek("cur").."/"..fend..")",
                    target = target
                })
                os.sleep(0.1)
            end
            i = i + 1
        end
        os.sleep(0.1)
        local percent = (handle.seek("cur") / fend) * 100
        print((math.floor(percent*100)/100).."% ("..handle.seek("cur").."/"..fend..")")
        modem.transmit(port, port, {
            mode = "PERCENT",
            percent = (math.floor(percent*100)/100).."% ("..handle.seek("cur").."/"..fend..")",
            target = target
        })
        modem.transmit(port, port, {
            mode = "END",
            target = target
        })
    end
    sendFile()
    handle.close()
end

function fileUploader()
    while true do
        if queu[1] ~= nil then
            uploadFile(queu[1].file, queu[1].target)
            table.remove(queu, 1)
        end
        os.sleep(0)
    end
end

parallel.waitForAny(main, fileUploader)