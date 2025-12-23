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

local LOCAL_PLAYER = Players.LocalPlayer

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

--==== Enhanced Teleport ====--
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

    -- Hide locally (invisible to yourself only)
    setCharacterVisible(char, false)

    local dist = (hrp.Position - cf.Position).Magnitude
    local tooFar = dist > 500

    hum.Sit = false
    hum.PlatformStand = false
    hum.AutoRotate = true
    hum:ChangeState(Enum.HumanoidStateType.Physics)

    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    if tooFar then
        hrp.CFrame = cf + Vector3.new(0, 3, 0)
        task.wait(0.3)
    else
        local goal = { CFrame = cf + Vector3.new(0, 6, 0) }
        local tween = TweenService:Create(hrp, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
        tween:Play()

        local originalGravity = workspace.Gravity
        workspace.Gravity = 4
        tween.Completed:Wait()
        workspace.Gravity = originalGravity

        task.wait(0.05)
        TweenService:Create(hrp, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
            { CFrame = cf + Vector3.new(0,3,0) }):Play()
    end

    -- Restore physics and smooth landing
    hum.PlatformStand = false
    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    task.wait(0.1)
    hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)

    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    -- Reappear after short delay
    task.delay(0.2, function()
        setCharacterVisible(char, true)
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

local function upsertEntries(newOnes)
    local appended = 0
    for _, e in ipairs(newOnes) do
        if not Saved.map[e.key] then
            Saved.map[e.key] = e
            table.insert(Saved.list, e)
            appended += 1
        else
            local existing = Saved.map[e.key]
            existing.label = e.label or existing.label
            existing.reason = e.reason or existing.reason
            existing.cframe = e.cframe or existing.cframe
            existing.instance = e.instance or existing.instance
        end
    end
    if appended > 0 then
        sortEntriesInPlace(Saved.list)
    end
end

--==== GUI ====--
local function createGui()
    local BG_PANEL   = Color3.fromRGB(20,20,25)
    local BG_CARD    = Color3.fromRGB(30,30,36)
    local BG_BUTTON  = Color3.fromRGB(40,40,48)
    local TXT_MAIN   = Color3.fromRGB(255,255,255)
    local TXT_MUTED  = Color3.fromRGB(220,220,230)
    local ACCENT     = Color3.fromRGB(140,220,255)
    local PADDING    = 8
    local currentData = {}

    local function hoverify(btn: GuiObject)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                {BackgroundColor3 = ACCENT}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                {BackgroundColor3 = BG_BUTTON}):Play()
        end)
    end

    local screen = Instance.new("ScreenGui")
    screen.Name = "SmartCheckpointUI"
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.IgnoreGuiInset = false
    screen.DisplayOrder = 100
    screen.Parent = LOCAL_PLAYER:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Name = "Panel"
    frame.BackgroundColor3 = BG_PANEL
    frame.BorderSizePixel = 0
    frame.Size = UDim2.fromOffset(360, 420)
    frame.Position = UDim2.fromScale(0.03, 0.25)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screen
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    local fPad = Instance.new("UIPadding", frame)
    fPad.PaddingTop    = UDim.new(0, PADDING)
    fPad.PaddingBottom = UDim.new(0, PADDING)
    fPad.PaddingLeft   = UDim.new(0, PADDING)
    fPad.PaddingRight  = UDim.new(0, PADDING)

    local top = Instance.new("Frame")
    top.BackgroundTransparency = 1
    top.Size = UDim2.new(1, 0, 0, 28)
    top.Parent = frame

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Text = "Smart Checkpoints"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = TXT_MAIN
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Size = UDim2.new(1, -28, 1, 0)
    title.Parent = top

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Text = "×"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.TextColor3 = TXT_MAIN
    closeBtn.BackgroundTransparency = 1
    closeBtn.AutoButtonColor = false
    closeBtn.Size = UDim2.fromOffset(24, 24)
    closeBtn.Position = UDim2.new(1, -24, 0, 2)
    closeBtn.Parent = top

    local hubBtn = Instance.new("TextButton")
    hubBtn.Name = "HubButton"
    hubBtn.Text = "Hub"
    hubBtn.TextSize = 14
    hubBtn.Font = Enum.Font.GothamMedium
    hubBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    hubBtn.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    hubBtn.AutoButtonColor = true
    hubBtn.Size = UDim2.fromOffset(60, 20)
    hubBtn.Position = UDim2.new(1, -156, 0, 4)
    hubBtn.Parent = top
    local hubCorner = Instance.new("UICorner")
    hubCorner.CornerRadius = UDim.new(0, 6)
    hubCorner.Parent = hubBtn
    
    local exitBtn = Instance.new("TextButton")
    exitBtn.Name = "ExitButton"
    exitBtn.Text = "Exit"
    exitBtn.TextSize = 14
    exitBtn.Font = Enum.Font.GothamMedium
    exitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    exitBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    exitBtn.AutoButtonColor = true
    exitBtn.Size = UDim2.fromOffset(60, 20)
    exitBtn.Position = UDim2.new(1, -90, 0, 4)
    exitBtn.Parent = top
    local exitCorner = Instance.new("UICorner")
    exitCorner.CornerRadius = UDim.new(0, 6)
    exitCorner.Parent = exitBtn

    local search = Instance.new("TextBox")
    search.Name = "Search"
    search.PlaceholderText = "Search checkpoints…"
    search.Font = Enum.Font.Gotham
    search.TextSize = 14
    search.Text = ""
    search.TextColor3 = TXT_MAIN
    search.PlaceholderColor3 = TXT_MUTED
    search.BackgroundColor3 = BG_CARD
    search.BorderSizePixel = 0
    search.ClearTextOnFocus = false
    search.Size = UDim2.new(1, 0, 0, 32)
    search.Position = UDim2.fromOffset(0, 28 + PADDING)
    search.Parent = frame
    Instance.new("UICorner", search).CornerRadius = UDim.new(0, 8)

    local refresh = Instance.new("TextButton")
    refresh.Name = "Refresh"
    refresh.Text = "Refresh"
    refresh.Font = Enum.Font.GothamMedium
    refresh.TextSize = 14
    refresh.TextColor3 = Color3.fromRGB(20,20,24)
    refresh.AutoButtonColor = false
    refresh.BackgroundColor3 = BG_BUTTON
    refresh.BorderSizePixel = 0
    refresh.Size = UDim2.fromOffset(96, 30)
    refresh.Position = UDim2.new(1, -96, 0, 28 + PADDING + 32 + PADDING)
    refresh.Parent = frame
    Instance.new("UICorner", refresh).CornerRadius = UDim.new(0, 8)
    hoverify(refresh)

    local listTopY = 28 + PADDING + 32 + PADDING + 30 + PADDING
    local listHolder = Instance.new("Frame")
    listHolder.BackgroundTransparency = 1
    listHolder.Position = UDim2.fromOffset(0, listTopY)
    listHolder.Size = UDim2.new(1, 0, 1, -listTopY)
    listHolder.Parent = frame

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "Results"
    scroll.Active = true
    scroll.BorderSizePixel = 0
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 6
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Size = UDim2.fromScale(1, 1)
    scroll.Parent = listHolder

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local emptyMsg = Instance.new("TextLabel")
    emptyMsg.BackgroundTransparency = 1
    emptyMsg.Text = "No checkpoints found. Press Refresh."
    emptyMsg.Font = Enum.Font.Gotham
    emptyMsg.TextSize = 12
    emptyMsg.TextColor3 = TXT_MUTED
    emptyMsg.Visible = false
    emptyMsg.Size = UDim2.new(1, -8, 0, 16)
    emptyMsg.Position = UDim2.fromOffset(4, 2)
    emptyMsg.Parent = listHolder

    local function clearList()
        for _, c in ipairs(scroll:GetChildren()) do
            if c:IsA("Frame") and c.Name == "Item" then
                c:Destroy()
            end
        end
    end

    local function makeItem(entry)
        local item = Instance.new("Frame")
        item.Name = "Item"
        item.BackgroundColor3 = BG_CARD
        item.BorderSizePixel = 0
        item.Size = UDim2.new(1, -8, 0, 52)
        item.Parent = scroll
        Instance.new("UICorner", item).CornerRadius = UDim.new(0, 8)

        local t = Instance.new("TextLabel")
        t.BackgroundTransparency = 1
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.Font = Enum.Font.GothamBold
        t.TextSize = 14
        t.TextColor3 = TXT_MAIN
        t.Text = entry.label
        t.Position = UDim2.fromOffset(10, 6)
        t.Size = UDim2.new(1, -120, 0, 18)
        t.Parent = item

        local sub = Instance.new("TextLabel")
        sub.BackgroundTransparency = 1
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 12
        sub.TextColor3 = TXT_MUTED
        sub.Text = "Found via: " .. tostring(entry.reason)
        sub.Position = UDim2.fromOffset(10, 28)
        sub.Size = UDim2.new(1, -120, 0, 16)
        sub.Parent = item

        local tp = Instance.new("TextButton")
        tp.Name = "TP"
        tp.Text = "Teleport"
        tp.Font = Enum.Font.GothamMedium
        tp.TextSize = 14
        tp.TextColor3 = Color3.fromRGB(22,22,26)
        tp.AutoButtonColor = false
        tp.BackgroundColor3 = BG_BUTTON
        tp.BorderSizePixel = 0
        tp.Size = UDim2.fromOffset(96, 30)
        tp.Position = UDim2.new(1, -104, 0.5, -15)
        tp.Parent = item
        Instance.new("UICorner", tp).CornerRadius = UDim.new(0, 8)
        hoverify(tp)

        tp.MouseButton1Click:Connect(function()
            TeleportTo(entry.cframe)
        end)
    end

    local function applyFilterAndRender()
        clearList()
        local q = string.lower(search.Text or "")
        local count = 0
        for _, e in ipairs(Saved.list) do
            if q == "" or string.find(string.lower((e.label or "") .. " " .. tostring(e.reason or "")), q, 1, true) then
                makeItem(e)
                count += 1
            end
        end
        emptyMsg.Visible = (count == 0)
    end

    local seq = 0
    local function debounceSearch()
        seq += 1
        local my = seq
        task.delay(0.07, function()
            if my == seq then
                applyFilterAndRender()
            end
        end)
    end

    local function runScan()
        refresh.Text = "Scanning…"
        refresh.Active = false
        task.defer(function()
            local data = SmartScan(workspace)
            upsertEntries(data)
            refresh.Text = "Refresh"
            refresh.Active = true
            applyFilterAndRender()
        end)
    end

    refresh.MouseButton1Click:Connect(runScan)
    search:GetPropertyChangedSignal("Text"):Connect(debounceSearch)
    closeBtn.MouseButton1Click:Connect(function() screen.Enabled = false end)
    hubBtn.MouseButton1Click:Connect(function()
        if _G.DodolHub and _G.DodolHub.Show then
            _G.DodolHub.Show()
        else
            warn("Hub not found. Make sure you loaded from Dodol Hub!")
        end
    end)
    exitBtn.MouseButton1Click:Connect(function()
        screen:Destroy()
    end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.Semicolon then
            screen.Enabled = not screen.Enabled
        end
    end)
    runScan()
    return screen, runScan
end

--==== Boot ====--
task.defer(function()
    createGui()
    task.defer(function() pcall(getCharacter) end)
    pcall(function() StarterGui:SetCore("TopbarEnabled", true) end)
end)
