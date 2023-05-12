local getEventHandler = require("eh")

function getSocket(uri)
    local soc = {}
    soc.ws = http.websocket(uri)
    soc.eh = getEventHandler()
    soc.close = function()
        if (soc.ws ~= nil) and (type(soc.ws) ~= "boolean") then
            soc.ws.close()
        end
    end
    soc.on = function(...) soc.eh.on(...) end
    soc.off = function(...) soc.eh.off(...) end
    soc.emit = function(...)
        if (soc.ws ~= nil) and (type(soc.ws) ~= "boolean") then
            local data = {...}
            soc.ws.send(textutils.serialiseJSON(data))
        end
    end

    soc.async = function(termi, nstop)
        while true do
            if (soc.ws ~= nil) and (type(soc.ws) ~= "boolean") then
                local stat,dat = pcall(soc.ws.receive)
                if not stat then
					if termi == true then
						if dat ~= "Terminated" then
							soc.eh.call("close")
							if nstop ~= true then
								break
							end
						end
					else
						soc.eh.call("close")
						if nstop ~= true then
							break
						end
					end
                else
                    if dat ~= nil then
                        local data = textutils.unserialiseJSON(dat)
                        soc.eh.call(table.unpack(data))
                    else
                        soc.eh.call("close")
                        if nstop ~= true then
                            break
                        end
                    end
                end
            else
                os.sleep(1)
            end
        end
    end
    return soc
end

return getSocket