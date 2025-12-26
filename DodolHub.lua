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
        Name = "Free Camera v1",
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
    },
    {
        Name = "Anti-afk",
        Description = "Prevents you from being kicked for inactivity",
        Icon = "🛡️",
        ScriptUrl = "https://raw.githubusercontent.com/who1sd0l/dodol-hub/main/anti-afk.lua",
        Color = Color3.fromRGB(100, 200, 255)
    }
}

-- Create Main ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DodolHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Create Floating AssistiveTouch Button
local FloatingButton = Instance.new("TextButton")
FloatingButton.Name = "FloatingButton"
FloatingButton.Size = UDim2.new(0, 60, 0, 60)
FloatingButton.Position = UDim2.new(1, -80, 0.5, -30)
FloatingButton.BackgroundColor3 = Color3.fromRGB(8, 12, 16)
FloatingButton.BorderSizePixel = 0
FloatingButton.Font = Enum.Font.Code
FloatingButton.Text = "🎮"
FloatingButton.TextColor3 = Color3.fromRGB(0, 255, 150)
FloatingButton.TextSize = 28
FloatingButton.Visible = false
FloatingButton.Active = true
FloatingButton.Draggable = true
FloatingButton.ZIndex = 100
FloatingButton.Parent = ScreenGui

local FloatingCorner = Instance.new("UICorner")
FloatingCorner.CornerRadius = UDim.new(1, 0)
FloatingCorner.Parent = FloatingButton

local FloatingStroke = Instance.new("UIStroke")
FloatingStroke.Color = Color3.fromRGB(0, 255, 150)
FloatingStroke.Transparency = 0.3
FloatingStroke.Thickness = 3
FloatingStroke.Parent = FloatingButton

-- Floating button hover effect
FloatingButton.MouseEnter:Connect(function()
    TweenService:Create(FloatingButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, 70, 0, 70)
    }):Play()
    TweenService:Create(FloatingStroke, TweenInfo.new(0.2), {
        Transparency = 0.1
    }):Play()
end)

FloatingButton.MouseLeave:Connect(function()
    TweenService:Create(FloatingButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, 60, 0, 60)
    }):Play()
    TweenService:Create(FloatingStroke, TweenInfo.new(0.2), {
        Transparency = 0.3
    }):Play()
end)

-- Pulse animation for floating button
spawn(function()
    while FloatingButton.Parent do
        if FloatingButton.Visible then
            TweenService:Create(FloatingStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                Transparency = 0.6
            }):Play()
        end
        wait(1)
    end
end)

-- Floating button click to show hub
FloatingButton.MouseButton1Click:Connect(function()
    -- Hide floating button
    TweenService:Create(FloatingButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1
    }):Play()
    
    task.wait(0.2)
    FloatingButton.Visible = false
    
    -- Show main frame (will be defined later)
    task.defer(function()
        if MainFrame then
            MainFrame.Visible = true
            MainFrame.Position = UDim2.new(0.5, -275, -1, 0)
            MainFrame.BackgroundTransparency = 1
            MainStroke.Transparency = 1
            
            -- Glitch-in effect
            for i = 1, 2 do
                MainFrame.Position = UDim2.new(0.5, -275 + math.random(-3, 3), -1, 0)
                wait(0.03)
            end
            
            -- Smooth materialize from top
            TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, -275, 0.5, -300),
                BackgroundTransparency = 0.1
            }):Play()
            
            TweenService:Create(MainStroke, TweenInfo.new(0.5), {
                Transparency = 0.4
            }):Play()
        end
    end)
end)

-- Create Terminal-Style Loading Screen (Hacker Theme)
local LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingFrame"
LoadingFrame.Size = UDim2.new(0, 500, 0, 350)
LoadingFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(5, 8, 12)
LoadingFrame.BackgroundTransparency = 0
LoadingFrame.BorderSizePixel = 0
LoadingFrame.Parent = ScreenGui

local LoadingFrameCorner = Instance.new("UICorner")
LoadingFrameCorner.CornerRadius = UDim.new(0, 4)
LoadingFrameCorner.Parent = LoadingFrame

