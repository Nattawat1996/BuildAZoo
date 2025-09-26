-- File: TradeUI.lua (Version 4 - Full UI Layout)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Module = {}

-- Callback placeholders
local onSelectionChanged = function() end
local onVisibilityChanged = function() end

-- UI Objects
local ScreenGui, MainFrame

-- Helper to create a consistent text label
local function createLabel(parent, text, position, size)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.BackgroundTransparency = 1
    label.Position = position
    label.Size = size
    label.Font = Enum.Font.Gotham
    label.TextColor3 = Color3.fromRGB(180, 180, 180)
    label.TextSize = 14
    label.Text = text
    label.ZIndex = 2
    return label
end

-- Function to create the UI if it doesn't exist
local function createUI()
    if ScreenGui and ScreenGui.Parent then return end -- Don't create if it already exists

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoTradeSystemUI"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Enabled = false

    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(31, 33, 38)
    MainFrame.BorderColor3 = Color3.fromRGB(20, 20, 25)
    MainFrame.BorderSizePixel = 1
    MainFrame.Size = UDim2.new(0, 850, 0, 550)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local DraggableFrame = require(game:GetService("ReplicatedStorage"):WaitForChild("Draggable"))
    DraggableFrame.new(MainFrame)

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame

    -- Add a title bar
    local TitleBar = Instance.new("TextLabel")
    TitleBar.Name = "TitleBar"
    TitleBar.Parent = MainFrame
    TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.Font = Enum.Font.GothamSemibold
    TitleBar.Text = "  Auto Trade System"
    TitleBar.TextColor3 = Color3.fromRGB(220, 220, 220)
    TitleBar.TextSize = 16
    TitleBar.TextXAlignment = Enum.TextXAlignment.Left
    
    local TitleCorner = UICorner:Clone()
    TitleCorner.Parent = TitleBar

    ----------------------------------
    -- === LEFT PANEL ELEMENTS ===
    ----------------------------------
    local LeftPanel = Instance.new("Frame")
    LeftPanel.Name = "LeftPanel"
    LeftPanel.Parent = MainFrame
    LeftPanel.BackgroundColor3 = Color3.fromRGB(40, 42, 49)
    LeftPanel.BorderSizePixel = 0
    LeftPanel.Position = UDim2.new(0, 20, 0, 60)
    LeftPanel.Size = UDim2.new(0, 250, 1, -80)

    local LeftPanelCorner = UICorner:Clone()
    LeftPanelCorner.Parent = LeftPanel

    -- Player Avatar Placeholder
    local AvatarFrame = Instance.new("Frame")
    AvatarFrame.Parent = LeftPanel
    AvatarFrame.BackgroundColor3 = Color3.fromRGB(31, 33, 38)
    AvatarFrame.Position = UDim2.new(0.5, 0, 0, 20)
    AvatarFrame.Size = UDim2.new(0, 128, 0, 128)
    AvatarFrame.AnchorPoint = Vector2.new(0.5, 0)
    local AvatarCorner = UICorner:Clone(); AvatarCorner.Parent = AvatarFrame

    createLabel(LeftPanel, "Random Player", UDim2.new(0.5, 0, 0, 160), UDim2.new(1, 0, 0, 20)).TextXAlignment = Enum.TextXAlignment.Center

    -- Controls below avatar
    -- (This is a simplified representation; a real implementation would use modules for sliders/dropdowns)
    createLabel(LeftPanel, "Select Target", UDim2.new(0.5, 0, 0, 200), UDim2.new(1, -40, 0, 20)).TextXAlignment = Enum.TextXAlignment.Left
    local SendNow = Instance.new("TextButton")
    SendNow.Parent = LeftPanel
    SendNow.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
    SendNow.Position = UDim2.new(0.5, 0, 0, 230)
    SendNow.Size = UDim2.new(1, -40, 0, 45)
    SendNow.AnchorPoint = Vector2.new(0.5, 0)
    SendNow.Font = Enum.Font.GothamBold
    SendNow.Text = "Send Now"
    SendNow.TextColor3 = Color3.fromRGB(255, 255, 255)
    SendNow.TextSize = 16
    local SendNowCorner = UICorner:Clone(); SendNowCorner.Parent = SendNow

    createLabel(LeftPanel, "Send Speed: 2.0s", UDim2.new(0.5, 0, 0, 295), UDim2.new(1, -40, 0, 20)).TextXAlignment = Enum.TextXAlignment.Left
    createLabel(LeftPanel, "UI Scale: 100%", UDim2.new(0.5, 0, 0, 345), UDim2.new(1, -40, 0, 20)).TextXAlignment = Enum.TextXAlignment.Left

    -- Bottom Controls
    local AutoTradeButton = Instance.new("TextButton")
    AutoTradeButton.Parent = LeftPanel
    AutoTradeButton.BackgroundColor3 = Color3.fromRGB(60, 62, 70)
    AutoTradeButton.Position = UDim2.new(0.5, 0, 1, -70)
    AutoTradeButton.Size = UDim2.new(1, -40, 0, 45)
    AutoTradeButton.AnchorPoint = Vector2.new(0.5, 1)
    AutoTradeButton.Font = Enum.Font.GothamBold
    AutoTradeButton.Text = "Auto Trade: OFF"
    AutoTradeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutoTradeButton.TextSize = 16
    local AutoTradeCorner = UICorner:Clone(); AutoTradeCorner.Parent = AutoTradeButton
    createLabel(LeftPanel, "Today Gift: 0/500", UDim2.new(0.5, 0, 1, -15), UDim2.new(1, -40, 0, 20)).TextXAlignment = Enum.TextXAlignment.Center

    -----------------------------------
    -- === RIGHT PANEL ELEMENTS ===
    -----------------------------------
    local RightPanel = Instance.new("Frame")
    RightPanel.Name = "RightPanel"
    RightPanel.Parent = MainFrame
    RightPanel.BackgroundTransparency = 1
    RightPanel.BorderSizePixel = 0
    RightPanel.Position = UDim2.new(0, 290, 0, 60)
    RightPanel.Size = UDim2.new(1, -310, 1, -80)
    
    -- Top Bar (Search, Sort, etc)
    local TopBar = Instance.new("Frame")
    TopBar.Parent = RightPanel
    TopBar.BackgroundTransparency = 1
    TopBar.Size = UDim2.new(1, 0, 0, 40)

    -- Tab Buttons
    local TabContainer = Instance.new("Frame")
    TabContainer.Parent = RightPanel
    TabContainer.BackgroundTransparency = 1
    TabContainer.Position = UDim2.new(0, 0, 0, 50)
    TabContainer.Size = UDim2.new(1, 0, 0, 40)
    
    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.Padding = UDim.new(0, 10)
    TabLayout.Parent = TabContainer

    -- Content Frame to hold ScrollingFrames
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Parent = RightPanel
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Position = UDim2.new(0, 0, 0, 100)
    ContentFrame.Size = UDim2.new(1, 0, 1, -100)

    -- Create ScrollingFrames for each tab, but hide them
    local PetsScroll = Instance.new("ScrollingFrame")
    PetsScroll.Parent = ContentFrame
    PetsScroll.Size = UDim2.new(1,0,1,0)
    PetsScroll.BackgroundTransparency = 1
    PetsScroll.BorderSizePixel = 0
    PetsScroll.Visible = true -- Default visible

    local EggsScroll = Instance.new("ScrollingFrame")
    EggsScroll.Parent = ContentFrame
    EggsScroll.Size = UDim2.new(1,0,1,0)
    EggsScroll.BackgroundTransparency = 1
    EggsScroll.BorderSizePixel = 0
    EggsScroll.Visible = false 

    local FruitsScroll = Instance.new("ScrollingFrame")
    FruitsScroll.Parent = ContentFrame
    FruitsScroll.Size = UDim2.new(1,0,1,0)
    FruitsScroll.BackgroundTransparency = 1
    FruitsScroll.BorderSizePixel = 0
    FruitsScroll.Visible = false 

    -- Tab Button Creation and Logic
    local tabs = {Pets = PetsScroll, Eggs = EggsScroll, Fruits = FruitsScroll}
    local tabButtons = {}
    local activeTabColor = Color3.fromRGB(33, 150, 243)
    local inactiveTabColor = Color3.fromRGB(50, 52, 60)

    for tabName, scrollFrame in pairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tabName
        tabBtn.Parent = TabContainer
        tabBtn.BackgroundColor3 = inactiveTabColor
        tabBtn.Size = UDim2.new(0, 120, 1, 0)
        tabBtn.Font = Enum.Font.GothamSemibold
        tabBtn.Text = tabName
        tabBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
        tabBtn.TextSize = 14
        local BtnCorner = UICorner:Clone(); BtnCorner.Parent = tabBtn
        table.insert(tabButtons, tabBtn)

        tabBtn.MouseButton1Click:Connect(function()
            for _, btn in ipairs(tabButtons) do
                btn.BackgroundColor3 = inactiveTabColor
                tabs[btn.Name].Visible = false
            end
            tabBtn.BackgroundColor3 = activeTabColor
            scrollFrame.Visible = true
        end)
    end
    tabButtons[1].BackgroundColor3 = activeTabColor -- Set "Pets" as active by default
end

function Module.Show(...)
    createUI() -- Make sure the UI is created
    -- The rest of the show logic
end

-- (The rest of the module remains the same)
return Module
