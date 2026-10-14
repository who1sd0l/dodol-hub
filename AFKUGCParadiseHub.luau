-- AFK UGC Paradise hub (place 99760506741480)
-- Auto-claims: daily gifts, free wheel spin, community reward, coin-rain drops,
-- and the coin-priced FREE UGCs (150k coins each) the moment you can afford one.
-- Remotes (all server-validated):
--   Economy.DailyRewardAction:InvokeServer("STATE"|"CLAIM")
--   Economy.WheelAction:InvokeServer("STATE"|"SPIN")
--   CommunityReward.CheckAndClaim:InvokeServer("CHECK")
--   FreeUGCRemotes.GetState:InvokeServer(assetId)   -- nil unless you stand within ~17 studs of the booth
--   FreeUGCRemotes.Action:FireServer("CLAIM", assetId)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- tear down a previous copy
if getgenv().AFKUGCParadiseHub and getgenv().AFKUGCParadiseHub.Destroy then
    pcall(getgenv().AFKUGCParadiseHub.Destroy)
end

local Hub = {
    Daily = true,
    Wheel = true,
    Community = true,
    CoinRain = true,
    AutoUGC = true,
    AntiAfk = true,
    Target = "Any",
    Running = true,
}
local conns, threads = {}, {}
local Log = {}

local Economy = ReplicatedStorage:WaitForChild("Economy")
local DailyRewardAction = Economy:WaitForChild("DailyRewardAction")
local WheelAction = Economy:WaitForChild("WheelAction")
local CheckAndClaim = ReplicatedStorage:WaitForChild("CommunityReward"):WaitForChild("CheckAndClaim")
local FreeUGCRemotes = ReplicatedStorage:WaitForChild("FreeUGCRemotes")
local UGCAction = FreeUGCRemotes:WaitForChild("Action")
local UGCFeedback = FreeUGCRemotes:WaitForChild("Feedback")
local UGCGetState = FreeUGCRemotes:WaitForChild("GetState")
local FreeUGCInteractions = Workspace:WaitForChild("FreeUGCInteractions")

local statusPara, logPara, ugcPara