-- Neon border stroke (hacker style)
local LoadingStroke = Instance.new("UIStroke")
LoadingStroke.Color = Color3.fromRGB(0, 255, 150)
LoadingStroke.Transparency = 0.3
LoadingStroke.Thickness = 2
LoadingStroke.Parent = LoadingFrame

-- Animated scanline effect
local Scanline = Instance.new("Frame")
Scanline.Name = "Scanline"
Scanline.Size = UDim2.new(1, 0, 0, 2)
Scanline.Position = UDim2.new(0, 0, 0, 0)
Scanline.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
Scanline.BackgroundTransparency = 0.7
Scanline.BorderSizePixel = 0
Scanline.ZIndex = 10
Scanline.Parent = LoadingFrame

-- Animate scanline
spawn(function()
    while LoadingFrame.Parent do
        TweenService:Create(Scanline, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
            Position = UDim2.new(0, 0, 1, 0)
        }):Play()
        wait(2)
    end
end)

-- Terminal Header
local LogoContainer = Instance.new("Frame")
LogoContainer.Name = "LogoContainer"
LogoContainer.Size = UDim2.new(1, -40, 0, 160)
LogoContainer.Position = UDim2.new(0, 20, 0, 40)
LogoContainer.BackgroundTransparency = 1
LogoContainer.Parent = LoadingFrame

-- Terminal prompt style
local TerminalPrompt = Instance.new("TextLabel")
TerminalPrompt.Name = "TerminalPrompt"
TerminalPrompt.Size = UDim2.new(1, 0, 0, 30)
TerminalPrompt.Position = UDim2.new(0, 0, 0, 0)
TerminalPrompt.BackgroundTransparency = 1
TerminalPrompt.Font = Enum.Font.Code
TerminalPrompt.Text = "root@dodol:~$"
TerminalPrompt.TextColor3 = Color3.fromRGB(0, 255, 150)
TerminalPrompt.TextSize = 16
TerminalPrompt.TextXAlignment = Enum.TextXAlignment.Left
TerminalPrompt.TextTransparency = 1
TerminalPrompt.Parent = LogoContainer

-- ASCII Art Logo
local LogoText = Instance.new("TextLabel")
LogoText.Name = "LogoText"
LogoText.Size = UDim2.new(1, 0, 0, 80)
LogoText.Position = UDim2.new(0, 0, 0, 35)
LogoText.BackgroundTransparency = 1
LogoText.Font = Enum.Font.Code
LogoText.Text = [[██████╗  ██████╗ ██████╗  ██████╗ ██╗     
██╔══██╗██╔═══██╗██╔══██╗██╔═══██╗██║     
██║  ██║██║   ██║██║  ██║██║   ██║██║     
██║  ██║██║   ██║██║  ██║██║   ██║██║     
██████╔╝╚██████╔╝██████╔╝╚██████╔╝███████╗]]
LogoText.TextColor3 = Color3.fromRGB(0, 255, 150)
LogoText.TextSize = 12
LogoText.TextXAlignment = Enum.TextXAlignment.Left
LogoText.TextTransparency = 1
LogoText.RichText = false
LogoText.Parent = LogoContainer

-- Terminal status text
local SubtitleText = Instance.new("TextLabel")
SubtitleText.Name = "SubtitleText"
SubtitleText.Size = UDim2.new(1, 0, 0, 25)
SubtitleText.Position = UDim2.new(0, 0, 0, 125)
SubtitleText.BackgroundTransparency = 1
SubtitleText.Font = Enum.Font.Code
SubtitleText.Text = "> Initializing script hub..."
SubtitleText.TextColor3 = Color3.fromRGB(0, 255, 255)
SubtitleText.TextSize = 14
SubtitleText.TextXAlignment = Enum.TextXAlignment.Left
SubtitleText.TextTransparency = 1
SubtitleText.Parent = LogoContainer

