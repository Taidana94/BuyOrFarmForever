-- Recipe book of a character for the gold planner and the professions view: every recipe seen in an
-- open profession window (characters[key].recipeBook[recipeKey] = { cooldown = true?, readyAt = server
-- time?, profession = key?, difficulty = skill type? }), the recipe data itself in db.recipes (shared,
-- Recipes.Store), and the skill bars (characters[key].professions[key] = { rank, maxRank, at }).
-- Recipes with a cooldown are known as such once the window showed a remaining cooldown; readyAt is
-- when they can be used again. Enchantments (no item) are kept too; users of the book that need an
-- item skip outputItemID 0.
-- Captured on profession window events, coalesced to one read per CAPTURE_DELAY_SECONDS; then the
-- internal signal RECIPES_CHANGED is raised.
local _, ns = ...

local Events = ns.Events
local Recipes = ns.Recipes

local RecipeBook = {}
ns.RecipeBook = RecipeBook

-- Blacksmithing alone has about 300 recipes in Classic Era; the cap only stops runaway growth.
RecipeBook.MAX_RECIPES = 1000
RecipeBook.CAPTURE_DELAY_SECONDS = 1
RecipeBook.MAX_SKILL = 1000

-- Profession keys in display order; OTHER = a window the adapter could not name.
RecipeBook.PROFESSIONS = {
	"ALCHEMY", "BLACKSMITHING", "ENCHANTING", "ENGINEERING", "LEATHERWORKING", "TAILORING", "MINING", "COOKING",
	"FIRST_AID", "POISONS", "OTHER",
}
local PROFESSION_SET = {}
for _, key in ipairs(RecipeBook.PROFESSIONS) do
	PROFESSION_SET[key] = true
end
-- Skill-up colours of the profession windows (orange, yellow, green, gray).
RecipeBook.DIFFICULTIES = { optimal = true, medium = true, easy = true, trivial = true }

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

-- Profession and difficulty as the window showed them; invalid values are not stored.
local function noteWindow(entry, raw)
	if PROFESSION_SET[raw.profession] then
		entry.profession = raw.profession
	end
	entry.difficulty = RecipeBook.DIFFICULTIES[raw.difficulty] and raw.difficulty or nil
end

-- Adds the recipes (raw adapter data with cooldownSeconds, profession, difficulty) to the book of a
-- character. Returns the number added.
function RecipeBook.Add(db, charData, rawRecipes, now)
	local book, added, size = charData.recipeBook, 0, count(charData.recipeBook)
	for _, raw in ipairs(rawRecipes) do
		local recipe = Recipes.Normalize(raw)
		local isNew = recipe and not book[recipe.key]
		if recipe and (not isNew or size < RecipeBook.MAX_RECIPES) then
			Recipes.Store(db, recipe, now)
			book[recipe.key] = book[recipe.key] or {}
			noteCooldown(book[recipe.key], raw.cooldownSeconds, now)
			noteWindow(book[recipe.key], raw)
			if isNew then
				added, size = added + 1, size + 1
			end
		end
	end
	return added
end

local function isSkill(value)
	return type(value) == "number" and value >= 0 and value <= RecipeBook.MAX_SKILL and value == math.floor(value)
end

-- Stores the skill bars (raw adapter data { profession, rank, maxRank }); invalid rows are skipped.
function RecipeBook.SetSkills(charData, rawSkills, now)
	for _, raw in ipairs(rawSkills) do
		if PROFESSION_SET[raw.profession] and isSkill(raw.rank) and isSkill(raw.maxRank) then
			charData.professions[raw.profession] = { rank = raw.rank, maxRank = raw.maxRank, at = now }
		end
	end
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

-- Validation of the stored book and skill bars (registered with DB.VALIDATORS).
local function validEntry(key, entry)
	return Recipes.IsValidKey(key) and type(entry) == "table"
		and (entry.cooldown == nil or entry.cooldown == true)
		and (entry.readyAt == nil or type(entry.readyAt) == "number")
		and (entry.profession == nil or PROFESSION_SET[entry.profession] == true)
		and (entry.difficulty == nil or RecipeBook.DIFFICULTIES[entry.difficulty] == true)
end

local function validSkill(key, skill)
	return PROFESSION_SET[key] and type(skill) == "table" and isSkill(skill.rank) and isSkill(skill.maxRank)
		and type(skill.at) == "number"
end

local function sanitize(charData, path, repairs)
	for key, entry in pairs(charData.recipeBook) do
		if not validEntry(key, entry) then
			charData.recipeBook[key] = nil
			repairs[#repairs + 1] = path .. ".recipeBook"
		end
	end
	for key, skill in pairs(charData.professions) do
		if not validSkill(key, skill) then
			charData.professions[key] = nil
			repairs[#repairs + 1] = path .. ".professions"
		end
	end
end

ns.DB.VALIDATORS[#ns.DB.VALIDATORS + 1] = sanitize

local pending = false

local function capture()
	pending = false
	local charData = ns.db and not ns.readOnly and ns.charKey and ns.db.characters[ns.charKey]
	if charData then
		local now = ns.Client:GetServerTime()
		RecipeBook.Add(ns.db, charData, (ns.Client:ReadAllRecipes()), now)
		RecipeBook.SetSkills(charData, ns.Client:ReadProfessionSkills(), now)
		Events.Emit("RECIPES_CHANGED")
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
