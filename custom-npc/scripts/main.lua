-- Mistwhisker (wcmods-examples/custom-npc): a cat of your own, with their own colours, a name over
-- their head and lines to say when you talk to them. Game.npcs (WCModsGame) keeps the cat in the
-- world; this script draws the name and the talk, with WCModsDraw. settings.json says who they are.
local Draw = require("WCModsDraw")
local View = require("WCModsView")
local S = MOD.settings

local TALK_RANGE, LABEL_RANGE, WALK_AWAY = 300, 2000, 600   -- cm
local npc, talking

local function spawn(at, level)
    if npc then npc:remove() end
    npc = Game.npcs.spawn({
        at = at, yaw = S.yaw or 0, level = level, size = S.size, eyes = S.eyes,
        colours = { fur = S.fur, pattern = S.pattern, markings = S.markings, nose = S.nose, paws = S.paws },
    })
end

-- Where they stand: settings.json's "at", or (the first time) beside your cat, remembered there. F8 moves
-- them to where you stand. The same cat moves (a new one would get new patterns from the game), unless
-- it's in another level.
local function place(here)
    local me = Game.cat()
    if not me then return end
    local at, yaw
    if here then
        local l = me:location()
        at, yaw = { X = l.X, Y = l.Y, Z = l.Z }, 0
        pcall(function() yaw = me.actor:K2_GetActorRotation().Yaw + 180 end)
    else
        at, yaw = Game.npcs.spot(200, 60)
        if not at then return end
    end
    S.at, S.level, S.yaw = { math.floor(at.X), math.floor(at.Y), math.floor(at.Z) }, Game.levelName(), yaw
    if npc and npc.level == S.level then
        local r = math.rad(yaw)
        npc:moveTo(S.at)
        npc:face({ X = S.at[1] + math.cos(r) * 100, Y = S.at[2] + math.sin(r) * 100, Z = S.at[3] })
    else
        spawn(S.at, S.level)
    end
    local ok, why = MOD.save()
    MOD.log("%s is at %d, %d, %d in %s%s", S.name, S.at[1], S.at[2], S.at[3], S.level,
        ok and "" or (" (not saved: " .. tostring(why) .. ")"))
end

Game.every(1, function()
    if npc or not Game.player() then return end
    if S.at and #S.at == 3 then spawn(S.at, S.level) else place(false) end
end)

-- Talking: the talk key (or button) starts and goes on; walking away ends it. It's T rather than the
-- game's own Interact (E), which would also open whatever else is in reach. Game.onPress reads the
-- game's own input, so it sees the controller too, and only while the game has the focus.
Game.onPress({ S.talk_key or "T", S.talk_button or "Gamepad_DPad_Up" }, function()
    if not npc then return end
    if talking then
        talking = talking + 1
        if talking > #S.lines then talking = nil end
    elseif npc:near(TALK_RANGE) and #S.lines > 0 then
        talking = 1
        npc:face()
    end
end, "Talk to " .. S.name)
Game.onPress(S.move_key or "F8", function() place(true) end, "Move " .. S.name .. " to where you stand")

-- Text broken into lines that fit `width` pixels.
local function wrap(d, text, size, width)
    local lines, line = {}, ""
    for word in text:gmatch("%S+") do
        local try = line == "" and word or (line .. " " .. word)
        if line ~= "" and d.measure(try, size) > width then
            lines[#lines + 1] = line
            line = word
        else
            line = try
        end
    end
    if line ~= "" then lines[#lines + 1] = line end
    return table.concat(lines, "\n"), #lines
end

Draw.onFrame(function(d)
    if not npc or not npc:valid() or not d.view then return end
    if #Game.screens() > 0 then talking = nil return end       -- the map, the inventory, the pause menu
    local away = npc:distance()
    if not away then return end
    if talking and away > WALK_AWAY then talking = nil end

    -- The name over their head, as the game shows its own cats'.
    if away <= LABEL_RANGE then
        local head = npc:location()
        head = { X = head.X, Y = head.Y, Z = head.Z + 30 * (S.size or 1) }
        local x, y = View.worldToScreen(head, d.view)
        if x then
            d.text(x, y - 18, S.title or "", { size = 14, color = "#a8e6a1", align = "center", valign = "bottom" })
            d.text(x, y, S.name, { size = 20, color = "#ffffff", align = "center", valign = "bottom" })
            if not talking and away <= TALK_RANGE then
                d.text(x, y + 28, (S.talk_key or "T") .. "   Talk", { size = 16, color = "#ffe9a8", align = "center" })
            end
        end
    end

    -- What they're saying, in a box at the bottom of the screen.
    if talking then
        local w = math.min(760, d.width - 80)
        local x = (d.width - w) / 2
        local text, n = wrap(d, S.lines[talking], 18, w - 40)
        local h = 70 + n * 24
        local y = d.panel(x, d.height - h - 60, w, h, S.name)
        d.text(x + 20, y + 6, text, { size = 18 })
        local more = talking < #S.lines and "next" or "end"
        d.text(x + w - 16, y + h - 44, string.format("%d/%d   %s  %s", talking, #S.lines, S.talk_key or "T", more),
            { size = 13, color = "#ffffffa0", align = "right" })
    end
end)