-- Terminal Progress Bar
local LoadingBarBG = Instance.new("Frame")
LoadingBarBG.Name = "LoadingBarBG"
LoadingBarBG.Size = UDim2.new(1, -60, 0, 3)
LoadingBarBG.Position = UDim2.new(0, 30, 1, -70)
LoadingBarBG.BackgroundColor3 = Color3.fromRGB(15, 25, 30)
LoadingBarBG.BorderSizePixel = 0
LoadingBarBG.BackgroundTransparency = 0
LoadingBarBG.Parent = LoadingFrame

-- Terminal-style bar fill
local LoadingBar = Instance.new("Frame")
LoadingBar.Name = "LoadingBar"
LoadingBar.Size = UDim2.new(0, 0, 1, 0)
LoadingBar.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
LoadingBar.BorderSizePixel = 0
LoadingBar.Parent = LoadingBarBG

-- Glowing effect
local BarGlow = Instance.new("UIStroke")
BarGlow.Color = Color3.fromRGB(0, 255, 150)
BarGlow.Transparency = 0.5
BarGlow.Thickness = 1
BarGlow.Parent = LoadingBar

-- Loading percentage text
local LoadingPercent = Instance.new("TextLabel")
LoadingPercent.Name = "LoadingPercent"
LoadingPercent.Size = UDim2.new(0, 100, 0, 25)
LoadingPercent.Position = UDim2.new(1, -110, 1, -60)
LoadingPercent.BackgroundTransparency = 1
LoadingPercent.Font = Enum.Font.Code
LoadingPercent.Text = "[0%]"
LoadingPercent.TextColor3 = Color3.fromRGB(0, 255, 150)
LoadingPercent.TextSize = 14
LoadingPercent.TextXAlignment = Enum.TextXAlignment.Right
LoadingPercent.TextTransparency = 1
LoadingPercent.Parent = LoadingFrame

-- Terminal boot sequence animation
local function animateIn()
    -- Boot sequence messages
    local bootMessages = {
        "> Loading kernel modules...",
        "> Initializing security protocols...",
        "> Establishing secure connection...",
        "> Decrypting script database...",
        "> Launching interface..."
    }
    
    -- Show terminal prompt
    TweenService:Create(TerminalPrompt, TweenInfo.new(0.3), {
        TextTransparency = 0
    }):Play()
    wait(0.4)
    
    -- Type effect for ASCII logo
    TweenService:Create(LogoText, TweenInfo.new(0.5), {
        TextTransparency = 0
    }):Play()
    wait(0.6)
    
    -- Show loading bar and percentage
    TweenService:Create(LoadingPercent, TweenInfo.new(0.3), {
        TextTransparency = 0
    }):Play()
    
    -- Animate boot messages with loading bar
    for i, msg in ipairs(bootMessages) do
        SubtitleText.Text = msg
        TweenService:Create(SubtitleText, TweenInfo.new(0.2), {
            TextTransparency = 0
        }):Play()
        
        local progress = i / #bootMessages
        TweenService:Create(LoadingBar, TweenInfo.new(0.4, Enum.EasingStyle.Linear), {
            Size = UDim2.new(progress, 0, 1, 0)
        }):Play()
        
        LoadingPercent.Text = string.format("[%d%%]", math.floor(progress * 100))
        wait(0.5)
    end
    
    wait(0.3)
    SubtitleText.Text = "> ACCESS GRANTED"
    SubtitleText.TextColor3 = Color3.fromRGB(0, 255, 150)
    wait(0.5)
    
    -- Fade out
    TweenService:Create(LoadingFrame, TweenInfo.new(0.4), {
        BackgroundTransparency = 1
    }):Play()
    TweenService:Create(LoadingStroke, TweenInfo.new(0.4), {
        Transparency = 1
    }):Play()
    TweenService:Create(LogoText, TweenInfo.new(0.4), {
        TextTransparency = 1
    }):Play()
    TweenService:Create(SubtitleText, TweenInfo.new(0.4), {
        TextTransparency = 1
    }):Play()
    TweenService:Create(TerminalPrompt, TweenInfo.new(0.4), {
        TextTransparency = 1
    }):Play()
    TweenService:Create(LoadingPercent, TweenInfo.new(0.4), {
        TextTransparency = 1
    }):Play()
    
    wait(0.5)
    LoadingFrame:Destroy()
