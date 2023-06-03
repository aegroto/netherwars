storage = minetest.get_mod_storage()

minetest.register_on_joinplayer(
    function(player)
        local player_name = player:get_player_name()
        local score_key = string.format("%s:score", player_name)

        if storage:get(score_key) == nil then
            storage:set_int(score_key, 0)
        end

        minetest.chat_send_all(string.format("%s score: %d", player:get_player_name(), storage:get(score_key)))
    end
)

scores = {}
scores["livingnether:cyst"] = 45
scores["livingnether:flyingrod"] = 45
scores["livingnether:lavawalker"] = 200
scores["livingnether:noodlemaster"] = 250
scores["livingnether:razorback"] = 120
scores["livingnether:sokaarcher"] = 50
scores["livingnether:sokameele"] = 80
scores["livingnether:tardigrade"] = 90
scores["livingnether:whip"] = 45

for key, score in pairs(scores) do
    minetest.log("action", string.format("Registering score for %s (%d)", key, score))
    entity_def = minetest.registered_entities[key]
    if not (entity_def.on_die == nil) then
        minetest.log("warning", string.format(
            "Unable to register score for %s as on_death callback is not null", 
            key))
    else
        entity_def.on_die = function(self)
            killer = self.cause_of_death["puncher"]

            if killer == nil then
                return
            end

            local player_name = killer:get_player_name()
            local score_key = string.format("%s:score", player_name)

            local new_score = storage:get_int(score_key) + score
            storage:set_int(score_key, new_score)

            minetest.chat_send_player(player_name, 
                string.format("You have killed %s! Current score: %d", key, new_score))
        end
    end
end

minetest.register_tool("netherwars_score:god_sword", {
	description = "God Sword",
	inventory_image = "god_sword.png",
	tool_capabilities = {
		full_punch_interval = 0.7,
		max_drop_level=1,
		groupcaps={
			snappy={times={[1]=1.5, [2]=0.6, [3]=0.2}, uses=45, maxlevel=3},
		},
		damage_groups = {fleshy=1000},
	},
	sound = {breaks = "default_tool_breaks"},
	groups = {sword = 1}
})

