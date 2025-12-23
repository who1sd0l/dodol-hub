-- Dodol Hub - Main Script Hub
-- Created with love ❤️

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Check if hub already exists
if PlayerGui:FindFirstChild("DodolHub") then
    PlayerGui.DodolHub:Destroy()
end

-- Script Registry
local Scripts = {
    {
        Name = "Free Camera",
        Description = "Fly around with smooth camera controls",
        Icon = "📷",
        ScriptUrl = "https://raw.githubusercontent.com/who1sd0l/dodol-hub/main/FreeCameraScript-ver-1.lua",
        Color = Color3.fromRGB(100, 200, 255)
    },
    {
        Name = "Movement Suite",
        Description = "Fly, Run, Noclip & Teleport with pro UI",
        Icon = "🚀",
        ScriptUrl = "https://raw.githubusercontent.com/who1sd0l/dodol-hub/main/fly.lua",
        Color = Color3.fromRGB(255, 150, 100)
    },
    {
        Name = "Checkpoint Teleporter",
        Description = "Smart checkpoint scanner & teleporter",
        Icon = "📍",
        ScriptUrl = "https://raw.githubusercontent.com/who1sd0l/dodol-hub/main/checkpoint.lua",
        Color = Color3.fromRGB(150, 255, 100)
    }
}

-- Create Main ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DodolHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Create Loading Screen
local LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingFrame"
LoadingFrame.Size = UDim2.new(0, 500, 0, 400)
LoadingFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
LoadingFrame.BorderSizePixel = 0
LoadingFrame.Parent = ScreenGui

local LoadingFrameCorner = Instance.new("UICorner")
LoadingFrameCorner.CornerRadius = UDim.new(0, 20)
LoadingFrameCorner.Parent = LoadingFrame

-- Loading Frame Shadow
local LoadingShadow = Instance.new("ImageLabel")
LoadingShadow.Name = "Shadow"
LoadingShadow.Size = UDim2.new(1, 40, 1, 40)
LoadingShadow.Position = UDim2.new(0, -20, 0, -20)
LoadingShadow.BackgroundTransparency = 1
LoadingShadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
LoadingShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
LoadingShadow.ImageTransparency = 0.5
LoadingShadow.ScaleType = Enum.ScaleType.Slice
LoadingShadow.SliceCenter = Rect.new(10, 10, 118, 118)
LoadingShadow.ZIndex = 0
LoadingShadow.Parent = LoadingFrame

-- Create Gradient Background
local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 40)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 15, 45)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 25, 50))
}
Gradient.Rotation = 45
Gradient.Parent = LoadingFrame

-- Animated gradient rotation
spawn(function()
    while LoadingFrame.Parent do
        for i = 0, 360, 2 do
            if not LoadingFrame.Parent then break end
            Gradient.Rotation = i
            wait(0.03)
        end
    end
end)

-- Logo Container
local LogoContainer = Instance.new("Frame")
LogoContainer.Name = "LogoContainer"
LogoContainer.Size = UDim2.new(1, -40, 0, 180)
LogoContainer.Position = UDim2.new(0, 20, 0, 60)
LogoContainer.BackgroundTransparency = 1
LogoContainer.Parent = LoadingFrame

-- Logo Text
local LogoText = Instance.new("TextLabel")
LogoText.Name = "LogoText"
LogoText.Size = UDim2.new(1, 0, 0, 70)
LogoText.Position = UDim2.new(0, 0, 0, 0)
LogoText.BackgroundTransparency = 1
LogoText.Font = Enum.Font.GothamBold
LogoText.Text = "DODOL HUB"
LogoText.TextColor3 = Color3.fromRGB(255, 255, 255)
LogoText.TextSize = 48
LogoText.TextTransparency = 1
LogoText.Parent = LogoContainer

-- Logo Subtitle
local SubtitleText = Instance.new("TextLabel")
SubtitleText.Name = "SubtitleText"
SubtitleText.Size = UDim2.new(1, 0, 0, 25)
SubtitleText.Position = UDim2.new(0, 0, 0, 80)
SubtitleText.BackgroundTransparency = 1
SubtitleText.Font = Enum.Font.Gotham
SubtitleText.Text = "Your Ultimate Script Collection"
SubtitleText.TextColor3 = Color3.fromRGB(150, 150, 255)
SubtitleText.TextSize = 16
SubtitleText.TextTransparency = 1
SubtitleText.Parent = LogoContainer

-- Loading Bar Background
local LoadingBarBG = Instance.new("Frame")
LoadingBarBG.Name = "LoadingBarBG"
LoadingBarBG.Size = UDim2.new(1, -80, 0, 6)
LoadingBarBG.Position = UDim2.new(0, 40, 1, -80)
LoadingBarBG.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
LoadingBarBG.BorderSizePixel = 0
LoadingBarBG.BackgroundTransparency = 1
LoadingBarBG.Parent = LoadingFrame

