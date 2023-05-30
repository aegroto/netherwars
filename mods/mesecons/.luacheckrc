
globals = {
	"mesecon",
	"minetest"
}

exclude_files = {
	"mesecons_luacontroller/examples/*"
}

-- ignore unused vars
unused = false

read_globals = {
	-- Stdlib
	string = {fields = {"split"}},
	table = {fields = {"copy", "getn", "insert_all"}},

	-- Minetest
	"vector", "ItemStack",
	"dump", "VoxelArea", "DIR_DELIM",

	-- deps
	"default", "screwdriver",
	"digiline", "doors", "dreambuilder_theme"
}

ignore = {
	"631", -- line too long
	"621", -- inconsistent indendation
	"542", -- empty if branch
}
