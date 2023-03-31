local args = {...}

local getSocket = require("socio")
if _G.yesvnc ~= nil then
    if args[1] == "close" then
        yesvnc.soc.close()
        print("Connection closed")
        _G.yesvnc = nil
    else
        print("Command not understood")
    end
else
    if #args ~= 2 then
        print("Usage: yesvnc.lua <hostname> <id>")
        return
    end
    local soc
    function conn()
        soc = getSocket(args[1])
        soc.emit("computer", "cc", args[2], os.getComputerID())
        soc.on("close", function()
            os.shutdown()
        end)
        _G.yesvnc = {soc=soc}
    end

    conn()
    print("Connected")
end