end

-- Create Cyberpunk Hacker Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 550, 0, 600)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -300)
MainFrame.BackgroundColor3 = Color3.fromRGB(8, 12, 18)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local MainFrameCorner = Instance.new("UICorner")
MainFrameCorner.CornerRadius = UDim.new(0, 6)
MainFrameCorner.Parent = MainFrame

-- Neon border (hacker style)
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 255, 150)
MainStroke.Transparency = 0.4
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- Dark background layer
local MainBlurBG = Instance.new("Frame")
MainBlurBG.Size = UDim2.new(1, 0, 1, 0)
MainBlurBG.BackgroundColor3 = Color3.fromRGB(5, 8, 12)
MainBlurBG.BackgroundTransparency = 0.2
MainBlurBG.BorderSizePixel = 0
MainBlurBG.ZIndex = -1
MainBlurBG.Parent = MainFrame

local MainBlurCorner = Instance.new("UICorner")
MainBlurCorner.CornerRadius = UDim.new(0, 6)
MainBlurCorner.Parent = MainBlurBG

-- Grid pattern overlay
local GridPattern = Instance.new("Frame")
GridPattern.Size = UDim2.new(1, 0, 1, 0)
GridPattern.BackgroundTransparency = 1
GridPattern.BorderSizePixel = 0
GridPattern.ZIndex = 0
GridPattern.Parent = MainFrame

-- Terminal-style Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 70)
Header.BackgroundColor3 = Color3.fromRGB(10, 15, 22)
Header.BackgroundTransparency = 0.3
Header.BorderSizePixel = 0
Header.Parent = MainFrame

-- Neon divider line
local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -40, 0, 2)
Divider.Position = UDim2.new(0, 20, 1, -2)
Divider.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
Divider.BackgroundTransparency = 0.7
Divider.BorderSizePixel = 0
Divider.Parent = Header

local DividerGlow = Instance.new("UIStroke")
DividerGlow.Color = Color3.fromRGB(0, 255, 150)
DividerGlow.Transparency = 0.5
DividerGlow.Thickness = 1
DividerGlow.Parent = Divider

-- Terminal prompt style title
local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Size = UDim2.new(1, -80, 0, 28)
HeaderTitle.Position = UDim2.new(0, 20, 0, 8)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Font = Enum.Font.Code
HeaderTitle.Text = "root@DODOL_HUB:~#"
HeaderTitle.TextColor3 = Color3.fromRGB(0, 255, 150)
HeaderTitle.TextSize = 18
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.Parent = Header

-- Status indicator
local HeaderSubtitle = Instance.new("TextLabel")
HeaderSubtitle.Size = UDim2.new(0, 200, 0, 16)
HeaderSubtitle.Position = UDim2.new(0, 20, 0, 40)
HeaderSubtitle.BackgroundTransparency = 1
HeaderSubtitle.Font = Enum.Font.Code
HeaderSubtitle.Text = "[STATUS: ONLINE] | v2.0.0"
HeaderSubtitle.TextColor3 = Color3.fromRGB(0, 255, 255)
HeaderSubtitle.TextSize = 11
HeaderSubtitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderSubtitle.Parent = Header

-- Cyberpunk Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 40, 0, 40)
CloseButton.Position = UDim2.new(1, -52, 0, 15)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 80)
CloseButton.BackgroundTransparency = 0.85
CloseButton.BorderSizePixel = 0
CloseButton.Font = Enum.Font.Code
CloseButton.Text = "[X]"
CloseButton.TextColor3 = Color3.fromRGB(255, 0, 80)
CloseButton.TextSize = 16
CloseButton.Parent = Header

local CloseButtonCorner = Instance.new("UICorner")
CloseButtonCorner.CornerRadius = UDim.new(0, 4)
CloseButtonCorner.Parent = CloseButton

local CloseButtonStroke = Instance.new("UIStroke")
CloseButtonStroke.Color = Color3.fromRGB(255, 0, 80)
CloseButtonStroke.Transparency = 0.5
CloseButtonStroke.Thickness = 1.5
CloseButtonStroke.Parent = CloseButton

