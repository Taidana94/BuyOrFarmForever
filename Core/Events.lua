-- One event frame for the whole addon, plus client-neutral signals.
-- WoW event handlers are called with (event, ...), signal handlers with (signal, ...).
-- An error in one handler is logged, passed to the client's error handler and does not
-- stop the other handlers.
local _, ns = ...

local Log = ns.Log

local Events = {}
ns.Events = Events

local handlers = {} -- WoW event -> list of fn
local signalHandlers = {} -- signal -> list of fn
local mappedEvents = {} -- WoW events already forwarded to their signal
local frame = CreateFrame("Frame")

-- Handlers run in xpcall without creating closures or argument tables per event: Lua 5.1's
-- xpcall cannot pass arguments, so each call reads them from a reused context. Contexts are
-- kept per nesting depth because a handler can raise a signal (Emit) while another runs.
local contexts = {}
local depth = 0

local function invoke()
	local c = contexts[depth]
	c.fn(c.name, unpack(c.args, 1, c.count))
end

local function onError(err)
	return Log.ReportError("Error in " .. contexts[depth].name .. " handler: " .. tostring(err))
end

local function callAll(list, name, ...)
	depth = depth + 1
	local c = contexts[depth]
	if not c then
		c = { args = {} }
		contexts[depth] = c
	end
	c.name, c.count = name, select("#", ...)
	for i = 1, c.count do
		c.args[i] = select(i, ...)
	end
	for i = 1, #list do
		c.fn = list[i]
		xpcall(invoke, onError)
	end
	for i = 1, c.count do
		c.args[i] = nil
	end
	c.fn = nil
	depth = depth - 1
end

local function dispatch(_, event, ...)
	local list = handlers[event]
	if not list then
		return
	end
	if Log.IsDebug() then
		Log.Trace("event " .. event)
	end
	callAll(list, event, ...)
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

-- Removes all handlers for a WoW event.
function Events.Off(event)
	if handlers[event] then
		handlers[event] = nil
		mappedEvents[event] = nil
		frame:UnregisterEvent(event)
	end
end

-- Calls all handlers of a signal (used for the WoW events mapped by the adapter; core code may
-- also raise its own signals).
function Events.Emit(signal, ...)
	local list = signalHandlers[signal]
	if list then
		callAll(list, signal, ...)
	end
end

-- Registers fn(signal, ...) for a client-neutral signal. The adapter's events table maps WoW
-- event names to signals, so core code never names WoW events. Signals without a WoW event
-- (internal signals) are only raised by Events.Emit.
-- Returns the number of WoW events that feed this signal.
function Events.OnSignal(signal, fn)
	local list = signalHandlers[signal]
	if not list then
		list = {}
		signalHandlers[signal] = list
	end
	list[#list + 1] = fn

	local map = ns.Client and ns.Client.events
	local count = 0
	if type(map) ~= "table" then
		return count
	end
	for event, mapped in pairs(map) do
		if mapped == signal then
			count = count + 1
			if not mappedEvents[event] then
				mappedEvents[event] = true
				Events.On(event, function(_, ...)
					Events.Emit(signal, ...)
				end)
			end
		end
	end
	return count
end

-- Removes fn from a signal. When the signal has no handlers left, the WoW events that only feed
-- this signal are unregistered (used by windows: register on show, unregister on hide).
function Events.OffSignal(signal, fn)
	local list = signalHandlers[signal]
	if not list then
		return
	end
	for i = #list, 1, -1 do
		if list[i] == fn then
			table.remove(list, i)
		end
	end
	if #list > 0 then
		return
	end
	signalHandlers[signal] = nil
	local map = ns.Client and ns.Client.events
	if type(map) ~= "table" then
		return
	end
	for event, mapped in pairs(map) do
		if mapped == signal then
			Events.Off(event)
		end
	end
end
