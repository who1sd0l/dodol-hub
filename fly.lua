-- StarterPlayerScripts/MovementSuite.client.lua
-- Fly + Run + Noclip + Teleport-To-Player (no server script required) + Professional UI

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- =================== Settings (do not change names) ===================
local settings = {
	HideGuiKey = Enum.KeyCode.Semicolon, -- toggle UI
	FlyKey = Enum.KeyCode.F,
	NoclipKey = Enum.KeyCode.N,
	SprintKey = Enum.KeyCode.LeftShift,
	RequireShiftForFly = true, -- Shift+F for fly
	RequireShiftForNoclip = true, -- Shift+N for noclip

	FlySpeed = 60,
	FlyAcceleration = 100,
	WalkSpeed = 16,
	SprintMultiplier = 1.75,
	SprintHold = true, -- when false, sprint toggles
}

-- =================== State ===================
local guiEnabled = true
local flying = false
local noclipOn = false
local sprinting = false

-- =================== Movement core (unchanged) ===================
local function onCharacterAdded(character)
	local root = character:WaitForChild("HumanoidRootPart")
	local humanoid = character:WaitForChild("Humanoid")
	local cam = workspace.CurrentCamera

	local moveVector = Vector3.zero
	local ascend = 0

	local flyConnStepped, flyConnInputs
	local noclipConn
	local sprintConnBegan, sprintConnEnded

	local function updateMoveVector()
		local dir = Vector3.new(moveVector.X, 0, moveVector.Z)
		if dir.Magnitude > 1 then
			dir = dir.Unit
		end

		if flying then
			local look = cam.CFrame
			local worldMove = (look.RightVector * dir.X + look.LookVector * dir.Z)
			local v = worldMove + Vector3.new(0, ascend, 0)
			local speed = settings.FlySpeed
			
			-- Use BodyVelocity for smooth controlled flight
			local bodyVel = root:FindFirstChild("FlyVelocity")
			local bodyGyro = root:FindFirstChild("FlyGyro")
			
			if bodyVel then
				-- When not moving, set velocity to zero to stay in place
				bodyVel.Velocity = v * speed
				-- Keep very high MaxForce active to completely counteract gravity
				bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
			end
			
			if bodyGyro then
				bodyGyro.CFrame = look
			end
		else
			-- ground movement: respect WalkSpeed and Sprint
			local base = settings.WalkSpeed
			if sprinting then
				base = math.max(8, math.floor(settings.WalkSpeed * settings.SprintMultiplier))
			end
			humanoid.WalkSpeed = base
		end
	end

	local function startFlying()
		if flying then return end
		flying = true
		
		-- Reset velocity to prevent launching
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		
		-- Disable gravity and physics properly
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end
		
		-- Create BodyVelocity for better control
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = Vector3.zero
		bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9) -- Very high force to counteract gravity completely
		bodyVelocity.P = 1250 -- Higher power for better position holding
		bodyVelocity.Name = "FlyVelocity"
		bodyVelocity.Parent = root
		
		local bodyGyro = Instance.new("BodyGyro")
		bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		bodyGyro.P = 3000
		bodyGyro.Name = "FlyGyro"
		bodyGyro.Parent = root
		
		-- Set character state to flying
		humanoid.PlatformStand = true

		flyConnStepped = RunService.Heartbeat:Connect(updateMoveVector)
	end

	local function stopFlying()
		if not flying then return end
		flying = false
		if flyConnStepped then flyConnStepped:Disconnect() flyConnStepped = nil end
		
		-- Restore character state
		humanoid.PlatformStand = false
		
		-- Remove fly objects
		local flyVel = root:FindFirstChild("FlyVelocity")
		if flyVel then flyVel:Destroy() end
		local flyGyro = root:FindFirstChild("FlyGyro")
		if flyGyro then flyGyro:Destroy() end
		
		-- Reset all velocities
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end
		
		updateMoveVector()
	end

	local function startNoclip()
		if noclipOn then return end
		noclipOn = true
		noclipConn = RunService.Stepped:Connect(function()
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					part.CanCollide = false
				end
			end
		end)
	end

	local function stopNoclip()
		if not noclipOn then return end
		noclipOn = false
		if noclipConn then noclipConn:Disconnect() noclipConn = nil end
		-- restore collisions
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
	end

	-- Input
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end

		if input.UserInputType == Enum.UserInputType.Keyboard then
			local shiftPressed = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
			
			if input.KeyCode == Enum.KeyCode.W then
				moveVector = Vector3.new(moveVector.X, moveVector.Y, 1)
			elseif input.KeyCode == Enum.KeyCode.S then
				moveVector = Vector3.new(moveVector.X, moveVector.Y, -1)
			elseif input.KeyCode == Enum.KeyCode.A then
				moveVector = Vector3.new(-1, moveVector.Y, moveVector.Z)
			elseif input.KeyCode == Enum.KeyCode.D then
				moveVector = Vector3.new(1, moveVector.Y, moveVector.Z)
			elseif input.KeyCode == settings.FlyKey then
				if settings.RequireShiftForFly then
					if shiftPressed then
						if flying then stopFlying() else startFlying() end
					end
				else
					if flying then stopFlying() else startFlying() end
				end
			elseif input.KeyCode == settings.NoclipKey then
				if settings.RequireShiftForNoclip then
					if shiftPressed then
						if noclipOn then stopNoclip() else startNoclip() end
					end
				else
					if noclipOn then stopNoclip() else startNoclip() end
				end
			elseif input.KeyCode == Enum.KeyCode.Space then
				ascend = 1
			elseif input.KeyCode == settings.SprintKey then
				if settings.SprintHold then
					sprinting = true
				else
					sprinting = not sprinting
				end
			end
			updateMoveVector()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			-- ignore
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gpe)
		if gpe then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S then
				moveVector = Vector3.new(moveVector.X, moveVector.Y, 0)
			elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then
				moveVector = Vector3.new(0, moveVector.Y, moveVector.Z)
			elseif input.KeyCode == Enum.KeyCode.Space then
				ascend = 0
			elseif input.KeyCode == Enum.KeyCode.LeftShift and settings.SprintHold then
				sprinting = false
				humanoid.WalkSpeed = settings.WalkSpeed
			end
			updateMoveVector()
		end
	end)

	humanoid.Died:Connect(function()
		stopFlying()
		stopNoclip()
	end)

	return {
		humanoid = humanoid,
		startFlying = startFlying,
		stopFlying = stopFlying,
		startNoclip = startNoclip,
		stopNoclip = stopNoclip,
	}