local LoadingBarBGCorner = Instance.new("UICorner")
LoadingBarBGCorner.CornerRadius = UDim.new(1, 0)
LoadingBarBGCorner.Parent = LoadingBarBG

-- Loading Bar Fill
local LoadingBar = Instance.new("Frame")
LoadingBar.Name = "LoadingBar"
LoadingBar.Size = UDim2.new(0, 0, 1, 0)
LoadingBar.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
LoadingBar.BorderSizePixel = 0
LoadingBar.Parent = LoadingBarBG

local LoadingBarCorner = Instance.new("UICorner")
LoadingBarCorner.CornerRadius = UDim.new(1, 0)
LoadingBarCorner.Parent = LoadingBar

-- Loading Bar Gradient
local BarGradient = Instance.new("UIGradient")
BarGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 200, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 100, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 200))
}
BarGradient.Parent = LoadingBar

-- Loading animations
local function animateIn()
    -- Fade in logo
    TweenService:Create(LogoText, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    }):Play()
    
    wait(0.3)
    
    TweenService:Create(SubtitleText, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    }):Play()
    
    wait(0.5)
    
    -- Fade in loading bar
    TweenService:Create(LoadingBarBG, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    }):Play()
    
    wait(0.3)
    
    -- Fill loading bar
    TweenService:Create(LoadingBar, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
        Size = UDim2.new(1, 0, 1, 0)
    }):Play()
    
    wait(1.8)
    
    -- Fade out loading screen
    TweenService:Create(LoadingFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
        BackgroundTransparency = 1
    }):Play()
    
    TweenService:Create(LogoText, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
        TextTransparency = 1
    }):Play()
    
    TweenService:Create(SubtitleText, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
        TextTransparency = 1
    }):Play()
    
    wait(0.7)
    LoadingFrame:Destroy()
end

-- Create Main Hub Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 600, 0, 500)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local MainFrameCorner = Instance.new("UICorner")
MainFrameCorner.CornerRadius = UDim.new(0, 15)
MainFrameCorner.Parent = MainFrame

-- Main Frame Shadow
local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(1, 40, 1, 40)
Shadow.Position = UDim2.new(0, -20, 0, -20)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.7
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
Shadow.ZIndex = 0
Shadow.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 70)
Header.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 15)
HeaderCorner.Parent = Header

local HeaderCover = Instance.new("Frame")
HeaderCover.Size = UDim2.new(1, 0, 0, 15)
HeaderCover.Position = UDim2.new(0, 0, 1, -15)
HeaderCover.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
HeaderCover.BorderSizePixel = 0
HeaderCover.Parent = Header

-- Header Title
local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Size = UDim2.new(1, -120, 1, 0)
HeaderTitle.Position = UDim2.new(0, 20, 0, 0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.Text = "🎮 DODOL HUB"
HeaderTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HeaderTitle.TextSize = 28
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.Parent = Header

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 40, 0, 40)
CloseButton.Position = UDim2.new(1, -55, 0.5, -20)
CloseButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseButton.BorderSizePixel = 0
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "✕"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 20
CloseButton.Parent = Header

local CloseButtonCorner = Instance.new("UICorner")
CloseButtonCorner.CornerRadius = UDim.new(0, 8)
CloseButtonCorner.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Scripts Container
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "ScrollFrame"
ScrollFrame.Size = UDim2.new(1, -40, 1, -100)
ScrollFrame.Position = UDim2.new(0, 20, 0, 85)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 8
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent = MainFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 15)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = ScrollFrame

