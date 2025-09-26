-- File: TradeUI.lua (Version 2 - with Layout)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Module table
local Module = {}

-- Callback placeholders
local onSelectionChanged = function() end
local onVisibilityChanged = function() end

-- UI Objects
local ScreenGui, MainFrame

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
    MainFrame.BackgroundColor3 = Color3.fromRGB(31, 33, 38) -- Darker background
    MainFrame.BorderColor3 = Color3.fromRGB(20, 20, 25)
    MainFrame.BorderSizePixel = 1
    MainFrame.Size = UDim2.new(0, 850, 0, 550) -- Slightly larger
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

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

    -- === Main Layout Panels ===
    local LeftPanel = Instance.new("Frame")
    LeftPanel.Name = "LeftPanel"
    LeftPanel.Parent = MainFrame
    LeftPanel.BackgroundColor3 = Color3.fromRGB(40, 42, 49)
    LeftPanel.BorderSizePixel = 0
    LeftPanel.Position = UDim2.new(0, 20, 0, 60)
    LeftPanel.Size = UDim2.new(0, 250, 1, -80)

    local LeftPanelCorner = UICorner:Clone()
    LeftPanelCorner.Parent = LeftPanel

    local RightPanel = Instance.new("Frame")
    RightPanel.Name = "RightPanel"
    RightPanel.Parent = MainFrame
    RightPanel.BackgroundColor3 = Color3.fromRGB(40, 42, 49)
    RightPanel.BorderSizePixel = 0
    RightPanel.Position = UDim2.new(0, 290, 0, 60)
    RightPanel.Size = UDim2.new(1, -310, 1, -80)
    
    local RightPanelCorner = UICorner:Clone()
    RightPanelCorner.Parent = RightPanel
    
    -- Now we can start adding elements into the panels
    -- Example: Add the "Select Target" dropdown to the Left Panel
    local TargetLabel = Instance.new("TextLabel")
    TargetLabel.Name = "TargetLabel"
    TargetLabel.Parent = LeftPanel
    TargetLabel.BackgroundTransparency = 1
    TargetLabel.Size = UDim2.new(1, -20, 0, 30)
    TargetLabel.Position = UDim2.new(0.5, 0, 0, 80)
    TargetLabel.AnchorPoint = Vector2.new(0.5, 0)
    TargetLabel.Font = Enum.Font.Gotham
    TargetLabel.Text = "Select Target"
    TargetLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    TargetLabel.TextSize = 14
    
    -- We would continue creating all other UI elements (buttons, sliders, tabs) here
    -- This is just the basic structure to get started.
end


function Module.Show(selectionCallback, visibilityCallback, savedSelections)
    createUI() -- Make sure the UI is created
    
    onSelectionChanged = selectionCallback or function() end
    onVisibilityChanged = visibilityCallback or function() end
    
    -- Logic to populate the inventory list goes here
    
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    ScreenGui.Enabled = true
    onVisibilityChanged(true)
end

function Module.Hide()
    if ScreenGui then
        ScreenGui.Enabled = false
    end
    onVisibilityChanged(false)
end

return Module
