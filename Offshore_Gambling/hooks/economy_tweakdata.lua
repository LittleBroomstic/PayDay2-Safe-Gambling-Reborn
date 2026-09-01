Hooks:PostHook(EconomyTweakData, "init", "offshore_legskin_registry_init", function(self, twaek_data)
    
    table.insert(self.contents.event_bah.contains.contents, "event_bah_legendary")

    table.insert(self.contents.mxs_01.contains.weapon_skins, "contraband_mxs")
    table.insert(self.contents.css_01.contains.weapon_skins, "contraband_css")

    table.insert(self.contents.sfs_01.contains.contents, "sfs_01_legendary")
    self.contents.sfs_01_legendary.contains.weapon_skins = { "contraband_sfs" }
end)

function EconomyTweakData:_init_ip_content(tweak_data)
    self.safes.sfs_01.first_file_extra = 0
	return
end