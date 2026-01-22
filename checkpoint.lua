-- // Smart Checkpoint Scanner + Teleporter (LocalScript)
-- // Minimalist GUI — now with persistent list across Refresh + natural sorting
-- // Enhanced: Smooth teleport landing + local invisibility fix (Option 1)

--==== Services ====--
local Players            = game:GetService("Players")
local CollectionService  = game:GetService("CollectionService")
local TweenService       = game:GetService("TweenService")
local StarterGui         = game:GetService("StarterGui")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local UserInputService   = game:GetService("UserInputService")
local HttpService        = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local LOCAL_PLAYER = Players.LocalPlayer

--==== Game Identification ====--
local PLACE_ID = game.PlaceId
local GAME_NAME = "Unknown"
pcall(function()
    local info = MarketplaceService:GetProductInfo(PLACE_ID)
    if info and info.Name then
        GAME_NAME = info.Name
    end
end)

--==== Persistent Storage Config ====--
local SAVE_FOLDER = "DodolHub/Checkpoints"
local SAVE_FILE = SAVE_FOLDER .. "/" .. tostring(PLACE_ID) .. ".json"

--==== Auto-Teleport State ====--
local AutoTP = {
    enabled = false,
    selectedItems = {},
    currentIndex = 0,
    delay = 2,
    connection = nil,
}

--==== File System Helpers ====--
local function ensureFolder()
    pcall(function()
        if makefolder and not isfolder(SAVE_FOLDER) then
            makefolder("DodolHub")
            makefolder(SAVE_FOLDER)
        end
    end)
end

local function saveCheckpoints(data)
    pcall(function()
        if writefile then
            ensureFolder()
            local saveData = {
                placeId = PLACE_ID,
                gameName = GAME_NAME,
                savedAt = os.date("%Y-%m-%d %H:%M:%S"),
                checkpoints = {}
            }
            for _, entry in ipairs(data) do
                local cpData = {
                    key = entry.key,
                    label = entry.label,
                    reason = entry.reason,
                    path = "",
                    position = nil,
                    rotation = nil,
                }
                -- Save path
                pcall(function()
                    if entry.instance and entry.instance.Parent then
                        cpData.path = entry.instance:GetFullName()
                    end
                end)
                -- Save CFrame as position + rotation
                if entry.cframe then
                    local pos = entry.cframe.Position
                    cpData.position = {x = pos.X, y = pos.Y, z = pos.Z}
                    local rx, ry, rz = entry.cframe:ToEulerAnglesXYZ()
                    cpData.rotation = {x = rx, y = ry, z = rz}
                end
                table.insert(saveData.checkpoints, cpData)
            end
            writefile(SAVE_FILE, HttpService:JSONEncode(saveData))
        end
    end)
end

local function loadCheckpoints()
    local loaded = {}
    pcall(function()
        if readfile and isfile and isfile(SAVE_FILE) then
            local content = readfile(SAVE_FILE)
            local data = HttpService:JSONDecode(content)
            if data and data.checkpoints then
                for _, cpData in ipairs(data.checkpoints) do
                    local cf = nil
                    if cpData.position then
                        local pos = Vector3.new(cpData.position.x, cpData.position.y, cpData.position.z)
                        if cpData.rotation then
                            cf = CFrame.new(pos) * CFrame.Angles(cpData.rotation.x, cpData.rotation.y, cpData.rotation.z)
                        else
                            cf = CFrame.new(pos)
                        end
                    end
                    -- Try to find the instance by path
                    local inst = nil
                    if cpData.path and cpData.path ~= "" then
                        pcall(function()
                            local parts = string.split(cpData.path, ".")
                            local current = game
                            for i, part in ipairs(parts) do
                                if i > 1 then -- Skip "game"
                                    current = current:FindFirstChild(part)
                                    if not current then break end
                                end
                            end
                            inst = current
                        end)
                    end
                    
                    -- Generate matching key based on position (same as SmartScan)
                    local loadedKey = cpData.key
                    if inst and cf then
                        -- Regenerate key to match what SmartScan would generate
                        loadedKey = makeKey(inst, cf)
                    end
                    
                    -- Clean label (remove old 💾 if exists)
                    local cleanLabel = cpData.label:gsub(" 💾", "")
                    local cleanReason = cpData.reason:gsub(" %[SAVED%]", "")
                    
                    table.insert(loaded, {
                        key = loadedKey,
                        label = cleanLabel,
                        reason = cleanReason,
                        cframe = cf,
                        instance = inst,
                        savedPath = cpData.path,
                        isLoaded = true,
                    })
                end
            end
        end
    end)
    return loaded
end

-- Optional: server-side authoritative teleports if provided
local TELEPORT_EVENT : RemoteEvent? = ReplicatedStorage:FindFirstChild("SmartCheckpointTeleport")

--==== Config ====--
local TAGS = { "Checkpoint", "CheckPoint","CP","Flag","Spawn","SpawnPoint","SpawnLocation",
                "CheckpointPart","Respawn","SavePoint","Stage","StageGate" }

local ATTR_KEYS = { "Checkpoint","IsCheckpoint","IsCP","Stage","CheckpointId","CP","cp","is_checkpoint" }

local NAME_KEYWORDS = { "checkpoint","check point","spawn","respawn","save","flag","stage","gate","cp" }

local TPPOINT_NAMES = { "TPPoint","TpPoint","TeleportPoint","Teleport","Teleporter","TelePoint","SpawnPoint" }
local TP_HEIGHT_OFFSET = 4