local function fmt(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local out = ""
    while #s > 3 do
        out = "," .. s:sub(-3) .. out
        s = s:sub(1, -4)
    end
    return s .. out
end

local function log(msg)
    table.insert(Log, 1, os.date("%H:%M:%S") .. "  " .. msg)
    while #Log > 8 do
        table.remove(Log)
    end
    print("[AFKUGCParadise] " .. msg)
    if logPara then
        pcall(function()
            logPara:SetDesc(table.concat(Log, "\n"))
        end)
    end
end

local function coins()
    return tonumber(LocalPlayer:GetAttribute("Coins")) or 0
end

local function hrp()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function loop(interval, fn)
    local t = task.spawn(function()
        while Hub.Running do
            local ok, err = pcall(fn)
            if not ok then
                warn("[AFKUGCParadise] " .. tostring(err))
            end
            task.wait(interval)
        end
    end)
    table.insert(threads, t)
end

---------------------------------------------------------------- daily gifts
-- 5 stages: 100/200/500/1000/2500 coins after 5/10/30/60/120 min of play
local function tryDaily()
    if not Hub.Daily then
        return
    end
    local ok, st = pcall(DailyRewardAction.InvokeServer, DailyRewardAction, "STATE")
    if not ok or type(st) ~= "table" or not st.ok or not st.state then
        return
    end
    local stage = tonumber(LocalPlayer:GetAttribute("DailyRewardStage")) or st.state.stage or 1
    local progress = tonumber(LocalPlayer:GetAttribute("DailyRewardProgress")) or 0
    local reward = st.state.rewards and st.state.rewards[stage]
    if not reward or stage >= (st.state.completedStage or 6) then
        return
    end
    if progress >= reward.duration then
        local ok2, res = pcall(DailyRewardAction.InvokeServer, DailyRewardAction, "CLAIM")
        if ok2 and type(res) == "table" and res.ok then
            log("Daily gift " .. stage .. " claimed: +" .. fmt(res.amount or reward.amount) .. " coins")
        end
    end
end

---------------------------------------------------------------- wheel
local function tryWheel()
    if not Hub.Wheel then
        return
    end
    local free = (tonumber(LocalPlayer:GetAttribute("NextFreeSpinAt")) or math.huge) <= os.time()
    local extra = (tonumber(LocalPlayer:GetAttribute("ExtraSpins")) or 0) > 0
    if not (free or extra) then
        return
    end
    local ok, res = pcall(WheelAction.InvokeServer, WheelAction, "SPIN")
    if ok and type(res) == "table" and res.ok then
        local prize = res.prize or res.amount or res.reward
        log("Wheel spun" .. (prize and (": " .. tostring(type(prize) == "table" and (prize.amount or "?") or prize)) or ""))
    end
end

---------------------------------------------------------------- community reward
local communityDone = false
local function tryCommunity()
    if not Hub.Community or communityDone or LocalPlayer:GetAttribute("CommunityRewardClaimed") == true then
        return
    end
    local ok, res = pcall(CheckAndClaim.InvokeServer, CheckAndClaim, "CHECK")
    if ok and type(res) == "table" then
        if res.Claimed or res.claimed or res.ok or res.Success then
            communityDone = true
            log("Community reward checked/claimed")
        end
    end
end

---------------------------------------------------------------- coin rain
local function tryCoinRain()
    if not Hub.CoinRain then
        return
    end
    local drops = Workspace:FindFirstChild("CoinRainDrops")
    local root = hrp()
    if not drops or not root or #drops:GetChildren() == 0 then
        return
    end
    for _, d in ipairs(drops:GetChildren()) do
        if not Hub.CoinRain then
            break
        end
        local part = d:IsA("BasePart") and d or d:FindFirstChildWhichIsA("BasePart", true)
        if part and part.Parent then
            pcall(firetouchinterest, root, part, 0)
            task.wait()
            pcall(firetouchinterest, root, part, 1)
        end
    end
end

---------------------------------------------------------------- free UGC
local function boothList()
    local list = {}
    for _, p in ipairs(FreeUGCInteractions:GetChildren()) do
        local id = tonumber(p:GetAttribute("UGCAssetId"))
        if id and p:IsA("BasePart") then
            table.insert(list, {
                Part = p,
                Id = id,
                Name = tostring(p:GetAttribute("UGCDisplayName") or p.Name),
                Price = tonumber(p:GetAttribute("CoinPrice")) or math.huge,
                Remaining = tonumber(p:GetAttribute("StockRemaining")) or 0,
                Total = tonumber(p:GetAttribute("StockTotal")) or 0,
                Enabled = p:GetAttribute("UGCEnabled") ~= false,
            })
        end
    end
    table.sort(list, function(a, b)
        return a.Price < b.Price
    end)
    return list
end

local claimedIds = {}
local claiming = false

local function claimBooth(b)
    local root = hrp()
    if not root then
        return false
    end
    claiming = true
    local back = root.CFrame
    -- GetState only answers within ~17 studs, so stand next to the booth
    root.CFrame = CFrame.new(b.Part.Position + Vector3.new(0, 2, 5))
    task.wait(0.6)
    local ok, st = pcall(UGCGetState.InvokeServer, UGCGetState, b.Id)
    local claimed = false
    if ok and type(st) == "table" then
        if st.Claimed == true then
            claimedIds[b.Id] = true
        elseif st.Enabled ~= false and (tonumber(st.Remaining) or 0) > 0
            and (tonumber(st.Coins) or 0) >= (tonumber(st.CoinPrice) or math.huge) then
            log("Claiming " .. b.Name .. " (" .. fmt(st.CoinPrice) .. " coins)")
            UGCAction:FireServer("CLAIM", b.Id)
            task.wait(2.5)
            claimed = true
        end
    end
    local r2 = hrp()
    if r2 then
        r2.CFrame = back
    end
    claiming = false
    return claimed
end

local function tryUGC()
    local list = boothList()
    local have = coins()
    local lines = {}
    for _, b in ipairs(list) do
        local tag = claimedIds[b.Id] and "OWNED" or (b.Remaining <= 0 and "SOLD OUT")
            or (have >= b.Price and "READY") or (fmt(b.Price - have) .. " to go")
        table.insert(lines, string.format("%s  [%d/%d]  %s", b.Name, b.Remaining, b.Total, tag))
    end
    if ugcPara then
        pcall(function()
            ugcPara:SetDesc(#lines > 0 and table.concat(lines, "\n") or "No free UGC booths found")
        end)
    end
    if not Hub.AutoUGC or claiming then
        return
    end
    for _, b in ipairs(list) do
        if (Hub.Target == "Any" or Hub.Target == b.Name) and not claimedIds[b.Id]
            and b.Enabled and b.Remaining > 0 and have >= b.Price then
            claimBooth(b)
            return
        end
    end
end

table.insert(conns, UGCFeedback.OnClientEvent:Connect(function(...)
    local parts = {}
    for _, v in ipairs({ ... }) do
        if type(v) == "table" then
            for k, x in pairs(v) do
                table.insert(parts, tostring(k) .. "=" .. tostring(x))
            end
        else
            table.insert(parts, tostring(v))
        end
    end
    log("UGC: " .. table.concat(parts, " "))
end))

---------------------------------------------------------------- anti-AFK
local VirtualUser = game:GetService("VirtualUser")
table.insert(conns, LocalPlayer.Idled:Connect(function()
    if not Hub.AntiAfk then
        return
    end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end))

---------------------------------------------------------------- UI
local WINDUI_CACHE = "AFKUGCParadise/windui.lua"
local windSrc
pcall(function()
    if isfolder and not isfolder("AFKUGCParadise") then
        makefolder("AFKUGCParadise")
    end
    for _, path in ipairs({ WINDUI_CACHE, "GrabExpressBot/windui.lua" }) do
        if not windSrc and isfile(path) then
            windSrc = readfile(path)
        end
    end
end)
local WindUI = windSrc and #windSrc > 1000 and select(2, pcall(function()
    return loadstring(windSrc)()
end))
if type(WindUI) ~= "table" then
    print("[AFKUGCParadise] Downloading the menu library, this can take ~20 s...")
    windSrc = game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")
    pcall(writefile, WINDUI_CACHE, windSrc)
    WindUI = loadstring(windSrc)()
