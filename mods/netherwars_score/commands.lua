minetest.register_chatcommand("scoreboard", {
    func = function(name)
        minetest.chat_send_player(name, "# Scoreboard: ")
        local p = 1
        for _, score_entry in pairs(scoreboard) do
            if p > 5 then
                break
            end

            local line = string.format("%d. %s - %d", p, score_entry["player"], score_entry["score"])
            minetest.chat_send_player(name, line)
            p = p + 1
        end
    end
})