-- Function to create script card
local function createScriptCard(scriptData, index)
    local Card = Instance.new("Frame")
    Card.Name = scriptData.Name
    Card.Size = UDim2.new(1, 0, 0, 100)
    Card.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    Card.BorderSizePixel = 0
    Card.Parent = ScrollFrame
    
    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 12)
    CardCorner.Parent = Card
    
    -- Icon
    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 60, 0, 60)
    Icon.Position = UDim2.new(0, 15, 0.5, -30)
    Icon.BackgroundColor3 = scriptData.Color
    Icon.BorderSizePixel = 0
    Icon.Font = Enum.Font.GothamBold
    Icon.Text = scriptData.Icon
    Icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    Icon.TextSize = 32
    Icon.Parent = Card
    
    local IconCorner = Instance.new("UICorner")
    IconCorner.CornerRadius = UDim.new(0, 10)
    IconCorner.Parent = Icon
    
    -- Script Name
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -200, 0, 30)
    NameLabel.Position = UDim2.new(0, 90, 0, 20)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.Text = scriptData.Name
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.TextSize = 20
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Card
    
    -- Description
    local DescLabel = Instance.new("TextLabel")
    DescLabel.Size = UDim2.new(1, -200, 0, 20)
    DescLabel.Position = UDim2.new(0, 90, 0, 55)
    DescLabel.BackgroundTransparency = 1
    DescLabel.Font = Enum.Font.Gotham
    DescLabel.Text = scriptData.Description
    DescLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    DescLabel.TextSize = 14
    DescLabel.TextXAlignment = Enum.TextXAlignment.Left
    DescLabel.Parent = Card
    
    -- Execute Button
    local ExecuteBtn = Instance.new("TextButton")
    ExecuteBtn.Size = UDim2.new(0, 100, 0, 35)
    ExecuteBtn.Position = UDim2.new(1, -115, 0.5, -17.5)
    ExecuteBtn.BackgroundColor3 = scriptData.Color
    ExecuteBtn.BorderSizePixel = 0
    ExecuteBtn.Font = Enum.Font.GothamBold
    ExecuteBtn.Text = "EXECUTE"
    ExecuteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ExecuteBtn.TextSize = 14
    ExecuteBtn.Parent = Card
    
    local ExecuteBtnCorner = Instance.new("UICorner")
    ExecuteBtnCorner.CornerRadius = UDim.new(0, 8)
    ExecuteBtnCorner.Parent = ExecuteBtn
    
    -- Button hover effect
    ExecuteBtn.MouseEnter:Connect(function()
        TweenService:Create(ExecuteBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(
                math.min(scriptData.Color.R * 255 + 30, 255),
                math.min(scriptData.Color.G * 255 + 30, 255),
                math.min(scriptData.Color.B * 255 + 30, 255)
            )
        }):Play()
    end)
    
    ExecuteBtn.MouseLeave:Connect(function()
        TweenService:Create(ExecuteBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = scriptData.Color
        }):Play()
    end)
    
    -- Execute script
    ExecuteBtn.MouseButton1Click:Connect(function()
        -- Check if URL is still a placeholder
        if string.find(scriptData.ScriptUrl, "YOUR_USERNAME") or string.find(scriptData.ScriptUrl, "YOUR_REPO") then
            warn("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            warn("⚠️ SETUP REQUIRED!")
            warn("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            warn("Please upload your scripts to GitHub first!")
            warn("")
            warn("Steps:")
            warn("1. Upload all .lua files to GitHub")
            warn("2. Edit DodolHub.lua")
            warn("3. Replace YOUR_USERNAME with your GitHub username")
            warn("4. Replace YOUR_REPO with your repository name")
            warn("")
            warn("Read QUICK_START.md for detailed instructions")
            warn("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            return
        end
        
        local success, err = pcall(function()
            -- Hide hub
            MainFrame.Visible = false
            
            -- Store hub reference for scripts
            _G.DodolHub = {
                Show = function()
                    MainFrame.Visible = true
                end,
                Hide = function()
                    MainFrame.Visible = false
                end
            }
            
            -- Load and execute script from URL
            local scriptUrl = scriptData.ScriptUrl
            
            print("Loading script: " .. scriptData.Name)
            print("URL: " .. scriptUrl)
            
            -- Use game:HttpGet for loadstring compatibility
            local scriptContent = game:HttpGet(scriptUrl, true)
            
            -- Check if we got valid content
            if not scriptContent or scriptContent == "" or scriptContent == nil then
                error("Failed to download script - URL may be incorrect or file not found")
            end
            
            -- Remove BOM (Byte Order Mark) if present - fixes Unicode character U+feff error
            if scriptContent:sub(1, 3) == "\239\187\191" then
                scriptContent = scriptContent:sub(4)
            end
            
            -- Execute the script
            local loadedScript, loadErr = loadstring(scriptContent)
            if loadedScript then
                loadedScript()
                print("✓ Script executed: " .. scriptData.Name)
            else
                error("Failed to load script: " .. tostring(loadErr))
            end
        end)
        
        if not success then
            warn("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            warn("❌ Failed to execute script!")
            warn("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            warn("Error: " .. tostring(err))
            warn("")
            warn("Common fixes:")
            warn("• Make sure your GitHub repository is PUBLIC")
            warn("• Check that the file exists on GitHub")
            warn("• Verify the URL is correct")
            warn("• Some games block HTTP requests")
            warn("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            MainFrame.Visible = true
        end
    end)
    
    -- Card hover effect
    Card.MouseEnter:Connect(function()
        TweenService:Create(Card, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        }):Play()
    end)
    
    Card.MouseLeave:Connect(function()
        TweenService:Create(Card, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        }):Play()
    end)
end

-- Create script cards
for i, scriptData in ipairs(Scripts) do
    createScriptCard(scriptData, i)
end

-- Update canvas size
ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 15)
end)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 15)

-- Make draggable
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Start animations
spawn(function()
    animateIn()
    MainFrame.Visible = true
    
    -- Scale in animation
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 600, 0, 500)
    }):Play()
end)

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🎮 Dodol Hub Loaded Successfully!")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
