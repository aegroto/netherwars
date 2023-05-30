minetest.register_craft({
	output = "bonemeal:bone",
	recipe = {
		{"bonemeal:mulch", "bonemeal:mulch", "bonemeal:mulch"},
		{"bonemeal:mulch", "default:dirt", "bonemeal:mulch"},
		{"bonemeal:mulch", "bonemeal:mulch", "bonemeal:mulch"},
	}
})

do
local s,l,_="default:sapling","default:leaves",""
minetest.register_craft({
	output = s.." 3",
	recipe = {
		{l,_,l},
		{_,s,_},
		{l,_,l}
	}
})
end

minetest.register_craft({
	output = "default:dirt 2",
	recipe = {
		{"bonemeal:mulch", "bonemeal:mulch", "bonemeal:mulch"},
		{"bonemeal:mulch", "bonemeal:bonemeal", "bonemeal:mulch"},
		{"bonemeal:mulch", "bonemeal:mulch", "bonemeal:mulch"},
	}
})

for k,v in pairs(minetest.registered_nodes) do
	if v.groups and v.groups.tree and v.groups.tree>0 then
		local groups={}
		for k,v in pairs(v.groups) do
			groups[k]=v
		end
		groups.oddly_breakable_by_hand=nil
		minetest.override_item(k,{groups=groups})
	end
end

for k,v in ipairs{"green","pink","cyan","brown","orange"} do
	local d = "dye:"..v
	minetest.register_craft({
		output = "default:coral_"..v.. " 2",
		recipe = {
			{d,d,d},
			{d, "bonemeal:bonemeal", d},
			{d,d,d}
		}
	})
end

minetest.register_craft({
	output = "default:dirt_with_grass",
	recipe = {
		{"default:grass_1"},
		{"default:dirt"}
	}
})
minetest.register_craft({
	output = "default:dirt_with_snow",
	recipe = {
		{"dye:white","bonemeal:bonemeal"},
		{"default:dirt_with_grass",""}
	}
})
minetest.register_craft({
	output = "default:dirt_with_dry_grass",
	recipe = {
		{"default:dry_grass_1"},
		{"default:dirt"}
	}
})
minetest.register_craft({
	output = "default:dry_dirt_with_dry_grass",
	recipe = {
		{"default:dry_grass_1"},
		{"default:dry_dirt"}
	}
})
minetest.register_craft({
	output = "default:dirt_with_coniferous_litter",
	recipe = {
		{"default:pine_needles","default:pine_needles","default:pine_needles"},
		{"default:pine_needles","default:dirt","default:pine_needles"},
		{"default:pine_needles","default:pine_needles","default:pine_needles"},
	}
})
minetest.register_craft({
	output = "default:dirt_with_rainforest_litter",
	recipe = {
		{"default:jungleleaves","default:jungleleaves","default:jungleleaves"},
		{"default:jungleleaves","default:dirt","default:jungleleaves"},
		{"default:jungleleaves","default:jungleleaves","default:jungleleaves"},
	}
})

minetest.register_craft({
	output = "default:permafrost",
	recipe = {
		{"default:ice"},
		{"default:dirt"}
	}
})
minetest.register_craft({
	output = "default:permafrost_with_stones",
	recipe = {
		{"group:stone"},
		{"default:permafrost"}
	}
})
minetest.register_craft({
	output = "default:permafrost_with_moss",
	recipe = {
		{"group:leaves"},
		{"default:permafrost"}
	}
})

