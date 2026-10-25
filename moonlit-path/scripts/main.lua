-- The Moonlit Path (wcmods-examples/moonlit-path): a questline with a quest giver of the mod's own.
-- Its steps are in settings.json: talk to the giver, pick things up, go somewhere, and a reward at the
-- end. Progress is kept in settings.json (MOD.save), so the quest carries on in the next session.
-- The giver is a Game.npcs cat (WCModsGame); the quest panel, markers and talk are drawn with WCModsDraw.
local Draw = require("WCModsDraw")
local View = require("WCModsView")
local S = MOD.settings
local G = S.giver
local P = S.progress

local TALK_RANGE, WALK_AWAY, LABEL_RANGE = 300, 600, 2000   -- cm
local giver, talking, lines       -- talking: the line being said, of `lines`
local doneAt                      -- when the quest was finished, for the panel's last word

local function step() return S.steps[P.step] end
local function finished() return P.step > #S.steps end

local function save()
    local ok, why = MOD.save()
    if not ok then MOD.log("progress not kept: %s", tostring(why)) end
end

-- On to the next step, with the reward if this one gives one (dropped at your paws, to pick up).
local function advance()
    local s = step()
    if not s then return end
    for tag, n in pairs(s.reward or {}) do
        local ok, why = Game.items.drop(tag, n)
        if not ok then MOD.log("reward %s not dropped: %s", tag, tostring(why)) end
    end
    MOD.log("done: %s", s.text)
    P.step, P.counts = P.step + 1, {}
    if finished() then doneAt = os.clock() end
    save()
end

-- ------------------------------------------------------------------------------- the giver
local function spawnGiver()
    if giver then giver:remove() end
    giver = Game.npcs.spawn({
        at = G.at, yaw = G.yaw or 0, level = G.level, size = G.size, eyes = G.eyes,
        colours = { fur = G.fur, pattern = G.pattern, markings = G.markings, nose = G.nose, paws = G.paws },
    })
end

-- The first time, the giver turns up beside your cat; where is kept in settings.json.
local function placeGiver()
    local me = Game.cat()
    if not me then return end
    local l, yaw = me:location(), 0
    pcall(function() yaw = me.actor:K2_GetActorRotation().Yaw end)
    G.at = { math.floor(l.X + math.cos(math.rad(yaw - 60)) * 220), math.floor(l.Y + math.sin(math.rad(yaw - 60)) * 220),
             math.floor(l.Z) }
    G.level, G.yaw = Game.levelName(), yaw + 180
    spawnGiver()
    save()
    MOD.log("%s is at %d, %d, %d in %s", G.name, G.at[1], G.at[2], G.at[3], G.level)
end

Game.every(1, function()
    if giver or not Game.player() then return end
    if G.at and #G.at == 3 then spawnGiver() else placeGiver() end
end)

-- ------------------------------------------------------------------------------- the steps
-- Collecting: what you pick up from the step's start counts.
Game.on("itemPickedUp", function(tag, quantity)
    local s = step()
    if not s or not s.collect or not s.collect[tag] then return end
    P.counts[tag] = math.min(s.collect[tag], (P.counts[tag] or 0) + (quantity or 1))
    for t, n in pairs(s.collect) do
        if (P.counts[t] or 0) < n then
            save()
            return
        end
    end
    advance()
end)

-- Visiting: an actor of a class (found while you play) or a place.
local found = {}
local function visitTarget(s)
    if s.at then return { X = s.at[1], Y = s.at[2], Z = s.at[3] } end
    if not s.visit then return nil end
    local a = found[s.visit]
    if not (a and a:IsValid()) then
        a = Game.find(s.visit)
        found[s.visit] = a
    end
    if not a then return nil end
    local ok, l = pcall(function() return a:K2_GetActorLocation() end)
    return ok and { X = l.X, Y = l.Y, Z = l.Z } or nil
end

local function distance(a, b)
    return math.sqrt((a.X - b.X) ^ 2 + (a.Y - b.Y) ^ 2 + (a.Z - b.Z) ^ 2)
end

Game.every(0.5, function()
    local s = step()
    if not s or not (s.visit or s.at) then return end
    local me, to = Game.cat(), visitTarget(s)
    if me and to and distance(me:location(), to) <= (s.radius or 400) then advance() end
end)

-- Talking: on a talk step the giver says its lines, and the step is done after the last; otherwise
-- they remind you what's next.
Game.onPress({ S.talk_key or "T", S.talk_button or "Gamepad_DPad_Up" }, function()
    if not giver then return end
    if talking then
        talking = talking + 1
        if talking > #lines then
            talking = nil
            local s = step()
            if s and s.talk and lines == s.talk then advance() end
        end
    elseif giver:near(TALK_RANGE) then
        local s = step()
        lines = s and s.talk or { finished() and "Thank you again, young one." or ("Have you done it yet? " .. s.text .. ".") }
        talking = 1
        giver:face()
    end
end, "Talk to " .. G.name)

