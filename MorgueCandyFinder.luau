-- Morgue Shift: Halloween candy finder
-- Right-side panel listing which rooms have candy (TrickOrTreatItem) during a Rush,
-- with distance, floor, the Rush countdown and how close the Reaper is.
-- Also highlights each candy in the world so you can see it through walls.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

if getgenv().MorgueCandyFinder then
    pcall(getgenv().MorgueCandyFinder)
end

local conns, marks = {}, {}
local alive = true

local parent = (gethui and gethui()) or game:GetService("CoreGui")
local gui = Instance.new("ScreenGui")
gui.Name = "MorgueCandyFinder"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = parent

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(1, 0.5)
panel.Position = UDim2.new(1, -12, 0.5, 0)
panel.Size = UDim2.fromOffset(230, 0)
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.BackgroundColor3 = Color3.fromRGB(24, 16, 30)
panel.BackgroundTransparency = 0.15
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", panel)
stroke.Color = Color3.fromRGB(255, 140, 40)
stroke.Thickness = 1.5
local pad = Instance.new("UIPadding", panel)
pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8)
pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
local layout = Instance.new("UIListLayout", panel)
layout.Padding = UDim.new(0, 3)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local function label(order, size, color, bold)
    local t = Instance.new("TextLabel")
    t.LayoutOrder = order
    t.Size = UDim2.new(1, 0, 0, 0)
    t.AutomaticSize = Enum.AutomaticSize.Y
    t.BackgroundTransparency = 1
    t.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    t.TextSize = size
    t.TextColor3 = color
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextWrapped = true
    t.RichText = true
    t.Text = ""
    t.Parent = panel
    return t
end

local title = label(1, 15, Color3.fromRGB(255, 160, 60), true)
title.Text = "🎃 CANDY FINDER"
local timer = label(2, 13, Color3.fromRGB(230, 220, 240), false)
local reaper = label(3, 13, Color3.fromRGB(230, 220, 240), false)
local list = label(4, 14, Color3.fromRGB(255, 255, 255), true)

-- auto-collect toggle
local autoOn = false
local busy = false
local toggle = Instance.new("TextButton")
toggle.LayoutOrder = 5
toggle.Size = UDim2.new(1, 0, 0, 28)
toggle.BackgroundColor3 = Color3.fromRGB(70, 40, 50)
toggle.BorderSizePixel = 0
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 13
toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
toggle.Text = "AUTO COLLECT: OFF"
toggle.Parent = panel
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 6)
local status = label(6, 12, Color3.fromRGB(200, 190, 210), false)
-- auto state is saved so the script comes back in the same mode after a shift change
local AUTO_FILE = "MorgueCandyFinder/auto.txt"
local function setAuto(v)
    autoOn = v
    toggle.Text = autoOn and "AUTO COLLECT: ON" or "AUTO COLLECT: OFF"
    toggle.BackgroundColor3 = autoOn and Color3.fromRGB(40, 120, 60) or Color3.fromRGB(70, 40, 50)
    pcall(function()
        if makefolder and not (isfolder and isfolder("MorgueCandyFinder")) then makefolder("MorgueCandyFinder") end
        writefile(AUTO_FILE, autoOn and "1" or "0")
    end)
end
toggle.MouseButton1Click:Connect(function()
    setAuto(not autoOn)
end)
getgenv().MorgueCandyAuto = setAuto
pcall(function()
    if isfile and isfile(AUTO_FILE) and readfile(AUTO_FILE) == "1" then setAuto(true) end
end)

local function hrp()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local SAFE = CFrame.new(57, 8, -61) -- ground spawn, far from the Reaper
local TRAVEL_SPEED = 38 -- studs per second for the smooth glide
local STAND_OFF = 3 -- how far in front of the candy to stand (at most)
local MAX_REACH = 4 -- the candy prompt works within 5 studs; keep a margin
local CORRIDOR_Z = -56.5 -- hallway between the east (z -44) and west (z -69) room rows

