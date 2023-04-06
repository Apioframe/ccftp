local args = {...}

local getSocket = require("socio")

local soc
function conn()
    soc = getSocket(args[1])
    soc.emit('subscribe', 'screen', args[2])
    soc.emit('ping', args[2], "screen")
    soc.on("close", function()
        os.shutdown()
    end)
end

conn()
print("Connected")

local termed = false
function systerm()
    termed = true
    os.queueEvent("terminate")
end

soc.on("screen", function(dat)
    term.clear()
    for i=1,#dat.lines,1 do
        term.setCursorPos(1,i)
        term.blit(dat.lines[i], dat.colors[i], dat.bgColors[i])
    end
end)

function ings()
    local function fing()
        while true do
            local event, key, is_held = os.pullEvent("key")
            key = keys.getName(key)
            if key == "rightAlt" then
                term.clear()
                term.setCursorPos(1,1)
                systerm()
            else
                soc.emit("interact", args[2], 'keydown', key)
            end
        end
    end
    local stat, err = pcall(fing, true)
    if not termed then
        ings()
    end
end
function cons()
    local stat, err = pcall(soc.async, true)
    if not termed then
        cons()
    end
end

parallel.waitForAny(ings, cons)