-- ------------------------------------------------------------------------------- on screen
local function wrap(d, text, size, width)
    local out, line = {}, ""
    for word in text:gmatch("%S+") do
        local try = line == "" and word or (line .. " " .. word)
        if line ~= "" and d.measure(try, size) > width then
            out[#out + 1] = line
            line = word
        else
            line = try
        end
    end
    if line ~= "" then out[#out + 1] = line end
    return table.concat(out, "\n"), #out
end

-- What's left to do on a collect step: "Moss 1/2".
local function collectText(s)
    local parts = {}
    for tag, n in pairs(s.collect) do
        parts[#parts + 1] = string.format("%s %d/%d", tag:match("([^.]+)$"), P.counts[tag] or 0, n)
    end
    table.sort(parts)
    return table.concat(parts, ", ")
end

Draw.onFrame(function(d)
    if not d.view or not Game.player() then return end
    if #Game.screens() > 0 then talking = nil return end
    local s = step()
    local away = giver and giver:valid() and giver:distance()
    if talking and (not away or away > WALK_AWAY) then talking = nil end

    -- The giver's name over their head, and the talk prompt.
    if away and away <= LABEL_RANGE then
        local head = giver:location()
        local x, y = View.worldToScreen({ X = head.X, Y = head.Y, Z = head.Z + 30 * (G.size or 1) }, d.view)
        if x then
            d.text(x, y - 18, G.title or "", { size = 14, color = "#a8e6a1", align = "center", valign = "bottom" })
            d.text(x, y, G.name, { size = 20, color = "#ffffff", align = "center", valign = "bottom" })
            if s and s.talk and not talking then
                d.text(x, y - 40, "!", { size = 30, color = "#ffd166", align = "center", valign = "bottom" })
            end
            if not talking and away <= TALK_RANGE then
                d.text(x, y + 28, (S.talk_key or "T") .. "   Talk", { size = 16, color = "#ffe9a8", align = "center" })
            end
        end
    end

    -- The quest: a panel at the top right, and a marker on where to go.
    local px, pw = d.width - 400, 380
    local py = d.panel(px, 150, pw, 86, S.title)
    if s then
        local detail = s.collect and collectText(s) or string.format("Step %d of %d", P.step, #S.steps)
        d.text(px + 14, py, s.text, { size = 16, color = "#ffe9a8" })
        d.text(px + 14, py + 24, detail, { size = 13, color = "#ffffffb0" })
        local to = s.talk and giver and giver:valid() and giver:location() or visitTarget(s)
        if to and not talking then
            d.marker({ X = to.X, Y = to.Y, Z = to.Z + 60 }, s.talk and G.name or s.text, { edge = true, color = "#ffd166" })
        end
    elseif doneAt and os.clock() - doneAt < 30 then
        d.text(px + 14, py, "Quest complete!", { size = 16, color = "#9ef0a0" })
    else
        d.text(px + 14, py, "Complete. The mod menu's page starts it over.", { size = 13, color = "#ffffffb0" })
    end

    -- What the giver says, in a box at the bottom.
    if talking then
        local w = math.min(760, d.width - 80)
        local x = (d.width - w) / 2
        local text, n = wrap(d, lines[talking], 18, w - 40)
        local h = 70 + n * 24
        local y = d.panel(x, d.height - h - 60, w, h, G.name)
        d.text(x + 20, y + 6, text, { size = 18 })
        d.text(x + w - 16, y + h - 44, string.format("%d/%d   %s  %s", talking, #lines, S.talk_key or "T",
            talking < #lines and "next" or "end"), { size = 13, color = "#ffffffa0", align = "right" })
    end
end)

-- ------------------------------------------------------------------------------- the mod menu
MOD.page(function(ui)
    ui.heading(S.title)
    local s = step()
    if s then
        ui.field("Now", s.text)
        if s.collect then ui.field("Picked up", collectText(s)) end
    else
        ui.text("Complete.")
    end
    ui.progress("Steps", math.min(P.step - 1, #S.steps) / #S.steps, { format = string.format("%d of %d", math.min(P.step - 1, #S.steps), #S.steps) })
    ui.space(8)
    if ui.button("Start over", { kind = "danger" }) then
        P.step, P.counts, talking, doneAt = 1, {}, nil, nil
        save()
    end
    if giver and ui.button("Bring " .. G.name .. " here") then placeGiver() end
end, { title = S.title })
