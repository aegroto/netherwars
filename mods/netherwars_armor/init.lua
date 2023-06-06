armor:register_armor("netherwars_armor:helmet_netherwarrior", {
	description = "Nether Warrior Helmet",
	inventory_image = "test.png",
	groups = {armor_head=1, armor_heal=0, armor_use=2000, flammable=1},
	armor_groups = {fleshy=10},
	progressive_updates = { armor = 1.0 },
	damage_groups = {cracky=3, snappy=2, choppy=3, crumbly=2, level=1},
})

minetest.register_craft({
	output = "netherwars_armor:helmet_netherwarrior",
	recipe = {
		{"netherwars_core:netherium_ingot", "netherwars_core:netherium_ingot", "netherwars_core:netherium_ingot"},
		{"netherwars_core:netherium_ingot", "", "netherwars_core:netherium_ingot"}
	}
})
