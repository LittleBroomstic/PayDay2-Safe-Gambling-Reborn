_G.SafeSim = _G.SafeSim or {}
SafeSim.menu = "SafeSimulatorMenu"

local T_E = tweak_data.economy

-- 1. Register localizations for the custom simulator menu container
Hooks:Add("LocalizationManagerPostInit", "SafeSimLoc", function(loc)
	LocalizationManager:add_localized_strings({
		["Safesim_menu_title"] = "Safe Simulator",
		["Safesim_menu_desc"] = "Safe Opening Simulator",
		["sell_common"] = "Sell all Fake Common Skins",
		["sell_common_desc"] = "Sells every common-rarity fake skin you own",
		["sell_uncommon"] = "Sell all Fake Uncommon Skins",
		["sell_uncommon_desc"] = "Sells every uncommon-rarity fake skin you own",
		["bm_menu_offshore_poc_inventory"] = "Fake Skins",
		["bm_menu_offshore_poc_favourites"] = "Favourites",
		["sell_nonfav"] = "Sell all Non-Favourite Skins",
		["sell_nonfav_desc"] = "Sells every fake skin you own that's not marked as favourite"
	})
end)

-- 2. Setup the custom menu structure
Hooks:Add("MenuManagerSetupCustomMenus", "SafeSimSetup", function(menu_manager, nodes)
	MenuHelper:NewMenu(SafeSim.menu)
end)

-- 3. Build the menu and place it right next to Steam Inventory on the main menu
Hooks:Add("MenuManagerBuildCustomMenus", "SafeSimBuild", function(menu_manager, nodes)
	nodes[SafeSim.menu] = MenuHelper:BuildMenu(SafeSim.menu)
	local mainmenu = nodes.main
	if mainmenu == nil then
		return
	end
	if mainmenu._items == nil then
		log("[SafeSimulator] Fatal Error: Main menu node is empty, aborting")
		return
	end

	local position = 1
	for index, item in pairs(mainmenu._items) do
		position = position + 1
	end
	
	MenuHelper:AddMenuItem(mainmenu, SafeSim.menu, "Safesim_menu_title", "Safesim_menu_desc", position)
	nodes[SafeSim.menu]._parameters.scene_state = "standard"
end)

-- 4. Dynamically populate buttons for every safe in tweak_data (including custom ones like offshore_poc_01)
Hooks:Add("MenuManagerPopulateCustomMenus", "SafeSimPopulate", function(menu_manager, nodes)
	for safe, safe_d in pairs(T_E.safes) do
		log("[Gambling] Safe name: " .. safe_d.name_id)
		log("[Gambling] Safe content: " .. safe_d.content)	
		MenuCallbackHandler["SafeSim_"..safe.."_callback"] = function(self, item)
			-- Calls the separate execution script when a safe is clicked
			if SafeSim.RunSimulation then
				SafeSim.RunSimulation(safe, safe_d)
			end
		end
		
		MenuHelper:AddButton({
			id = "SafeSim_"..safe.."_id",
			title = safe_d.name_id,
			callback = "SafeSim_"..safe.."_callback",
			menu_id = SafeSim.menu,  
		})
	end
	
end)
Hooks:Add("MenuManagerPopulateCustomMenus", "SafeSimSellAllButtons", function(menu_manager, nodes)
	local function offshore_poc_show_sell_result_dialog(count, value, rarity_label)
		local dialog_data = {}

		dialog_data.title = managers.localization:text("Safesim_menu_title")
		dialog_data.text = "Sold " .. count .. " " .. rarity_label .. " skins for " .. value .. "$"

		local ok_button = {}
		ok_button.text = managers.localization:text("dialog_ok")

		dialog_data.button_list = { ok_button }

		managers.system_menu:show(dialog_data)
	end

	MenuCallbackHandler.SafeSim_sell_common_callback = function(self, item)
		local count, value = managers.blackmarket:offshore_poc_sell_all_fake_skins_by_rarity("common")

		offshore_poc_show_sell_result_dialog(count, value, "common")
	end
	MenuCallbackHandler.SafeSim_sell_non_favourite_callback = function(self, item)
		local count, value = managers.blackmarket:offshore_poc_sell_all_non_favourite_fake_skins()

		offshore_poc_show_sell_result_dialog(count, value, "non-favourite")
	end
	MenuCallbackHandler.SafeSim_sell_uncommon_callback = function(self, item)
		local count, value = managers.blackmarket:offshore_poc_sell_all_fake_skins_by_rarity("uncommon")

		offshore_poc_show_sell_result_dialog(count, value, "uncommon")
	end
	MenuHelper:AddButton({
		id = "SafeSim_sell_non_favourite_id",
		title = "sell_nonfav",
		desc = "sell_nonfav_desc",
		callback = "SafeSim_sell_non_favourite_callback",
		menu_id = SafeSim.menu,
		priority = 1001
	})
	MenuHelper:AddButton({
		id = "SafeSim_sell_common_id",
		title = "sell_common",
		desc = "sell_common_desc",
		callback = "SafeSim_sell_common_callback",
		menu_id = SafeSim.menu,
		priority = 1000
	})

	MenuHelper:AddButton({
		id = "SafeSim_sell_uncommon_id",
		title = "sell_uncommon",
		desc = "sell_uncommon_desc",
		callback = "SafeSim_sell_uncommon_callback",
		menu_id = SafeSim.menu,
		priority = 999
	})

	MenuHelper:AddDivider({
		id = "SafeSim_sell_all_divider",
		size = 16,
		menu_id = SafeSim.menu,
		priority = 998
	})
end)