minetest.register_craft({
	output = "default:pine_sapling",
	recipe = {
		{"default:sapling","default:sapling","default:sapling"},
		{"default:sapling","bonemeal:bonemeal","default:sapling"},
		{"default:sapling","dye:white","default:sapling"},
	}
})
minetest.register_craft({
	output = "default:aspen_sapling",
	recipe = {
		{"default:pine_sapling","default:pine_sapling","default:pine_sapling"},
		{"default:pine_sapling","bonemeal:bonemeal","default:pine_sapling"},
		{"default:pine_sapling","dye:white","default:pine_sapling"},
	}
})
minetest.register_craft({
	output = "default:acacia_sapling",
	recipe = {
		{"default:sapling","default:aspen_sapling","default:sapling"},
		{"default:aspen_sapling","bonemeal:bonemeal","default:aspen_sapling"},
		{"default:pine_sapling","dye:red","default:pine_sapling"},
	}
})
minetest.register_craft({
	output = "default:junglesapling",
	recipe = {
		{"default:pine_sapling","default:sapling","default:pine_sapling"},
		{"default:aspen_sapling","bonemeal:bonemeal","default:aspen_sapling"},
		{"default:acacia_sapling","dye:brown","default:acacia_sapling"},
	}
})
minetest.register_craft({
	output = "moretrees:rubber_tree_sapling",
	recipe = {
		{"default:sapling","default:sapling","default:sapling"},
		{"default:sapling","bonemeal:bonemeal","default:sapling"},
		{"mesecons_materials:glue","dye:white","mesecons_materials:glue"},
	}
})

minetest.register_craft({
	output = "default:bush_sapling",
	recipe = {
		{"default:sapling","default:sapling","default:sapling"},
		{"","bonemeal:bonemeal",""}
	}
})
minetest.register_craft({
	output = "default:acacia_bush_sapling",
	recipe = {
		{"default:acacia_sapling","default:acacia_sapling","default:acacia_sapling"},
		{"","bonemeal:bonemeal",""}
	}
})
minetest.register_craft({
	output = "default:pine_bush_sapling",
	recipe = {
		{"default:pine_sapling","default:pine_sapling","default:pine_sapling"},
		{"","bonemeal:bonemeal",""}
	}
})
minetest.register_craft({
	output = "default:blueberry_bush_sapling",
	recipe = {
		{"default:bush_sapling","default:apple","default:bush_sapling"},
		{"default:bush_sapling","bonemeal:bonemeal","default:bush_sapling"},
		{"default:bush_sapling","dye:violet","default:bush_sapling"}
	}
})

minetest.register_craft({
	output = "default:cactus",
	recipe = {
		{"default:acacia_bush_sapling","bonemeal:fertiliser","default:acacia_bush_sapling"},
		{"group:tree","group:tree","group:tree"}
	}
})

minetest.register_craft({
	output = "default:papyrus",
	recipe = {
		{"default:stick","dye:green","default:stick"},
		{"default:stick","bonemeal:bonemeal","default:stick"},
		{"default:stick","default:bush_sapling","default:stick"},
	}
})

minetest.register_craft({
	type = "cooking",
	output = "default:coal_lump",
	recipe = "group:tree",
})

minetest.register_craft({
	type = "cooking",
	output = "default:dry_dirt",
	recipe = "default:dirt",
})

minetest.register_craft({
	output = "default:desert_cobble",
	recipe = {
		{"default:dirt"},
		{"default:coral_skeleton"}
	}
})
minetest.register_craft({
	output = "default:desert_cobble 2",
	recipe = {
		{"default:desert_stone","bonemeal:bonemeal"}
	}
})

minetest.register_craft({
	output = "default:cobble",
	recipe = {
		{"dye:grey"},
		{"default:desert_cobble"}
	}
})
minetest.register_craft({
	output = "default:gravel",
	recipe = {
		{"bonemeal:bonemeal"},
		{"default:stone"}
	}
})
minetest.register_craft({
	output = "default:sand",
	recipe = {
		{"bonemeal:bonemeal"},
		{"default:gravel"}
	}
})
minetest.register_craft({
	output = "default:desert_sand",
	recipe = {
		{"bonemeal:bonemeal","bonemeal:bonemeal"},
		{"default:desert_stone",""}
	}
})
minetest.register_craft({
	output = "default:silver_sand",
	recipe = {
		{"dye:grey"},
		{"group:sand"},
	}
})
minetest.register_craft({
	output = "default:clay",
	recipe = {
		{"bonemeal:bonemeal"},
		{"default:dirt"}
	}
})

minetest.register_craft({
	output = "default:ice",
	recipe = {
		{"bonemeal:bonemeal"},
		{"default:snowblock"}
	}
})