-- Hover effect
CloseButton.MouseEnter:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), {
        BackgroundTransparency = 0.2
    }):Play()
    TweenService:Create(CloseButtonStroke, TweenInfo.new(0.2), {
        Transparency = 0.2
    }):Play()
end)

CloseButton.MouseLeave:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), {
        BackgroundTransparency = 0.85
    }):Play()
    TweenService:Create(CloseButtonStroke, TweenInfo.new(0.2), {
        Transparency = 0.5
    }):Play()
end)

CloseButton.MouseButton1Click:Connect(function()
    -- Minimize hub and show floating button
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -275, -1, 0),
        BackgroundTransparency = 1
    }):Play()
    TweenService:Create(MainStroke, TweenInfo.new(0.3), {
        Transparency = 1
    }):Play()
    
    task.wait(0.3)
    MainFrame.Visible = false
    
    -- Show floating button with animation
    FloatingButton.Visible = true
    FloatingButton.Size = UDim2.new(0, 20, 0, 20)
    FloatingButton.BackgroundTransparency = 1
    TweenService:Create(FloatingButton, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 60, 0, 60),
        BackgroundTransparency = 0
    }):Play()
end)

-- Scripts Container
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "ScrollFrame"
ScrollFrame.Size = UDim2.new(1, -40, 1, -100)
ScrollFrame.Position = UDim2.new(0, 20, 0, 80)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 3
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 150)
ScrollFrame.ScrollBarImageTransparency = 0.6
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent = MainFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 10)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = ScrollFrame

