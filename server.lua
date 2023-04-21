--CONFIG
local port = 2222
local users = {
    ["root"]={
        password = "root"
    }
}
--CODE
local modem = peripheral.find("modem")
local sga69 = require("sga69")

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
    else
        modem.transmit(port, port, {
            mode = "ERR",
            err = "Invalid mode",
            target = message.author
        })
    end
end