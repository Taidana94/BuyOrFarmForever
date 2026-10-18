-- Namespace and shared constants. Loaded first (see TOC).
local addonName, ns = ...

ns.ADDON_NAME = addonName

-- Expose the namespace for debugging (e.g. /dump BuyOrFarmForever.Client.id).
-- Besides the SavedVariables, this is the only global the addon creates.
BuyOrFarmForever = ns