minetest.register_craft({
	output = "bucket:bucket_water",
	recipe = {
		{"bonemeal:bonemeal","default:snowblock","bonemeal:bonemeal"},
		{"default:snowblock","bucket:bucket_empty","default:snowblock"},
		{"bonemeal:bonemeal","default:snowblock","bonemeal:bonemeal"}
	},
})
minetest.register_craft({
	output = "bucket:bucket_lava",
	recipe = {
		{"bonemeal:fertiliser","default:stone","bonemeal:fertiliser"},
		{"default:stone","bucket:bucket_empty","default:stone"},
		{"bonemeal:fertiliser","default:stone","bonemeal:fertiliser"}
	},
})

minetest.register_craft({
	output = "default:stone_with_coal",
	recipe = {
		{"default:coal_lump"},
		{"default:stone"}
	}
})

local function ore_discover_recipe(out,a,b)
	minetest.register_craft({
		output=out,
		recipe={
			{"bonemeal:fertiliser",a,"bonemeal:fertiliser"},
			{"bonemeal:fertiliser","default:stone","bonemeal:fertiliser"},
			{"bonemeal:fertiliser",b or a,"bonemeal:fertiliser"},
		}
	})
end

local function ore_renew_recipe(out,lu,cat)
	minetest.register_craft({
		output = out .. " 4",
		recipe = {
			{"default:stone","bonemeal:fertiliser","default:stone"},
			{"bonemeal:fertiliser",lu,"bonemeal:fertiliser"},
			{"default:stone",cat,"default:stone"},
		}
	})
end

local function ore_recipe(out,disc,renew)
	local unpack = unpack or table.unpack
	ore_discover_recipe(out,unpack(disc))
	ore_renew_recipe(out,unpack(renew))
end

ore_recipe("default:stone_with_tin",{"default:coalblock"},{"default:tin_lump","default:coal_lump"})
ore_recipe("default:stone_with_copper",{"default:tinblock"},{"default:copper_lump","default:coal_lump"})
ore_recipe("default:stone_with_iron",{"default:bronzeblock"},{"default:iron_lump","default:bronze_ingot"})
ore_recipe("default:stone_with_gold",{"default:steelblock"},{"default:gold_lump","default:steel_ingot"})
ore_recipe("default:stone_with_mese",{"default:goldblock"},{"default:mese_crystal","default:steel_ingot"})
ore_recipe("default:stone_with_diamond",{"default:mese"},{"default:diamond","default:gold_ingot"})
ore_recipe("moreores:mineral_silver",{"default:steelblock","default:tinblock"},{"moreores:silver_lump","default:bronze_ingot"})
ore_recipe("moreores:mineral_mithril",{"default:mese","dye:blue"},{"moreores:mithril_lump","default:gold_ingot"})
ore_recipe("technic:mineral_chromium",{"default:tinblock","dye:white"},{"technic:chromium_lump","default:tin_ingot"})
ore_recipe("technic:mineral_lead",{"default:tinblock","dye:grey"},{"technic:lead_lump","default:tin_ingot"})
ore_recipe("technic:mineral_sulfur",{"default:tinblock","dye:yellow"},{"technic:sulfur_lump","default:tin_ingot"})
ore_recipe("technic:mineral_zinc",{"default:tinblock","dye:cyan"},{"technic:zinc_lump","default:tin_ingot"})
ore_recipe("technic:mineral_uranium",{"default:goldblock","dye:green"},{"technic:uranium_lump","default:gold_ingot"})

minetest.register_craft({
	output = "technic:marble 2",
	recipe = {
		{"bonemeal:bonemeal","default:stone","bonemeal:bonemeal"},
		{"default:stone","dye:white","default:stone"},
		{"bonemeal:bonemeal","default:stone","bonemeal:bonemeal"}
	}
})

minetest.register_craft({
	output = "technic:granite 2",
	recipe = {
		{"bonemeal:bonemeal","default:stone","bonemeal:bonemeal"},
		{"default:stone","default:coral_skeleton","default:stone"},
		{"bonemeal:bonemeal","default:stone","bonemeal:bonemeal"}
	}
})
