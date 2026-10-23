-- Classic Era adapter part: contents of the mailbox (items and gold attached to received mail).
-- Loaded before Adapters/ClassicEra.lua, which exposes these functions as adapter methods.
-- GetInboxNumItems, GetInboxHeaderInfo (5th return: money) and GetInboxItem (name, itemID, texture,
-- count, ...) are used this way by the Classic Era MailFrame (Blizzard_UIPanels_Game/Classic/MailFrame.lua,
-- client 70003); the inbox can only be read while the mailbox is open.
local _, ns = ...

local Mail = {}
ns.ClassicEraMail = Mail

-- Attachment slots of a received mail (ATTACHMENTS_MAX_RECEIVE in MailFrame.lua).
local DEFAULT_ATTACHMENTS = 16
-- The client lists at most this many mails in the inbox.
local MAX_MAILS = 50

local function canScan()
	return GetInboxNumItems and GetInboxItem and GetInboxHeaderInfo
end

local function addAttachments(counts, index)
	for attachment = 1, ATTACHMENTS_MAX_RECEIVE or DEFAULT_ATTACHMENTS do
		local _, itemID, _, count = GetInboxItem(index, attachment)
		if itemID and count and count > 0 then
			counts[itemID] = (counts[itemID] or 0) + count
		end
	end
end

-- Fills counts with { [itemID] = count attached to received mail } (cleared first) and returns
-- counts and the gold (copper) attached to the mails. Only meaningful while the mailbox is open.
function Mail.ScanMail(counts)
	for itemID in pairs(counts) do
		counts[itemID] = nil
	end
	if not canScan() then
		return counts, 0
	end
	local money = 0
	for index = 1, math.min(GetInboxNumItems() or 0, MAX_MAILS) do
		local _, _, _, _, mailMoney, _, _, itemCount = GetInboxHeaderInfo(index)
		money = money + (mailMoney or 0)
		if itemCount and itemCount > 0 then
			addAttachments(counts, index)
		end
	end
	return counts, money
end

-- Auction house mails -----------------------------------------------------------------------
-- Recognized by the client's own localized subject templates, e.g. "Auktion erfolgreich: %s". The
-- global names AUCTION_SOLD_MAIL_SUBJECT, AUCTION_EXPIRED_MAIL_SUBJECT and AUCTION_REMOVED_MAIL_SUBJECT
-- come from the client's GlobalStrings and are NOT in the UI source of this project: unverified, used
-- only when present. Mails are never opened (GetInboxText would mark them read).
local SUBJECT_GLOBALS = {
	SOLD = "AUCTION_SOLD_MAIL_SUBJECT", EXPIRED = "AUCTION_EXPIRED_MAIL_SUBJECT", CANCELLED = "AUCTION_REMOVED_MAIL_SUBJECT",
}

-- "Auktion erfolgreich: %s" -> "^Auktion erfolgreich: (.+)$" (magic characters escaped).
local function subjectPattern(template)
	local escaped = template:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"):gsub("%%%%s", "(.+)")
	return "^" .. escaped .. "$"
end

local function subjectPatterns()
	local patterns = {}
	for kind, name in pairs(SUBJECT_GLOBALS) do
		local template = _G[name]
		if type(template) == "string" and template:find("%s", 1, true) then
			patterns[kind] = subjectPattern(template)
		end
	end
	return patterns
end

-- Item id of a cached item by its localized name (C_Item.GetItemInfo takes names of items in the
-- client cache; the player's own auctions are), or nil.
local function itemIDByName(name)
	if not (C_Item and C_Item.GetItemInfo) then
		return nil
	end
	local _, link = C_Item.GetItemInfo(name)
	local _, itemID = ns.Util.ParseLink(link)
	return itemID
end

local function auctionMail(index, patterns)
	local _, _, _, subject, money, _, daysLeft, itemCount = GetInboxHeaderInfo(index)
	for kind, pattern in pairs(patterns) do
		local name = type(subject) == "string" and subject:match(pattern)
		if name then
			local _, itemID, _, count = GetInboxItem(index, 1)
			return { kind = kind, name = name, itemID = itemID or itemIDByName(name), count = itemCount and itemCount > 0
				and count or nil, money = money or 0, daysLeft = daysLeft or 0, subject = subject }
		end
	end
	return nil
end

-- Auction house mails in the open inbox: { { kind = "SOLD" | "EXPIRED" | "CANCELLED", name, itemID?,
-- count?, money, daysLeft, subject } }. Empty without the API or the subject templates.
function Mail.ReadAuctionMails()
	local mails = {}
	if not canScan() then
		return mails
	end
	local patterns = subjectPatterns()
	if next(patterns) == nil then
		return mails
	end
	for index = 1, math.min(GetInboxNumItems() or 0, MAX_MAILS) do
		mails[#mails + 1] = auctionMail(index, patterns)
	end
	return mails
end
