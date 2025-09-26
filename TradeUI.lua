-- File: TradeUI.lua (Version 6 - Corrected Callbacks)

local Module = {}

-- ตัวแปรสำหรับเก็บ UI Library และหน้าต่างหลัก
local WindUI
local Window

-- Callback placeholders
local onSelectionChanged_callback = function(key, value) end
local onVisibilityChanged_callback = function(isVisible) end

-- ฟังก์ชันสำหรับสร้าง UI ทั้งหมด
local function createUI(playersList, savedConfig)
    if Window then return end

    WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    Window = WindUI:CreateWindow({
        Title = "Auto Trade System",
        Width = 850,
        Height = 550,
        Draggable = true,
        Visible = false
    })

    local LeftGroup = Window:Group({ Side = "Left", Size = 250, Name = "Controls" })
    local RightGroup = Window:Group({ Side = "Right", Name = "Inventory Management" })

    -- === ส่วนควบคุมฝั่งซ้าย ===
    LeftGroup:Image({ Image = "rbxassetid://0", Height = 128 })
    LeftGroup:Label({ Text = game:GetService("Players").LocalPlayer.Name, Centered = true })

    LeftGroup:Dropdown({
        Title = "Select Target",
        Values = playersList or {},
        Default = savedConfig.TargetPlayer,
        Callback = function(value) onSelectionChanged_callback("TargetPlayer", value) end
    })

    LeftGroup:Button({
        Title = "Send Now",
        Callback = function() onSelectionChanged_callback("SendNow", true) end
    })

    LeftGroup:Slider({
        Title = "Send Speed",
        Default = savedConfig.SendSpeed,
        Min = 0.2, Max = 5.0, Suffix = "s", Precision = 1,
        Callback = function(value) onSelectionChanged_callback("SendSpeed", value) end
    })

    LeftGroup:Dropdown({
        Title = "Mutation Filter",
        Values = {"Any", "None"}, -- จะมาเพิ่มทีหลัง
        Default = savedConfig.MutationFilter,
        Callback = function(value) onSelectionChanged_callback("MutationFilter", value) end
    })

    LeftGroup:Toggle({
        Title = "Exclude Ocean Pets/Egg",
        Default = savedConfig.ExcludeOcean,
        Callback = function(value) onSelectionChanged_callback("ExcludeOcean", value) end
    })

    LeftGroup:Toggle({
        Title = "Auto Trade",
        Default = savedConfig.Enabled,
        Callback = function(value) onSelectionChanged_callback("Enabled", value) end
    })

    LeftGroup:Label({ Text = "Today Gift: 0/500" })

    -- === ส่วนไอเทมฝั่งขวา ===
    local Tabs = RightGroup:Tabs()
    local PetsTab = Tabs:Tab({ Name = "Pets" })
    local EggsTab = Tabs:Tab({ Name = "Eggs" })
    local FruitsTab = Tabs:Tab({ Name = "Fruits" })
end

-- ฟังก์ชันที่สคริปต์หลักจะเรียกใช้เพื่อเปิด UI (แก้ไขการรับค่า)
function Module.Show(selectionCb, visibilityCb, savedCfg, players)
    -- สร้าง UI ถ้ายังไม่เคยสร้าง
    createUI(players, savedCfg)

    -- รับ Callback เข้ามาเก็บไว้ในตัวแปร
    onSelectionChanged_callback = selectionCb or function() end
    onVisibilityChanged_callback = visibilityCb or function() end
    
    Window:Toggle()
    onVisibilityChanged_callback(Window.Visible)
end

function Module.Hide()
    if Window then
        Window:Toggle(false)
    end
    onVisibilityChanged_callback(false)
end

return Module