-- ---------------------------------------------------------------- collected totals
local HttpService = game:GetService("HttpService")
local STATS_FILE = "MorgueCandyFinder/stats.json"
local stats = { total = 0, byType = {} }
pcall(function()
    if isfile and isfile(STATS_FILE) then
        local d = HttpService:JSONDecode(readfile(STATS_FILE))
        if type(d) == "table" then
            stats.total = tonumber(d.total) or 0
            stats.byType = type(d.byType) == "table" and d.byType or {}
        end
    end
end)
local session = { total = 0, byType = {} }

-- every attempt is written to MorgueCandyFinder/log.txt so an overnight run can be checked later
local LOG_FILE = "MorgueCandyFinder/log.txt"
local function log(msg)
    local line = os.date("!%Y-%m-%d %H:%M:%S UTC  ") .. msg
    print("[MCF] " .. line)
    pcall(function()
        if makefolder and not (isfolder and isfolder("MorgueCandyFinder")) then makefolder("MorgueCandyFinder") end
        if isfile(LOG_FILE) then appendfile(LOG_FILE, line .. "\n") else writefile(LOG_FILE, line .. "\n") end
    end)
end

local function itemType(item)
    local t = item:GetAttribute("Type") or item:GetAttribute("ItemType")
    if t then return tostring(t) end
    local n = ""
    pcall(function() n = (item.MeshId or "") .. " " .. (item.TextureID or "") end)
    local p = item:FindFirstChildWhichIsA("ProximityPrompt", true)
    local low = (item.Name .. " " .. n .. " " .. (p and (p.ActionText .. " " .. p.ObjectText) or "")):lower()
    if low:find("pumpkin") then return "Pumpkin" end
    if low:find("candy") then return "Candy" end
    return "Item"
end

local totalLabel = label(7, 13, Color3.fromRGB(255, 210, 120), true)
local function refreshTotals()
    local function fmt(t)
        local parts = {}
        for k, v in pairs(t.byType) do table.insert(parts, k .. " " .. v) end
        table.sort(parts)
        return #parts > 0 and (" (" .. table.concat(parts, ", ") .. ")") or ""
    end
    totalLabel.Text = string.format("Collected: this session <b>%d</b>%s\nAll-time: <b>%d</b>%s",
        session.total, fmt(session), stats.total, fmt(stats))
end
local function addCollected(kind)
    session.total += 1
    session.byType[kind] = (session.byType[kind] or 0) + 1
    stats.total += 1
    stats.byType[kind] = (stats.byType[kind] or 0) + 1
    pcall(function()
        if makefolder and not (isfolder and isfolder("MorgueCandyFinder")) then makefolder("MorgueCandyFinder") end
        writefile(STATS_FILE, HttpService:JSONEncode(stats))
    end)
    refreshTotals()
end
refreshTotals()

-- ---------------------------------------------------------------- anti-AFK
local antiAfk = true
local afkBtn = Instance.new("TextButton")
afkBtn.LayoutOrder = 8
afkBtn.Size = UDim2.new(1, 0, 0, 24)
afkBtn.BorderSizePixel = 0
afkBtn.Font = Enum.Font.GothamBold
afkBtn.TextSize = 12
afkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
afkBtn.Parent = panel
Instance.new("UICorner", afkBtn).CornerRadius = UDim.new(0, 6)
local function paintAfk()
    afkBtn.Text = antiAfk and "ANTI-AFK: ON" or "ANTI-AFK: OFF"
    afkBtn.BackgroundColor3 = antiAfk and Color3.fromRGB(40, 90, 120) or Color3.fromRGB(70, 40, 50)
end
paintAfk()
afkBtn.MouseButton1Click:Connect(function()
    antiAfk = not antiAfk
    paintAfk()
end)
local VirtualUser = game:GetService("VirtualUser")
table.insert(conns, LocalPlayer.Idled:Connect(function()
    if not antiAfk or not alive then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end))

-- ---------------------------------------------------------------- smooth movement
local function setNoclip(char, on)
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            if on then
                if p:GetAttribute("_mcfCollide") == nil then p:SetAttribute("_mcfCollide", p.CanCollide) end
                p.CanCollide = false
            elseif p:GetAttribute("_mcfCollide") ~= nil then
                p.CanCollide = p:GetAttribute("_mcfCollide")
                p:SetAttribute("_mcfCollide", nil)
            end
        end
    end
