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

-- Create Loading Screen with glass morphism
local LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingFrame"
LoadingFrame.Size = UDim2.new(0, 400, 0, 300)
LoadingFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
LoadingFrame.BackgroundTransparency = 0.1
LoadingFrame.BorderSizePixel = 0
LoadingFrame.Parent = ScreenGui

local LoadingFrameCorner = Instance.new("UICorner")
LoadingFrameCorner.CornerRadius = UDim.new(0, 24)
LoadingFrameCorner.Parent = LoadingFrame

-- Subtle stroke for glass effect
local LoadingStroke = Instance.new("UIStroke")
LoadingStroke.Color = Color3.fromRGB(255, 255, 255)
LoadingStroke.Transparency = 0.85
LoadingStroke.Thickness = 1.5
LoadingStroke.Parent = LoadingFrame

-- Blur effect background
local BlurBG = Instance.new("Frame")
BlurBG.Size = UDim2.new(1, 0, 1, 0)
BlurBG.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BlurBG.BackgroundTransparency = 0.3
BlurBG.BorderSizePixel = 0
BlurBG.ZIndex = -1
BlurBG.Parent = LoadingFrame

local BlurCorner = Instance.new("UICorner")
BlurCorner.CornerRadius = UDim.new(0, 24)
BlurCorner.Parent = BlurBG

-- Subtle gradient overlay
local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 75)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 45))
}
Gradient.Rotation = 135
Gradient.Parent = BlurBG

-- Logo Container
local LogoContainer = Instance.new("Frame")
LogoContainer.Name = "LogoContainer"
LogoContainer.Size = UDim2.new(1, -60, 0, 120)
LogoContainer.Position = UDim2.new(0, 30, 0, 60)
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

-- Create Main Hub Frame with glass morphism
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 580)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -290)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local MainFrameCorner = Instance.new("UICorner")
MainFrameCorner.CornerRadius = UDim.new(0, 20)
MainFrameCorner.Parent = MainFrame

-- Glass effect stroke
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Transparency = 0.9
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Background blur effect
local MainBlurBG = Instance.new("Frame")
MainBlurBG.Size = UDim2.new(1, 0, 1, 0)
MainBlurBG.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainBlurBG.BackgroundTransparency = 0.4
MainBlurBG.BorderSizePixel = 0
MainBlurBG.ZIndex = -1
MainBlurBG.Parent = MainFrame

local MainBlurCorner = Instance.new("UICorner")
MainBlurCorner.CornerRadius = UDim.new(0, 20)
MainBlurCorner.Parent = MainBlurBG

-- Header with clean design
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 65)
Header.BackgroundTransparency = 1
Header.BorderSizePixel = 0
Header.Parent = MainFrame

-- Subtle divider line
local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -40, 0, 1)
Divider.Position = UDim2.new(0, 20, 1, -1)
Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Divider.BackgroundTransparency = 0.92
Divider.BorderSizePixel = 0
Divider.Parent = Header

-- Header Title with modern styling
local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Size = UDim2.new(1, -80, 1, -10)
HeaderTitle.Position = UDim2.new(0, 25, 0, 5)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.Text = "DODOL"
HeaderTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HeaderTitle.TextSize = 24
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.Parent = Header

-- Subtitle tag
local HeaderSubtitle = Instance.new("TextLabel")
HeaderSubtitle.Size = UDim2.new(0, 150, 0, 18)
HeaderSubtitle.Position = UDim2.new(0, 25, 0, 35)
HeaderSubtitle.BackgroundTransparency = 1
HeaderSubtitle.Font = Enum.Font.Gotham
HeaderSubtitle.Text = "Script Hub v1.0"
HeaderSubtitle.TextColor3 = Color3.fromRGB(140, 140, 160)
HeaderSubtitle.TextSize = 12
HeaderSubtitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderSubtitle.Parent = Header

-- Minimalist Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 36, 0, 36)
CloseButton.Position = UDim2.new(1, -48, 0, 15)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.BackgroundTransparency = 0.95
CloseButton.BorderSizePixel = 0
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 22
CloseButton.Parent = Header

local CloseButtonCorner = Instance.new("UICorner")
CloseButtonCorner.CornerRadius = UDim.new(1, 0)
CloseButtonCorner.Parent = CloseButton

-- Hover effect for close button
CloseButton.MouseEnter:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(255, 70, 70),
        BackgroundTransparency = 0
    }):Play()
end)

CloseButton.MouseLeave:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.95
    }):Play()
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Scripts Container with padding
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "ScrollFrame"
ScrollFrame.Size = UDim2.new(1, -50, 1, -95)
ScrollFrame.Position = UDim2.new(0, 25, 0, 75)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
ScrollFrame.ScrollBarImageTransparency = 0.8
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent = MainFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 12)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = ScrollFrame