--==== Character / HRP helpers ====--
local function getCharacter()
    local char = LOCAL_PLAYER.Character
    if not char or not char.Parent then
        char = LOCAL_PLAYER.CharacterAdded:Wait()
    end
    return char
end

local function getHRP(character)
    character = character or getCharacter()
    return character:WaitForChild("HumanoidRootPart", 2)
end

--==== Invisibility helper (Option 1: client-side only) ====--
local function setCharacterVisible(char, visible)
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = visible and 0 or 1
        elseif part:IsA("Decal") then
            part.Transparency = visible and 0 or 1
        end
    end
end

--==== TP point resolution ====--
local function findPreferredTPChild(instance)
    for _, n in ipairs(TPPOINT_NAMES) do
        local child = instance:FindFirstChild(n, true)
        if child then
            if child:IsA("Attachment") then
                return child.WorldCFrame
            elseif child:IsA("BasePart") then
                return child.CFrame
            end
        end
    end
    return nil
end

local function cframeFromInstance(inst : Instance)
    if not inst then return nil end
    local preferred = findPreferredTPChild(inst)
    if preferred then
        return preferred + Vector3.new(0, TP_HEIGHT_OFFSET, 0)
    end
    if inst:IsA("BasePart") then
        return inst.CFrame + Vector3.new(0, TP_HEIGHT_OFFSET, 0)
    end
    if inst:IsA("Model") then
        if inst.PrimaryPart then
            return inst.PrimaryPart.CFrame + Vector3.new(0, TP_HEIGHT_OFFSET, 0)
        else
            local ok, cf = pcall(function() return inst:GetPivot() end)
            if ok and typeof(cf) == "CFrame" then
                return cf + Vector3.new(0, TP_HEIGHT_OFFSET, 0)
            end
        end
    end
    if inst:IsA("Attachment") then
        return inst.WorldCFrame + Vector3.new(0, TP_HEIGHT_OFFSET, 0)
    end
    return nil
end

--==== Heuristics ====--
local function hasAnyCollectionTag(inst)
    for _, tag in ipairs(TAGS) do
        if CollectionService:HasTag(inst, tag) then
            return true, tag
        end
    end
    return false, nil
end

local function hasAnyAttribute(inst)
    for _, key in ipairs(ATTR_KEYS) do
        local v = inst:GetAttribute(key)
        if v ~= nil then
            if typeof(v) == "boolean" and v == true then
                return true, key .. "=true"
            end
            if (typeof(v) == "string" and v ~= "") or (typeof(v) == "number" and v ~= 0) then
                return true, key .. "=" .. tostring(v)
            end
        end
    end
    return false, nil
end

local function nameMatches(inst)
    local n = string.lower(inst.Name or "")
    for _, kw in ipairs(NAME_KEYWORDS) do
        if string.find(n, kw, 1, true) then
            return true, kw
        end
    end
    return false, nil
end

--==== Key generator ====--
local function roundedVec3(v: Vector3)
    return Vector3.new(
        math.floor(v.X*10 + 0.5),
        math.floor(v.Y*10 + 0.5),
        math.floor(v.Z*10 + 0.5)
    )
end

local function makeKey(inst: Instance, cf: CFrame?)
    local pos = (cf and cf.Position) or Vector3.zero
    local r = roundedVec3(pos)
    return inst:GetDebugId() .. "|" .. r.X .. "," .. r.Y .. "," .. r.Z
end

--==== Natural sort ====--
local function tokenizeForNatural(s: string)
    local t = {}
    local i = 1
    while i <= #s do
        local c = s:sub(i,i)
        local isDigit = (c >= "0" and c <= "9")
        local j = i
        while j <= #s do
            local cj = s:sub(j,j)
            local d = (cj >= "0" and cj <= "9")
            if d ~= isDigit then break end
            j = j + 1
        end
        table.insert(t, s:sub(i, j-1))
        i = j
    end
    return t
end

