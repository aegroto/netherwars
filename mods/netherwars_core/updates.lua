netherwars.leveling_items = {}

function netherwars:register_leveling_item(name, def) 
    netherwars.leveling_items[name] = def
end

-- Damage items
netherwars:register_leveling_item("technic:mithril_dust", { damage = 0.2, armor = 0.1 })

-- Transferrable weapons
netherwars:register_leveling_item("netherwars_weapons:sword_netherwarrior", { damage = 0.5, min_transfer = 0.2 })