-- Function to create modern script card
local function createScriptCard(scriptData, index)
    local Card = Instance.new("Frame")
    Card.Name = scriptData.Name
    Card.Size = UDim2.new(1, 0, 0, 90)
    Card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Card.BackgroundTransparency = 0.96
    Card.BorderSizePixel = 0
    Card.Parent = ScrollFrame
    
    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 16)
    CardCorner.Parent = Card
    
    -- Subtle card border
    local CardStroke = Instance.new("UIStroke")
    CardStroke.Color = Color3.fromRGB(255, 255, 255)
    CardStroke.Transparency = 0.92
    CardStroke.Thickness = 1
    CardStroke.Parent = Card
    
    -- Modern minimalist icon
    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 50, 0, 50)
    Icon.Position = UDim2.new(0, 18, 0.5, -25)
    Icon.BackgroundColor3 = scriptData.Color
    Icon.BackgroundTransparency = 0.85
    Icon.BorderSizePixel = 0
    Icon.Font = Enum.Font.GothamBold
    Icon.Text = scriptData.Icon
    Icon.TextColor3 = scriptData.Color
    Icon.TextSize = 26
    Icon.Parent = Card
    
    local IconCorner = Instance.new("UICorner")
    IconCorner.CornerRadius = UDim.new(0, 14)
    IconCorner.Parent = Icon
    
    -- Script Name with modern font
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -190, 0, 24)
    NameLabel.Position = UDim2.new(0, 80, 0, 18)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.Text = scriptData.Name
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.TextSize = 16
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Card
    
    -- Minimal description
    local DescLabel = Instance.new("TextLabel")
    DescLabel.Size = UDim2.new(1, -190, 0, 18)
    DescLabel.Position = UDim2.new(0, 80, 0, 46)
    DescLabel.BackgroundTransparency = 1
    DescLabel.Font = Enum.Font.Gotham
    DescLabel.Text = scriptData.Description
    DescLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
    DescLabel.TextSize = 12
    DescLabel.TextXAlignment = Enum.TextXAlignment.Left
    DescLabel.Parent = Card
    
    -- Modern Execute Button
    local ExecuteBtn = Instance.new("TextButton")
    ExecuteBtn.Size = UDim2.new(0, 85, 0, 32)
    ExecuteBtn.Position = UDim2.new(1, -100, 0.5, -16)
    ExecuteBtn.BackgroundColor3 = scriptData.Color
    ExecuteBtn.BackgroundTransparency = 0.15
    ExecuteBtn.BorderSizePixel = 0
    ExecuteBtn.Font = Enum.Font.GothamBold
    ExecuteBtn.Text = "Execute"
    ExecuteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ExecuteBtn.TextSize = 13
    ExecuteBtn.Parent = Card
    
    local ExecuteBtnCorner = Instance.new("UICorner")
    ExecuteBtnCorner.CornerRadius = UDim.new(0, 10)
    ExecuteBtnCorner.Parent = ExecuteBtn
    
    -- Smooth hover effect
    ExecuteBtn.MouseEnter:Connect(function()
        TweenService:Create(ExecuteBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 0,
            Size = UDim2.new(0, 88, 0, 32)
        }):Play()
    end)
    
    ExecuteBtn.MouseLeave:Connect(function()
        TweenService:Create(ExecuteBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 0.15,
            Size = UDim2.new(0, 85, 0, 32)
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
    
    -- Subtle card hover effect
    Card.MouseEnter:Connect(function()
        TweenService:Create(Card, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 0.93
        }):Play()
        TweenService:Create(CardStroke, TweenInfo.new(0.3), {
            Transparency = 0.85
        }):Play()
    end)
    
    Card.MouseLeave:Connect(function()
        TweenService:Create(Card, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 0.96
        }):Play()
        TweenService:Create(CardStroke, TweenInfo.new(0.3), {
            Transparency = 0.92
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

-- Start animations with smooth entrance
spawn(function()
    animateIn()
    MainFrame.Visible = true
    
    -- Smooth scale and fade in
    MainFrame.Size = UDim2.new(0, 470, 0, 530)
    MainFrame.BackgroundTransparency = 1
    MainStroke.Transparency = 1
    
    TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 520, 0, 580),
        BackgroundTransparency = 0.05
    }):Play()
    
    TweenService:Create(MainStroke, TweenInfo.new(0.6), {
        Transparency = 0.9
    }):Play()
end)

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🎮 Dodol Hub Loaded Successfully!")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
