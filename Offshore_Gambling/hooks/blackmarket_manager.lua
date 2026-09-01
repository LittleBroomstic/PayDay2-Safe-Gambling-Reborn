local safe_cost = 1000000
local OFFSHORE_POC_SELL_BONUS_MULT = 1.25
local OFFSHORE_POC_SELL_RARITY_MULT = {
	common = 0.1,
	uncommon = 0.4,
	rare = 1,
	epic = 2.5,
	legendary = 10
}
local OFFSHORE_POC_SELL_CONDITION_MULT = {
	poor = 0.25,
	fair = 0.6,
	good = 1,
	fine = 1.4,
	mint = 1.75
}
local function offshore_poc_format_money(amount)
	local str = tostring(math.floor(amount))
	local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
 
	return formatted .. "$"
end
Hooks:PostHook(BlackMarketManager, "init_finalize", "offshore_poc_registry_init", function(self)
	self._global.offshore_poc_fake_skins = self._global.offshore_poc_fake_skins or {}
	if not self._offshore_poc_json_loaded then
		self:offshore_poc_load_json()
		self._offshore_poc_json_loaded = true
	end
	local crafted = managers.blackmarket._global.crafted_items
	for _, cat in pairs({crafted.primaries, crafted.secondaries}) do
		for _, data in pairs(cat) do
			if data.cosmetics then
				data.customize_locked = nil
			end
		end
	end
	-- Modifiable Legendary Skins
	local weapon_skins = tweak_data.blackmarket.weapon_skins
	for id, data in pairs(weapon_skins) do
		if not string.find(id, "color") then
			data.locked = false
		end
	end

end)

function BlackMarketManager:can_afford_economy_safe()
	log("[CheckCheck] Money: " .. tostring(managers.money:offshore()))
	log("[CheckCheck] Cost: " .. tostring(safe_cost))
	return managers.money:offshore() >= safe_cost
end

function BlackMarketManager:pay_for_economy_safe()

	if not self:can_afford_economy_safe() then
		return false
	end

	managers.money:deduct_from_offshore(safe_cost)

	return true
end

function BlackMarketManager:offshore_poc_grant_fake_skin(category, entry, quality, bonus, instance_id)
	if category ~= "weapon_skins" then
		Application:error("[OffshorePOC] Unsupported fake reward category", category)
		return
	end

	instance_id = instance_id or tostring(entry)

	self._global.offshore_poc_fake_skins = self._global.offshore_poc_fake_skins or {}
	self._global.offshore_poc_fake_skins[instance_id] = {
		category = category,
		entry = entry,
		quality = quality,
		bonus = bonus
	}

	managers.blackmarket:tradable_add_item(instance_id, category, entry, quality or "mint", bonus or false, 1)

	self:offshore_poc_save_json()
end

function BlackMarketManager:offshore_poc_is_fake_skin(instance_id)
	return self._global.offshore_poc_fake_skins[instance_id] ~= nil
end
-- Rebuilds and returns the fake collection, e.g. for a custom UI panel that
-- lists only mod-granted skins separately from real ones.
function BlackMarketManager:offshore_poc_fake_skin_collection()
	local collection = {}

	for entry, data in pairs(self._global.offshore_poc_fake_skins) do
		table.insert(collection, data)
	end

	return collection
end

local offshore_poc_real_have_inventory_tradable_item = BlackMarketManager.have_inventory_tradable_item


local SAVE_DIR = SavePath or "mods/Offshore_Gambling/"
local SAVE_FILE_PATH = SAVE_DIR .. "offshore_poc_skins.json"

-- Save the fake skin database to a custom JSON file
function BlackMarketManager:offshore_poc_save_json()
	-- Ensure the directory exists
	if not SystemFS:exists(SAVE_DIR) then
		SystemFS:make_dir(SAVE_DIR)
	end

	local file = io.open(SAVE_FILE_PATH, "w")
	if file then
		local data_to_save = self._global.offshore_poc_fake_skins or {}
		file:write(json.encode(data_to_save))
		file:close()
		log("[OffshorePOC] Successfully saved fake skins to JSON.")
	else
		Application:error("[OffshorePOC] Failed to open save file for writing: " .. SAVE_FILE_PATH)
	end
end

function BlackMarketManager:offshore_poc_load_json()
	self._global.offshore_poc_fake_skins = {}

	if SystemFS:exists(SAVE_FILE_PATH) then
		local file = io.open(SAVE_FILE_PATH, "r")
		if file then
			local content = file:read("*all")
			file:close()

			local decoded_data = json.decode(content)
			if decoded_data then
				self._global.offshore_poc_fake_skins = decoded_data

				for instance_id, skin_data in pairs(self._global.offshore_poc_fake_skins) do
					managers.blackmarket:tradable_add_item(
						instance_id,
						skin_data.category,
						skin_data.entry,
						skin_data.quality or "mint",
						skin_data.bonus or false,
						1
					)
				end

				log("[OffshorePOC] Successfully loaded fake skins from JSON. Total entries: " .. table.size(self._global.offshore_poc_fake_skins))
			end
		end
	else
		log("[OffshorePOC] No existing JSON save file found. Starting fresh.")
	end
end

function BlackMarketManager:tradable_update()
	--self:offshore_poc_save_json()
	--self:offshore_poc_resync_tradable()
	return
end

function BlackMarketManager:offshore_poc_resync_tradable()
	self._global.inventory_tradable = self._global.inventory_tradable or {}

	for instance_id, skin_data in pairs(self._global.offshore_poc_fake_skins or {}) do
		if not self._global.inventory_tradable[instance_id] then
			log("[OffshorePOC] Resyncing missing tradable entry: " .. tostring(instance_id))
			managers.blackmarket:tradable_add_item(
				instance_id,
				skin_data.category,
				skin_data.entry,
				skin_data.quality or "mint",
				skin_data.bonus or false,
				1
			)
		end
	end
