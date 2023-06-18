armor:register_armor("netherwars_armor:helmet_netherwarrior", {
	description = "Nether Warrior Helmet",
	inventory_image = "netherwars_armor_inv_helmet_netherwarrior.png",
	groups = {armor_head=1, armor_heal=0, armor_use=66, flammable=1},
	armor_groups = {fleshy=5},
	progressive_updates = { 
		armor = 1.0,
		heal = 1.0,
		upgrade_decay = 0.01
	},
	damage_groups = {cracky=3, snappy=2, choppy=3, crumbly=2, level=1},
})

armor:register_armor("netherwars_armor:chestplate_netherwarrior", {
	description = "Nether Warrior Chestplate",
	inventory_image = "netherwars_armor_inv_chestplate_netherwarrior.png",
	groups = {armor_torso=1, armor_heal=0, armor_use=66},
	armor_groups = {fleshy=11},
	progressive_updates = { 
		armor = 1.0,
		heal = 1.0,
		upgrade_decay = 0.005
	},
	damage_groups = {cracky=2, snappy=1, level=3},
})

armor:register_armor("netherwars_armor:leggings_netherwarrior", {
	description = "Nether Warrior Leggings",
	inventory_image = "netherwars_armor_inv_leggings_netherwarrior.png",
	groups = {armor_legs=1, armor_heal=0, armor_use=66},
	armor_groups = {fleshy=11},
	progressive_updates = { 
		armor = 1.0,
		heal = 1.0,
		upgrade_decay = 0.0075
	},
	damage_groups = {cracky=2, snappy=1, level=3},
})

armor:register_armor("netherwars_armor:boots_netherwarrior", {
	description = "Nether Warrior Boots",
	inventory_image = "netherwars_armor_inv_boots_netherwarrior.png",
	groups = {armor_feet=1, armor_heal=0, armor_use=66},
	armor_groups = {fleshy=6},
	progressive_updates = { 
		armor = 1.0,
		heal = 1.0,
		upgrade_decay = 0.01
	},
	damage_groups = {cracky=2, snappy=1, level=3},
})

armor:register_armor("netherwars_armor:shield_netherwarrior", {
	description = "Nether Warrior Shield",
	inventory_image = "netherwars_armor_inv_shield_netherwarrior.png",
	groups = {armor_shield=1, armor_heal=0, armor_use=66},
	armor_groups = {fleshy=6},
	damage_groups = {cracky=2, snappy=1, level=3},
	reciprocate_damage = true,
	progressive_updates = { 
		armor = 1.0,
		heal = 1.0,
		upgrade_decay = 0.01
	},
	on_damage = function(player, index, stack)
		play_sound_effect(player, "default_glass_footstep")
	end,
	on_destroy = function(player, index, stack)
		play_sound_effect(player, "default_break_glass")
	end,
})

local s = "netherwarrior"
local m = "netherwars_core:netherium_ingot"
minetest.register_craft({
	output = "netherwars_armor:helmet_"..s,
	recipe = {
		{m, m, m},
		{m, "", m},
		{"", "", ""},
	},
})
minetest.register_craft({
	output = "netherwars_armor:chestplate_"..s,
	recipe = {
		{m, "", m},
		{m, m, m},
		{m, m, m},
	},
})
minetest.register_craft({
	output = "netherwars_armor:leggings_"..s,
	recipe = {
		{m, m, m},
		{m, "", m},
		{m, "", m},
	},
})
minetest.register_craft({
	output = "netherwars_armor:boots_"..s,
	recipe = {
		{m, "", m},
		{m, "", m},
	},
})
minetest.register_craft({
	output = "netherwars_armor:shield_"..s,
	recipe = {
		{m, m, m},
		{m, m, m},
		{"", m, ""},
	},
})

