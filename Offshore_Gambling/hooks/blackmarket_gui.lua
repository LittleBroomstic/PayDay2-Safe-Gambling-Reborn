local function offshore_poc_format_money(amount)
	local str = tostring(math.floor(amount))
	local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
 
	return formatted .. "$"
end

local offshore_poc_real_create_steam_inventory = BlackMarketGui.create_steam_inventory
function BlackMarketGui:create_steam_inventory(data)
	
	local node_parameters = self._node and self._node:parameters()
	local desired_selected = node_parameters and node_parameters.menu_component_selected
	
	offshore_poc_real_create_steam_inventory(self, data)
	
	table.insert(data, {
		category = "all",
		name = "bm_menu_offshore_poc_inventory",
		on_create_func_name = "populate_inventory_tradable",
		weapons_with_cosmetics_instance = {},
		override_slots = { 5, 3 },
		identifier = self.identifiers.inventory_tradable,
		offshore_poc_fake = true
	})

	table.insert(data, {
		category = "all",
		name = "bm_menu_offshore_poc_favourites",
		on_create_func_name = "populate_inventory_tradable",
		weapons_with_cosmetics_instance = {},
		override_slots = { 5, 3 },
		identifier = self.identifiers.inventory_tradable,
		offshore_poc_fake = true,
		offshore_poc_favourites_only = true
	})
	if node_parameters and desired_selected and desired_selected <= #data then
		node_parameters.menu_component_selected = desired_selected
	end
end

local offshore_poc_real_populate_inventory_tradable = BlackMarketGui.populate_inventory_tradable

function BlackMarketGui:populate_inventory_tradable(data)
	if not data.offshore_poc_fake then
		return offshore_poc_real_populate_inventory_tradable(self, data)
	end

	local real_get_inventory_tradable = managers.blackmarket.get_inventory_tradable
	local real_get_inventory_tradable_by_category = managers.blackmarket.get_inventory_tradable_by_category

	if data.offshore_poc_favourites_only then
		managers.blackmarket.get_inventory_tradable = BlackMarketManager.offshore_poc_get_fake_inventory_tradable_favourites
		managers.blackmarket.get_inventory_tradable_by_category = BlackMarketManager.offshore_poc_get_fake_inventory_tradable_by_category_favourites
	else
		managers.blackmarket.get_inventory_tradable = BlackMarketManager.offshore_poc_get_fake_inventory_tradable
		managers.blackmarket.get_inventory_tradable_by_category = BlackMarketManager.offshore_poc_get_fake_inventory_tradable_by_category
	end

	local ok, err = pcall(offshore_poc_real_populate_inventory_tradable, self, data)

	managers.blackmarket.get_inventory_tradable = real_get_inventory_tradable
	managers.blackmarket.get_inventory_tradable_by_category = real_get_inventory_tradable_by_category

	if not ok then
		Application:error("[OffshorePOC] populate_inventory_tradable (fake tab) failed:", err)
		return
	end

	for _, item in ipairs(data) do
		if item.instance_id then
			local skin_data = managers.blackmarket._global.offshore_poc_fake_skins[item.instance_id]

			if skin_data and skin_data.favourite then
				item.corner_text = item.corner_text or {}
				item.corner_text.selected_text = "FAV"
				item.corner_text.selected_color = Color.yellow
				item.corner_text.noselected_text = "FAV"
				item.corner_text.noselected_color = Color.yellow
			end
		end
	end
end

local offshore_poc_real_preview_weapon_cosmetics_callback = BlackMarketGui.preview_weapon_cosmetics_callback

function BlackMarketGui:preview_weapon_cosmetics_callback(data)
	local entry = data.instance_id or data.cosmetic_id

	if entry and managers.blackmarket:offshore_poc_is_fake_skin(entry) then
		local selected = self._selected

		managers.blackmarket:offshore_poc_toggle_fake_skin_favourite(entry)

		self:reload()
		return
	end

	return offshore_poc_real_preview_weapon_cosmetics_callback(self, data)
end

function BlackMarketGui:offshore_poc_confirm_sell_fake_skin(data)
	local selected = self._selected

	managers.blackmarket:offshore_poc_sell_fake_skin(data.instance_id or data.name)

	self:reload()
end

local offshore_poc_real_sell_tradable_item = BlackMarketGui.sell_tradable_item

function BlackMarketGui:sell_tradable_item(data)
	local entry = data.instance_id or data.name

	if entry and managers.blackmarket:offshore_poc_is_fake_skin(entry) then
		self:offshore_poc_sell_fake_skin_callback(data)

		return
	end

	return offshore_poc_real_sell_tradable_item(self, data)
end

function BlackMarketGui:offshore_poc_sell_fake_skin_callback(data)
	local entry = data.instance_id or data.name
	local value = managers.blackmarket:offshore_poc_get_fake_skin_sell_value(entry)

	local params = {}

	params.name = data.name_localized or data.name
	params.category = data.category
	params.money = offshore_poc_format_money(value)
	params.yes_func = callback(self, self, "_dialog_yes", callback(self, self, "offshore_poc_confirm_sell_fake_skin", data))
	params.no_func = callback(self, self, "_dialog_no")

	managers.menu:show_confirm_blackmarket_sell(params)
end