end

local Window = WindUI:CreateWindow({
    Title = "AFK UGC Paradise",
    Icon = "gift",
    Author = "auto-claim hub",
    Folder = "AFKUGCParadise",
    Size = UDim2.fromOffset(560, 430),
    Theme = "Dark",
})

local Main = Window:Tab({ Title = "Auto Claim", Icon = "gift" })
statusPara = Main:Paragraph({ Title = "Status", Desc = "..." })
Main:Toggle({ Title = "Auto daily gifts", Desc = "5 gifts: 100/200/500/1000/2500 coins by playtime", Value = Hub.Daily, Callback = function(v) Hub.Daily = v end })
Main:Toggle({ Title = "Auto wheel spin", Desc = "Spins whenever a free or extra spin is ready", Value = Hub.Wheel, Callback = function(v) Hub.Wheel = v end })
Main:Toggle({ Title = "Auto community reward", Value = Hub.Community, Callback = function(v) Hub.Community = v end })
Main:Toggle({ Title = "Auto collect coin rain", Desc = "Grabs drops during Coin Rain events", Value = Hub.CoinRain, Callback = function(v) Hub.CoinRain = v end })
Main:Toggle({ Title = "Anti-AFK", Desc = "Stops the 20-minute idle kick", Value = Hub.AntiAfk, Callback = function(v) Hub.AntiAfk = v end })

local UGCTab = Window:Tab({ Title = "Free UGC", Icon = "shopping-bag" })
UGCTab:Toggle({ Title = "Auto claim UGC when coins are enough", Desc = "Walks to the booth, claims, then teleports you back", Value = Hub.AutoUGC, Callback = function(v) Hub.AutoUGC = v end })
local names = { "Any" }
for _, b in ipairs(boothList()) do
    table.insert(names, b.Name)
end
UGCTab:Dropdown({ Title = "Which UGC", Desc = "\"Any\" takes the first affordable one in stock", Values = names, Value = "Any", Callback = function(v) Hub.Target = v end })
ugcPara = UGCTab:Paragraph({ Title = "Booths", Desc = "..." })
logPara = UGCTab:Paragraph({ Title = "Log", Desc = "Waiting..." })

pcall(function() Window:SelectTab(1) end)
pcall(function() Window:Open() end)

---------------------------------------------------------------- loops
local startCoins, startTime = coins(), os.clock()
loop(5, tryDaily)
loop(10, tryWheel)
loop(60, tryCommunity)
loop(0.5, tryCoinRain)
loop(4, tryUGC)
loop(1, function()
    if not statusPara then
        return
    end
    local now = os.time()
    local gained = coins() - startCoins
    local mins = (os.clock() - startTime) / 60
    local rate = mins > 0.5 and (gained / mins * 60) or 0
    local spinIn = (tonumber(LocalPlayer:GetAttribute("NextFreeSpinAt")) or now) - now
    local stage = tonumber(LocalPlayer:GetAttribute("DailyRewardStage")) or 1
    statusPara:SetDesc(string.format(
        "Coins: %s   (x%s multiplier)\nEarned this session: %s  (~%s/hour)\nDaily gift stage: %d/5   Free spin in: %s",
        fmt(coins()), tostring(LocalPlayer:GetAttribute("TotalMultiplier") or 1),
        fmt(gained), fmt(rate), stage,
        spinIn > 0 and string.format("%dh %02dm", spinIn // 3600, (spinIn % 3600) // 60) or "ready"
    ))
end)

log("Hub started")

getgenv().AFKUGCParadiseHub = {
    Hub = Hub,
    Destroy = function()
        Hub.Running = false
        for _, t in ipairs(threads) do
            pcall(task.cancel, t)
        end
        for _, c in ipairs(conns) do
            pcall(function() c:Disconnect() end)
        end
        pcall(function() Window:Destroy() end)
    end,
}
