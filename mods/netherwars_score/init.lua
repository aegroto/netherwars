storage = minetest.get_mod_storage()

minetest.register_on_joinplayer(
    function(player)
        player_name = player:get_player_name()
        score_key = string.format("%s:score", player_name)

        if storage:get(score_key) == nil then
            storage:set_int(score_key, 0)
        end

        minetest.chat_send_all(string.format("%s score: %d", player:get_player_name(), storage:get(score_key)))
    end
)
