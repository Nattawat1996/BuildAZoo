-- File: TradeUI.lua (Final Corrected Version)

local Module = {}

-- ตัวแปรสำหรับเก็บ UI Library และหน้าต่างหลัก
local WindUI
local Window

-- Callback placeholders
local onActionCallback = function(action, data) end
local onVisibilityChanged_callback = function(isVisible) end

-- ตัวแปรสำหรับเก็บ Tabs เพื่อให้ฟังก์ชันอื่นเรียกใช้ได้
local PetsTab, EggsTab, FruitsTab

-- ฟังก์ชันสำหรับ "วาด" รายการไอเทมลงในแท็บที่กำหนด
function Module.Populate(allItems, savedSelections)
    if not PetsTab then return end -- ป้องกัน Error ถ้า UI ยังไม่พร้อม

    local function populateTab(tab, items, itemType)
        tab:Clear() -- ล้างรายการเก่าทิ้งก่อน
        if not items or #items == 0 then
            tab:Label({ Text = "No items found in this category.", Centered = true })
            return
        end

        for _, itemInfo in ipairs(items) do
            local itemGroup = tab:Groupbox({ Name = itemInfo.Name, Horizontal = true })
            itemGroup:Label({ Text = string.format("%s (Own: %d)", itemInfo.Name, itemInfo.Count), Size = 300 })
            itemGroup:Textbox({
                Title = "", Placeholder = "Keep", Numeric = true, Width = 100,
                Default = tostring(savedSelections[itemInfo.UID] or ""),
                Callback = function(value)
                    onActionCallback("UpdateSendAmount", {
                        type = itemType,
                        uid = itemInfo.UID,
                        amount = tonumber(value) or 0
                    })
                end
            })
        end
    end
    
    -- จัดการข้อมูล SendList ที่ซับซ้อน
    local selections = {}
    for k, v in pairs(savedSelections.SendListPets) do selections[k] = v end
    for k, v in pairs(savedSelections.SendListEggs) do selections[k] = v end
    for k, v in pairs(savedSelections.SendListFruits) do selections[k] = v end

    populateTab(PetsTab, allItems.pets, "Pets")
    populateTab(EggsTab, allItems.eggs, "Eggs")
    populateTab(FruitsTab, allItems.fruits, "Fruits")
end

-- ฟังก์ชันสำหรับสร้าง UI ทั้งหมด (จะถูกเรียกแค่ครั้งแรก)
local function createUI(playersList, mutationsList, savedConfig)
    if Window then return end

    WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    
    -- ใช้ CreateWindow
    Window = WindUI:CreateWindow({
        Title = "Auto Trade System",
        Width = 850, Height = 550, Draggable = true, Visible = false
    })

    -- ใช้ Groupbox
    local LeftGroup = Window:Groupbox({ Side = "Left", Size = 260, Name = "Controls" })
    local RightGroup = Window:Groupbox({ Side = "Right", Name = "Inventory Management" })

    -- (ส่วนที่เหลือของ UI เหมือนเดิม แต่ถูกต้องแล้ว)
    LeftGroup:Image({ Image = "rbxassetid://0", Height = 128 })
    LeftGroup:Label({ Text = game:GetService("Players").LocalPlayer.Name, Centered = true })
    LeftGroup:Dropdown({ Title = "Select Target", Values = playersList or {}, Default = savedConfig.TargetPlayer, Callback = function(v) onActionCallback("UpdateConfig", { key = "TargetPlayer", value = v }) end })
    LeftGroup:Button({ Title = "Send Now", Callback = function() onActionCallback("SendNow") end })
    LeftGroup:Slider({ Title = "Send Speed", Default = savedConfig.SendSpeed, Min = 0.2, Max = 5.0, Suffix = "s", Precision = 1, Callback = function(v) onActionCallback("UpdateConfig", { key = "SendSpeed", value = v }) end })
    LeftGroup:Dropdown({ Title = "Mutation Filter", Values = mutationsList or {"Any"}, Default = savedConfig.MutationFilter, Callback = function(v) onActionCallback("UpdateConfig", { key = "MutationFilter", value = v }); onActionCallback("RefreshUI") end })
    LeftGroup:Toggle({ Title = "Exclude Ocean Pets/Egg", Default = savedConfig.ExcludeOcean, Callback = function(v) onActionCallback("UpdateConfig", { key = "ExcludeOcean", value = v }); onActionCallback("RefreshUI") end })
    LeftGroup:Toggle({ Title = "Auto Trade", Default = savedConfig.Enabled, Callback = function(v) onActionCallback("ToggleAutoTrade", v) end })
    LeftGroup:Label({ Text = "Today Gift: 0/500" })

    local Tabs = RightGroup:Tabs()
    PetsTab = Tabs:Tab({ Name = "Pets" })
    EggsTab = Tabs:Tab({ Name = "Eggs" })
    FruitsTab = Tabs:Tab({ Name = "Fruits" })
end

-- ฟังก์ชันที่สคริปต์หลักจะเรียกใช้
function Module.Show(actionCb, visibilityCb, savedCfg, players, mutations)
    onActionCallback = actionCb or function() end
    onVisibilityChanged_callback = visibilityCb or function() end
    
    createUI(players, mutations, savedCfg)
    
    Window:Toggle()
    onVisibilityChanged_callback(Window.Visible)
end

return Module
