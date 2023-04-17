local api = {}
local sga69 = require("sga69")
local parts = 100

function api.transmit(target, modem, port, handle)
    function sendData()
        while true do
            local part = handle.read(parts)
            if not part then break end
            modem.transmit(port, port, {
                mode = "DATA",
                file = target,
                data = part
            })
        end
        handle.seek("set", 1)
        local checksum = sga69(handle.readAll(), 32, 16)
        modem.transmit(port, port, {
            mode = "END",
            file = target,
            checksum = checksum
        })
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
    while true do
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        if message.mode == "DATA" then
            local h = fs.open(message.file, "ab")
            h.write(message.data)
            h.close()
        elseif message.mode == "END" then
            local h = fs.open(message.file, "rb")
            local checksum = sga69(h.readAll(), 32, 16)
            h.close()
            if checksum == message.checksum then
                modem.transmit(port, port, {
                    mode = "DONE"
                })
                break
            else
                modem.transmit(port, port, {
                    mode = "RESEND"
                })
            end
        end
    end
    modem.close(port)
end

return api