netherwars.leveling_items = {}

function netherwars:register_leveling_item(name, def) 
    netherwars.leveling_items[name] = def
end

-- Damage items
netherwars:register_leveling_item("technic:mithril_dust", { damage = 0.2, armor = 0.1, heal = 0.1 })

-- Transferrable weapons
netherwars:register_leveling_item("netherwars_weapons:sword_netherwarrior", { damage = 0.5, min_transfer = 0.5 })

netherwars:register_leveling_item("netherwars_armor:helmet_netherwarrior", { armor = 0.5, heal = 0.5, min_transfer = 0.5 })
netherwars:register_leveling_item("netherwars_armor:chestplate_netherwarrior", { armor = 0.5, heal = 0.5, min_transfer = 0.5 })
netherwars:register_leveling_item("netherwars_armor:leggings_netherwarrior", { armor = 0.5, heal = 0.5, min_transfer = 0.5 })
netherwars:register_leveling_item("netherwars_armor:boots_netherwarrior", { armor = 0.5, heal = 0.5, min_transfer = 0.5 })
netherwars:register_leveling_item("netherwars_armor:shield_netherwarrior", { armor = 0.5, heal = 0.5, min_transfer = 0.5 })
