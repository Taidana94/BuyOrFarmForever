-- Recipe book of a character for the gold planner: every recipe seen in an open profession window
-- (characters[key].recipeBook[recipeKey] = { cooldown = true?, readyAt = server time? }), the recipe
-- data itself in db.recipes (shared, Recipes.Store). Recipes with a cooldown are known as such once
-- the window showed a remaining cooldown; readyAt is when they can be used again.
-- Captured on profession window events, coalesced to one read per CAPTURE_DELAY_SECONDS.
local _, ns = ...

local Events = ns.Events
local Recipes = ns.Recipes

local RecipeBook = {}
ns.RecipeBook = RecipeBook

RecipeBook.MAX_RECIPES = 500
RecipeBook.CAPTURE_DELAY_SECONDS = 1

local function count(book)
	local n = 0
	for _ in pairs(book) do
		n = n + 1
	end
	return n
end

local function noteCooldown(entry, cooldownSeconds, now)
	if type(cooldownSeconds) == "number" and cooldownSeconds > 0 then
		entry.cooldown, entry.readyAt = true, now + cooldownSeconds
	elseif entry.cooldown then
		entry.readyAt = now
	end
end

-- Adds the recipes (raw adapter data with cooldownSeconds) to the book of a character. Recipes
-- without an item (enchantments) cannot be sold and are skipped. Returns the number added.
function RecipeBook.Add(db, charData, rawRecipes, now)
	local book, added, size = charData.recipeBook, 0, count(charData.recipeBook)
	for _, raw in ipairs(rawRecipes) do
		local recipe = Recipes.Normalize(raw)
		local isNew = recipe and not book[recipe.key]
		if recipe and recipe.outputItemID ~= 0 and (not isNew or size < RecipeBook.MAX_RECIPES) then
			Recipes.Store(db, recipe, now)
			book[recipe.key] = book[recipe.key] or {}
			noteCooldown(book[recipe.key], raw.cooldownSeconds, now)
			if isNew then
				added, size = added + 1, size + 1
			end
		end
	end
	return added
end

-- Recipes of the book whose cooldown is over (cooldown recipes only), as recipe keys.
function RecipeBook.ReadyCooldowns(charData, now)
	local ready = {}
	for key, entry in pairs(charData.recipeBook) do
		if entry.cooldown and (entry.readyAt or 0) <= now then
			ready[#ready + 1] = key
		end
	end
	table.sort(ready)
	return ready
end

-- Validation of the stored book (registered with DB.VALIDATORS).
local function sanitize(charData, path, repairs)
	for key, entry in pairs(charData.recipeBook) do
		local valid = Recipes.IsValidKey(key) and type(entry) == "table"
			and (entry.cooldown == nil or entry.cooldown == true)
			and (entry.readyAt == nil or type(entry.readyAt) == "number")
		if not valid then
			charData.recipeBook[key] = nil
			repairs[#repairs + 1] = path .. ".recipeBook"
		end
	end
end

ns.DB.VALIDATORS[#ns.DB.VALIDATORS + 1] = sanitize

local pending = false

local function capture()
	pending = false
	local charData = ns.db and not ns.readOnly and ns.charKey and ns.db.characters[ns.charKey]
	if charData then
		RecipeBook.Add(ns.db, charData, (ns.Client:ReadAllRecipes()), ns.Client:GetServerTime())
	end
end

-- Profession window updates come in bursts (every cast, every filter change): one read per delay.
local function requestCapture()
	if not pending then
		pending = true
		C_Timer.After(RecipeBook.CAPTURE_DELAY_SECONDS, capture)
	end
end

if ns.Client then
	Events.OnSignal("PROFESSION_OPENED", requestCapture)
	Events.OnSignal("PROFESSION_CHANGED", requestCapture)
end
