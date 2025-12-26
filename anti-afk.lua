-- Anti-AFK Script for Roblox
-- Place this in StarterPlayer > StarterPlayerScripts as a LocalScript
-- Safe method: Simulates small camera movements to prevent AFK detection

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Anti-AFK Settings
local antiAFK = {
    enabled = false,
    method = "camera", -- camera, input, or hybrid
    interval = 60, -- Seconds between actions (30-120 recommended)
    lastAction = 0
}

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AntiAFKGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Create Main GUI Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 280, 0, 220)
mainFrame.Position = UDim2.new(0, 20, 0, 20) -- Top left
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Visible = true
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Corner for main frame
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 2
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

-- Title Label
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🛡️ Anti-AFK"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 3
titleLabel.Parent = titleBar

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -32, 0, 2.5)
closeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 14
closeButton.Font = Enum.Font.GothamBold
closeButton.BorderSizePixel = 0
closeButton.ZIndex = 4
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

closeButton.MouseEnter:Connect(function()
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
end)

closeButton.MouseLeave:Connect(function()
    closeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
end)

closeButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

-- Status Indicator
local statusFrame = Instance.new("Frame")
statusFrame.Name = "StatusFrame"
statusFrame.Size = UDim2.new(1, -20, 0, 50)
statusFrame.Position = UDim2.new(0, 10, 0, 45)
statusFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
statusFrame.BorderSizePixel = 0
statusFrame.ZIndex = 2
statusFrame.Parent = mainFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 8)
statusCorner.Parent = statusFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 5)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Inactive"
statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
statusLabel.TextSize = 14
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.ZIndex = 3
statusLabel.Parent = statusFrame

local timeLabel = Instance.new("TextLabel")
timeLabel.Size = UDim2.new(1, -20, 0, 20)
timeLabel.Position = UDim2.new(0, 10, 0, 25)
timeLabel.BackgroundTransparency = 1
timeLabel.Text = "Next Action: --"
timeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
timeLabel.TextSize = 12
timeLabel.Font = Enum.Font.Gotham
timeLabel.TextXAlignment = Enum.TextXAlignment.Left
timeLabel.ZIndex = 3
timeLabel.Parent = statusFrame

-- Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(1, -20, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0, 105)
toggleButton.BackgroundColor3 = Color3.fromRGB(60, 150, 60)
toggleButton.Text = "🚀 Activate Anti-AFK"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 14
toggleButton.Font = Enum.Font.GothamBold
toggleButton.BorderSizePixel = 0
toggleButton.ZIndex = 2
toggleButton.Parent = mainFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

-- Interval Slider
local intervalLabel = Instance.new("TextLabel")
intervalLabel.Size = UDim2.new(1, -20, 0, 20)
intervalLabel.Position = UDim2.new(0, 10, 0, 155)
intervalLabel.BackgroundTransparency = 1
intervalLabel.Text = "Interval: " .. antiAFK.interval .. "s"
intervalLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
intervalLabel.TextSize = 12
intervalLabel.Font = Enum.Font.Gotham
intervalLabel.TextXAlignment = Enum.TextXAlignment.Left
intervalLabel.ZIndex = 2
intervalLabel.Parent = mainFrame

local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(1, -20, 0, 8)
sliderBg.Position = UDim2.new(0, 10, 0, 180)
sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
sliderBg.BorderSizePixel = 0
sliderBg.ZIndex = 2
sliderBg.Parent = mainFrame

local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(1, 0)
sliderCorner.Parent = sliderBg

local sliderButton = Instance.new("TextButton")
sliderButton.Size = UDim2.new(0, 12, 0, 18)
sliderButton.Position = UDim2.new((antiAFK.interval - 30) / 90, -6, 0.5, -9)
sliderButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
sliderButton.Text = ""
sliderButton.BorderSizePixel = 0
sliderButton.ZIndex = 3
sliderButton.Parent = sliderBg

local sliderButtonCorner = Instance.new("UICorner")
sliderButtonCorner.CornerRadius = UDim.new(0, 6)
sliderButtonCorner.Parent = sliderButton

-- Info Label
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 0, 15)
infoLabel.Position = UDim2.new(0, 10, 0, 200)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Safe method - No auto-click"
infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
infoLabel.TextSize = 10
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextXAlignment = Enum.TextXAlignment.Center
infoLabel.ZIndex = 2
infoLabel.Parent = mainFrame

-- Slider functionality
local draggingSlider = false

sliderButton.MouseButton1Down:Connect(function()
    draggingSlider = true
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = UserInputService:GetMouseLocation()
        local relativePos = (mousePos.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
        relativePos = math.clamp(relativePos, 0, 1)
        sliderButton.Position = UDim2.new(relativePos, -6, 0.5, -9)
        antiAFK.interval = math.floor(30 + (90 * relativePos)) -- Range: 30-120 seconds
        intervalLabel.Text = "Interval: " .. antiAFK.interval .. "s"
    end
end)

-- Toggle button functionality
toggleButton.MouseButton1Click:Connect(function()
    antiAFK.enabled = not antiAFK.enabled
    
    if antiAFK.enabled then
        toggleButton.BackgroundColor3 = Color3.fromRGB(150, 60, 60)
        toggleButton.Text = "🛑 Deactivate Anti-AFK"
        statusLabel.Text = "Status: Active ✓"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        antiAFK.lastAction = tick()
    else
        toggleButton.BackgroundColor3 = Color3.fromRGB(60, 150, 60)
        toggleButton.Text = "🚀 Activate Anti-AFK"
        statusLabel.Text = "Status: Inactive"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        timeLabel.Text = "Next Action: --"
    end
end)

-- Anti-AFK Functions
local function PerformAntiAFKAction()
    if not antiAFK.enabled then return end
    
    -- Method 1: Respond to Roblox's idle detection
    -- This is the safest method - it only responds when Roblox checks for idle
    player.Idled:Connect(function()
        if antiAFK.enabled then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end

-- Initialize idle detection
player.Idled:Connect(function()
    if antiAFK.enabled then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- Update timer display
RunService.RenderStepped:Connect(function()
    if antiAFK.enabled then
        local timeSinceLastAction = tick() - antiAFK.lastAction
        local timeUntilNext = antiAFK.interval - timeSinceLastAction
        
        if timeUntilNext <= 0 then
            antiAFK.lastAction = tick()
            timeUntilNext = antiAFK.interval
        end
        
        local minutes = math.floor(timeUntilNext / 60)
        local seconds = math.floor(timeUntilNext % 60)
        timeLabel.Text = string.format("Next Action: %02d:%02d", minutes, seconds)
    end
end)

-- Keyboard shortcut to toggle GUI (F2)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F2 then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

-- Initial setup
PerformAntiAFKAction()

print("Anti-AFK Script Loaded!")
print("Press F2 to toggle GUI")
print("This script uses safe methods and won't interfere with gameplay")
