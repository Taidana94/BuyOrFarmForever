-- Play session of a character for the summary at the next login: gold gained and spent, online
-- time and farm runs. The session is kept in memory and written to characters[charKey].lastSession
-- at logout. A login within RELOAD_GRACE_SECONDS of that write is a /reload and continues the
-- session. Pure logic; times are server time in seconds, passed in by the caller.
local _, ns = ...

local Session = {}
ns.Session = Session

Session.RELOAD_GRACE_SECONDS = 60

local function newSession(now)
	return { startedAt = now, gained = 0, spent = 0, seconds = 0, endedAt = now }
end

-- Starts or continues the session at login. Returns the session and the previous one (nil after a
-- /reload, when the stored session is continued).
function Session.Begin(charData, now)
	local last = charData.lastSession
	if last and now - last.endedAt <= Session.RELOAD_GRACE_SECONDS then
		return ns.Util.CopyTable(last), nil
	end
	return newSession(now), last
end

function Session.AddMoney(session, delta)
	if delta > 0 then
		session.gained = session.gained + delta
	else
		session.spent = session.spent - delta
	end
end

function Session.AddTime(session, seconds)
	session.seconds = session.seconds + seconds
end

-- Number of farm runs of the character saved since the session started.
function Session.CountRuns(db, charKey, session)
	local runs = 0
	for _, run in ipairs(db.farmRuns) do
		if run.charKey == charKey and run.endedAt >= session.startedAt then
			runs = runs + 1
		end
	end
	return runs
end

-- Stores the session at logout.
function Session.End(charData, session, now, runs)
	session.endedAt = now
	session.runs = runs
	charData.lastSession = ns.Util.CopyTable(session)
end

-- Validation (registered with DB.VALIDATORS): a broken stored session is dropped.
local FIELDS = { "startedAt", "endedAt", "gained", "spent", "seconds" }

function Session.Sanitize(charData, path, repairs)
	local last = charData.lastSession
	if last == nil then
		return
	end
	local valid = type(last) == "table"
	for _, field in ipairs(FIELDS) do
		valid = valid and type(last[field]) == "number" and last[field] >= 0
	end
	if not valid then
		charData.lastSession = nil
		repairs[#repairs + 1] = path .. ".lastSession"
	end
end

ns.DB.VALIDATORS[#ns.DB.VALIDATORS + 1] = Session.Sanitize
