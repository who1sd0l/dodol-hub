--[[
    UNIVERSAL ANTI-AFK   |   UI: WindUI
    Game-agnostic: it touches nothing game-specific, so it drops into any place.

    WHY MORE THAN ONE LAYER
    Roblox's own 20-minute idle kick is only half the problem. Most farms die to
    a game's OWN afk detector, and those watch different things, so this ships a
    layer per detector type and lets you turn on only what a place needs:

      1. IDLE NUDGE (always the core)  LocalPlayer.Idled fires ~20 min in, right
         before Roblox disconnects you. VirtualUser:ClickButton2 at zero delta
         resets that timer and — unlike the executor's native keypress/mouse1click
         — it still lands while the window is UNFOCUSED, which is the whole AFK
         case. It does not move you or fire anything at the server.
      2. FALLBACK NUDGE  a timer that nudges when no real input has been seen for
         N minutes, in case another script swallowed Idled.
      3. MICRO-MOVE  a fraction-of-a-stud step and step back, for games that watch
         HumanoidRootPart position. Returns you to the exact CFrame you started at.
      4. MICRO-JUMP   for games that watch Humanoid state changes.
      5. CAMERA JIGGLE  a hair of yaw and back, for games that watch the camera.
      6. BLOCK AFK REMOTES  a __namecall filter that drops outgoing remotes whose
         name looks like an afk/idle report (the "client tells the server it went
         idle, server kicks it" pattern). Needs a hookmetamethod-capable executor.
      7. AUTO-REJOIN  watches for the disconnect prompt and teleports back into the
         same server instance, so an unlucky kick does not end an overnight run.

    Layers 3-5 only fire while you are ACTUALLY idle (no real input for the grace
    period), so none of them fight you during active play.
]]

------------------------------------------------------------------- services
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TeleportService  = game:GetService("TeleportService")
local VirtualUser      = game:GetService("VirtualUser")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

------------------------------------------------------------------- re-run guard
-- If a previous copy is running, tear it down first so we never stack two.
if getgenv().UniversalAntiAFK then
    pcall(function() getgenv().UniversalAntiAFK.Destroy() end)
    getgenv().UniversalAntiAFK = nil
end
local HUB = {}
getgenv().UniversalAntiAFK = HUB

local function alive() return getgenv().UniversalAntiAFK == HUB end

------------------------------------------------------------------- config
local CFG = {
    idleNudge     = true,   -- layer 1: hook LocalPlayer.Idled
    fallback      = true,   -- layer 2: proactive nudge
    fallbackMins  = 12,     -- nudge after this many minutes with no real input

    graceSecs     = 60,     -- "actually idle" = no real input for this long
    microMove     = false,  -- layer 3
    microJump     = false,  -- layer 4
    camJiggle     = false,  -- layer 5
    activityEvery = 45,     -- seconds between activity pulses (layers 3-5)

    blockRemotes  = false,  -- layer 6
    autoRejoin    = false,  -- layer 7
}
getgenv().AntiAFKConfig = CFG   -- readable/tweakable from another script

------------------------------------------------------------------- stats
local stats = {
    started    = os.clock(),
    lastInput  = os.clock(),
    nudges     = 0,
    pulses     = 0,
    blocked    = 0,
    lastAction = "none yet",
}

local function mark(what)
    stats.lastAction = ("%s @ %s"):format(what, os.date("%H:%M:%S"))
end

------------------------------------------------------------------- real-input tracking
-- Everything that decides "are they actually away" reads stats.lastInput. Mouse
-- movement counts, so simply sitting at the machine keeps the activity layers off.
local conns = {}
local function connect(sig, fn)
    local c = sig:Connect(fn)
    table.insert(conns, c)
    return c
end

local function touch() stats.lastInput = os.clock() end
connect(UserInputService.InputBegan,   touch)
connect(UserInputService.InputChanged, touch)
connect(UserInputService.InputEnded,   touch)

local function idleFor() return os.clock() - stats.lastInput end
local function reallyIdle() return idleFor() >= CFG.graceSecs end

------------------------------------------------------------------- layer 1+2: the nudge
local function nudge(why)
    local ok = pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    if ok then
        stats.nudges += 1
        mark("nudge (" .. why .. ")")
    end
    return ok
end

local idleConn
local function setIdleNudge(on)
    CFG.idleNudge = on
    if on and not idleConn then
        idleConn = LocalPlayer.Idled:Connect(function()
            if CFG.idleNudge then nudge("Idled") end
        end)
    elseif not on and idleConn then
        idleConn:Disconnect()
        idleConn = nil
    end
end
setIdleNudge(true)

task.spawn(function()
    while alive() do
        if CFG.fallback and idleFor() > CFG.fallbackMins * 60 then
            nudge("fallback")
            stats.lastInput = os.clock()   -- back off so we don't hammer it
        end
        for _ = 1, 15 do                   -- 15s tick, bail fast on teardown
            if not alive() then return end
            task.wait(1)
        end
    end
end)

------------------------------------------------------------------- layers 3-5: activity pulses
local function character()
    local ch = LocalPlayer.Character
    if not ch then return nil end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if hum and hrp and hum.Health > 0 then return ch, hum, hrp end
    return nil
end

-- A step out and back. We snapshot the CFrame and restore it, so anchored
-- platforms, vehicles and tight ledges all survive this.
local function doMicroMove()
    local ch, hum, hrp = character()
    if not ch then return false end
    local before = hrp.CFrame
    local ok = pcall(function()
        hum:Move(Vector3.new(0.35, 0, 0), false)
        task.wait(0.12)
        hum:Move(Vector3.new(-0.35, 0, 0), false)
        task.wait(0.12)
        hum:Move(Vector3.zero, false)
    end)
    -- only snap back if we barely moved; if the game teleported us mid-pulse,
    -- leave it alone rather than yanking the character backwards.
    pcall(function()
        if ok and (hrp.CFrame.Position - before.Position).Magnitude < 6 then
            hrp.CFrame = before
        end
    end)
    return ok
end

local function doMicroJump()
    local ch, hum = character()
    if not ch then return false end
    return (pcall(function() hum.Jump = true end))
end

local function doCamJiggle()
    local cam = workspace.CurrentCamera
    if not cam then return false end
    return (pcall(function()
        local before = cam.CFrame
        cam.CFrame = before * CFrame.Angles(0, math.rad(0.6), 0)
        task.wait(0.08)
        cam.CFrame = before
    end))
end

task.spawn(function()
    while alive() do
        local wants = CFG.microMove or CFG.microJump or CFG.camJiggle
        if wants and reallyIdle() then
            local did = false
            if CFG.microMove then did = doMicroMove() or did end
            if CFG.microJump then did = doMicroJump() or did end
            if CFG.camJiggle then did = doCamJiggle() or did end
            if did then
                stats.pulses += 1
                mark("activity pulse")
            end
            local waited = 0
            while alive() and waited < CFG.activityEvery do
                task.wait(1)
                waited += 1
            end
        else
            task.wait(1)
        end
    end
end)

------------------------------------------------------------------- layer 6: block afk remotes
--[[ The pattern this defeats: the game's own LocalScript notices you stopped
     playing and TELLS the server, which then kicks you. Dropping that one call
     client-side is enough. We install the hook once and gate it on the flag, so
     toggling off is a pass-through rather than a risky re-hook. ]]
local AFK_WORDS = { "afk", "idle", "inactiv", "kickplayer", "afkkick", "idlekick", "antiafk" }
local hookInstalled, hookAvailable = false, false

local function looksAfk(name)
    name = string.lower(tostring(name))
    for _, w in ipairs(AFK_WORDS) do
        if string.find(name, w, 1, true) then return true end
    end
    return false
end

local function installRemoteBlock()
    if hookInstalled then return true end
    if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then
        return false
    end
    local old
    local ok = pcall(function()
        old = hookmetamethod(game, "__namecall", function(self, ...)
            if CFG.blockRemotes and not (checkcaller and checkcaller()) then
                local method = getnamecallmethod()
                if method == "FireServer" or method == "InvokeServer" then
                    local okName, nm = pcall(function() return self.Name end)
                    if okName and looksAfk(nm) then
                        stats.blocked += 1
                        mark("blocked remote: " .. tostring(nm))
                        return nil     -- swallow it
                    end
                end
            end
            return old(self, ...)
        end)
    end)
    hookInstalled = ok and old ~= nil
    return hookInstalled
end

hookAvailable = (type(hookmetamethod) == "function" and type(getnamecallmethod) == "function")

------------------------------------------------------------------- layer 7: auto-rejoin
local rejoining = false
local function rejoin()
    if rejoining then return end
    rejoining = true
    mark("rejoining…")
    task.spawn(function()
        local ok = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
        if not ok then
            pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
        end
        task.wait(8)
        rejoining = false
    end)
end
HUB.Rejoin = rejoin

-- The disconnect dialog is CoreGui.RobloxPromptGui.promptOverlay.ErrorPrompt.
-- We connect if we can read CoreGui, and poll as a fallback if we cannot.
local function watchDisconnect()
    pcall(function()
        local overlay = CoreGui:FindFirstChild("RobloxPromptGui")
        overlay = overlay and overlay:FindFirstChild("promptOverlay")
        if not overlay then return end
        connect(overlay.ChildAdded, function(child)
            if CFG.autoRejoin and string.find(string.lower(child.Name), "errorprompt", 1, true) then
                task.wait(1)
                rejoin()
            end
        end)
    end)
end
watchDisconnect()

task.spawn(function()
    while alive() do
        if CFG.autoRejoin and not rejoining then
            pcall(function()
                local o = CoreGui:FindFirstChild("RobloxPromptGui")
                o = o and o:FindFirstChild("promptOverlay")
                if o and o:FindFirstChild("ErrorPrompt") then rejoin() end
            end)
        end
        task.wait(3)
    end
end)

------------------------------------------------------------------- UI (WindUI)
local okWind, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not okWind or not WindUI then
    warn("[AntiAFK] Failed to load WindUI: " .. tostring(WindUI))
    warn("[AntiAFK] Core anti-afk is still running headless. getgenv().AntiAFKConfig to tweak.")
    return
end

local Window = WindUI:CreateWindow({
    Title  = "Universal Anti-AFK",
    Icon   = "coffee",
    Author = "works in any game",
    Folder = "UniversalAntiAFK",
    Size   = UDim2.fromOffset(500, 400),
    Theme  = "Dark",
})
pcall(function() Window:EditOpenButton({ Title = "Anti-AFK", Icon = "coffee" }) end)

local TabMain     = Window:Tab({ Title = "Anti-AFK",  Icon = "coffee" })
local TabActivity = Window:Tab({ Title = "Activity",  Icon = "activity" })
local TabAdvanced = Window:Tab({ Title = "Advanced",  Icon = "shield" })

------------------------------------------------------------- Tab: Anti-AFK
local statusPara = TabMain:Paragraph({ Title = "Status", Desc = "Starting…" })

TabMain:Section({ Title = "Core" })

TabMain:Toggle({
    Title = "Idle Nudge",
    Desc  = "Beats Roblox's 20-min idle kick. Works while the window is unfocused. Leave this on.",
    Value = true,
    Callback = function(state)
        setIdleNudge(state)
        WindUI:Notify({ Title = "Idle Nudge", Content = state and "ON" or "OFF", Duration = 3 })
    end,
})

TabMain:Toggle({
    Title = "Fallback Nudge",
    Desc  = "Also nudges on a timer, in case another script swallowed the Idled event.",
    Value = true,
    Callback = function(state) CFG.fallback = state end,
})

TabMain:Slider({
    Title = "Fallback interval (min)",
    Desc  = "Minutes of no real input before a fallback nudge. Keep under 20.",
    Value = { Min = 3, Max = 19, Default = CFG.fallbackMins },
    Step  = 1,
    Callback = function(v) CFG.fallbackMins = v end,
})

TabMain:Button({
    Title = "Nudge Now",
    Desc  = "Fire one manually to confirm it works in this game.",
    Callback = function()
        local ok = nudge("manual")
        WindUI:Notify({
            Title = "Anti-AFK",
            Content = ok and "Nudge sent." or "VirtualUser is blocked by this executor — use the Activity layers instead.",
            Duration = 4,
        })
    end,
})

------------------------------------------------------------- Tab: Activity
TabActivity:Paragraph({
    Title = "When to use these",
    Desc  = "The core nudge only satisfies ROBLOX. If a specific game still kicks you, it is running "
         .. "its own detector — turn on whichever of these matches what it watches. All three fire "
         .. "only after you have been genuinely idle for the grace period, so they never fight you "
         .. "while you are playing.",
})

TabActivity:Toggle({
    Title = "Micro-Move",
    Desc  = "Steps a fraction of a stud and back. For games watching your position.",
    Value = false,
    Callback = function(state) CFG.microMove = state end,
})

TabActivity:Toggle({
    Title = "Micro-Jump",
    Desc  = "One jump per pulse. For games watching Humanoid state.",
    Value = false,
    Callback = function(state) CFG.microJump = state end,
})

TabActivity:Toggle({
    Title = "Camera Jiggle",
    Desc  = "A hair of yaw and back. For games watching the camera.",
    Value = false,
    Callback = function(state) CFG.camJiggle = state end,
})

TabActivity:Slider({
    Title = "Pulse interval (s)",
    Desc  = "Seconds between activity pulses.",
    Value = { Min = 10, Max = 240, Default = CFG.activityEvery },
    Step  = 5,
    Callback = function(v) CFG.activityEvery = v end,
})

TabActivity:Slider({
    Title = "Idle grace (s)",
    Desc  = "How long you must be input-free before the activity layers start.",
    Value = { Min = 5, Max = 300, Default = CFG.graceSecs },
    Step  = 5,
    Callback = function(v) CFG.graceSecs = v end,
})

------------------------------------------------------------- Tab: Advanced
TabAdvanced:Section({ Title = "Remote filter" })

local blockPara = TabAdvanced:Paragraph({
    Title = "Block AFK Remotes",
    Desc  = hookAvailable
        and "Drops outgoing remotes whose name looks like an afk/idle report (afk, idle, inactive, kick). "
         .. "Beats the 'client reports itself idle, server kicks it' pattern. Only your own outgoing calls "
         .. "are filtered; nothing else is touched."
        or  "Unavailable — this executor has no hookmetamethod/getnamecallmethod.",
})

TabAdvanced:Toggle({
    Title = "Block AFK Remotes",
    Desc  = "Requires a hookmetamethod-capable executor.",
    Value = false,
    Callback = function(state)
        if state and not installRemoteBlock() then
            CFG.blockRemotes = false
            WindUI:Notify({ Title = "Block AFK Remotes", Content = "Could not install the hook on this executor.", Duration = 5 })
            return
        end
        CFG.blockRemotes = state
        WindUI:Notify({ Title = "Block AFK Remotes", Content = state and "ON" or "OFF", Duration = 3 })
    end,
})

TabAdvanced:Section({ Title = "Disconnects" })

TabAdvanced:Toggle({
    Title = "Auto-Rejoin",
    Desc  = "On a disconnect prompt, teleports back into the SAME server instance (falls back to a fresh one).",
    Value = false,
    Callback = function(state)
        CFG.autoRejoin = state
        WindUI:Notify({ Title = "Auto-Rejoin", Content = state and "ON — will rejoin on disconnect." or "OFF", Duration = 3 })
    end,
})

TabAdvanced:Button({
    Title = "Rejoin Now",
    Desc  = "Hop back into this same server.",
    Callback = function() rejoin() end,
})

TabAdvanced:Section({ Title = "Session" })

TabAdvanced:Button({
    Title = "Unload",
    Desc  = "Stop every layer and close this window.",
    Callback = function() HUB.Destroy() end,
})

------------------------------------------------------------------- live status
local function fmt(sec)
    sec = math.max(math.floor(sec), 0)
    return ("%dh %02dm %02ds"):format(sec // 3600, sec % 3600 // 60, sec % 60)
end

task.spawn(function()
    while alive() do
        local layers = {}
        if CFG.idleNudge then table.insert(layers, "idle") end
        if CFG.fallback  then table.insert(layers, "fallback/" .. CFG.fallbackMins .. "m") end
        if CFG.microMove then table.insert(layers, "move") end
        if CFG.microJump then table.insert(layers, "jump") end
        if CFG.camJiggle then table.insert(layers, "cam") end
        if CFG.blockRemotes then table.insert(layers, "remote-filter") end
        if CFG.autoRejoin   then table.insert(layers, "rejoin") end

        local desc = ("Uptime: %s   |   Idle: %s%s\nLayers: %s\nNudges: %d   Pulses: %d   Blocked: %d\nLast: %s")
            :format(
                fmt(os.clock() - stats.started),
                fmt(idleFor()),
                reallyIdle() and "  (away)" or "  (active)",
                #layers > 0 and table.concat(layers, ", ") or "NONE — you are not protected",
                stats.nudges, stats.pulses, stats.blocked,
                stats.lastAction)

        pcall(function() statusPara:SetDesc(desc) end)
        task.wait(1)
    end
end)

------------------------------------------------------------------- teardown
function HUB.Destroy()
    CFG.microMove, CFG.microJump, CFG.camJiggle = false, false, false
    CFG.blockRemotes, CFG.autoRejoin, CFG.fallback = false, false, false
    setIdleNudge(false)
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    conns = {}
    getgenv().UniversalAntiAFK = nil
    pcall(function() Window:Close() end)
end

pcall(function() Window:SelectTab(1) end)
pcall(function() Window:Open() end)

WindUI:Notify({
    Title    = "Universal Anti-AFK",
    Content  = "Loaded. Idle Nudge is already on — that alone beats Roblox's 20-min kick. "
            .. "If a game still kicks you, add an Activity layer.",
    Duration = 6,
})