end

-- glide the character to a CFrame with ease-in/out, passing through walls
local function glideTo(goal)
    local char = LocalPlayer.Character
    local root = hrp()
    if not (char and root) then return false end
    local start = root.CFrame
    local dist = (goal.Position - start.Position).Magnitude
    local dur = math.clamp(dist / TRAVEL_SPEED, 0.25, 4)
    setNoclip(char, true)
    local t0 = os.clock()
    while alive do
        local a = math.min(1, (os.clock() - t0) / dur)
        local e = a < 0.5 and 2 * a * a or 1 - (-2 * a + 2) ^ 2 / 2 -- easeInOutQuad
        local r = hrp()
        if not r then break end
        r.CFrame = start:Lerp(goal, e)
        r.AssemblyLinearVelocity = Vector3.zero
        r.AssemblyAngularVelocity = Vector3.zero
        if a >= 1 then break end
        RunService.Heartbeat:Wait()
    end
    setNoclip(char, false)
    return true
end

-- a spot on the floor a few studs in front of the item, facing it (prefers the hallway side)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function standSpot(pos)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = hrp()
    local ignore = { gui }
    if char then table.insert(ignore, char) end
    local H = workspace:FindFirstChild("Halloween")
    if H then table.insert(ignore, H) end
    rayParams.FilterDescendantsInstances = ignore
    local lift = (hum and hum.HipHeight or 2) + (root and root.Size.Y / 2 or 1)

    local toHall = Vector3.new(0, 0, (CORRIDOR_Z - pos.Z) >= 0 and 1 or -1)
    local dirs = { toHall, Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), -toHall }
    local origin = pos + Vector3.new(0, 1.5, 0)
    for _, dir in ipairs(dirs) do
        local blocked = workspace:Raycast(origin, dir * (STAND_OFF + 1), rayParams)
        if not blocked then
            local spot = pos + dir * STAND_OFF
            local floor = workspace:Raycast(spot + Vector3.new(0, 4, 0), Vector3.new(0, -12, 0), rayParams)
            local y = floor and (floor.Position.Y + lift) or (pos.Y + lift)
            -- the prompt only reaches MAX_REACH studs (3D), so step closer when the height gap eats into it
            local dy = math.abs(y - pos.Y)
            local horiz = math.clamp(math.sqrt(math.max(0, MAX_REACH * MAX_REACH - dy * dy)), 1.5, STAND_OFF)
            spot = pos + dir * horiz
            local stand = Vector3.new(spot.X, y, spot.Z)
            return CFrame.lookAt(stand, Vector3.new(pos.X, y, pos.Z))
        end
    end
    local stand = pos + toHall * STAND_OFF + Vector3.new(0, lift, 0)
    return CFrame.lookAt(stand, Vector3.new(pos.X, stand.Y, pos.Z))
end

