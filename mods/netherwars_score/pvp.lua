minetest.register_on_dieplayer(
    function(player, reason)
        local player_name = player:get_player_name()
        local score_lose = nethewars_score:get_score(player_name) / 2
        local new_score = nethewars_score:add_score(player_name, -score_lose)

        minetest.chat_send_player(player_name, 
            string.format("You have died! Current score: %d", new_score))

        local puncher = reason.object
        if puncher then
            local killer_name = puncher:get_player_name()
            local new_killer_score = nethewars_score:add_score(killer_name, score_lose / 2)
            minetest.chat_send_player(killer_name, 
                string.format("You have killed %s! Current score: %d", killer_name, new_killer_score))
        end
    end
)

-- TODO: Remove
minetest.register_chatcommand("score", {
    func = function(name)
        nethewars_score:add_score(name, 100)
    end
})

