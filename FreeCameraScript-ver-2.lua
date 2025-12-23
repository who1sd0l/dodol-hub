-- Professional Free Camera Script
-- Controls: WASD + Mouse | Q/E Up/Down | Shift/Ctrl Speed

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Settings
local freeCamEnabled = false
local baseSpeed = 0.5
local rotating = false

-- Camera Variables
local storedCameraType
local storedCameraSubject

-- Input Tracking
local keysDown = {
    W = false,
    A = false,
    S = false,
    D = false,
    E = false,
    Q = false,
    LeftShift = false,
    LeftControl = false
}

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
local ControlsFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local StatusLabel = Instance.new("TextLabel")
local ControlsList = Instance.new("TextLabel")
local ExitButton = Instance.new("TextButton")
local ToggleButton = Instance.new("TextButton")
local HubButton = Instance.new("TextButton")
local HideButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")
local UICorner2 = Instance.new("UICorner")
local UICorner3 = Instance.new("UICorner")
local UICorner4 = Instance.new("UICorner")
local UICorner5 = Instance.new("UICorner")

-- GUI Setup
ScreenGui.Name = "FreeCameraGUI"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Controls Frame
ControlsFrame.Name = "ControlsFrame"
ControlsFrame.Parent = ScreenGui
ControlsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ControlsFrame.BackgroundTransparency = 0.2
ControlsFrame.BorderSizePixel = 0
ControlsFrame.Position = UDim2.new(0.02, 0, 0.3, 0)
ControlsFrame.Size = UDim2.new(0, 280, 0, 360)
ControlsFrame.Visible = true

UICorner.Parent = ControlsFrame
UICorner.CornerRadius = UDim.new(0, 10)

-- Title
Title.Name = "Title"
Title.Parent = ControlsFrame
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 10, 0, 10)
Title.Size = UDim2.new(1, -20, 0, 30)
Title.Font = Enum.Font.GothamBold
Title.Text = "📷 FREE CAMERA MODE"
Title.TextColor3 = Color3.fromRGB(100, 200, 255)
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Status Label
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = ControlsFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 10, 0, 45)
StatusLabel.Size = UDim2.new(1, -20, 0, 20)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Status: Inactive"
StatusLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
StatusLabel.TextSize = 14
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Controls List
ControlsList.Name = "ControlsList"
ControlsList.Parent = ControlsFrame
ControlsList.BackgroundTransparency = 1
ControlsList.Position = UDim2.new(0, 10, 0, 75)
ControlsList.Size = UDim2.new(1, -20, 0, 180)
ControlsList.Font = Enum.Font.Code
ControlsList.Text = [[CONTROLS:
━━━━━━━━━━━━━━━━━━━━

Movement:
  W A S D - Move Camera
  Q - Move Down
  E - Move Up
  
Speed Control:
  Shift - Fast Speed
  Ctrl - Slow Speed
  
Mouse:
  Right Click + Drag
  to Look Around
  
  Scroll - Adjust Speed]]
ControlsList.TextColor3 = Color3.fromRGB(220, 220, 220)
ControlsList.TextSize = 12
ControlsList.TextXAlignment = Enum.TextXAlignment.Left
ControlsList.TextYAlignment = Enum.TextYAlignment.Top

-- Toggle Button
ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = ControlsFrame
ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
ToggleButton.BorderSizePixel = 0
ToggleButton.Position = UDim2.new(0, 10, 1, -90)
ToggleButton.Size = UDim2.new(1, -20, 0, 35)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "ENABLE FREE CAM"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14
ToggleButton.AutoButtonColor = true

UICorner2.Parent = ToggleButton
UICorner2.CornerRadius = UDim.new(0, 8)

-- Exit Button
ExitButton.Name = "ExitButton"
ExitButton.Parent = ControlsFrame
ExitButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
ExitButton.BorderSizePixel = 0
ExitButton.Position = UDim2.new(0, 10, 1, -45)
ExitButton.Size = UDim2.new(1, -20, 0, 35)
ExitButton.Font = Enum.Font.GothamBold
ExitButton.Text = "EXIT SCRIPT"
ExitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ExitButton.TextSize = 14
ExitButton.AutoButtonColor = true

UICorner3.Parent = ExitButton
UICorner3.CornerRadius = UDim.new(0, 8)

