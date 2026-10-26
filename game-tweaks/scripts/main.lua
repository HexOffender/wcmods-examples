-- Game Tweaks: a small in-game script built on WCModsGame (Game) and the settings in settings.json
-- (MOD.settings). It has no page of its own, so wcmods makes one for the settings in the mod menu.
-- docs/scripting.md documents every call.
local S = MOD.settings

-- Twice a second: top up stamina, hold the clock, keep the pile from running low.
Game.every(0.5, function()
    local cat = Game.cat()
    if not cat then return end          -- menus, loading
    if S.keep_stamina_full then cat:setStamina(cat:maxStamina()) end
    if S.hold_time then Game.time.setSeconds(S.time_of_day * 3600) end
    local pile = Game.freshKill.value()
    if pile and S.min_fresh_kill > 0 and pile < S.min_fresh_kill then Game.freshKill.set(S.min_fresh_kill) end
end)

-- A key that heals your cat (and its stamina) at once. The last argument puts it on the menu's Overview.
-- The key is typed on the settings page, so only a name UE4SS knows (F1-F12, a letter...) is bound; "" is none.
if type(S.heal_key) == "string" and S.heal_key ~= "" then
    if Key[S.heal_key] then
        Game.onKey(S.heal_key, function()
            local cat = Game.cat()
            if not cat then return end
            cat:heal()
            cat:setStamina(cat:maxStamina())
            MOD.log("healed %s", cat:name() or "your cat")
        end, nil, "Game Tweaks: heal your cat")
    else
        MOD.log("heal_key %q isn't a key UE4SS knows; no heal key", S.heal_key)
    end
end

-- Events: say where we are and when a fight starts.
Game.on("level", function(name) MOD.log("now in %s", tostring(name)) end)
Game.on("combatStart", function(fight)
    MOD.log("a fight: %d on your side, %d against", #fight:players(), #fight:enemies())
end)

MOD.log("loaded")
