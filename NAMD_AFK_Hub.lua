--[[
    NAMD Community AFK for UGC - AFK Hub
    - Anti-AFK (answers Roblox's idle kick)
    - Auto-claim the gift chest chain (SistemaRegalos)
    - Auto spin the roulette when a free spin (or an owned extra spin) is ready
    - UGC stand watcher: detects a restock and auto-buys with coins once you can afford it
    - Never spends Robux: ComprarGiros (Robux spins) is never called
    Hide / unhide: the floating "AFK Hub" button (drag it anywhere) or Right Ctrl.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local TOGGLE_KEY = Enum.KeyCode.RightControl

-- Re-running the script replaces the previous copy instead of stacking a second one.
local env = getgenv()
if env.__NAMD_AFK_HUB and env.__NAMD_AFK_HUB.Cleanup then
    pcall(env.__NAMD_AFK_HUB.Cleanup)
end

local hub = { Alive = true, Connections = {}, Threads = {} }
env.__NAMD_AFK_HUB = hub

local function track(conn)
    table.insert(hub.Connections, conn)
    return conn
end

local function spawnLoop(fn)
    local thread = task.spawn(fn)
    table.insert(hub.Threads, thread)
    return thread
end

local settings = {
    AntiAfk = true,
    AutoGift = true,
    AutoSpin = true,
    UseExtraSpins = true,
    UgcNotify = true,
    UgcAutoBuy = true,
    UgcSkipOwned = true,
    UgcWanted = nil, -- nil = every stand; otherwise a set of item names
}

local stats = {
    AfkSaves = 0,
    GiftsClaimed = 0,
    Spins = 0,
    CoinsFromSpins = 0,
    UgcBought = 0,
}

local function fmtTime(seconds)
    seconds = math.max(0, math.floor(seconds))
    local h = seconds // 3600
    local m = (seconds % 3600) // 60
    local s = seconds % 60
    if h > 0 then
        return string.format("%dh %02dm %02ds", h, m, s)
    end
    return string.format("%dm %02ds", m, s)
end

local function fmtNumber(n)
    local s = tostring(math.floor(n))
    return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function getCoins()
    local coins = 0
    pcall(function()
        coins = LocalPlayer.leaderstats.Monedas.Value
    end)
    return coins
end

-- WindUI is cached on disk: the GitHub download can take ~20 s and makes the script look dead.
local function loadWindUI()
    local cachePath = "NAMDHub/windui.lua"
    local source
    if isfile and isfile(cachePath) then
        source = readfile(cachePath)
    else
        source = game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")
        if writefile then
            pcall(function()
                if makefolder and not isfolder("NAMDHub") then
                    makefolder("NAMDHub")
                end
                writefile(cachePath, source)
            end)
        end
    end
    return loadstring(source)()
end

local WindUI = loadWindUI()

local Window = WindUI:CreateWindow({
    Title = "NAMD AFK Hub",
    Author = "Anti-AFK · Rewards · Spin · UGC",
    Folder = "NAMDHub",
    Size = UDim2.fromOffset(540, 420),
    Theme = "Dark",
    Resizable = true,
    IgnoreAlerts = true,
})

local function notify(title, content, duration)
    pcall(function()
        WindUI:Notify({ Title = title, Content = content, Duration = duration or 4 })
    end)
end

local function setDesc(element, text)
    if not element then
        return
    end
    if not pcall(function() element:SetDesc(text) end) then
        pcall(function() element:SetTitle(text) end)
    end
end

-- UGC stands (read once so the UGC tab can list item names) ----------------

local StandsFree = workspace:WaitForChild("StandsFree", 10)
local ugcStands = {} -- { {Model, Name, AssetId, PricePrompt...} }
local productNameCache = {}

local function productName(assetId)
    if not assetId then
        return nil
    end
    if productNameCache[assetId] == nil then
        local ok, info = pcall(function()
            return MarketplaceService:GetProductInfo(assetId)
        end)
        productNameCache[assetId] = ok and info and info.Name or false
    end
    return productNameCache[assetId] or nil
end

local function scanStands()
    table.clear(ugcStands)
    if not StandsFree then
        return
    end
    for _, stand in ipairs(StandsFree:GetChildren()) do
        local buyPart = stand:FindFirstChild("BuyItem")
        local buyPrompt = buyPart and buyPart:FindFirstChildWhichIsA("ProximityPrompt", true)
        local equipPart = stand:FindFirstChild("EquipItem")
        local equipPrompt = equipPart and equipPart:FindFirstChildWhichIsA("ProximityPrompt", true)
        local assetId = equipPrompt and tonumber(equipPrompt:GetAttribute("AssetId"))
        local priceLabel, stockLabel
        pcall(function() priceLabel = stand.CoinsPrice.BillboardGui.TextLabel end)
        pcall(function() stockLabel = stand.DisplayPart.BillboardGui.StockText end)
        if buyPrompt and assetId and priceLabel and stockLabel then
            table.insert(ugcStands, {
                Model = stand,
                StandName = stand.Name,
                AssetId = assetId,
                Name = productName(assetId) or ("Stand " .. stand.Name),
                BuyPart = buyPart,
                BuyPrompt = buyPrompt,
                PriceLabel = priceLabel,
                StockLabel = stockLabel,
                LastAttempt = 0,
                Owned = nil,
                WasInStock = nil,
            })
        end
    end
    table.sort(ugcStands, function(a, b)
        return tonumber(a.StandName) and tonumber(b.StandName) and tonumber(a.StandName) < tonumber(b.StandName) or a.StandName < b.StandName
    end)
end

scanStands()

local function parsePrice(stand)
    local digits = (stand.PriceLabel.Text or ""):gsub("[^%d]", "")
    return tonumber(digits)
end

local function parseStock(stand)
    local available, total = (stand.StockLabel.Text or ""):match("(%d+)%s*/%s*(%d+)")
    return tonumber(available), tonumber(total)
end

local function ownsAsset(stand)
    if stand.Owned ~= nil and os.clock() - (stand.OwnedCheckedAt or 0) < 60 then
        return stand.Owned
    end
    local ok, owned = pcall(function()
        return MarketplaceService:PlayerOwnsAsset(LocalPlayer, stand.AssetId)
    end)
    stand.Owned = ok and owned or false
    stand.OwnedCheckedAt = os.clock()
    return stand.Owned
end

-- Tabs -----------------------------------------------------------------------

local MainTab = Window:Tab({ Title = "Main" })
local RewardTab = Window:Tab({ Title = "Rewards" })
local SpinTab = Window:Tab({ Title = "Spin" })
local UgcTab = Window:Tab({ Title = "UGC" })

-- Main tab
MainTab:Toggle({
    Title = "Anti-AFK",
    Desc = "Stops Roblox from kicking you for being idle",
    Value = settings.AntiAfk,
    Callback = function(state)
        settings.AntiAfk = state
    end,
})

local SessionInfo = MainTab:Paragraph({
    Title = "Session",
    Desc = "Starting...",
})

MainTab:Paragraph({
    Title = "Hide / unhide",
    Desc = "Tap the floating 'AFK Hub' button (drag it anywhere) or press Right Ctrl.",
})

-- Rewards tab
RewardTab:Toggle({
    Title = "Auto-claim gift chests",
    Desc = "Claims each of the 5 timed gift chests as soon as it is ready",
    Value = settings.AutoGift,
    Callback = function(state)
        settings.AutoGift = state
    end,
})

local GiftInfo = RewardTab:Paragraph({
    Title = "Gift chests",
    Desc = "Waiting for state from the server...",
})

-- Spin tab
SpinTab:Toggle({
    Title = "Auto spin",
    Desc = "Spins the roulette whenever a free spin is ready",
    Value = settings.AutoSpin,
    Callback = function(state)
        settings.AutoSpin = state
    end,
})

SpinTab:Toggle({
    Title = "Also use extra spins I already own",
    Desc = "Never buys spins - only uses ones already in your account",
    Value = settings.UseExtraSpins,
    Callback = function(state)
        settings.UseExtraSpins = state
    end,
})

local SpinInfo = SpinTab:Paragraph({
    Title = "Roulette",
    Desc = "Loading...",
})

-- UGC tab
UgcTab:Toggle({
    Title = "Auto-buy UGC on restock",
    Desc = "Buys a stand's UGC with coins as soon as it has stock and you can afford it",
    Value = settings.UgcAutoBuy,
    Callback = function(state)
        settings.UgcAutoBuy = state
    end,
})

UgcTab:Toggle({
    Title = "Notify me when a stand restocks",
    Value = settings.UgcNotify,
    Callback = function(state)
        settings.UgcNotify = state
    end,
})

UgcTab:Toggle({
    Title = "Skip items I already own",
    Desc = "Most of these are 1 per player, so buying again would fail anyway",
    Value = settings.UgcSkipOwned,
    Callback = function(state)
        settings.UgcSkipOwned = state
    end,
})

do
    local names = {}
    for _, stand in ipairs(ugcStands) do
        table.insert(names, stand.Name)
    end
    if #names > 0 then
        pcall(function()
            UgcTab:Dropdown({
                Title = "Items to auto-buy",
                Desc = "Untick anything you don't want. Most expensive is tried first.",
                Values = names,
                Value = names,
                Multi = true,
                AllowNone = true,
                Callback = function(selected)
                    local wanted = {}
                    for _, name in ipairs(selected or {}) do
                        wanted[name] = true
                    end
                    settings.UgcWanted = wanted
                end,
            })
        end)
    end
end

local UgcInfo = UgcTab:Paragraph({
    Title = "UGC stands",
    Desc = "Scanning...",
})

pcall(function() Window:SelectTab(1) end)
pcall(function() Window:Open() end)

-- Floating hide/unhide button ------------------------------------------------

local guiParent = (gethui and gethui()) or game:GetService("CoreGui")
local toggleGui = Instance.new("ScreenGui")
toggleGui.Name = "NAMDHubToggle"
toggleGui.ResetOnSpawn = false
toggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
toggleGui.DisplayOrder = 999
toggleGui.Parent = guiParent

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "Toggle"
toggleButton.AnchorPoint = Vector2.new(1, 0)
toggleButton.Position = UDim2.new(1, -16, 0, 96)
toggleButton.Size = UDim2.fromOffset(130, 36)
toggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
toggleButton.BackgroundTransparency = 0.1
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 14
toggleButton.Text = "AFK Hub: Hide"
toggleButton.AutoButtonColor = true
toggleButton.Parent = toggleGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = toggleButton

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(120, 200, 255)
stroke.Thickness = 1.5
stroke.Parent = toggleButton

local function refreshToggleText()
    local closed = false
    pcall(function() closed = Window.Closed end)
    toggleButton.Text = closed and "AFK Hub: Show" or "AFK Hub: Hide"
end

local function toggleWindow()
    pcall(function() Window:Toggle() end)
    task.defer(refreshToggleText)
end

-- Drag support that does not fire a toggle at the end of a drag.
do
    local dragging, dragStart, startPos, moved = false, nil, nil, false
    track(toggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, moved = true, false
            dragStart = input.Position
            startPos = toggleButton.Position
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            if delta.Magnitude > 6 then
                moved = true
            end
            toggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging and not moved then
                toggleWindow()
            end
            dragging = false
        end
    end))
end

track(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.KeyCode == TOGGLE_KEY then
        toggleWindow()
    end
end))

-- Anti-AFK -------------------------------------------------------------------

track(LocalPlayer.Idled:Connect(function()
    if not settings.AntiAfk then
        return
    end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    stats.AfkSaves += 1
end))

-- Gift chest chain -----------------------------------------------------------

local SistemaRegalos = ReplicatedStorage:WaitForChild("SistemaRegalos", 10)
local ReclamarRegalo = SistemaRegalos and SistemaRegalos:FindFirstChild("ReclamarRegalo")
local EstadoRegalos = SistemaRegalos and SistemaRegalos:FindFirstChild("EstadoRegalos")
local giftState = nil
local GIFT_COUNT = 5

if EstadoRegalos then
    track(EstadoRegalos.OnClientEvent:Connect(function(state)
        if type(state) == "table" then
            giftState = state
        end
    end))
end

spawnLoop(function()
    local lastStateRequest = 0
    local lastClaimAttempt = 0
    while hub.Alive do
        if ReclamarRegalo then
            local now = workspace:GetServerTimeNow()
            if not giftState or os.clock() - lastStateRequest > 60 then
                lastStateRequest = os.clock()
                pcall(function() ReclamarRegalo:FireServer("estado") end)
            end

            if giftState then
                local nextGift = tonumber(giftState.siguiente) or 0
                local readyIn = (tonumber(giftState.disponibleEn) or 0) - now
                if nextGift > GIFT_COUNT then
                    setDesc(GiftInfo, "All 5 gift chests claimed. Watching for a reset.")
                elseif readyIn > 0 then
                    setDesc(GiftInfo, string.format("Next: chest %d of %d in %s\nClaimed this session: %d", nextGift, GIFT_COUNT, fmtTime(readyIn), stats.GiftsClaimed))
                else
                    setDesc(GiftInfo, string.format("Chest %d of %d is READY%s\nClaimed this session: %d", nextGift, GIFT_COUNT, settings.AutoGift and " - claiming..." or "", stats.GiftsClaimed))
                    if settings.AutoGift and os.clock() - lastClaimAttempt > 3 then
                        lastClaimAttempt = os.clock()
                        local before = nextGift
                        pcall(function() ReclamarRegalo:FireServer() end)
                        task.wait(1.5)
                        if giftState and (tonumber(giftState.siguiente) or 0) > before then
                            stats.GiftsClaimed += 1
                            notify("Gift claimed", string.format("Chest %d of %d", before, GIFT_COUNT))
                        else
                            pcall(function() ReclamarRegalo:FireServer("estado") end)
                        end
                    end
                end
            end
        else
            setDesc(GiftInfo, "Gift system not found in this game.")
        end
        task.wait(1)
    end
end)

-- Roulette -------------------------------------------------------------------

local SistemaRuleta = ReplicatedStorage:WaitForChild("SistemaRuleta", 10)
local ObtenerEstado = SistemaRuleta and SistemaRuleta:FindFirstChild("ObtenerEstado")
local Girar = SistemaRuleta and SistemaRuleta:FindFirstChild("Girar")
local EstadoActualizado = SistemaRuleta and SistemaRuleta:FindFirstChild("EstadoActualizado")

local spin = { freeAt = nil, extra = 0, busy = false, lastWin = nil }

local function applySpinState(state)
    if type(state) ~= "table" then
        return
    end
    spin.freeAt = os.clock() + (tonumber(state.restante) or 0)
    spin.extra = tonumber(state.giros) or 0
end

local function refreshSpinState()
    if not ObtenerEstado then
        return
    end
    local ok, state = pcall(function()
        return ObtenerEstado:InvokeServer()
    end)
    if ok then
        applySpinState(state)
    end
end

if EstadoActualizado then
    track(EstadoActualizado.OnClientEvent:Connect(applySpinState))
end

spawnLoop(function()
    local lastRefresh = 0
    while hub.Alive do
        if Girar and ObtenerEstado then
            if not spin.freeAt or os.clock() - lastRefresh > 30 then
                lastRefresh = os.clock()
                refreshSpinState()
            end

            if spin.freeAt then
                local freeIn = spin.freeAt - os.clock()
                local freeReady = freeIn <= 0
                local canSpin = freeReady or (settings.UseExtraSpins and spin.extra > 0)

                local lines = {
                    freeReady and "Free spin: READY" or ("Free spin in " .. fmtTime(freeIn)),
                    "Extra spins owned: " .. spin.extra,
                    string.format("Spins this session: %d  ·  Coins won: %s", stats.Spins, fmtNumber(stats.CoinsFromSpins)),
                }
                if spin.lastWin then
                    table.insert(lines, "Last win: " .. fmtNumber(spin.lastWin) .. " coins")
                end
                setDesc(SpinInfo, table.concat(lines, "\n"))

                if settings.AutoSpin and canSpin and not spin.busy then
                    spin.busy = true
                    local ok, result = pcall(function()
                        return Girar:InvokeServer()
                    end)
                    if ok and type(result) == "table" and result.ok then
                        stats.Spins += 1
                        local coins = tonumber(result.monedas) or 0
                        stats.CoinsFromSpins += coins
                        spin.lastWin = coins
                        applySpinState(result.estado)
                        notify("Roulette", "You won " .. fmtNumber(coins) .. " coins!")
                        task.wait((tonumber(result.duracion) or 5) + 1)
                    else
                        refreshSpinState()
                        task.wait(5)
                    end
                    spin.busy = false
                end
            end
        else
            setDesc(SpinInfo, "Roulette not found in this game.")
        end
        task.wait(1)
    end
end)

-- UGC watcher + auto-buy -----------------------------------------------------

local ugcBusy = false
local BUY_RETRY_SECONDS = 20

local function wantsStand(stand)
    if not settings.UgcWanted then
        return true
    end
    return settings.UgcWanted[stand.Name] == true
end

-- Walks the purchase exactly like a player: stand at the BuyItem prompt, press it,
-- then return to where you were. The server checks coins and stock itself.
local function buyStand(stand, price)
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return false, "no character"
    end
    local coinsBefore = getCoins()
    local returnCFrame = root.CFrame

    root.CFrame = CFrame.new(stand.BuyPart.Position + Vector3.new(0, 3, 0))
    task.wait(0.45) -- let the new position replicate; the prompt distance is checked server-side
    pcall(function() fireproximityprompt(stand.BuyPrompt) end)

    local bought = false
    for _ = 1, 20 do
        task.wait(0.25)
        if getCoins() <= coinsBefore - price * 0.9 then
            bought = true
            break
        end
    end

    if root.Parent then
        root.CFrame = returnCFrame
    end

    if not bought then
        stand.Owned = nil -- re-check ownership next time
        if ownsAsset(stand) then
            bought = true
        end
    end
    return bought
end

local function onRestock(stand, available, total)
    if settings.UgcNotify then
        notify("UGC RESTOCK!", string.format("%s is back: %d/%d left", stand.Name, available, total or 0), 8)
    end
end

spawnLoop(function()
    while hub.Alive do
        local coins = getCoins()
        local lines = {}
        local candidates = {}

        for _, stand in ipairs(ugcStands) do
            local price = parsePrice(stand)
            local available, total = parseStock(stand)
            local inStock = available and available > 0

            if stand.WasInStock == false and inStock then
                onRestock(stand, available, total)
            end
            stand.WasInStock = inStock and true or false

            local status
            local owned = settings.UgcSkipOwned and ownsAsset(stand)
            if owned then
                status = "owned ✓"
            elseif not inStock then
                status = "sold out"
            elseif not price then
                status = "price unknown"
            elseif coins < price then
                status = "IN STOCK - need " .. fmtNumber(price - coins) .. " more coins"
            else
                status = "IN STOCK - affordable"
                if settings.UgcAutoBuy and wantsStand(stand) and os.clock() - stand.LastAttempt > BUY_RETRY_SECONDS then
                    table.insert(candidates, { stand = stand, price = price })
                end
            end

            table.insert(lines, string.format("%s - %s coins - %s/%s - %s",
                stand.Name,
                price and fmtNumber(price) or "?",
                available and tostring(available) or "?",
                total and tostring(total) or "?",
                status))
        end

        table.insert(lines, "")
        table.insert(lines, "Your coins: " .. fmtNumber(coins) .. "  ·  Bought this session: " .. stats.UgcBought)
        if #ugcStands == 0 then
            lines = { "No UGC stands found (workspace.StandsFree)." }
        end
        setDesc(UgcInfo, table.concat(lines, "\n"))

        if #candidates > 0 and not ugcBusy then
            table.sort(candidates, function(a, b) return a.price > b.price end)
            local pick = candidates[1]
            ugcBusy = true
            pick.stand.LastAttempt = os.clock()
            notify("Buying UGC", "Trying to buy " .. pick.stand.Name .. " for " .. fmtNumber(pick.price) .. " coins...", 5)
            local ok, bought = pcall(buyStand, pick.stand, pick.price)
            if ok and bought then
                stats.UgcBought += 1
                pick.stand.Owned = true
                notify("UGC bought!", pick.stand.Name .. " - if Roblox shows a purchase window, press Get/Buy to finish.", 10)
            else
                notify("UGC not bought yet", pick.stand.Name .. " - will retry in " .. BUY_RETRY_SECONDS .. "s if still in stock.", 6)
            end
            ugcBusy = false
        end

        task.wait(1)
    end
end)

-- Re-scan stands if the game rebuilds them (new stand or new item).
if StandsFree then
    track(StandsFree.ChildAdded:Connect(function()
        task.wait(1)
        scanStands()
    end))
end

-- Session panel --------------------------------------------------------------

local startedAt = os.clock()
spawnLoop(function()
    while hub.Alive do
        setDesc(SessionInfo, string.format(
            "Running for %s\nCoins: %s\nAnti-AFK: %s (saved you %d times)\nGifts claimed: %d  ·  Spins: %d  ·  UGC bought: %d",
            fmtTime(os.clock() - startedAt),
            fmtNumber(getCoins()),
            settings.AntiAfk and "ON" or "OFF",
            stats.AfkSaves,
            stats.GiftsClaimed,
            stats.Spins,
            stats.UgcBought
        ))
        refreshToggleText()
        task.wait(1)
    end
end)

-- Cleanup (used when the script is run again) -------------------------------

function hub.Cleanup()
    hub.Alive = false
    for _, conn in ipairs(hub.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    for _, thread in ipairs(hub.Threads) do
        pcall(task.cancel, thread)
    end
    pcall(function() toggleGui:Destroy() end)
    pcall(function() Window:Destroy() end)
end

notify("NAMD AFK Hub", "Loaded. Right Ctrl or the AFK Hub button hides the menu.")
