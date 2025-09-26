-- File: TradeUI.lua (Version 7 - With Dynamic List Logic)

local Module = {}
local WindUI, Window
local onSelectionChanged_callback = function(key, value) end
local onVisibilityChanged_callback = function(isVisible) end

-- ตัวแปรสำหรับเก็บ Tabs เพื่อให้ฟังก์ชันอื่นเรียกใช้ได้
local PetsTab, EggsTab, FruitsTab

-- ฟังก์ชันสำหรับ "วาด" รายการไอเทมลงในแท็บที่กำหนด
local function populateItems(tab, items, itemType)
    -- ล้างรายการเก่าทิ้งก่อน
    tab:Clear()

    if not items or #items == 0 then
        tab:Label({ Text = "No items found in this category.", Centered = true })
        return
    end

    for _, itemInfo in ipairs(items) do
        -- สร้าง Groupbox สำหรับไอเทมแต่ละชิ้นเพื่อให้จัดวางสวยงาม
        local itemGroup = tab:Groupbox({
            Name = itemInfo.Name
        })

        -- (ในอนาคตเราจะเพิ่มรูป Icon เข้ามาตรงนี้)
        itemGroup:Label({ Text = string.format("Own: %d", itemInfo.Count) })
        
        -- สร้างช่อง Input สำหรับใส่จำนวนที่จะส่ง
        itemGroup:Textbox({
            Title = "Send Amount",
            Placeholder = "0",
            Numeric = true,
            Default = itemInfo.SendAmount or "",
            Callback = function(value)
                local amount = tonumber(value) or 0
                -- ส่งข้อมูลกลับไปที่สคริปต์หลัก
                onSelectionChanged_callback("UpdateSendAmount", {
                    type = itemType,
                    uid = itemInfo.UID,
                    name = itemInfo.Name,
                    amount = amount
                })
            end
        })
    end
end

local function createUI(playersList, savedConfig, allItems)
    if Window then return end

    WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    Window = WindUI:CreateWindow({
        Title = "Auto Trade System",
        Width = 850, Height = 550, Draggable = true, Visible = false
    })

    local LeftGroup = Window:Groupbox({ Side = "Left", Size = 250, Name = "Controls" })
    local RightGroup = Window:Groupbox({ Side = "Right", Name = "Inventory Management" })

    -- (โค้ดส่วน LeftGroup เหมือนเดิมทุกประการ)
    LeftGroup:Image({ Image = "rbxassetid://0", Height = 128 })
    LeftGroup:Label({ Text = game:GetService("Players").LocalPlayer.Name, Centered = true })
    LeftGroup:Dropdown({ Title = "Select Target", Values = playersList or {}, Default = savedConfig.TargetPlayer, Callback = function(v) onSelectionChanged_callback("TargetPlayer", v) end })
    LeftGroup:Button({ Title = "Send Now", Callback = function() onSelectionChanged_callback("SendNow", true) end })
    LeftGroup:Slider({ Title = "Send Speed", Default = savedConfig.SendSpeed, Min = 0.2, Max = 5.0, Suffix = "s", Precision = 1, Callback = function(v) onSelectionChanged_callback("SendSpeed", v) end })
    LeftGroup:Dropdown({ Title = "Mutation Filter", Values = {"Any", "None"}, Default = savedConfig.MutationFilter, Callback = function(v) onSelectionChanged_callback("MutationFilter", v) end })
    LeftGroup:Toggle({ Title = "Exclude Ocean Pets/Egg", Default = savedConfig.ExcludeOcean, Callback = function(v) onSelectionChanged_callback("ExcludeOcean", v) end })
    LeftGroup:Toggle({ Title = "Auto Trade", Default = savedConfig.Enabled, Callback = function(v) onSelectionChanged_callback("Enabled", v) end })
    LeftGroup:Label({ Text = "Today Gift: 0/500" })

    -- === ส่วนไอเทมฝั่งขวา ===
    local Tabs = RightGroup:Tabs()
    PetsTab = Tabs:Tab({ Name = "Pets" })
    EggsTab = Tabs:Tab({ Name = "Eggs" })
    FruitsTab = Tabs:Tab({ Name = "Fruits" })

    -- เรียกใช้ฟังก์ชันเพื่อเติมข้อมูล (จากข้อมูลจำลอง)
    populateItems(PetsTab, allItems.pets, "Pet")
    populateItems(EggsTab, allItems.eggs, "Egg")
    populateItems(FruitsTab, allItems.fruits, "Fruit")
end

-- ฟังก์ชันที่สคริปต์หลักจะเรียกใช้
function Module.Show(selectionCb, visibilityCb, savedCfg, players, allItems)
    onSelectionChanged_callback = selectionCb or function() end
    onVisibilityChanged_callback = visibilityCb or function() end
    
    -- สร้าง UI ถ้ายังไม่เคยสร้าง (ส่งข้อมูลทั้งหมดเข้าไป)
    createUI(players, savedCfg, allItems)
    
    Window:Toggle()
    onVisibilityChanged_callback(Window.Visible)
end

return Module