local function naturalLess(aLabel: string, bLabel: string)
    local a = string.lower(aLabel or "")
    local b = string.lower(bLabel or "")
    local at = tokenizeForNatural(a)
    local bt = tokenizeForNatural(b)
    local n = math.max(#at, #bt)
    for i = 1, n do
        local av = at[i]
        local bv = bt[i]
        if av == nil then return true end
        if bv == nil then return false end
        local an = tonumber(av)
        local bn = tonumber(bv)
        if an and bn then
            if an ~= bn then return an < bn end
        else
            if av ~= bv then return av < bv end
        end
    end
    return false
end

--==== Looks-like checkpoint ====--
local function looksLikeCheckpoint(inst : Instance)
    if inst:IsA("SpawnLocation") then
        return true, "SpawnLocation"
    end
    if inst:IsA("BasePart") or inst:IsA("Model") or inst:IsA("Attachment") then
        local t, whichTag = hasAnyCollectionTag(inst)
        if t then return true, "Tag:"..whichTag end

        local a, whichAttr = hasAnyAttribute(inst)
        if a then return true, "Attr:"..whichAttr end

        local m, whichKw = nameMatches(inst)
        if m then return true, "Name:"..whichKw end
    end
    if inst:IsA("BasePart") then
        if inst:FindFirstChildOfClass("TouchTransmitter") then
            local hint = inst:FindFirstChildWhichIsA("BoolValue") or inst:FindFirstChildWhichIsA("StringValue")
            if hint and nameMatches(hint) then
                return true, "TouchHint"
            end
        end
    end
    return false, nil
end

--==== SmartScan ====--
local function SmartScan(root : Instance?)
    root = root or workspace
    local results, seen = {}, {}
    for _, inst in ipairs(root:GetDescendants()) do
        local ok, reason = looksLikeCheckpoint(inst)
        if ok then
            local cf = cframeFromInstance(inst)
            if cf then
                local key = makeKey(inst, cf)
                if not seen[key] then
                    seen[key] = true
                    local label = inst.Name
                    for _, keyAttr in ipairs({ "Stage","CheckpointId","CP","cp" }) do
                        local v = inst:GetAttribute(keyAttr)
                        if v ~= nil then
                            label = string.format("%s  [ %s=%s ]", label, keyAttr, tostring(v))
                            break
                        end
                    end
                    table.insert(results, {
                        key = key,
                        instance = inst,
                        label = label,
                        reason = reason,
                        cframe = cf,
                    })
                end
            end
        end
    end
    return results
end

--==== Enhanced Teleport (Smooth & Natural) ====--
local function TeleportTo(cf : CFrame)
    if not cf then return end
    local char = getCharacter()
    local hrp = getHRP(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not (char and hrp and hum) then return end

    if TELEPORT_EVENT then
        TELEPORT_EVENT:FireServer(cf)
        return
    end

    -- Stop any current movement first
    hum.Sit = false
    hum.PlatformStand = false
    hum.AutoRotate = true
    
    -- Clear all velocity before teleport
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    
    -- Calculate target position (slightly above ground for natural landing)
    local targetCF = cf + Vector3.new(0, 0.5, 0)
    local dist = (hrp.Position - targetCF.Position).Magnitude
    
    -- For short distances, use smooth tween
    if dist <= 200 then
        -- Smooth walk-like teleport
        local tweenTime = math.clamp(dist / 300, 0.2, 0.5)
        
        -- Anchor temporarily to prevent physics interference
        local wasAnchored = hrp.Anchored
        hrp.Anchored = true
        
        -- Smooth tween to destination
        local tween = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            CFrame = targetCF
        })
        tween:Play()
        tween.Completed:Wait()
        
        -- Unanchor and let character settle naturally
        hrp.Anchored = wasAnchored
    else
        -- For long distances, instant teleport with smooth settle
        local wasAnchored = hrp.Anchored
        hrp.Anchored = true
        hrp.CFrame = targetCF
        task.wait(0.05)
        hrp.Anchored = wasAnchored
    end
    
    -- Ensure clean landing - clear any residual velocity
    task.defer(function()
        if hrp and hrp.Parent then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
    
    -- Set to standing state for natural appearance
    task.defer(function()
        if hum and hum.Parent then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
end

--==== Persistent store ====--
local Saved = {
    map = {},
    list = {},
}

local function sortEntriesInPlace(arr)
    table.sort(arr, function(a,b)
        local aHasMeta = string.find(a.label, "%[", 1, true) ~= nil
        local bHasMeta = string.find(b.label, "%[", 1, true) ~= nil
        if aHasMeta ~= bHasMeta then
            return aHasMeta
        end
        return naturalLess(a.label, b.label)
    end)
end

local function upsertEntries(newOnes, skipSave, isFromScan)
    local appended = 0
    for _, e in ipairs(newOnes) do
        if not Saved.map[e.key] then
            Saved.map[e.key] = e
            table.insert(Saved.list, e)
            appended += 1
        else
            local existing = Saved.map[e.key]
            -- Only update non-saved entries from scan, preserve saved entries
            if isFromScan and existing.isLoaded then
                -- Update instance reference only (position might have changed)
                existing.instance = e.instance or existing.instance
            else
                existing.label = e.label or existing.label
                existing.reason = e.reason or existing.reason
                existing.cframe = e.cframe or existing.cframe
                existing.instance = e.instance or existing.instance
            end
        end
    end
    if appended > 0 then
        sortEntriesInPlace(Saved.list)
        -- Auto-save when new checkpoints are found
        if not skipSave then
            saveCheckpoints(Saved.list)
        end
    end
end

-- Load previously saved checkpoints on init
local function initSavedCheckpoints()
    local loaded = loadCheckpoints()
    if #loaded > 0 then
        upsertEntries(loaded, true) -- Skip save on load
        print("📍 Checkpoint Scanner: Loaded " .. #loaded .. " saved checkpoints for " .. GAME_NAME)
    end
end

--==== GUI ====--
local function createGui()
    -- Minimalist Dark Theme
    local BG_PANEL   = Color3.fromRGB(15, 15, 18)
    local BG_CARD    = Color3.fromRGB(25, 25, 30)
    local BG_BUTTON  = Color3.fromRGB(35, 35, 42)
    local TXT_WHITE  = Color3.fromRGB(255, 255, 255)
    local TXT_GRAY   = Color3.fromRGB(180, 180, 180)
    local TXT_DIM    = Color3.fromRGB(120, 120, 130)
    local ACCENT     = Color3.fromRGB(80, 200, 120)      -- Green accent
    local ACCENT2    = Color3.fromRGB(100, 180, 255)     -- Blue accent
    local DANGER     = Color3.fromRGB(255, 90, 90)       -- Red
    local SAVE_CLR   = Color3.fromRGB(200, 220, 80)      -- Yellow-green
    local BORDER     = Color3.fromRGB(50, 50, 55)
    local PADDING    = 10

    local function hoverify(btn, normalColor)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(55, 55, 65)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = normalColor or BG_BUTTON}):Play()
        end)
    end

    local screen = Instance.new("ScreenGui")
    screen.Name = "SmartCheckpointUI"
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.IgnoreGuiInset = false
    screen.DisplayOrder = 100
    screen.Parent = LOCAL_PLAYER:WaitForChild("PlayerGui")

    -- Main Panel
    local frame = Instance.new("Frame")
    frame.Name = "Panel"
    frame.BackgroundColor3 = BG_PANEL
    frame.BorderSizePixel = 0
    frame.Size = UDim2.fromOffset(380, 480)
    frame.Position = UDim2.fromScale(0.03, 0.2)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screen
    
    local frameCorner = Instance.new("UICorner", frame)
    frameCorner.CornerRadius = UDim.new(0, 8)
    
    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = BORDER
    frameStroke.Thickness = 1
    frameStroke.Parent = frame

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.BackgroundColor3 = BG_CARD
    header.BorderSizePixel = 0
    header.Size = UDim2.new(1, 0, 0, 50)
    header.Parent = frame
    
    local headerCorner = Instance.new("UICorner", header)
    headerCorner.CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Text = "📍 CHECKPOINT SCANNER"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = TXT_WHITE
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Position = UDim2.fromOffset(12, 8)
    title.Size = UDim2.new(1, -120, 0, 18)
    title.Parent = header
    
    local gameLabel = Instance.new("TextLabel")
    gameLabel.BackgroundTransparency = 1
    gameLabel.Text = GAME_NAME:sub(1, 40) .. (GAME_NAME:len() > 40 and "..." or "")
    gameLabel.Font = Enum.Font.Gotham
    gameLabel.TextSize = 11
    gameLabel.TextColor3 = ACCENT
    gameLabel.TextXAlignment = Enum.TextXAlignment.Left
    gameLabel.Position = UDim2.fromOffset(12, 28)
    gameLabel.Size = UDim2.new(1, -120, 0, 16)
    gameLabel.Parent = header

    -- Header Buttons
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Text = "—"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.TextColor3 = TXT_GRAY
    closeBtn.BackgroundColor3 = BG_BUTTON
    closeBtn.AutoButtonColor = false
    closeBtn.Size = UDim2.fromOffset(32, 32)
    closeBtn.Position = UDim2.new(1, -76, 0, 9)
    closeBtn.Parent = header
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    hoverify(closeBtn, BG_BUTTON)
    
    local exitBtn = Instance.new("TextButton")
    exitBtn.Name = "Exit"
    exitBtn.Text = "✕"
    exitBtn.Font = Enum.Font.GothamBold
    exitBtn.TextSize = 14
    exitBtn.TextColor3 = DANGER
    exitBtn.BackgroundColor3 = BG_BUTTON
    exitBtn.AutoButtonColor = false
    exitBtn.Size = UDim2.fromOffset(32, 32)
    exitBtn.Position = UDim2.new(1, -40, 0, 9)
    exitBtn.Parent = header
    Instance.new("UICorner", exitBtn).CornerRadius = UDim.new(0, 6)
    hoverify(exitBtn, BG_BUTTON)

    -- Content Area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Position = UDim2.fromOffset(PADDING, 58)
    content.Size = UDim2.new(1, -PADDING*2, 1, -58-PADDING)
    content.Parent = frame

    -- Search Box
    local searchFrame = Instance.new("Frame")
    searchFrame.BackgroundColor3 = BG_CARD
    searchFrame.BorderSizePixel = 0
    searchFrame.Size = UDim2.new(1, 0, 0, 36)
    searchFrame.Parent = content
    Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 6)
    
    local searchIcon = Instance.new("TextLabel")
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.Font = Enum.Font.Gotham
    searchIcon.TextSize = 14
    searchIcon.Position = UDim2.fromOffset(10, 0)
    searchIcon.Size = UDim2.fromOffset(20, 36)
    searchIcon.Parent = searchFrame

    local search = Instance.new("TextBox")
    search.Name = "Search"
    search.PlaceholderText = "Search checkpoints..."
    search.Font = Enum.Font.Gotham
    search.TextSize = 13
    search.Text = ""
    search.TextColor3 = TXT_WHITE
    search.PlaceholderColor3 = TXT_DIM
    search.BackgroundTransparency = 1
    search.BorderSizePixel = 0
    search.ClearTextOnFocus = false
    search.Size = UDim2.new(1, -40, 1, 0)
    search.Position = UDim2.fromOffset(32, 0)
    search.Parent = searchFrame

    -- Button Row
    local btnRow = Instance.new("Frame")
    btnRow.BackgroundTransparency = 1
    btnRow.Position = UDim2.fromOffset(0, 44)
    btnRow.Size = UDim2.new(1, 0, 0, 32)
    btnRow.Parent = content

    local function createBtn(name, text, color, textColor, posX, width)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.TextColor3 = textColor or TXT_WHITE
        btn.BackgroundColor3 = color
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        btn.Size = UDim2.fromOffset(width or 80, 32)
        btn.Position = UDim2.fromOffset(posX, 0)
        btn.Parent = btnRow
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        hoverify(btn, color)
        return btn
    end

    local refresh = createBtn("Refresh", "REFRESH", BG_BUTTON, TXT_WHITE, 0, 75)
    local saveBtn = createBtn("SaveBtn", "💾 SAVE", Color3.fromRGB(45, 55, 35), SAVE_CLR, 83, 75)
    local clearSaveBtn = createBtn("ClearSaveBtn", "🗑 CLEAR", Color3.fromRGB(55, 30, 30), DANGER, 166, 75)
    
    -- Stats Label
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Name = "Stats"
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = "0 found"
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.TextSize = 11
    statsLabel.TextColor3 = TXT_DIM
    statsLabel.TextXAlignment = Enum.TextXAlignment.Right
    statsLabel.Size = UDim2.fromOffset(80, 32)
    statsLabel.Position = UDim2.new(1, -80, 0, 0)
    statsLabel.Parent = btnRow

    -- Results List
    local listHolder = Instance.new("Frame")
    listHolder.BackgroundTransparency = 1
    listHolder.Position = UDim2.fromOffset(0, 84)
    listHolder.Size = UDim2.new(1, 0, 1, -84)
    listHolder.Parent = content

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "Results"
    scroll.Active = true
    scroll.BorderSizePixel = 0
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = ACCENT
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Size = UDim2.fromScale(1, 1)
    scroll.Parent = listHolder

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local emptyMsg = Instance.new("TextLabel")
    emptyMsg.BackgroundTransparency = 1
    emptyMsg.Text = "No checkpoints found.\nPress REFRESH to scan."
    emptyMsg.Font = Enum.Font.Gotham
    emptyMsg.TextSize = 13
    emptyMsg.TextColor3 = TXT_DIM
    emptyMsg.TextXAlignment = Enum.TextXAlignment.Center
    emptyMsg.TextYAlignment = Enum.TextYAlignment.Center
    emptyMsg.Size = UDim2.fromScale(1, 1)
    emptyMsg.Visible = false
    emptyMsg.Parent = listHolder

    local function clearList()
        for _, c in ipairs(scroll:GetChildren()) do
            if c:IsA("Frame") and c.Name == "Item" then
                c:Destroy()
            end
        end
    end
    
    local function updateStats()
        local total = #Saved.list
        local savedCount = 0
        for _, e in ipairs(Saved.list) do
            if e.isLoaded then savedCount += 1 end
        end
        statsLabel.Text = total .. " found" .. (savedCount > 0 and " • " .. savedCount .. " 💾" or "")
    end

    local function makeItem(entry)
        local item = Instance.new("Frame")
        item.Name = "Item"
        item.BackgroundColor3 = BG_CARD
        item.BorderSizePixel = 0
        item.Size = UDim2.new(1, 0, 0, 72)
        item.Parent = scroll
        Instance.new("UICorner", item).CornerRadius = UDim.new(0, 6)
        
        -- Checkbox for selection
        local checkboxBG = Instance.new("Frame")
        checkboxBG.Name = "CheckboxBG"
        checkboxBG.BackgroundColor3 = BG_BUTTON
        checkboxBG.BorderSizePixel = 0
        checkboxBG.Size = UDim2.fromOffset(20, 20)
        checkboxBG.Position = UDim2.fromOffset(8, 26)
        checkboxBG.Parent = item
        Instance.new("UICorner", checkboxBG).CornerRadius = UDim.new(0, 4)
        
        local checkboxStroke = Instance.new("UIStroke")
        checkboxStroke.Color = BORDER
        checkboxStroke.Thickness = 1.5
        checkboxStroke.Parent = checkboxBG
        
        local checkmark = Instance.new("TextLabel")
        checkmark.Name = "Checkmark"
        checkmark.BackgroundTransparency = 1
        checkmark.Text = "✓"
        checkmark.Font = Enum.Font.GothamBold
        checkmark.TextSize = 14
        checkmark.TextColor3 = ACCENT
        checkmark.Size = UDim2.fromScale(1, 1)
        checkmark.Visible = AutoTP.selectedItems[entry.key] or false
        checkmark.Parent = checkboxBG
        
        local checkboxBtn = Instance.new("TextButton")
        checkboxBtn.Name = "CheckboxBtn"
        checkboxBtn.Text = ""
        checkboxBtn.BackgroundTransparency = 1
        checkboxBtn.Size = UDim2.fromOffset(28, 28)
        checkboxBtn.Position = UDim2.fromOffset(4, 22)
        checkboxBtn.ZIndex = 5
        checkboxBtn.Parent = item
        
        checkboxBtn.MouseButton1Click:Connect(function()
            AutoTP.selectedItems[entry.key] = not AutoTP.selectedItems[entry.key]
            checkmark.Visible = AutoTP.selectedItems[entry.key]
            if AutoTP.selectedItems[entry.key] then
                TweenService:Create(checkboxBG, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 40, 48)}):Play()
            else
                TweenService:Create(checkboxBG, TweenInfo.new(0.15), {BackgroundColor3 = BG_BUTTON}):Play()
            end
        end)
        
        -- Saved indicator bar
        if entry.isLoaded then
            local indicator = Instance.new("Frame")
            indicator.BackgroundColor3 = SAVE_CLR
            indicator.BorderSizePixel = 0
            indicator.Size = UDim2.new(0, 3, 1, -8)
            indicator.Position = UDim2.fromOffset(0, 4)
            indicator.Parent = item
            Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 2)
        end

        -- Checkpoint Name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 13
        nameLabel.TextColor3 = TXT_WHITE
        nameLabel.Text = entry.label:gsub(" 💾", "") .. (entry.isLoaded and " 💾" or "")
        nameLabel.Position = UDim2.fromOffset(36, 6)
        nameLabel.Size = UDim2.new(1, -120, 0, 18)
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = item

        -- Detection Method
        local methodLabel = Instance.new("TextLabel")
        methodLabel.BackgroundTransparency = 1
        methodLabel.TextXAlignment = Enum.TextXAlignment.Left
        methodLabel.Font = Enum.Font.Gotham
        methodLabel.TextSize = 11
        methodLabel.TextColor3 = entry.isLoaded and SAVE_CLR or ACCENT2
        methodLabel.Text = tostring(entry.reason):gsub(" %[SAVED%]", "") .. (entry.isLoaded and " [SAVED]" or "")
        methodLabel.Position = UDim2.fromOffset(36, 24)
        methodLabel.Size = UDim2.new(1, -120, 0, 14)
        methodLabel.Parent = item
        
        -- Full Path
        local fullPath = "Unknown"
        pcall(function()
            if entry.savedPath and entry.savedPath ~= "" then
                fullPath = entry.savedPath
            elseif entry.instance and entry.instance.Parent then
                fullPath = entry.instance:GetFullName()
            end
        end)
        
        local pathLabel = Instance.new("TextLabel")
        pathLabel.BackgroundTransparency = 1
        pathLabel.TextXAlignment = Enum.TextXAlignment.Left
        pathLabel.Font = Enum.Font.Gotham
        pathLabel.TextSize = 10
        pathLabel.TextColor3 = TXT_DIM
        pathLabel.Text = fullPath
        pathLabel.Position = UDim2.fromOffset(36, 40)
        pathLabel.Size = UDim2.new(1, -120, 0, 14)
        pathLabel.TextTruncate = Enum.TextTruncate.AtEnd
        pathLabel.Parent = item
        
        -- Position
        local posText = "—"
        if entry.cframe then
            local p = entry.cframe.Position
            posText = string.format("%.0f, %.0f, %.0f", p.X, p.Y, p.Z)
        end
        
        local posLabel = Instance.new("TextLabel")
        posLabel.BackgroundTransparency = 1
        posLabel.TextXAlignment = Enum.TextXAlignment.Left
        posLabel.Font = Enum.Font.Gotham
        posLabel.TextSize = 10
        posLabel.TextColor3 = TXT_GRAY
        posLabel.Text = "📍 " .. posText
        posLabel.Position = UDim2.fromOffset(36, 54)
        posLabel.Size = UDim2.new(1, -120, 0, 14)
        posLabel.Parent = item
        
        -- Copy Button
        local copyBtn = Instance.new("TextButton")
        copyBtn.Name = "Copy"
        copyBtn.Text = "📋"
        copyBtn.Font = Enum.Font.Gotham
        copyBtn.TextSize = 14
        copyBtn.TextColor3 = TXT_GRAY
        copyBtn.BackgroundColor3 = BG_BUTTON
        copyBtn.AutoButtonColor = false
        copyBtn.BorderSizePixel = 0
        copyBtn.Size = UDim2.fromOffset(28, 28)
        copyBtn.Position = UDim2.new(1, -74, 0, 6)
        copyBtn.Parent = item
        Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)
        hoverify(copyBtn, BG_BUTTON)
        
        copyBtn.MouseButton1Click:Connect(function()
            pcall(function()
                if setclipboard then
                    setclipboard(fullPath)
                    copyBtn.Text = "✓"
                    task.delay(1, function() copyBtn.Text = "📋" end)
                elseif toclipboard then
                    toclipboard(fullPath)
                    copyBtn.Text = "✓"
                    task.delay(1, function() copyBtn.Text = "📋" end)
                end
            end)
        end)

        -- Teleport Button
        local tp = Instance.new("TextButton")
        tp.Name = "TP"
        tp.Text = "TP"
        tp.Font = Enum.Font.GothamBold
        tp.TextSize = 12
        tp.TextColor3 = BG_PANEL
        tp.BackgroundColor3 = ACCENT
        tp.AutoButtonColor = false
        tp.BorderSizePixel = 0
        tp.Size = UDim2.fromOffset(36, 28)
        tp.Position = UDim2.new(1, -38, 0, 38)
        tp.Parent = item
        Instance.new("UICorner", tp).CornerRadius = UDim.new(0, 6)
        
        tp.MouseEnter:Connect(function()
            TweenService:Create(tp, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(100, 220, 140)}):Play()
        end)
        tp.MouseLeave:Connect(function()
            TweenService:Create(tp, TweenInfo.new(0.15), {BackgroundColor3 = ACCENT}):Play()
        end)

        tp.MouseButton1Click:Connect(function()
            TeleportTo(entry.cframe)
        end)
    end

    local function applyFilterAndRender()
        clearList()
        local q = string.lower(search.Text or "")
        local count = 0
        for _, e in ipairs(Saved.list) do
            local searchText = string.lower((e.label or "") .. " " .. tostring(e.reason or "") .. " " .. (e.savedPath or ""))
            if q == "" or string.find(searchText, q, 1, true) then
                makeItem(e)
                count += 1
            end
        end
        emptyMsg.Visible = (count == 0)
        updateStats()
    end

    local seq = 0
    local function debounceSearch()
        seq += 1
        local my = seq
        task.delay(0.1, function()
            if my == seq then
                applyFilterAndRender()
            end
        end)
    end

    local function runScan()
        refresh.Text = "..."
        refresh.Active = false
        task.defer(function()
            local data = SmartScan(workspace)
            upsertEntries(data, false, true) -- isFromScan = true
            refresh.Text = "REFRESH"
            refresh.Active = true
            applyFilterAndRender()
        end)
    end
    
    -- Auto-Teleport Controls
    local autoTPFrame = Instance.new("Frame")
    autoTPFrame.Name = "AutoTPFrame"
    autoTPFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    autoTPFrame.BorderSizePixel = 0
    autoTPFrame.Size = UDim2.new(1, 0, 0, 88)
    autoTPFrame.Position = UDim2.fromOffset(0, 320)
    autoTPFrame.Parent = content
    Instance.new("UICorner", autoTPFrame).CornerRadius = UDim.new(0, 6)
    
    local autoTPStroke = Instance.new("UIStroke")
    autoTPStroke.Color = BORDER
    autoTPStroke.Thickness = 1
    autoTPStroke.Parent = autoTPFrame
    
    local autoTPLabel = Instance.new("TextLabel")
    autoTPLabel.BackgroundTransparency = 1
    autoTPLabel.Text = "🤖 AUTO TELEPORT"
    autoTPLabel.Font = Enum.Font.GothamBold
    autoTPLabel.TextSize = 11
    autoTPLabel.TextColor3 = TXT_WHITE
    autoTPLabel.TextXAlignment = Enum.TextXAlignment.Left
    autoTPLabel.Position = UDim2.fromOffset(10, 6)
    autoTPLabel.Size = UDim2.new(1, -20, 0, 14)
    autoTPLabel.Parent = autoTPFrame
    
    -- Select All / Clear Buttons
    local selectAllBtn = Instance.new("TextButton")
    selectAllBtn.Text = "SELECT ALL"
    selectAllBtn.Font = Enum.Font.GothamBold
    selectAllBtn.TextSize = 10
    selectAllBtn.TextColor3 = TXT_WHITE
    selectAllBtn.BackgroundColor3 = BG_BUTTON
    selectAllBtn.AutoButtonColor = false
    selectAllBtn.Size = UDim2.new(0.48, 0, 0, 24)
    selectAllBtn.Position = UDim2.fromOffset(10, 26)
    selectAllBtn.Parent = autoTPFrame
    Instance.new("UICorner", selectAllBtn).CornerRadius = UDim.new(0, 4)
    hoverify(selectAllBtn, BG_BUTTON)
    
    local clearSelBtn = Instance.new("TextButton")
    clearSelBtn.Text = "CLEAR"
    clearSelBtn.Font = Enum.Font.GothamBold
    clearSelBtn.TextSize = 10
    clearSelBtn.TextColor3 = TXT_WHITE
    clearSelBtn.BackgroundColor3 = BG_BUTTON
    clearSelBtn.AutoButtonColor = false
    clearSelBtn.Size = UDim2.new(0.48, 0, 0, 24)
    clearSelBtn.Position = UDim2.new(0.52, 0, 0, 26)
    clearSelBtn.Parent = autoTPFrame
    Instance.new("UICorner", clearSelBtn).CornerRadius = UDim.new(0, 4)
    hoverify(clearSelBtn, BG_BUTTON)
    
    -- Delay Slider
    local delayLabel = Instance.new("TextLabel")
    delayLabel.BackgroundTransparency = 1
    delayLabel.Text = "Delay: " .. AutoTP.delay .. "s"
    delayLabel.Font = Enum.Font.Gotham
    delayLabel.TextSize = 10
    delayLabel.TextColor3 = TXT_GRAY
    delayLabel.TextXAlignment = Enum.TextXAlignment.Left
    delayLabel.Position = UDim2.fromOffset(10, 54)
    delayLabel.Size = UDim2.new(0.4, 0, 0, 12)
    delayLabel.Parent = autoTPFrame
    
    local sliderBG = Instance.new("Frame")
    sliderBG.BackgroundColor3 = BG_BUTTON
    sliderBG.BorderSizePixel = 0
    sliderBG.Size = UDim2.new(1, -100, 0, 4)
    sliderBG.Position = UDim2.fromOffset(75, 58)
    sliderBG.Parent = autoTPFrame
    Instance.new("UICorner", sliderBG).CornerRadius = UDim.new(1, 0)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.BackgroundColor3 = ACCENT
    sliderFill.BorderSizePixel = 0
    sliderFill.Size = UDim2.new((AutoTP.delay - 1) / 9, 0, 1, 0)
    sliderFill.Parent = sliderBG
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
    
    local sliderKnob = Instance.new("Frame")
    sliderKnob.BackgroundColor3 = TXT_WHITE
    sliderKnob.BorderSizePixel = 0
    sliderKnob.Size = UDim2.fromOffset(12, 12)
    sliderKnob.Position = UDim2.new((AutoTP.delay - 1) / 9, -6, 0.5, -6)
    sliderKnob.Parent = sliderBG
    Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)
    
    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Text = ""
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Size = UDim2.fromScale(1, 1)
    sliderBtn.Position = UDim2.fromOffset(0, -4)
    sliderBtn.Parent = sliderBG
    
    local dragging = false
    sliderBtn.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mouse = UserInputService:GetMouseLocation()
            local sliderPos = sliderBG.AbsolutePosition
            local sliderSize = sliderBG.AbsoluteSize
            local relX = math.clamp(mouse.X - sliderPos.X, 0, sliderSize.X)
            local percent = relX / sliderSize.X
            AutoTP.delay = math.floor(1 + percent * 9 + 0.5)
            delayLabel.Text = "Delay: " .. AutoTP.delay .. "s"
            sliderFill.Size = UDim2.new(percent, 0, 1, 0)
            sliderKnob.Position = UDim2.new(percent, -6, 0.5, -6)
        end
    end)
    
    -- Start/Stop Button
    local startTPBtn = Instance.new("TextButton")
    startTPBtn.Name = "StartTP"
    startTPBtn.Text = "▶ START TELEPORT"
    startTPBtn.Font = Enum.Font.GothamBold
    startTPBtn.TextSize = 11
    startTPBtn.TextColor3 = BG_PANEL
    startTPBtn.BackgroundColor3 = ACCENT
    startTPBtn.AutoButtonColor = false
    startTPBtn.Size = UDim2.new(1, -20, 0, 28)
    startTPBtn.Position = UDim2.fromOffset(10, 69)
    startTPBtn.Parent = autoTPFrame
    Instance.new("UICorner", startTPBtn).CornerRadius = UDim.new(0, 6)
    
    startTPBtn.MouseEnter:Connect(function()
        if not AutoTP.enabled then
            TweenService:Create(startTPBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(100, 220, 140)}):Play()
        end
    end)
    startTPBtn.MouseLeave:Connect(function()
        if not AutoTP.enabled then
            TweenService:Create(startTPBtn, TweenInfo.new(0.15), {BackgroundColor3 = ACCENT}):Play()
        else
            TweenService:Create(startTPBtn, TweenInfo.new(0.15), {BackgroundColor3 = DANGER}):Play()
        end
    end)
    
    -- Auto-Teleport Logic
    local function stopAutoTP()
        AutoTP.enabled = false
        AutoTP.currentIndex = 0
        if AutoTP.connection then
            AutoTP.connection:Disconnect()
            AutoTP.connection = nil
        end
        startTPBtn.Text = "▶ START TELEPORT"
        startTPBtn.BackgroundColor3 = ACCENT
    end
    
    local function startAutoTP()
        -- Get selected checkpoints in order
        local selected = {}
        for _, e in ipairs(Saved.list) do
            if AutoTP.selectedItems[e.key] and e.cframe then
                table.insert(selected, e)
            end
        end
        
        if #selected == 0 then
            -- Flash warning
            startTPBtn.Text = "⚠ SELECT CHECKPOINTS"
            task.delay(2, function()
                if not AutoTP.enabled then
                    startTPBtn.Text = "▶ START TELEPORT"
                end
            end)
            return
        end
        
        -- Sort by label (natural sorting)
        table.sort(selected, function(a, b)
            return naturalLess(a.label, b.label)
        end)
        
        AutoTP.enabled = true
        AutoTP.currentIndex = 0
        startTPBtn.Text = "■ STOP (0/" .. #selected .. ")"
        startTPBtn.BackgroundColor3 = DANGER
        
        -- Start teleport loop
        task.spawn(function()
            while AutoTP.enabled and AutoTP.currentIndex < #selected do
                AutoTP.currentIndex += 1
                local entry = selected[AutoTP.currentIndex]
                
                startTPBtn.Text = "■ STOP (" .. AutoTP.currentIndex .. "/" .. #selected .. ")"
                
                -- Teleport
                pcall(function()
                    TeleportTo(entry.cframe)
                end)
                
                -- Wait delay
                local waited = 0
                while waited < AutoTP.delay and AutoTP.enabled do
                    task.wait(0.1)
                    waited += 0.1
                end
                
                if not AutoTP.enabled then break end
            end
            
            -- Finished or stopped
            if AutoTP.enabled then
                startTPBtn.Text = "✓ COMPLETED"
                task.delay(2, function()
                    stopAutoTP()
                end)
            end
        end)
    end
    
    selectAllBtn.MouseButton1Click:Connect(function()
        for _, e in ipairs(Saved.list) do
            AutoTP.selectedItems[e.key] = true
        end
        applyFilterAndRender()
    end)
    
    clearSelBtn.MouseButton1Click:Connect(function()
        AutoTP.selectedItems = {}
        applyFilterAndRender()
    end)
    
    startTPBtn.MouseButton1Click:Connect(function()
        if AutoTP.enabled then
            stopAutoTP()
        else
            startAutoTP()
        end
    end)
    
    -- Button Handlers
    saveBtn.MouseButton1Click:Connect(function()
        saveBtn.Text = "..."
        task.defer(function()
            saveCheckpoints(Saved.list)
            saveBtn.Text = "✓ SAVED"
            task.delay(1.5, function() saveBtn.Text = "💾 SAVE" end)
        end)
    end)
    
    clearSaveBtn.MouseButton1Click:Connect(function()
        clearSaveBtn.Text = "..."
        task.defer(function()
            pcall(function()
                if delfile and isfile and isfile(SAVE_FILE) then
                    delfile(SAVE_FILE)
                end
            end)
            local newList, newMap = {}, {}
            for _, e in ipairs(Saved.list) do
                if not e.isLoaded then
                    table.insert(newList, e)
                    newMap[e.key] = e
                end
            end
            Saved.list = newList
            Saved.map = newMap
            clearSaveBtn.Text = "✓ DONE"
            applyFilterAndRender()
            task.delay(1.5, function() clearSaveBtn.Text = "🗑 CLEAR" end)
        end)
    end)

    refresh.MouseButton1Click:Connect(runScan)
    search:GetPropertyChangedSignal("Text"):Connect(debounceSearch)
    closeBtn.MouseButton1Click:Connect(function() screen.Enabled = false end)
    exitBtn.MouseButton1Click:Connect(function() screen:Destroy() end)
    
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.Semicolon then
            screen.Enabled = not screen.Enabled
        end
    end)
    
    -- Initialize
    initSavedCheckpoints()
    runScan()
    return screen, runScan
end

--==== Boot ====--
task.defer(function()
    createGui()
    task.defer(function() pcall(getCharacter) end)
    pcall(function() StarterGui:SetCore("TopbarEnabled", true) end)
end)
