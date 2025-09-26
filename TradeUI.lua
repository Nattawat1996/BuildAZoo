-- File: TradeUI.lua (WindUI Version)

local Module = {}

-- ตัวแปรสำหรับเก็บ UI Library และหน้าต่างหลัก
local WindUI
local Window

-- Callback placeholders
local onSelectionChanged = function() end
local onVisibilityChanged = function() end

-- ฟังก์ชันสำหรับสร้าง UI ทั้งหมด (จะถูกเรียกแค่ครั้งแรก)
local function createUI(playersList, savedConfig)
    if Window then return end -- ถ้าสร้างไปแล้ว ไม่ต้องสร้างซ้ำ

    -- 1. โหลด WindUI Library เข้ามา
    WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

    -- 2. สร้างหน้าต่างหลัก
    Window = WindUI:Window({
        Title = "Auto Trade System",
        Width = 850,
        Height = 550,
        Draggable = true,
        Visible = false -- เริ่มต้นแบบซ่อนไว้
    })

    -- 3. สร้าง Layout 2 ฝั่ง
    local LeftGroup = Window:Group({ Side = "Left", Size = 250, Name = "Controls" })
    local RightGroup = Window:Group({ Side = "Right", Name = "Inventory Management" })

    ----------------------------------
    -- === ส่วนควบคุมฝั่งซ้าย ===
    ----------------------------------
    LeftGroup:Image({ Image = "rbxassetid://0", Height = 128 }) -- Placeholder for avatar
    LeftGroup:Label({ Text = game:GetService("Players").LocalPlayer.Name, Centered = true })

    LeftGroup:Dropdown({
        Title = "Select Target",
        Values = playersList or {},
        Default = savedConfig.TargetPlayer,
        Callback = function(value)
            -- ส่งค่ากลับไปที่สคริปต์หลัก
            onSelectionChanged("TargetPlayer", value)
        end
    })

    LeftGroup:Button({
        Title = "Send Now",
        Callback = function()
            onSelectionChanged("SendNow", true) -- ส่งสัญญาณให้สคริปต์หลักเริ่มส่งของ
        end
    })

    LeftGroup:Slider({
        Title = "Send Speed",
        Default = savedConfig.SendSpeed,
        Min = 0.2, Max = 5.0, Suffix = "s", Precision = 1,
        Callback = function(value) onSelectionChanged("SendSpeed", value) end
    })

    -- (UI Scale เป็นส่วนเสริมที่ซับซ้อน จะข้ามไปก่อน)
    
    LeftGroup:Dropdown({
        Title = "Mutation Filter",
        Values = {"Any", "None"}, -- เราจะมาเพิ่มลิสต์เต็มๆ ทีหลัง
        Default = savedConfig.MutationFilter,
        Callback = function(value) onSelectionChanged("MutationFilter", value) end
    })

    LeftGroup:Toggle({
        Title = "Exclude Ocean Pets/Egg",
        Default = savedConfig.ExcludeOcean,
        Callback = function(value) onSelectionChanged("ExcludeOcean", value) end
    })

    LeftGroup:Toggle({
        Title = "Auto Trade",
        Default = savedConfig.Enabled,
        Callback = function(value) onSelectionChanged("AutoTrade", value) end
    })

    LeftGroup:Label({ Text = "Today Gift: 0/500" })

    ----------------------------------
    -- === ส่วนไอเทมฝั่งขวา ===
    ----------------------------------
    local SearchBar = RightGroup:Textbox({
        Title = "Search...",
        Callback = function(value) onSelectionChanged("Search", value) end
    })
    
    local Tabs = RightGroup:Tabs()
    local PetsTab = Tabs:Tab({ Name = "Pets" })
    local EggsTab = Tabs:Tab({ Name = "Eggs" })
    local FruitsTab = Tabs:Tab({ Name = "Fruits" })

    -- เราจะสร้างฟังก์ชันสำหรับเติมข้อมูลไอเทมลงในแต่ละแท็บนี้ทีหลัง
    -- PetsTab:Label({Text = "Pet list will appear here..."})
end

-- ฟังก์ชันที่สคริปต์หลักจะเรียกใช้เพื่อเปิด UI
function Module.Show(callbacks, savedConfig, playersList)
    -- สร้าง UI ถ้ายังไม่เคยสร้าง
    createUI(playersList, savedConfig)

    -- อัปเดต Callback และข้อมูล
    onSelectionChanged = callbacks.onSelectionChanged or function() end
    onVisibilityChanged = callbacks.onVisibilityChanged or function() end
    
    -- (ส่วนโค้ดสำหรับ Refresh รายการไอเทมจะถูกเพิ่มที่นี่ในอนาคต)

    -- เปิด/ปิดหน้าต่าง
    Window:Toggle()
    onVisibilityChanged(Window.Visible)
end

function Module.Hide()
    if Window then
        Window:Toggle(false)
    end
end

return Module
