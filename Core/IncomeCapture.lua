-- Income capture: gold changes (MONEY_CHANGED) and online time of the current character.
-- Online time is counted between checkpoints (login, gold changes, bag changes, logout), each gap
-- capped by Income (an idle or crashed client does not inflate the hours).
-- Assumption to confirm in game: GetMoney() is valid at PLAYER_LOGIN. As a guard, a gain within
-- LOGIN_GRACE_SECONDS after a login that read 0 gold is treated as the initial value, not income.
local _, ns = ...

local Events = ns.Events
local Income = ns.Income

local IncomeCapture = {}
ns.IncomeCapture = IncomeCapture

IncomeCapture.LOGIN_GRACE_SECONDS = 30

local lastMoney, lastCheckpoint, loginAt

local function writableCharacter()
	local db = ns.db
	return db and not ns.readOnly and ns.charKey and db.characters[ns.charKey]
end

local function checkpoint(charData, now)
	if lastCheckpoint then
		Income.RecordTime(charData, lastCheckpoint, now)
	end
	lastCheckpoint = now
end

local function onMoneyChanged()
	local charData = writableCharacter()
	local money = ns.Client:GetMoney()
	if not (charData and money and lastMoney) then
		return
	end
	local now = ns.Client:GetServerTime()
	local delta = money - lastMoney
	local initialValue = lastMoney == 0 and delta > 0 and now - loginAt <= IncomeCapture.LOGIN_GRACE_SECONDS
	if not initialValue then
		Income.RecordChange(charData, delta, now)
	end
	lastMoney = money
	checkpoint(charData, now)
end

local function onActivity()
	local charData = writableCharacter()
	if charData and lastCheckpoint then
		checkpoint(charData, ns.Client:GetServerTime())
	end
end

if ns.Client then
	Events.OnSignal("CHARACTER_READY", function()
		lastMoney = ns.Client:GetMoney()
		loginAt = ns.Client:GetServerTime()
		lastCheckpoint = loginAt
	end)
	Events.OnSignal("MONEY_CHANGED", onMoneyChanged)
	Events.OnSignal("BAGS_CHANGED", onActivity)
	Events.OnSignal("LOGOUT", onActivity)
end
