local api = {}
local sga69 = require("sga69")
local parts = 500

function api.transmit(target, modem, port, handle)
    function sendData()
        modem.transmit(port, port, {
            mode = "BEGIN",
            file = target
        })
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
                prevHash = prevHash
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
        })
        print("Verifying...")
        modem.open(port)
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        if message.mode == "RESEND" then
            sendData()
        end
        modem.close(port)
    end
    sendData()
    handle.close()
end

function api.receive(modem, port)
    modem.open(port)
    local hashs = {}
    local fil = nil
    while true do
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        if message.mode == "DATA" then
            local h = fs.open(fil, "ab")
            h.write(message.data)
            table.insert(hashs, {
                data=message.data,
                globall=message.hash,
                msgprevHash=message.prevHash,
            })
            h.close()
        elseif message.mode == "BEGIN" then
            if fs.exists(message.file) then
                if fil == nil then
                    fil = message.file
                end
                fs.delete(message.file)
            end
        elseif message.mode == "END" then
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
                modem.transmit(port, port, {
                    mode = "DONE"
                })
                break
            else
                modem.transmit(port, port, {
                    mode = "RESEND"
                })
                resend = false
            end
        end
    end
    modem.close(port)
end

return api