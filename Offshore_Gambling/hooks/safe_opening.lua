_G.SafeSim = _G.SafeSim or {}

local rand = math.random
local randseed = math.randomseed
local tab_insert = table.insert
local stamp = os.date("%Y%m%d_%H%M%S")
local T_B_weapon_skins = tweak_data.blackmarket.weapon_skins
local T_E = tweak_data.economy

local r_index = {"common", "uncommon", "rare", "epic", "legendary"}
local q_index = {"poor", "fair", "good", "fine", "mint"}
local sim_chances = {
	r = {65, 20, 5, 1.5, 0.5},
	r_o = {70, 25, 5},
	r_a = {65, 30, 5},
	q = {20, 20, 20, 20, 20},
	stat = 10
}

local function get_total(index, t)
	local total = 0
	for i, n in pairs(index) do
		total = total + sim_chances[t][i]
	end
	return total
end

local function random_choice(index, t)
	local total = get_total(index, t)
	local rand_n = rand(total)
	local track = 0
	for i, n in pairs(index) do
		local prob = sim_chances[t][i]
		if prob > 0 and rand_n > track and rand_n <= track + prob then
			return n
		end
		track = track + prob
	end
	return index[1]
end

local function choose_item(safe)
	local r_index_over = safe.content == "overkill_01" and {"rare", "epic", "legendary"} or safe.content == "lones_01" and {"rare", "epic", "legendary"} or nil
	local is_armor = T_E.contents[safe.content].contains.armor_skins and {"uncommon", "rare", "epic"} or nil
	local r_index_armor = is_armor or nil
	local data = is_armor and {amount = 1, category = "armor_skins"} or {amount = 1, category = "weapon_skins"}
	local now = os.date("!*t")
	randseed(now.yday * (now.hour + 1) * (now.min + 1) * (now.sec + 1))
	
	if is_armor == nil then 
		data.bonus = rand(100) <= sim_chances.stat
	end
	
	local rarity_chances = r_index_over and "r_o" or r_index_armor and "r_a" or "r"
	local rarity = random_choice(r_index_over or r_index_armor or r_index, rarity_chances)
	local skin_index = {}
	
	if is_armor ~= nil then
		for _, skin in pairs(T_E.contents[safe.content].contains.armor_skins) do
			if T_E.armor_skins[skin].rarity == rarity then
				tab_insert(skin_index, skin)
			end
		end
	else
		if rarity == "legendary" then
			for _, skin in pairs(T_E.contents[T_E.contents[safe.content].contains.contents[1]].contains.weapon_skins) do
				tab_insert(skin_index, skin)
			end
		else
			for _, skin in pairs(T_E.contents[safe.content].contains.weapon_skins) do
				if T_B_weapon_skins[skin].rarity == rarity then
					tab_insert(skin_index, skin)
				end
			end
		end
	end
	
	data.entry = skin_index[rand(#skin_index)]
	if not is_armor then
		data.quality = random_choice(q_index, "q")
	end
	
	data.def_id = 101
	local i = 1
	while managers.blackmarket._global.inventory_tradable[tostring(i)] ~= nil do
		i = i + 1
	end
	data.instance_id = tostring(i)
	
	return data
end

-- Function called by the menu script to run the 3D scene animation and drop reward
SafeSim.RunSimulation = function(safe_name, safe_info)
	local function ready_clbk()
		managers.menu:back()
		managers.system_menu:force_close_all()
		managers.menu_component:set_blackmarket_enabled(false)
		managers.menu:open_node("open_steam_safe", {safe_info.content})
	end
	if not managers.blackmarket:can_afford_economy_safe() then
		log("[CheckCheck] Couldnt afford")
		return
	else
		managers.blackmarket:pay_for_economy_safe()
	end
	managers.menu_component:set_blackmarket_disable_fetching(true)
	managers.menu_component:set_blackmarket_enabled(false)
	managers.menu_scene:create_economy_safe_scene(safe_name, ready_clbk)
	managers.menu_scene:set_scene_template("standard")
	

	local item = choose_item(safe_info)
	
	if managers.blackmarket.offshore_poc_grant_fake_skin then
		managers.blackmarket:offshore_poc_grant_fake_skin(item.category, item.entry, item.quality, item.bonus, item.instance_id)

	else
		Application:error("[SafeSim] offshore_poc_grant_fake_skin function not found! Check blackmarket_manager.lua hook.")
	end

	-- 3. Feed the result into the native safe result receiver
	MenuCallbackHandler:_safe_result_recieved(nil, {item}, {})
end