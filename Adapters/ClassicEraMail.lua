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
