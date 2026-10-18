-- Chat output and the debug log (ring buffer in the SavedVariables).
-- Log messages are technical English for development; everything the user is meant
-- to read goes through Log.Print with localized text (see docs/LOCALIZATION.md).
local _, ns = ...

local L = ns.L

local Log = {}
ns.Log = Log

Log.MAX_ENTRIES = 200

-- Entries collected before the database is available (or while it is read-only).
local pending = {}

local function now()
	local client = ns.Client
	if client and client.GetServerTime then
		return client:GetServerTime()
	end
	return 0
end

local function output(text)
	local frame = DEFAULT_CHAT_FRAME
	if frame and frame.AddMessage then
		frame:AddMessage(text)
	end
end

local function trim(list)
	while #list > Log.MAX_ENTRIES do
		table.remove(list, 1)
	end
end

local function target()
	local db = ns.db
	if db and not ns.readOnly and type(db.debugLog) == "table" then
		return db.debugLog
	end
	return pending
end

local function store(level, message)
	local list = target()
	list[#list + 1] = { at = now(), level = level, msg = tostring(message) }
	trim(list)
end

function Log.IsDebug()
	local db = ns.db
	return db ~= nil and type(db.settings) == "table" and db.settings.debug == true
end

-- Prints a user-facing (localized) message with the addon prefix.
function Log.Print(text)
	output("|cff33ff99" .. L.ADDON_TITLE .. "|r: " .. tostring(text))
end

-- Moves entries collected before the database was ready into the database.
function Log.Flush()
	local list = target()
	if list == pending then
		return
	end
	for i = 1, #pending do
		list[#list + 1] = pending[i]
	end
	pending = {}
	trim(list)
end

-- Errors and warnings are always stored. Info and trace only in debug mode.
function Log.Error(message)
	store("ERROR", message)
end

function Log.Warn(message)
	store("WARN", message)
end

function Log.Info(message)
	if Log.IsDebug() then
		store("INFO", message)
	end
end

-- Stored in debug mode, never printed (for frequent events).
function Log.Trace(message)
	if Log.IsDebug() then
		store("TRACE", message)
	end
end

-- Stored and printed in debug mode.
function Log.Debug(message)
	if Log.IsDebug() then
		store("DEBUG", message)
		output("|cff33ff99" .. L.ADDON_TITLE .. "|r " .. L.DEBUG_PREFIX .. " " .. tostring(message))
	end
end

-- Logs an error and passes it to the client's error handler (BugSack/BugGrabber or the
-- default error frame), so errors are never silently swallowed.
function Log.ReportError(message)
	message = tostring(message)
	Log.Error(message)
	local handler = geterrorhandler and geterrorhandler()
	if handler then
		handler(message)
	end
	return message
end