-- Function to create cyberpunk hacker card
local function createScriptCard(scriptData, index)
    local Card = Instance.new("Frame")
    Card.Name = scriptData.Name
    Card.Size = UDim2.new(1, 0, 0, 85)
    Card.BackgroundColor3 = Color3.fromRGB(12, 18, 25)
    Card.BackgroundTransparency = 0.3
    Card.BorderSizePixel = 0
    Card.Parent = ScrollFrame
    
    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 6)
    CardCorner.Parent = Card
    
    -- Neon border
    local CardStroke = Instance.new("UIStroke")
    CardStroke.Color = Color3.fromRGB(0, 255, 150)
    CardStroke.Transparency = 0.75
    CardStroke.Thickness = 1.5
    CardStroke.Parent = Card
    
    -- Terminal icon style
    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 55, 0, 55)
    Icon.Position = UDim2.new(0, 15, 0.5, -27.5)
    Icon.BackgroundColor3 = Color3.fromRGB(15, 22, 30)
    Icon.BackgroundTransparency = 0.2
    Icon.BorderSizePixel = 0
    Icon.Font = Enum.Font.Code
    Icon.Text = scriptData.Icon
    Icon.TextColor3 = Color3.fromRGB(0, 255, 150)
    Icon.TextSize = 28
    Icon.Parent = Card
    
    local IconCorner = Instance.new("UICorner")
    IconCorner.CornerRadius = UDim.new(0, 4)
    IconCorner.Parent = Icon
    
    local IconStroke = Instance.new("UIStroke")
    IconStroke.Color = Color3.fromRGB(0, 255, 150)
    IconStroke.Transparency = 0.6
    IconStroke.Thickness = 1
    IconStroke.Parent = Icon
    
    -- Terminal-style name
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -195, 0, 22)
    NameLabel.Position = UDim2.new(0, 82, 0, 16)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Font = Enum.Font.Code
    NameLabel.Text = "> " .. scriptData.Name:upper()
    NameLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    NameLabel.TextSize = 15
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Card
    
    -- Cyan description
    local DescLabel = Instance.new("TextLabel")
    DescLabel.Size = UDim2.new(1, -195, 0, 16)
    DescLabel.Position = UDim2.new(0, 82, 0, 42)
    DescLabel.BackgroundTransparency = 1
    DescLabel.Font = Enum.Font.Code
    DescLabel.Text = "// " .. scriptData.Description
    DescLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    DescLabel.TextSize = 11
    DescLabel.TextXAlignment = Enum.TextXAlignment.Left
    DescLabel.Parent = Card
    
    -- Hacker-style Execute Button
    local ExecuteBtn = Instance.new("TextButton")
    ExecuteBtn.Size = UDim2.new(0, 90, 0, 30)
    ExecuteBtn.Position = UDim2.new(1, -102, 0.5, -15)
    ExecuteBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
    ExecuteBtn.BackgroundTransparency = 0.85
    ExecuteBtn.BorderSizePixel = 0
    ExecuteBtn.Font = Enum.Font.Code
    ExecuteBtn.Text = "[RUN]"
    ExecuteBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
    ExecuteBtn.TextSize = 13
    ExecuteBtn.Parent = Card
    
    local ExecuteBtnCorner = Instance.new("UICorner")
    ExecuteBtnCorner.CornerRadius = UDim.new(0, 4)
    ExecuteBtnCorner.Parent = ExecuteBtn
    
    local ExecuteBtnStroke = Instance.new("UIStroke")
    ExecuteBtnStroke.Color = Color3.fromRGB(0, 255, 150)
    ExecuteBtnStroke.Transparency = 0.5
    ExecuteBtnStroke.Thickness = 1.5
    ExecuteBtnStroke.Parent = ExecuteBtn
    
    -- Glow hover effect
    ExecuteBtn.MouseEnter:Connect(function()
        TweenService:Create(ExecuteBtn, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.2
        }):Play()
        TweenService:Create(ExecuteBtnStroke, TweenInfo.new(0.2), {
            Transparency = 0.1
        }):Play()
    end)
    
    ExecuteBtn.MouseLeave:Connect(function()
        TweenService:Create(ExecuteBtn, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.85
        }):Play()
        TweenService:Create(ExecuteBtnStroke, TweenInfo.new(0.2), {
            Transparency = 0.5
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
    
    -- Neon glow hover effect
    Card.MouseEnter:Connect(function()
        TweenService:Create(Card, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.1
        }):Play()
        TweenService:Create(CardStroke, TweenInfo.new(0.2), {
            Transparency = 0.3,
            Thickness = 2
        }):Play()
    end)
    
    Card.MouseLeave:Connect(function()
        TweenService:Create(Card, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.3
        }):Play()
        TweenService:Create(CardStroke, TweenInfo.new(0.2), {
            Transparency = 0.75,
            Thickness = 1.5
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

-- Start animations with cyberpunk entrance
spawn(function()
    animateIn()
    MainFrame.Visible = true
    
    -- Glitch-in effect
    MainFrame.Position = UDim2.new(0.5, -275, 0.5, -320)
    MainFrame.BackgroundTransparency = 1
    MainStroke.Transparency = 1
    
    -- Quick glitch flash
    for i = 1, 3 do
        MainFrame.Position = UDim2.new(0.5, -275 + math.random(-5, 5), 0.5, -300)
        wait(0.05)
    end
    
    -- Smooth materialize
    TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -275, 0.5, -300),
        BackgroundTransparency = 0.1
    }):Play()
    
    TweenService:Create(MainStroke, TweenInfo.new(0.4), {
        Transparency = 0.4
    }):Play()
end)

-- Global functions for external scripts
_G.DodolHub = {
    Show = function()
        if FloatingButton.Visible then
            FloatingButton.MouseButton1Click:Fire()
        elseif not MainFrame.Visible then
            MainFrame.Visible = true
            MainFrame.Position = UDim2.new(0.5, -275, -1, 0)
            MainFrame.BackgroundTransparency = 1
            MainStroke.Transparency = 1
            
            TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, -275, 0.5, -300),
                BackgroundTransparency = 0.1
            }):Play()
            
            TweenService:Create(MainStroke, TweenInfo.new(0.5), {
                Transparency = 0.4
            }):Play()
        end
    end,
    
    Hide = function()
        CloseButton.MouseButton1Click:Fire()
    end,
    
    Toggle = function()
        if MainFrame.Visible then
            _G.DodolHub.Hide()
        else
            _G.DodolHub.Show()
        end
    end
}

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🎮 Dodol Hub Loaded Successfully!")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("💡 Minimized? Click floating button!")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")