-- Hub Button
HubButton.Name = "HubButton"
HubButton.Parent = ControlsFrame
HubButton.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
HubButton.BorderSizePixel = 0
HubButton.Position = UDim2.new(0, 10, 1, -135)
HubButton.Size = UDim2.new(1, -20, 0, 35)
HubButton.Font = Enum.Font.GothamBold
HubButton.Text = "BACK TO HUB"
HubButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HubButton.TextSize = 14
HubButton.AutoButtonColor = true

UICorner4.Parent = HubButton
UICorner4.CornerRadius = UDim.new(0, 8)

-- Hide Button
HideButton.Name = "HideButton"
HideButton.Parent = ControlsFrame
HideButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
HideButton.BorderSizePixel = 0
HideButton.Position = UDim2.new(0, 10, 1, -180)
HideButton.Size = UDim2.new(1, -20, 0, 35)
HideButton.Font = Enum.Font.GothamBold
HideButton.Text = "HIDE GUI"
HideButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HideButton.TextSize = 14
HideButton.AutoButtonColor = true

UICorner5.Parent = HideButton
UICorner5.CornerRadius = UDim.new(0, 8)

-- Functions
local function getSpeed()
    if keysDown.LeftShift then
        return baseSpeed * 2
    elseif keysDown.LeftControl then
        return baseSpeed * 0.3
    else
        return baseSpeed
    end
end

local function enableFreeCam()
    if freeCamEnabled then return end
    
    freeCamEnabled = true
    
    -- Store and set camera
    storedCameraType = Camera.CameraType
    storedCameraSubject = Camera.CameraSubject
    Camera.CameraType = Enum.CameraType.Scriptable
    
    -- Hide character and freeze in place
    local character = LocalPlayer.Character
    if character then
        -- Anchor character to prevent movement
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.Anchored = true
        end
        
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.LocalTransparencyModifier = 1
            end
        end
    end
    
    -- Update UI
    StatusLabel.Text = "Status: Active"
    StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    ToggleButton.Text = "DISABLE FREE CAM"
    ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
    
    print("Free Camera: Enabled")
end

local function disableFreeCam()
    if not freeCamEnabled then return end
    
    freeCamEnabled = false
    rotating = false
    
    -- Restore camera
    Camera.CameraType = storedCameraType
    Camera.CameraSubject = storedCameraSubject
    
    -- Restore character visibility and movement
    local character = LocalPlayer.Character
    if character then
        -- Unanchor character to allow movement
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.Anchored = false
        end
        
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.LocalTransparencyModifier = 0
            end
        end
    end
    
    -- Reset mouse behavior
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    
    -- Reset keys
    for key, _ in pairs(keysDown) do
        keysDown[key] = false
    end
    
    -- Update UI
    StatusLabel.Text = "Status: Inactive"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
    ToggleButton.Text = "ENABLE FREE CAM"
    ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    
    print("Free Camera: Disabled")
end

-- Button Functions
ToggleButton.MouseButton1Click:Connect(function()
    if freeCamEnabled then
        disableFreeCam()
    else
        enableFreeCam()
    end
end)

ExitButton.MouseButton1Click:Connect(function()
    -- Disable free cam if enabled
    if freeCamEnabled then
        disableFreeCam()
    end
    
    -- Disconnect update connection
    if updateConnection then
        updateConnection:Disconnect()
    end
    
    -- Destroy the GUI
    ScreenGui:Destroy()
    
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("📷 Free Camera Script Exited!")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
end)

HubButton.MouseButton1Click:Connect(function()
    if _G.DodolHub and _G.DodolHub.Show then
        _G.DodolHub.Show()
    else
        warn("Hub not found. Make sure you loaded from Dodol Hub!")
    end
end)

HideButton.MouseButton1Click:Connect(function()
    ControlsFrame.Visible = not ControlsFrame.Visible
end)

-- Input Handling
    if _G.DodolHub and _G.DodolHub.Show then
        _G.DodolHub.Show()
    else
        warn("Hub not found. Make sure you loaded from Dodol Hub!")
    end
end)

