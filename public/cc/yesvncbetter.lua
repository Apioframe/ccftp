local args = {...}

function systerm()
    os.queueEvent("terminate")
end

local getSocket = require("socio")
if _G.yesvnc ~= nil then
    if args[1] == "close" then
        term.redirect(yesvnc.prevTerm)
        yesvnc.soc.close()
        print("Connection closed")
        _G.yesvnc = nil
        systerm()
    else
        print("Command not understood")
    end
else
    function copy(table)
        local out = {}
        for k,v in pairs(table) do
            out[k] = v
        end
        return out
    end

    if #args ~= 2 then
        print("Usage: yesvnc.lua <hostname> <id>")
        return
    end
    local soc
    function conn()
        soc = getSocket(args[1])
        soc.emit("computer", "cc", args[2], os.getComputerID())
        soc.emit('subscribe', 'interact', args[2])
        soc.emit('subscribe', 'fs', args[2])
        soc.on("close", function()
            os.shutdown()
        end)
    end

    conn()
    print("Connected")

    _G.yesvnc = {soc=soc}

    --Graphics

    local function newGPU(w,h,original)
        local ngpu = {}
        ngpu.w = w
        ngpu.h = h
        ngpu.original = original
        ngpu.lines = {}
        ngpu.colors = {}
        ngpu.bgColors = {}

        ngpu.cursorX = 1
        ngpu.cursorY = 1
        ngpu.cursorBlink = false
        ngpu.textColor = "0"
        ngpu.bgColor = "f"

        ngpu.dirty = false

        function ngpu.canUseOriginal()
            local w,h = original.getSize()
            if w ~= ngpu.w or h ~= ngpu.h then
                return false
            end
            return true
        end

        function ngpu.write(text)
            --if type(text) ~= "string" then error("bad argument #1 (string expected, got " .. type(text) .. ")", 2) end
            text = tostring(text)
            if ngpu.canUseOriginal() then
                ngpu.original.write(text)
            end
            ngpu.dirty = true

            local ltext = ngpu.lines[ngpu.cursorY]
            local lcolor = ngpu.colors[ngpu.cursorY]
            local lbgColor = ngpu.bgColors[ngpu.cursorY]
            local preStop = ngpu.cursorX - 1
            local preStart = math.min(1, preStop)
            local postStart = ngpu.cursorX + #text
            local postStop = ngpu.w
            ltext = string.sub(ltext, preStart, preStop)..text..string.sub(ltext, postStart, postStop)
            lcolor = string.sub(lcolor, preStart, preStop)..string.rep(ngpu.textColor, #text)..string.sub(lcolor, postStart, postStop)
            lbgColor = string.sub(lbgColor, preStart, preStop)..string.rep(ngpu.bgColor, #text)..string.sub(lbgColor, postStart, postStop)
            ngpu.lines[ngpu.cursorY] = ltext
            ngpu.colors[ngpu.cursorY] = lcolor
            ngpu.bgColors[ngpu.cursorY] = lbgColor
            ngpu.cursorX = ngpu.cursorX + #text
            --[[if (ngpu.cursorX > ngpu.w) or (ngpu.cursorX < 1) or (ngpu.cursorX + #text <= 1) or (ngpu.cursorX > ngpu.w) then
                ngpu.cursorX = ngpu.cursorX + #text
                return
            end
            if ngpu.cursorX < 1 then
                text = text:sub(-ngpu.cursorX + 2)
                ngpu.cursorX = 1
            elseif ngpu.cursorX + #text > ngpu.w then
                text = text:sub(1, ngpu.w - ngpu.cursorX + 1)
            end
            local ltext = text[ngpu.cursorY]
            local lcolor = text]]
        end

        function ngpu.scroll(y)
            if type(y) ~= "number" then error("bad argument #1 (number expected, got " .. type(y) .. ")", 2) end
            local empty = string.rep(" ", ngpu.w)
            local emptyColor = string.rep(ngpu.textColor, ngpu.w)
            local emptyBgColor = string.rep(ngpu.bgColor, ngpu.w)
            if y > 0 then
                for i=1,ngpu.h do
                    ngpu.lines[i] = ngpu.lines[i + y] or empty
                    ngpu.colors[i] = ngpu.colors[i + y] or emptyColor
                    ngpu.bgColors[i] = ngpu.bgColors[i + y] or emptyBgColor
                end
            elseif y < 0 then
                for i=ngpu.h,1,-1 do
                    ngpu.lines[i] = ngpu.lines[i + y] or empty
                    ngpu.colors[i] = ngpu.colors[i + y] or emptyColor
                    ngpu.bgColors[i] = ngpu.bgColors[i + y] or emptyBgColor
                end
            end
            ngpu.dirty = true
            if ngpu.canUseOriginal() then
                return ngpu.original.scroll(y)
            end
        end

        function ngpu.getCursorPos()
            return ngpu.cursorX, ngpu.cursorY
        end

        function ngpu.setCursorPos(x,y)
            if type(x) ~= "number" then error("bad argument #1 (number expected, got " .. type(x) .. ")", 2) end
            if type(y) ~= "number" then error("bad argument #2 (number expected, got " .. type(y) .. ")", 2) end
            if x ~= ngpu.cursorX or y ~= ngpu.cursorY then
                ngpu.cursorX = x
                ngpu.cursorY = y
                ngpu.dirty = true
            end
            if ngpu.canUseOriginal() then
                return ngpu.original.setCursorPos(x,y)
            end
        end

        function ngpu.getCursorBlink()
            return ngpu.cursorBlink
        end 

        function ngpu.setCursorBlink(blink)
            if type(blink) ~= "boolean" then error("bad argument #1 (boolean expected, got " .. type(blink) .. ")", 2) end
            if ngpu.cursorBlink ~= blink then
                ngpu.cursorBlink = blink
                ngpu.dirty = true
            end
            if ngpu.canUseOriginal() then
                return ngpu.original.setCursorBlink(blink)
            end
        end

        function ngpu.getSize()
            return ngpu.w, ngpu.h
        end

        function ngpu.clear()
            local empty = string.rep(" ", ngpu.w)
            local emptyColor = string.rep(ngpu.textColor, ngpu.w)
            local emptyBgColor = string.rep(ngpu.bgColor, ngpu.w)
            for i=1,ngpu.h do
                ngpu.lines[i] = empty
                ngpu.colors[i] = emptyColor
                ngpu.bgColors[i] = emptyBgColor
            end
            dirty = true
            if ngpu.canUseOriginal() then
                return ngpu.original.clear()
            end
        end

        function ngpu.clearLine()
            local empty = string.rep(" ", ngpu.w)
            local emptyColor = string.rep(ngpu.textColor, ngpu.w)
            local emptyBgColor = string.rep(ngpu.bgColor, ngpu.w)
            
            ngpu.lines[ngpu.cursorY] = empty
            ngpu.colors[ngpu.cursorY] = emptyColor
            ngpu.bgColors[ngpu.cursorY] = emptyBgColor

            dirty = true
            if ngpu.canUseOriginal() then
                return ngpu.original.clearLine()
            end
        end

        function ngpu.getTextColor()
            return 2 ^ tonumber(ngpu.textColor, 16)
        end
        ngpu.getTextColour = ngpu.getTextColor

        function ngpu.getBackgroundColor()
            return 2 ^ tonumber(ngpu.bgColor, 16)
        end
        ngpu.getBackgroundColour = ngpu.getBackgroundColor

        function ngpu.setTextColor(color)
            if type(color) ~= "number" then error("bad argument #1 (number expected, got " .. type(color) .. ")", 2) end
            local newColor = colors.toBlit(color) or error("Invalid color (got "..color..")", 2)
            if newColor ~= ngpu.textColor then
                ngpu.textColor = newColor
                dirty = true
            end
            if ngpu.canUseOriginal() then
                return ngpu.original.setTextColor(color)
            end
        end
        ngpu.setTextColour = ngpu.setTextColor

        function ngpu.setBackgroundColor(color)
            if type(color) ~= "number" then error("bad argument #1 (number expected, got " .. type(color) .. ")", 2) end
            local newColor = colors.toBlit(color) or error("Invalid color (got "..color..")", 2)
            if newColor ~= ngpu.bgColor then
                ngpu.bgColor = newColor
                dirty = true
            end
            if ngpu.canUseOriginal() then
                return ngpu.original.setBackgroundColor(color)
            end
        end
        ngpu.setBackgroundColour = ngpu.setBackgroundColor

        function ngpu.isColor()
            return ngpu.original.isColor()
        end
        ngpu.isColour = ngpu.isColor

        function ngpu.blit(text, tc, bc)
            if type(text) ~= "string" then error("bad argument #1 (string expected, got " .. type(text) .. ")", 2) end
            if type(tc) ~= "string" then error("bad argument #2 (string expected, got " .. type(tc) .. ")", 2) end
            if type(bc) ~= "string" then error("bad argument #3 (string expected, got " .. type(bc) .. ")", 2) end
            text = tostring(text)
            if ngpu.canUseOriginal() then
                ngpu.original.blit(text, tc, bc)
            end
            ngpu.dirty = true

            local ltext = ngpu.lines[ngpu.cursorY]
            local lcolor = ngpu.colors[ngpu.cursorY]
            local lbgColor = ngpu.bgColors[ngpu.cursorY]
            local preStop = ngpu.cursorX - 1
            local preStart = math.min(1, preStop)
            local postStart = ngpu.cursorX + #text
            local postStop = ngpu.w
            ltext = string.sub(ltext, preStart, preStop)..text..string.sub(ltext, postStart, postStop)
            lcolor = string.sub(lcolor, preStart, preStop)..tc..string.sub(lcolor, postStart, postStop)
            lbgColor = string.sub(lbgColor, preStart, preStop)..bc..string.sub(lbgColor, postStart, postStop)
            ngpu.lines[ngpu.cursorY] = ltext
            ngpu.colors[ngpu.cursorY] = lcolor
            ngpu.bgColors[ngpu.cursorY] = lbgColor
            ngpu.cursorX = ngpu.cursorX + #text
        end

        function ngpu.setPaletteColor(ind, ...)
            return ngpu.original.setPaletteColor(ind, ...)
        end
        ngpu.setPaletteColour = ngpu.setPaletteColor

        function ngpu.getPaletteColor(ind, ...)
            return ngpu.original.getPaletteColor(ind, ...)
        end
        ngpu.getPaletteColour = ngpu.getPaletteColor

        return ngpu
    end

    local previous_term, parent_term = term.current()
    local w,h = term.getSize()
    local guppa = newGPU(w,h,previous_term)
    guppa.clear()
    guppa.setCursorPos(1,1)
    term.redirect(guppa)

    --[[
        ngpu.w = w
        ngpu.h = h
        ngpu.original = original
        ngpu.lines = {}
        ngpu.colors = {}
        ngpu.bgColors = {}

        ngpu.cursorX = 0
        ngpu.cursorY = 0
        ngpu.cursorBlink = false
        ngpu.textColor = "0"
        ngpu.bgColor = "f"

        ngpu.dirty = false
    ]]

    function transmat()
        soc.emit("screen", args[2], {
            lines=guppa.lines,
            colors=guppa.colors,
            bgColors=guppa.bgColors,
            cursorX = guppa.cursorX,
            cursorY = guppa.cursorY,
            cursorBlink = guppa.cursorBlink,
            w=guppa.w,
            h=guppa.h
        })
        guppa.dirty = false
    end

    function taack()
        while true do
            if guppa.dirty then
                transmat()
            end
            os.sleep(0.1)
        end
    end

    soc.on('interact', function(evnt, ...)
        local irgs = {...}
        if evnt == "click" then
            os.queueEvent("mouse_click", 1, irgs[1]+1, irgs[2]+1)
        end
        if evnt == "keydown" then
            os.queueEvent("key", keys[irgs[1]],false)
            if #irgs[1] == 1 then
                os.queueEvent("char", irgs[1])
            end
        end
        if evnt == "scroll" then
            os.queueEvent("mouse_scroll", irgs[1], irgs[2], irgs[3])
        end
        if evnt == "terminate" then
            systerm()
        end
    end)

    soc.on('ping', function(mode)
        if mode == "screen" then
            transmat()
        end
    end)

    --Filesystem (Coming soon)
    function recusive(dir, callback)
        local files = fs.list(dir)
        for k,v in ipairs(files) do
            local path = dir..v
            if fs.isDir(path) then
                recusive(path.."/", callback)
            else
                callback(path)
            end
        end
    end

    soc.on('fs', function(cid, evnt, ...)
        local irgs = {...}
        if evnt == "tree" then
            local out = {}
            recusive("/", function(path)
                table.insert(out, path)
            end)
            soc.emit('fsres', args[2], cid, "tree", out)
        end
        if evnt == "list" then
            local pout = fs.list(irgs[1])
            local dirs = {}
            local files = {}
            for k,v in ipairs(pout) do
                local path = irgs[1]..v
                if fs.isDir(path) then
                    table.insert(dirs, v)
                else
                    table.insert(files, v)
                end
            end
            soc.emit('fsres', args[2], cid, "list", {dirs = dirs, files = files})
        end
        if evnt == "nfi" then
            if not fs.exists(irgs[1]) then
                local h = fs.open(irgs[1], "w")
                h.write("")
                h.close()
            end
        end
        if evnt == "nfo" then
            if not fs.exists(irgs[1]) then
                fs.makeDir(irgs[1])
            end
        end
        if evnt == "del" then
            if fs.exists(irgs[1]) then
                fs.delete(irgs[1])
            end
        end
        if evnt == "read" then
            if fs.exists(irgs[1]) then
                local hand = fs.open(irgs[1], "r")
                soc.emit('fsres', args[2], cid, "read", irgs[1], hand.readAll())
                hand.close()
            end
        end
        if evnt == "save" then
            if fs.exists(irgs[1]) then
                local hand = fs.open(irgs[1], "w")
                hand.write(irgs[2])
                hand.close()
            end
        end
    end)

    yesvnc.prevTerm = previous_term

    --Other
    function a()
        local stat, err = pcall(taack)
        if yesvnc ~= nil then
            --print(err)
            a()
        else
            term.clear()
            term.setCursorPos(1,1)
        end
        
        --[[term.redirect(previous_term)
        yesvnc.soc.close()
        print("Connection closed")
        _G.yesvnc = nil]]
    end
    function b()
        local stat, err = pcall(shell.run, "shell")
        if yesvnc ~= nil then
            --print(err)
            b()
        else
            term.clear()
            term.setCursorPos(1,1)
        end
        
        --[[term.redirect(previous_term)
        yesvnc.soc.close()
        print("Connection closed")
        _G.yesvnc = nil]]
    end
    function c()
        local stat, err = pcall(soc.async, true)
        if yesvnc ~= nil then
            --print(err)
            c()
        else
            term.clear()
            term.setCursorPos(1,1)
        end
        
        --[[term.redirect(previous_term)
        yesvnc.soc.close()
        print("Connection closed")
        _G.yesvnc = nil]]
    end

    parallel.waitForAny(a,b,c)
end