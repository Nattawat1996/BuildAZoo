-- File: TradeUI.lua (Version 3 - with Dropdown Structure)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Module = {}

local onSelectionChanged = function() end
local onVisibilityChanged = function() end

local ScreenGui, MainFrame

local function createUI()
    if ScreenGui and ScreenGui.Parent then return end

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

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame

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
    
    -- vvv [ส่วนที่เพิ่มเข้ามาใหม่] vvv
    -- สร้างโครงสร้างของ Dropdown "Select Target"
    local DropdownContainer = Instance.new("Frame")
    DropdownContainer.Name = "DropdownContainer"
    DropdownContainer.Parent = LeftPanel
    DropdownContainer.BackgroundTransparency = 1
    DropdownContainer.Position = UDim2.new(0.5, 0, 0, 80)
    DropdownContainer.Size = UDim2.new(1, -40, 0, 40)
    DropdownContainer.AnchorPoint = Vector2.new(0.5, 0)
    DropdownContainer.ZIndex = 2

    -- ปุ่มหลักสำหรับกดเพื่อเปิด/ปิด Dropdown
    local DropdownButton = Instance.new("TextButton")
    DropdownButton.Name = "DropdownButton"
    DropdownButton.Parent = DropdownContainer
    DropdownButton.BackgroundColor3 = Color3.fromRGB(50, 52, 60)
    DropdownButton.Size = UDim2.new(1, 0, 1, 0)
    DropdownButton.Font = Enum.Font.Gotham
    DropdownButton.Text = "Select Target"
    DropdownButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    DropdownButton.TextSize = 14
    
    local DropdownCorner = UICorner:Clone()
    DropdownCorner.Parent = DropdownButton

    -- กรอบสำหรับแสดงรายชื่อผู้เล่น (ซ่อนไว้ก่อน)
    local OptionsFrame = Instance.new("ScrollingFrame")
    OptionsFrame.Name = "OptionsFrame"
    OptionsFrame.Parent = DropdownContainer
    OptionsFrame.BackgroundColor3 = Color3.fromRGB(50, 52, 60)
    OptionsFrame.BorderSizePixel = 0
    OptionsFrame.Position = UDim2.new(0, 0, 1, 5) -- อยู่ข้างล่างปุ่มหลัก
    OptionsFrame.Size = UDim2.new(1, 0, 4, 0) -- สูง 4 เท่าของปุ่ม
    OptionsFrame.Visible = false -- << ซ่อนไว้เป็นค่าเริ่มต้น
    OptionsFrame.ZIndex = 3

    local OptionsCorner = UICorner:Clone()
    OptionsCorner.Parent = OptionsFrame

    -- เมื่อกดปุ่มหลัก ให้สลับการมองเห็นของกรอบรายชื่อ
    DropdownButton.MouseButton1Click:Connect(function()
        OptionsFrame.Visible = not OptionsFrame.Visible
    end)
    -- ^^^ [จบส่วนที่เพิ่มเข้ามาใหม่] ^^^
end

function Module.Show(selectionCallback, visibilityCallback, savedSelections)
    createUI()
    onSelectionChanged = selectionCallback or function() end
    onVisibilityChanged = visibilityCallback or function() end
    
    -- เราจะมาเขียนโค้ดสำหรับใส่รายชื่อผู้เล่นในนี้ทีหลัง
    
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
