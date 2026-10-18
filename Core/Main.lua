-- Startup: SavedVariables on ADDON_LOADED, character data on PLAYER_LOGIN.
-- Loaded last. Does nothing if no adapter matched the running client.
local addonName, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util

local function onAddonLoaded(event, loadedName)
	if loadedName ~= addonName then
		return
	end
	ns.Events.Off(event)

	local client = ns.Client
	local version = client:GetAddOnVersion(addonName) or ""
	local db, status, info = ns.DB.Load(BuyOrFarmForeverDB, {
		client = client.id,
		now = client:GetServerTime(),
		addonVersion = version,
	})
	BuyOrFarmForeverDB = db
	ns.db = db
	ns.readOnly = (status == "newer" or status == "migration_failed")
	Log.Flush()
	Log.Info("loaded " .. addonName .. " " .. version .. ", database status " .. status)

	if status == "newer" then
		Log.Print(L.DB_NEWER_SCHEMA)
		Log.Warn("stored schema " .. tostring(db.schemaVersion) .. " is newer than " .. ns.DB.SCHEMA_VERSION)
	elseif status == "migration_failed" then
		Log.Print(L.DB_MIGRATION_FAILED)
		Log.ReportError("BuyOrFarmForever: " .. tostring(info.error))
	end
	if #info.repairs > 0 then
		Log.Print(Util.Format(L.DB_REPAIRED, #info.repairs))
		for _, path in ipairs(info.repairs) do
			Log.Warn("repaired invalid value: " .. path)
		end
	end
	if info.otherClient then
		Log.Warn("saved data was created by client " .. info.otherClient)
	end
end

local function onPlayerLogin(event)
	ns.Events.Off(event)
	local client = ns.Client
	local character = client:GetCharacterKey()
	if not character then
		Log.Warn("character key not available at PLAYER_LOGIN")
		return
	end
	ns.charKey = character.key
	if ns.db and not ns.readOnly then
		ns.DB.EnsureCharacter(ns.db, character.key, character.faction)
	end
	local build = client:GetBuildInfo()
	Log.Info(string.format(
		"client %s %s (%s), interface %s, locale %s, character %s",
		client.id,
		tostring(build.version),
		tostring(build.build),
		tostring(build.interface),
		ns.Locale.GetActive(),
		character.key
	))
end

if ns.Client then
	ns.Slash.Register()
	ns.Events.On("ADDON_LOADED", onAddonLoaded)
	ns.Events.On("PLAYER_LOGIN", onPlayerLogin)
end