end

-- Teleport glue (unchanged)
local function teleportToUserId(targetUserId)
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
		return false, "Target not found"
	end
	local me = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not me then return false, "No character" end
	me.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
	return true
end

-- =================== GUI (updated minimalist) ===================
local function makeGui()
	local ui = {}

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MovementSuiteUI"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = player:WaitForChild("PlayerGui")

	-- Side panel (Cyberpunk Theme)
	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.new(0, 360, 0, 340)
	main.Position = UDim2.new(1, -380, 0, 28)
	main.BackgroundColor3 = Color3.fromRGB(8, 12, 16)
	main.BorderSizePixel = 0
	main.Active = true
	main.Draggable = true
	main.Parent = screenGui
	do
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = main

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Transparency = 0.3
		stroke.Color = Color3.fromRGB(0, 255, 150)
		stroke.Parent = main
	end

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = main

	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, 28)
	header.Parent = main

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -220, 1, 0)
	title.Text = "root@MOVEMENT:~# 🚀"
	title.TextColor3 = Color3.fromRGB(0, 255, 150)
	title.Font = Enum.Font.Code
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local exitBtn = Instance.new("TextButton")
	exitBtn.AnchorPoint = Vector2.new(1,0)
	exitBtn.Position = UDim2.new(1, 0, 0, 0)
	exitBtn.Size = UDim2.new(0, 65, 1, 0)
	exitBtn.Text = "[EXIT]"
	exitBtn.BackgroundColor3 = Color3.fromRGB(80, 10, 20)
	exitBtn.TextColor3 = Color3.fromRGB(255, 0, 80)
	exitBtn.Font = Enum.Font.Code
	exitBtn.TextSize = 13
	exitBtn.AutoButtonColor = false
	exitBtn.Parent = header
	do
		local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = exitBtn
		local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(255, 0, 80) s.Transparency = 0.3 s.Thickness = 2 s.Parent = exitBtn
	end

	local hubBtn = Instance.new("TextButton")
	hubBtn.AnchorPoint = Vector2.new(1,0)
	hubBtn.Position = UDim2.new(1, -75, 0, 0)
	hubBtn.Size = UDim2.new(0, 65, 1, 0)
	hubBtn.Text = "[HUB]"
	hubBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 90)
	hubBtn.TextColor3 = Color3.fromRGB(180, 100, 255)
	hubBtn.Font = Enum.Font.Code
	hubBtn.TextSize = 13
	hubBtn.AutoButtonColor = false
	hubBtn.Parent = header
	do
		local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = hubBtn
		local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(180, 100, 255) s.Transparency = 0.3 s.Thickness = 2 s.Parent = hubBtn
	end

	local hideBtn = Instance.new("TextButton")
	hideBtn.AnchorPoint = Vector2.new(1,0)
	hidden = false
	hideBtn.Position = UDim2.new(1, -150, 0, 0)
	hideBtn.Size = UDim2.new(0, 65, 1, 0)
	hideBtn.Text = "[HIDE]"
	hideBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 100)
	hideBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
	hideBtn.Font = Enum.Font.Code
	hideBtn.TextSize = 13
	hideBtn.AutoButtonColor = false
	hideBtn.Parent = header
	do
		local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = hideBtn
		local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(0, 200, 255) s.Transparency = 0.3 s.Thickness = 2 s.Parent = hideBtn
	end

	local layout = Instance.new("UIListLayout")
	layout.Parent = main
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder

	local function section(name, height)
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 0, height or 110)
		frame.BackgroundColor3 = Color3.fromRGB(5, 8, 10)
		frame.Parent = main
		do
			local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = frame
			local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(0, 255, 150) s.Transparency = 0.6 s.Thickness = 1 s.Parent = frame
		end

		local p = Instance.new("UIPadding")
		p.PaddingTop = UDim.new(0, 8)
		p.PaddingLeft = UDim.new(0, 8)
		p.PaddingRight = UDim.new(0, 8)
		p.PaddingBottom = UDim.new(0, 8)
		p.Parent = frame

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 0, 18)
		label.Text = "┌─ " .. name .. " ───"
		label.Font = Enum.Font.Code
		label.TextSize = 13
		label.TextColor3 = Color3.fromRGB(0, 200, 255)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = frame

		local content = Instance.new("Frame")
		content.BackgroundTransparency = 1
		content.Size = UDim2.new(1, 0, 1, -24)
		content.Position = UDim2.new(0, 0, 0, 24)
		content.Parent = frame

		return frame, content
	end

	local function pillButton(text)
		local b = Instance.new("TextButton")
		b.Text = text
		b.Font = Enum.Font.Code
		b.TextSize = 13
		b.TextColor3 = Color3.fromRGB(0, 255, 150)
		b.AutoButtonColor = false
		b.BackgroundColor3 = Color3.fromRGB(0, 40, 30)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 4)
		c.Parent = b
		local s = Instance.new("UIStroke")
		s.Color = Color3.fromRGB(0, 255, 150)
		s.Transparency = 0.5
		s.Thickness = 1
		s.Parent = b
		return b
	end

	local function valueRow(labelText, startValue)
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, 28)

		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.new(0.35, -6, 1, 0)
		l.Text = labelText .. ": "
		l.Font = Enum.Font.Code
		l.TextSize = 13
		l.TextColor3 = Color3.fromRGB(0, 200, 255)
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Parent = row

		-- Editable value input box
		local valueBox = Instance.new("TextBox")
		valueBox.Size = UDim2.new(0.2, -6, 1, 0)
		valueBox.Position = UDim2.new(0.35, 0, 0, 0)
		valueBox.BackgroundColor3 = Color3.fromRGB(5, 8, 10)
		valueBox.BorderSizePixel = 0
		valueBox.Text = tostring(startValue)
		valueBox.TextColor3 = Color3.fromRGB(0, 255, 150)
		valueBox.Font = Enum.Font.Code
		valueBox.TextSize = 14
		valueBox.TextXAlignment = Enum.TextXAlignment.Center
		valueBox.ClearTextOnFocus = true
		valueBox.Parent = row
		do
			local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = valueBox
			local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(0, 255, 150) s.Transparency = 0.6 s.Thickness = 1 s.Parent = valueBox
		end

		local minus = pillButton("-"); minus.Size = UDim2.new(0.225, -3, 1, 0); minus.Position = UDim2.new(0.55, 6, 0, 0); minus.Parent = row
		local plus  = pillButton("+"); plus.Size  = UDim2.new(0.225, -3, 1, 0);  plus.Position  = UDim2.new(0.775, 6, 0, 0); plus.Parent  = row
		return row, l, valueBox, minus, plus
	end

	-- Section: Motion
	local motion, motionContent = section("Motion", 120)
	local grid = Instance.new("UIGridLayout")
	grid.CellPadding = UDim2.new(0, 6, 0, 6)
	grid.CellSize = UDim2.new(0.5, -9, 0, 28)
	grid.Parent = motionContent

	local flyToggle = pillButton("Fly: OFF"); flyToggle.Parent = motionContent
	local sprintToggle = pillButton("SprintHold: " .. tostring(settings.SprintHold)); sprintToggle.Parent = motionContent
	local noclipToggle = pillButton("Noclip: OFF"); noclipToggle.Parent = motionContent
	local spacer = Instance.new("Frame"); spacer.BackgroundTransparency = 1; spacer.Parent = motionContent

	-- Inline rows
	local flyRow, flyLabel, flyValueBox, flyMinus, flyPlus = valueRow("Fly Speed", settings.FlySpeed); flyRow.Parent = main
	local walkRow, walkLabel, walkValueBox, walkMinus, walkPlus = valueRow("Walk Speed", settings.WalkSpeed); walkRow.Parent = main

	-- Section: Teleport
	local tp, tpContent = section("Teleport To Player", 160)

	-- Search box
	local searchBox = Instance.new("TextBox")
	searchBox.Size = UDim2.new(1, 0, 0, 28)
	searchBox.BackgroundColor3 = Color3.fromRGB(5, 8, 10)
	searchBox.BorderSizePixel = 0
	searchBox.Text = ""
	searchBox.PlaceholderText = "$ search player..."
	searchBox.PlaceholderColor3 = Color3.fromRGB(0, 100, 80)
	searchBox.TextColor3 = Color3.fromRGB(0, 255, 150)
	searchBox.Font = Enum.Font.Code
	searchBox.TextSize = 13
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = tpContent
	do
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = searchBox
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(0, 255, 150)
		stroke.Transparency = 0.6
		stroke.Thickness = 1
		stroke.Parent = searchBox
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 8)
		padding.PaddingRight = UDim.new(0, 8)
		padding.Parent = searchBox
	end

	local dropdown = pillButton("Select player"); dropdown.Size = UDim2.new(1, 0, 0, 28); dropdown.Position = UDim2.new(0, 0, 0, 34); dropdown.Parent = tpContent
	local goBtn = pillButton("Teleport"); goBtn.Size = UDim2.new(1, 0, 0, 28); goBtn.Position = UDim2.new(0, 0, 0, 68); goBtn.Parent = tpContent

	local status = Instance.new("TextLabel")
	status.BackgroundTransparency = 1
	status.Size = UDim2.new(1, 0, 0, 20)
	status.Position = UDim2.new(0, 0, 0, 102)
	status.Font = Enum.Font.Code
	status.TextSize = 12
	status.TextColor3 = Color3.fromRGB(0, 200, 255)
	status.Text = ""
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = tpContent

	-- Full-screen overlay behind dropdown
	local overlay = Instance.new("TextButton")
	overlay.Name = "DropdownOverlay"
	overlay.AutoButtonColor = false
	overlay.Text = ""
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Visible = false
	overlay.Active = true
	overlay.ZIndex = 4
	overlay.Size = UDim2.fromScale(1,1)
	overlay.Position = UDim2.new(0,0,0,0)
	overlay.Parent = screenGui

	-- Scrollable dropdown list (replaces old listHolder)
	local listHolder = Instance.new("ScrollingFrame")
	listHolder.Name = "List"
	listHolder.Visible = false
	listHolder.Active = true
	listHolder.ClipsDescendants = true
	listHolder.ScrollingDirection = Enum.ScrollingDirection.Y
	listHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listHolder.CanvasSize = UDim2.new(0,0,0,0)
	listHolder.ScrollBarThickness = 4
	listHolder.ZIndex = 5
	listHolder.BackgroundColor3 = Color3.fromRGB(5, 8, 10)
	listHolder.BorderSizePixel = 0
	listHolder.Size = UDim2.new(1, 0, 0, 140)
	listHolder.Position = UDim2.new(0, 0, 0, 30)
	listHolder.Parent = dropdown
	do
		local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = listHolder
		local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(0, 255, 150) s.Transparency = 0.6 s.Thickness = 1 s.Parent = listHolder
		local padIn = Instance.new("UIPadding")
		padIn.PaddingTop = UDim.new(0, 8)
		padIn.PaddingBottom = UDim.new(0, 8)
		padIn.PaddingLeft = UDim.new(0, 8)
		padIn.PaddingRight = UDim.new(0, 8)
		padIn.Parent = listHolder
		local listLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 4)
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Parent = listHolder
	end

	-- Hide toggle (semicolon also supported in main())
	hideBtn.MouseButton1Click:Connect(function()
		guiEnabled = not guiEnabled
		main.Visible = guiEnabled
	end)

	-- Exit button
	exitBtn.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	-- Hub button
	hubBtn.MouseButton1Click:Connect(function()
		if _G.DodolHub and _G.DodolHub.Show then
			_G.DodolHub.Show()
		else
			warn("Hub not found. Make sure you loaded from Dodol Hub!")
		end
	end)

	-- expose
	ui.root = screenGui
	ui.main = main
	ui.flyToggle = flyToggle
	ui.sprintToggle = sprintToggle
	ui.noclipToggle = noclipToggle
	ui.flyLabel = flyLabel
	ui.flyValueBox = flyValueBox
	ui.walkLabel = walkLabel
	ui.walkValueBox = walkValueBox
	ui.flyMinus = flyMinus
	ui.flyPlus = flyPlus
	ui.walkMinus = walkMinus
	ui.walkPlus = walkPlus
	ui.searchBox = searchBox
	ui.dropdown = dropdown
	ui.listHolder = listHolder -- expose as ui.listHolder
	ui.dropdownOverlay = overlay
	ui.goBtn = goBtn
	ui.status = status
	return ui