end

----------------------------------------------------------------------------
-- SECTION : BlackMarketGui
----------------------------------------------------------------------------
function BlackMarketManager:offshore_poc_get_fake_inventory_tradable()
	local result = {}

	for entry, data in pairs(self._global.offshore_poc_fake_skins) do
		result[entry] = {
			category = data.category,
			entry = data.entry,
			quality = data.quality,
			bonus = data.bonus,
		}
	end

	return result
end
function BlackMarketManager:offshore_poc_get_fake_inventory_tradable_favourites()
	local result = {}

	for entry, data in pairs(self._global.offshore_poc_fake_skins) do
		if data.favourite then
			result[entry] = {
				category = data.category,
				entry = data.entry,
				quality = data.quality,
				bonus = data.bonus
			}
		end
	end

	return result
end
function BlackMarketManager:offshore_poc_get_fake_inventory_tradable_by_category()
	local result = {}

	for entry, data in pairs(self._global.offshore_poc_fake_skins) do
		result[data.category] = result[data.category] or {}

		table.insert(result[data.category], entry)
	end

	return result
end
function BlackMarketManager:offshore_poc_get_fake_inventory_tradable_by_category_favourites()
	local result = {}

	for entry, data in pairs(self._global.offshore_poc_fake_skins) do
		if data.favourite then
			result[data.category] = result[data.category] or {}
			table.insert(result[data.category], entry)
		end
	end

	return result
end


function BlackMarketManager:offshore_poc_get_fake_skin_sell_value(instance_id)
	local skin_data = self._global.offshore_poc_fake_skins[instance_id]

	if not skin_data then
		return 0
	end

	local weapon_skin_tweak = tweak_data.blackmarket.weapon_skins[skin_data.entry]
	local rarity = weapon_skin_tweak and weapon_skin_tweak.rarity or "common"

	local rarity_mult = OFFSHORE_POC_SELL_RARITY_MULT[rarity] or OFFSHORE_POC_SELL_RARITY_MULT.common
	local condition_mult = OFFSHORE_POC_SELL_CONDITION_MULT[skin_data.quality] or 1

	local value = safe_cost * rarity_mult * condition_mult

	if skin_data.bonus then
		value = value * OFFSHORE_POC_SELL_BONUS_MULT
	end

	return math.floor(value)
end

function BlackMarketManager:offshore_poc_sell_fake_skin(instance_id)
	local existing = self._global.offshore_poc_fake_skins[instance_id]

	if not existing then
		return 0
	end

	local value = self:offshore_poc_get_fake_skin_sell_value(instance_id)

	self._global.offshore_poc_fake_skins[instance_id] = nil
	managers.blackmarket:tradable_remove_item(instance_id)
	managers.money:add_to_offshore(value)

	self:offshore_poc_save_json()

	return value
end

function BlackMarketManager:offshore_poc_sell_all_fake_skins_by_rarity(rarity)
	local total_value = 0
	local sold_count = 0

	for instance_id, skin_data in pairs(self._global.offshore_poc_fake_skins or {}) do
		local weapon_skin_tweak = tweak_data.blackmarket.weapon_skins[skin_data.entry]
		local skin_rarity = weapon_skin_tweak and weapon_skin_tweak.rarity

		if skin_rarity == rarity and not skin_data.favourite then
			
			local value = self:offshore_poc_get_fake_skin_sell_value(instance_id)
			self._global.offshore_poc_fake_skins[instance_id] = nil
			managers.blackmarket:tradable_remove_item(instance_id)
			managers.money:add_to_offshore(value)

			total_value = total_value + value
			sold_count = sold_count + 1
		end
	end

	log("[OffshorePOC] Sold " .. sold_count .. " " .. tostring(rarity) .. " skins for " .. total_value)
	self:offshore_poc_save_json()
	return sold_count, total_value
end

--------------------------
-------[FAV SYSTEM]-------
--------------------------
-- blackmarket_manager.lua

function BlackMarketManager:offshore_poc_set_fake_skin_favourite(instance_id, favourite)
	local skin_data = self._global.offshore_poc_fake_skins[instance_id]

	if not skin_data then
		return false
	end

	skin_data.favourite = favourite or nil -- store as nil rather than false, keeps JSON small/consistent

	self:offshore_poc_save_json()

	return true
end

function BlackMarketManager:offshore_poc_toggle_fake_skin_favourite(instance_id)
	local skin_data = self._global.offshore_poc_fake_skins[instance_id]

	if not skin_data then
		return false
	end

	return self:offshore_poc_set_fake_skin_favourite(instance_id, not skin_data.favourite)
end
function BlackMarketManager:offshore_poc_sell_all_non_favourite_fake_skins()
	local total_value = 0
	local sold_count = 0

	for instance_id, skin_data in pairs(self._global.offshore_poc_fake_skins or {}) do
		if not skin_data.favourite then
			local value = self:offshore_poc_get_fake_skin_sell_value(instance_id)
			self._global.offshore_poc_fake_skins[instance_id] = nil
			managers.blackmarket:tradable_remove_item(instance_id)
			managers.money:add_to_offshore(value)

			total_value = total_value + value
			sold_count = sold_count + 1
		end
	end

	log("[OffshorePOC] Sold " .. sold_count .. " non-favourite skins for " .. total_value)
	self:offshore_poc_save_json()
	return sold_count, total_value
end