HideButton.MouseButton1Click:Connect(function()
    ControlsFrame.Visible = not ControlsFrame.Visible
end)
-- Input Handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if not freeCamEnabled then return end
    
    -- Movement keys
    if input.KeyCode == Enum.KeyCode.W then
        keysDown.W = true
    elseif input.KeyCode == Enum.KeyCode.A then
        keysDown.A = true
    elseif input.KeyCode == Enum.KeyCode.S then
        keysDown.S = true
    elseif input.KeyCode == Enum.KeyCode.D then
        keysDown.D = true
    elseif input.KeyCode == Enum.KeyCode.E then
        keysDown.E = true
    elseif input.KeyCode == Enum.KeyCode.Q then
        keysDown.Q = true
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        keysDown.LeftShift = true
    elseif input.KeyCode == Enum.KeyCode.LeftControl then
        keysDown.LeftControl = true
    end
    
    -- Right click to rotate
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rotating = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if not freeCamEnabled then return end
    
    -- Movement keys
    if input.KeyCode == Enum.KeyCode.W then
        keysDown.W = false
    elseif input.KeyCode == Enum.KeyCode.A then
        keysDown.A = false
    elseif input.KeyCode == Enum.KeyCode.S then
        keysDown.S = false
    elseif input.KeyCode == Enum.KeyCode.D then
        keysDown.D = false
    elseif input.KeyCode == Enum.KeyCode.E then
        keysDown.E = false
    elseif input.KeyCode == Enum.KeyCode.Q then
        keysDown.Q = false
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        keysDown.LeftShift = false
    elseif input.KeyCode == Enum.KeyCode.LeftControl then
        keysDown.LeftControl = false
    end
    
    -- Right click release
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rotating = false
    end
end)

-- Mouse wheel for speed control
UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if not freeCamEnabled then return end
    
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        baseSpeed = math.clamp(baseSpeed + (input.Position.Z * 0.1), 0.1, 5)
    end
end)

-- Camera Update Loop (based on reference script for no slanting)
local updateConnection
updateConnection = RunService.RenderStepped:Connect(function()
    if not freeCamEnabled then return end
    
    -- Handle rotation (prevents camera slant)
    if rotating then
        local delta = UserInputService:GetMouseDelta()
        local cf = Camera.CFrame
        local yAngle = cf:ToEulerAnglesYXZ()
        local newAmount = math.deg(yAngle) + delta.Y
        
        -- Prevent camera flipping at extreme angles
        if newAmount > 65 or newAmount < -65 then
            if not (yAngle < 0 and delta.Y < 0) and not (yAngle > 0 and delta.Y > 0) then
                delta = Vector2.new(delta.X, 0)
            end
        end
        
        -- Apply rotation properly to avoid gimbal lock
        cf = cf * CFrame.Angles(-math.rad(delta.Y), 0, 0)
        cf = CFrame.Angles(0, -math.rad(delta.X), 0) * (cf - cf.Position) + cf.Position
        cf = CFrame.lookAt(cf.Position, cf.Position + cf.LookVector)
        
        if delta ~= Vector2.new(0, 0) then
            Camera.CFrame = Camera.CFrame:Lerp(cf, 0.3)
        end
        
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
    
    -- Handle movement
    local speed = getSpeed()
    
    if keysDown.W then
        Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, -speed)
    end
    if keysDown.A then
        Camera.CFrame = Camera.CFrame * CFrame.new(-speed, 0, 0)
    end
    if keysDown.S then
        Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, speed)
    end
    if keysDown.D then
        Camera.CFrame = Camera.CFrame * CFrame.new(speed, 0, 0)
    end
    if keysDown.E then
        Camera.CFrame = Camera.CFrame * CFrame.new(0, speed, 0)
    end
    if keysDown.Q then
        Camera.CFrame = Camera.CFrame * CFrame.new(0, -speed, 0)
    end
    
    -- Move character to camera position for voice chat proximity
    local character = LocalPlayer.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(Camera.CFrame.Position)
        end
    end
end)

-- Cleanup on character respawn
LocalPlayer.CharacterAdded:Connect(function()
    if freeCamEnabled then
        disableFreeCam()
    end
end)

-- Cleanup on script destruction
ScreenGui.Destroying:Connect(function()
    if freeCamEnabled then
        disableFreeCam()
    end
    if updateConnection then
        updateConnection:Disconnect()
    end
end)

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("📷 Free Camera Script Loaded!")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("Press Shift + P to toggle Free Camera")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
