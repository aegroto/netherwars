netherwars.leveling_items = {}

function netherwars:register_leveling_item(name, def) 
    netherwars.leveling_items[name] = def
end

netherwars:register_leveling_item("moreores:mithril_ingot", { damage = 0.2 })
