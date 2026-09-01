# PayDay2-Gambling-Reborn
This mod introduces safes back with the ability to buy them with offshore money and them granting you fake skins you can equip

In the main menu you can find new Safe Simulator button where you can choose different safes to open. Each safe costs 1 million offshore money to open. Opening allows to obtain fake skins you can put on your weapons. 

The skins can be found under 2 new tabs in Steam Inventory menu. Theres 'Fake Skins' as well as 'Favourites'.

To sell your fake skin all you have to do is press 'Sell on Community Market'. This gives you a prompt to sell your skin for specific amount of Offshore money. This amount is decided by the skin quality and rarity.
To set your skin as favourite you have to press 'Preview skin' on your fake skin.

The fake skins are fully equippable and will be seen by peers. It may mark you as cheater albeit its very unlikely.

In Safe Simulator menu theres option to sell all your fake non-favourite skins of common quality, uncommon quality or all of your non-favourite skins. To see if a fake skin is marked as favourite you can check either Favourite Skins tab in Steam Inventory or just look at yellow 'FAV' text on the bottom of the skin tile.

This mod is essentially a skin unlocker slapped on top of Safe Opening Simulator made by NANI SORE on ModWorkshop.

The skins are saved in json file in saves. Required SuperBLT. If your skins dont show up, simply go to hooks/blackmarket_manage.lua and 

function BlackMarketManager:tradable_update()
	--self:offshore_poc_save_json()
	--self:offshore_poc_resync_tradable()
	return
end

and uncomment both lines. It should resync your fake skin json database with your steam inventory tradable.

To remove the fake skins from your savefile: simply delete the mod. You can make backups of your fake skin database to reinstate them if needed.

To edit the safe costs and skin selling values, go to blackmarket_manager.lua and edit

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

on the very top of the file. The value of the skin is safe_cost * rarity multiplier * condition multiplier and if the skin has bonuses attached you get addition 1.25x multiplier. 
