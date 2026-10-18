-- One event frame for the whole addon. Handlers are called with (event, ...).
-- An error in one handler is logged, passed to the client's error handler and does not
-- stop the other handlers for the same event.
local _, ns = ...

local Log = ns.Log

local Events = {}
ns.Events = Events

local handlers = {}
local frame = CreateFrame("Frame")

local function dispatch(_, event, ...)
	local list = handlers[event]
	if not list then
		return
	end
	Log.Trace("event " .. event)
	local count = select("#", ...)
	local args = { ... }
	for i = 1, #list do
		local fn = list[i]
		xpcall(function()
			fn(event, unpack(args, 1, count))
		end, function(err)
			return Log.ReportError("Error in " .. event .. " handler: " .. tostring(err))
		end)
	end
end

frame:SetScript("OnEvent", dispatch)

function Events.On(event, fn)
	local list = handlers[event]
	if not list then
		list = {}
		handlers[event] = list
		frame:RegisterEvent(event)
	end
	list[#list + 1] = fn
end

-- Registers fn(signal, ...) for a client-neutral signal (e.g. "BANK_OPENED"). The adapter's
-- events table maps WoW event names to signals, so core code never names WoW events.
-- Returns the number of WoW events that were registered for the signal.
function Events.OnSignal(signal, fn)
	local map = ns.Client and ns.Client.events
	local count = 0
	if type(map) ~= "table" then
		return count
	end
	for event, mapped in pairs(map) do
		if mapped == signal then
			Events.On(event, function(_, ...)
				fn(signal, ...)
			end)
			count = count + 1
		end
	end
	return count
end

-- Removes all handlers for an event.
function Events.Off(event)
	if handlers[event] then
		handlers[event] = nil
		frame:UnregisterEvent(event)
	end
end
