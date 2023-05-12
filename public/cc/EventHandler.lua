function getEventHandler()
	local eh = {}
	eh.events = {}

	function includes(table, string)
		for k,v in pairs(table) do
			if v == string then
				return true
			end
		end
		return false
	end

	function indexOf(table, string)
		for k,v in pairs(table) do
			if v == string then
				return k
			end
		end
		return nil
	end

	eh.on = function(event, callback)
		if eh.events[event] == nil then
			eh.events[event] = {}
		end
		table.insert(eh.events[event], callback)
	end
	eh.off = function(event, callback)
		if eh.events[event] == nil then
			eh.events[event] = {}
		end
		if includes(eh.events[event], callback) then
			table.remove(eh.events[event], indexOf(eh.events[event], callback))
		end
	end
	eh.off = function(event, callback)
		if eh.events[event] == nil then
			eh.events[event] = {}
		end
		if includes(eh.events[event], callback) then
			table.remove(eh.events[event], indexOf(eh.events[event], callback))
		end
	end
	eh.call = function(event, ...)
		if eh.events[event] == nil then
			eh.events[event] = {}
		end
		for k,v in ipairs(eh.events[event]) do
			v(...)
		end
	end

	return eh
end
return getEventHandler