end

-- =================== Main (UI wiring only; movement untouched) ===================
local function main()
	local ui = makeGui()

	local charController
	local function bindCharacter(char)
		if charController and charController.humanoid then
			charController.stopFlying()
			charController.stopNoclip()
		end
		charController = onCharacterAdded(char)
	end
	if player.Character then bindCharacter(player.Character) end
	player.CharacterAdded:Connect(bindCharacter)

	-- Fly toggle
	ui.flyToggle.MouseButton1Click:Connect(function()
		if not charController then return end
		if flying then
			charController.stopFlying(); ui.flyToggle.Text = "Fly: OFF"
		else
			charController.startFlying(); ui.flyToggle.Text = "Fly: ON"
		end
	end)

	-- Sprint hold toggle
	ui.sprintToggle.MouseButton1Click:Connect(function()
		settings.SprintHold = not settings.SprintHold
		ui.sprintToggle.Text = "SprintHold: " .. tostring(settings.SprintHold)
		if not settings.SprintHold and charController then
			charController.humanoid.WalkSpeed = settings.WalkSpeed
		end
	end)

	-- Noclip toggle
	ui.noclipToggle.MouseButton1Click:Connect(function()
		if not charController then return end
		if noclipOn then
			charController.stopNoclip(); ui.noclipToggle.Text = "Noclip: OFF"
		else
			charController.startNoclip(); ui.noclipToggle.Text = "Noclip: ON"
		end
	end)

	-- Speed adjust
	ui.flyMinus.MouseButton1Click:Connect(function()
		settings.FlySpeed = math.max(5, settings.FlySpeed - 5)
		ui.flyValueBox.Text = tostring(settings.FlySpeed)
	end)
	ui.flyPlus.MouseButton1Click:Connect(function()
		settings.FlySpeed = settings.FlySpeed + 5
		ui.flyValueBox.Text = tostring(settings.FlySpeed)
	end)
	ui.flyValueBox.FocusLost:Connect(function(enterPressed)
		local num = tonumber(ui.flyValueBox.Text)
		if num and num >= 5 then
			settings.FlySpeed = math.floor(num)
		end
		ui.flyValueBox.Text = tostring(settings.FlySpeed)
	end)

	ui.walkMinus.MouseButton1Click:Connect(function()
		settings.WalkSpeed = math.max(4, settings.WalkSpeed - 2)
		ui.walkValueBox.Text = tostring(settings.WalkSpeed)
		if charController and not sprinting then
			charController.humanoid.WalkSpeed = settings.WalkSpeed
		end
	end)
	ui.walkPlus.MouseButton1Click:Connect(function()
		settings.WalkSpeed = settings.WalkSpeed + 2
		ui.walkValueBox.Text = tostring(settings.WalkSpeed)
		if charController and not sprinting then
			charController.humanoid.WalkSpeed = settings.WalkSpeed
		end
	end)
	ui.walkValueBox.FocusLost:Connect(function(enterPressed)
		local num = tonumber(ui.walkValueBox.Text)
		if num and num >= 4 then
			settings.WalkSpeed = math.floor(num)
			if charController and not sprinting then
				charController.humanoid.WalkSpeed = settings.WalkSpeed
			end
		end
		ui.walkValueBox.Text = tostring(settings.WalkSpeed)
	end)

	-- Quick hide key (semicolon)
	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == settings.HideGuiKey then
			guiEnabled = not guiEnabled
			ui.main.Visible = guiEnabled
		end
	end)

	-- ===== Player dropdown (scrollable, outside-click close) =====
	local selectedUserId
	local tmpConns = {}
	local currentSearchFilter = ""

	local function setDropdownOpen(isOpen)
		ui.listHolder.Visible = isOpen
		ui.dropdownOverlay.Visible = isOpen
	end
	local function closeDropdown()
		setDropdownOpen(false)
	end

	-- Debounced rebuild of player list
	local rebuilding = false
	local pending = false
	local function _buildNow()
		for _, c in ipairs(ui.listHolder:GetChildren()) do
			if c:IsA("TextButton") then
				c:Destroy()
			end
		end

		local others = {}
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then 
				-- Filter by search text
				local searchText = currentSearchFilter:lower()
				if searchText == "" or 
				   plr.DisplayName:lower():find(searchText, 1, true) or 
				   plr.Name:lower():find(searchText, 1, true) then
					table.insert(others, plr) 
				end
			end
		end

		if #others == 0 then
			if currentSearchFilter ~= "" then
				ui.dropdown.Text = "No matches"
			else
				selectedUserId = nil
				ui.dropdown.Text = "No other players"
			end
			return
		end

		-- reset label if previous selection is gone
		local stillValid = selectedUserId and Players:GetPlayerByUserId(selectedUserId)
		if not stillValid then
			ui.dropdown.Text = "Select player"
		end

		for _, plr in ipairs(others) do
			local item = Instance.new("TextButton")
			item.Name = "Option_" .. plr.UserId
			item.Size = UDim2.new(1, 0, 0, 28)
			item.BackgroundColor3 = Color3.fromRGB(52,52,60)
			item.BackgroundTransparency = 0
			item.AutoButtonColor = false
			item.Text = ("  %s (@%s)"):format(plr.DisplayName, plr.Name)
			item.TextXAlignment = Enum.TextXAlignment.Left
			item.TextColor3 = Color3.fromRGB(235,235,240)
			item.Font = Enum.Font.Gotham
			item.TextSize = 14
			item.Selectable = true
			item.ZIndex = ui.listHolder.ZIndex + 1
			item.Parent = ui.listHolder

			local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0, 6); ic.Parent = item

			-- subtle hover/press feedback
			item.MouseEnter:Connect(function() item.BackgroundTransparency = 0.1 end)
			item.MouseLeave:Connect(function() item.BackgroundTransparency = 0 end)
			item.MouseButton1Down:Connect(function() item.BackgroundTransparency = 0.15 end)
			item.MouseButton1Up:Connect(function() item.BackgroundTransparency = 0.1 end)

			item.MouseButton1Click:Connect(function()
				selectedUserId = plr.UserId
				ui.dropdown.Text = "Target: " .. plr.DisplayName
				ui.status.Text = ""
				closeDropdown()
			end)
		end
	end

	local function rebuildList()
		if rebuilding then
			pending = true
			return
		end
		rebuilding = true
		task.delay(0.1, function()
			_buildNow()
			rebuilding = false
			if pending then
				pending = false
				rebuildList()
			end
		end)
	end

	-- initial build
	rebuildList()

	-- Search box filtering
	ui.searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		currentSearchFilter = ui.searchBox.Text
		rebuildList()
		-- Auto-open dropdown when typing
		if currentSearchFilter ~= "" and not ui.listHolder.Visible then
			setDropdownOpen(true)
		end
	end)

	-- Keep dropdown open when clicking in search box
	ui.searchBox.Focused:Connect(function()
		if ui.dropdown.Text ~= "No other players" then
			setDropdownOpen(true)
		end
	end)

	-- player signals (debounced)
	table.insert(tmpConns, Players.PlayerAdded:Connect(function()
		rebuildList()
	end))
	table.insert(tmpConns, Players.PlayerRemoving:Connect(function(rem)
		if selectedUserId == rem.UserId then
			selectedUserId = nil
			ui.dropdown.Text = "Select player"
		end
		rebuildList()
	end))

	-- open/close interactions
	ui.dropdown.MouseButton1Click:Connect(function()
		if ui.dropdown.Text == "No other players" or ui.dropdown.Text == "No matches" then return end
		setDropdownOpen(not ui.listHolder.Visible)
	end)
	table.insert(tmpConns, ui.dropdownOverlay.MouseButton1Click:Connect(function()
		-- Only close if not clicking on search box
		closeDropdown()
		ui.searchBox:ReleaseFocus()
	end))

	-- Teleport wiring (unchanged behavior)
	ui.goBtn.MouseButton1Click:Connect(function()
		if not selectedUserId then
			ui.status.Text = "Select a player first."
			return
		end
		local ok, err = teleportToUserId(selectedUserId)
		if ok then
			ui.status.Text = "Teleported to target."
		else
			ui.status.Text = "Failed: " .. tostring(err)
		end
	end)

	-- Cleanup temporary connections on GUI destroy / player leave
	local function cleanup()
		for _, conn in ipairs(tmpConns) do
			if conn and conn.Disconnect then
				conn:Disconnect()
			end
		end
		tmpConns = {}
		if ui.dropdownOverlay then ui.dropdownOverlay.Visible = false end
		if ui.listHolder then ui.listHolder.Visible = false end
	end
	table.insert(tmpConns, ui.root.AncestryChanged:Connect(function(_, parent)
		if not parent then cleanup() end
	end))
	player.AncestryChanged:Connect(function(_, parent)
		if not parent then cleanup() end
	end)

	-- Safety on leave (existing)
	player.AncestryChanged:Connect(function(_, parent)
		if not parent and charController then
			charController.stopFlying()
			charController.stopNoclip()
		end
	end)
end

-- run
main()
