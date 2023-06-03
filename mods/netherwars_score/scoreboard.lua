scoreboard = {}

UPDATE_INTERVAL = 1

function sort_score_entries(l, r)
    return l["score"] > r["score"]
end

function update_scoreboard()
    local keys = storage:get_keys()
    scoreboard = {}
    for _, key in pairs(keys) do
        if string.find(key, ":score") then
            local score = storage:get_int(key)
            local player_name = key:gsub(":score", "")
            local entry = {}
            entry["player"] = player_name
            entry["score"] = score
            table.insert(scoreboard, entry)
        end
    end

    table.sort(scoreboard, sort_score_entries)

    minetest.after(UPDATE_INTERVAL, update_scoreboard)
end

update_scoreboard()