local function rushInfo()
    local t = os.time()
    local m, s = tonumber(os.date("!%M", t)), tonumber(os.date("!%S", t))
    local inRush = (m % 30) < 5
    if inRush then
        local left = (5 - (m % 30)) * 60 - s
        return true, string.format("<font color='#7CFF7C'>RUSH ON</font> · ends in %d:%02d", left // 60, left % 60)
    end
    local to = (30 - (m % 30)) * 60 - s
    return false, string.format("Next rush in %d:%02d", to // 60, to % 60)
end

local function itemPos(item)
    if item:IsA("BasePart") then
        return item.Position
    elseif item:IsA("Model") then
        return item:GetPivot().Position
    end
end

local function mark(item, room)
    if marks[item] then
        return
    end
    local h = Instance.new("Highlight")
    h.FillColor = Color3.fromRGB(255, 140, 40)
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = 0.3
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee = item
    h.Parent = gui
    local bb = Instance.new("BillboardGui")
    bb.Adornee = item
    bb.AlwaysOnTop = true
    bb.Size = UDim2.fromOffset(90, 22)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.Parent = gui
    local t = Instance.new("TextLabel", bb)
    t.Size = UDim2.fromScale(1, 1)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.TextSize = 14
    t.TextColor3 = Color3.fromRGB(255, 190, 90)
    t.TextStrokeTransparency = 0.3
    t.Text = (itemType(item) == "Pumpkin" and "🎃 " or "🍬 ") .. tostring(room)
    marks[item] = { h, bb }
end

local function cleanupMarks()
    for item, objs in pairs(marks) do
        if not item.Parent then
            for _, o in ipairs(objs) do
                o:Destroy()
            end
            marks[item] = nil
        end
    end
end

local acc = 0
table.insert(conns, RunService.Heartbeat:Connect(function(dt)
    acc += dt
    if acc < 0.25 or not alive then
        return
    end
    acc = 0

    local _, rushText = rushInfo()
    timer.Text = rushText

    local root = hrp()
    local H = workspace:FindFirstChild("Halloween")
    local sp = H and H:FindFirstChild("SpawnPoint")

    -- Reaper distance
    local rp = H and H:FindFirstChild("ActiveReaper")
    local touch = rp and (rp:FindFirstChild("model", true) or rp:FindFirstChildWhichIsA("BasePart", true))
    if touch and root then
        local d = (touch.Position - root.Position).Magnitude
        local col = d < 25 and "#FF5555" or d < 50 and "#FFCC55" or "#7CFF7C"
        reaper.Text = string.format("Reaper: <font color='%s'>%d studs</font>", col, d)
    else
        reaper.Text = "Reaper: not spawned"
    end

    if not sp then
        list.Text = "<font color='#AAAAAA'>Not in a shift (no SpawnPoint)</font>"
        return
    end

    local found = {}
    for _, d in ipairs(sp:GetDescendants()) do
        if d.Name == "TrickOrTreatItem" then
            local room = d.Parent and d.Parent.Name or "?"
            local pos = itemPos(d)
            local dist = (pos and root) and (pos - root.Position).Magnitude or 0
            table.insert(found, { room = room, dist = dist })
            mark(d, room)
        end
    end
    cleanupMarks()
    table.sort(found, function(a, b)
        return a.dist < b.dist
    end)

    if #found == 0 then
        list.Text = "<font color='#AAAAAA'>No candy right now</font>"
        return
    end
    local lines = { string.format("<font color='#FFA040'>%d candy left</font>", #found) }
    for _, f in ipairs(found) do
        local floor = tostring(f.room):sub(1, 1)
        table.insert(lines, string.format("🍬 Room <b>%s</b>  · floor %s · %d studs", f.room, floor, f.dist))
    end
    list.Text = table.concat(lines, "\n")
end))

-- auto collector: teleport next to each candy, hold its prompt, then go back to the safe spot
local function reaperPos()
    local H = workspace:FindFirstChild("Halloween")
    local rp = H and H:FindFirstChild("ActiveReaper")
    local touch = rp and (rp:FindFirstChild("model", true) or rp:FindFirstChildWhichIsA("BasePart", true))
    return touch and touch.Position
end

-- items the server would not hand over; each gets MAX_TRIES before it is left alone,
-- otherwise one stuck item keeps the bot gliding back and forth all night
local MAX_TRIES = 2
local tries = setmetatable({}, { __mode = "k" })

local function collectOne(item)
    local root = hrp()
    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
    local pos = itemPos(item)
    local room = tostring(item.Parent and item.Parent.Name)
    if not (root and prompt and pos) then
        return false
    end
    if not prompt.Enabled then
        tries[item] = MAX_TRIES
        log("room " .. room .. ": prompt disabled, skipping")
        return false
    end
    local rpos = reaperPos()
    if rpos and (rpos - pos).Magnitude < 14 then
        status.Text = "Skipping room " .. room .. " (Reaper too close)"
        return false
    end
    tries[item] = (tries[item] or 0) + 1
    local kind = itemType(item)
    status.Text = "Going to room " .. room .. "..."
    pcall(function() LocalPlayer:RequestStreamAroundAsync(pos, 5) end)
    local spot = standSpot(pos)
    glideTo(spot)
    if not item.Parent then
        log("room " .. room .. ": gone before arrival (someone else took it)")
        return false
    end
    status.Text = "Collecting room " .. room .. "..."
    task.wait(0.15)
    -- fireproximityprompt is what the server reliably accepts; the manual hold runs alongside it
    task.spawn(function() pcall(fireproximityprompt, prompt) end)
    pcall(function() prompt:InputHoldBegin() end)
    local held = false
    local t0 = os.clock()
    -- stay planted in front of the candy until the server removes it (hold time + a few seconds)
    while item.Parent and alive and os.clock() - t0 < prompt.HoldDuration + 5 do
        if not held and os.clock() - t0 >= prompt.HoldDuration + 0.3 then
            held = true
            pcall(function() prompt:InputHoldEnd() end)
        end
        local r = hrp()
        if r then
            r.CFrame = spot
            r.AssemblyLinearVelocity = Vector3.zero
        end
        RunService.Heartbeat:Wait()
    end
    if not held then pcall(function() prompt:InputHoldEnd() end) end
    if item.Parent == nil then
        addCollected(kind)
        log(string.format("room %s: collected %s in %.1fs", room, kind, os.clock() - t0))
        return true
    end
    local r = hrp()
    log(string.format("room %s: NOT collected after %.1fs (try %d/%d, dist %.1f, prompt enabled=%s, max %s)",
        room, os.clock() - t0, tries[item], MAX_TRIES, r and (r.Position - pos).Magnitude or -1,
        tostring(prompt.Enabled), tostring(prompt.MaxActivationDistance)))
    return false
end

local function collectPass()
    local H = workspace:FindFirstChild("Halloween")
    local sp = H and H:FindFirstChild("SpawnPoint")
    local root = hrp()
    if not (sp and root) then return end
    local items = {}
    for _, d in ipairs(sp:GetDescendants()) do
        if d.Name == "TrickOrTreatItem" and itemPos(d) and (tries[d] or 0) < MAX_TRIES then
            table.insert(items, { item = d, dist = (itemPos(d) - root.Position).Magnitude })
        end
    end
    if #items == 0 then return end
    busy = true
    table.sort(items, function(a, b) return a.dist < b.dist end)
    log(string.format("pass: %d item(s) to try", #items))
    local got = 0
    for _, e in ipairs(items) do
        if not autoOn or not alive then break end
        if e.item.Parent and collectOne(e.item) then
            got += 1
        end
    end
    status.Text = "Collected " .. got .. " · heading back"
    glideTo(SAFE)
    status.Text = "Collected " .. got .. " · back at spawn"
end

-- the whole pass runs under pcall: one error used to kill this thread silently and leave
-- the toggle saying ON while nothing collected any more
local collectorThread = task.spawn(function()
    while alive do
        task.wait(0.3)
        if autoOn and not busy then
            local ok, err = pcall(collectPass)
            busy = false
            if not ok then
                log("ERROR in collector: " .. tostring(err))
                status.Text = "Error (recovered): " .. tostring(err):sub(1, 60)
                pcall(function()
                    local c = LocalPlayer.Character
                    if c then setNoclip(c, false) end
                end)
                task.wait(2)
            end
        end
    end
end)

-- come back after a teleport (new shift / rejoin in the same session)
pcall(function()
    local q = queue_on_teleport or queueonteleport
    if q and isfile and isfile("MorgueCandyFinder/finder.luau") then
        q([[task.wait(8) pcall(function() loadstring(readfile("MorgueCandyFinder/finder.luau"))() end)]])
    end
end)
log("script started (auto " .. (autoOn and "ON" or "OFF") .. ", place v" .. game.PlaceVersion .. ")")

getgenv().MorgueCandyFinder = function()
    pcall(task.cancel, collectorThread)
    alive = false
    pcall(function()
        local c = LocalPlayer.Character
        if c then setNoclip(c, false) end
    end)
    for _, c in ipairs(conns) do
        pcall(function() c:Disconnect() end)
    end
    pcall(function() gui:Destroy() end)
end
