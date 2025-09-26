-- File: TradeUI.lua (Final Version)

local Module = {}
local WindUI, Window
local onActionCallback = function(action, data) end
local PetsTab, EggsTab, FruitsTab

local function createUI(playersList, mutationsList, savedConfig)
    if Window then return end

    WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    Window = WindUI:CreateWindow({
        Title = "Auto Trade System",
        Width = 850, Height = 550, Draggable = true, Visible = false
    })

    local LeftGroup = Window:Groupbox({ Side = "Left", Size = 260, Name = "Controls" })
    local RightGroup = Window:Groupbox({ Side = "Right", Name = "Inventory Management" })

    -- === Left Panel ===
    LeftGroup:Image({ Image = "rbxassetid://0", Height = 128 })
    LeftGroup:Label({ Text = game:GetService("Players").LocalPlayer.Name, Centered = true })

    LeftGroup:Dropdown({
        Title = "Select Target", Values = playersList or {}, Default = savedConfig.TargetPlayer,
        Callback = function(v) onActionCallback("UpdateConfig", { key = "TargetPlayer", value = v }) end
    })

    LeftGroup:Button({ Title = "Send Now", Callback = function() onActionCallback("SendNow") end })

    LeftGroup:Slider({
        Title = "Send Speed", Default = savedConfig.SendSpeed, Min = 0.2, Max = 5.0, Suffix = "s", Precision = 1,
        Callback = function(v) onActionCallback("UpdateConfig", { key = "SendSpeed", value = v }) end
    })

    LeftGroup:Dropdown({
        Title = "Mutation Filter", Values = mutationsList or {"Any"}, Default = savedConfig.MutationFilter,
        Callback = function(v) onActionCallback("RefreshUI") end -- สั่งให้ UI รีเฟรช
    })

    LeftGroup:Toggle({
        Title = "Exclude Ocean Pets/Egg", Default = savedConfig.ExcludeOcean,
        Callback = function(v) onActionCallback("RefreshUI") end -- สั่งให้ UI รีเฟรช
    })

    LeftGroup:Toggle({
        Title = "Auto Trade", Default = savedConfig.Enabled,
        Callback = function(v) onActionCallback("ToggleAutoTrade", v) end
    })

    LeftGroup:Label({ Text = "Today Gift: 0/500" })

    -- === Right Panel ===
    RightGroup:Textbox({ Title = "Search...", Callback = function(v) onActionCallback("RefreshUI") end })
    
    local topBar = RightGroup:Groupbox({ Horizontal = true })
    topBar:Dropdown({ Title = "Sort:", Values = {"Name", "Count"}, Callback = function(v) onActionCallback("RefreshUI") end })
    topBar:Toggle({ Title = "Show 0x", Callback = function(v) onActionCallback("RefreshUI") end })
    topBar:Toggle({ Title = "Configured", Callback = function(v) onActionCallback("RefreshUI") end })
    
    local Tabs = RightGroup:Tabs()
    PetsTab = Tabs:Tab({ Name = "Pets" })
    EggsTab = Tabs:Tab({ Name = "Eggs" })
    FruitsTab = Tabs:Tab({ Name = "Fruits" })
end

-- ฟังก์ชันสำหรับวาดรายการไอเทม
function Module.Populate(allItems, savedSelections)
    if not PetsTab then return end

    local function populateTab(tab, items, itemType)
        tab:Clear()
        if not items or #items == 0 then
            tab:Label({ Text = "No items found.", Centered = true })
            return
        end
        for _, itemInfo in ipairs(items) do
            local itemGroup = tab:Groupbox({ Name = itemInfo.Name, Horizontal = true })
            itemGroup:Label({ Text = string.format("%s (Own: %d)", itemInfo.Name, itemInfo.Count), Size = 300 })
            itemGroup:Textbox({
                Title = "", Placeholder = "Keep", Numeric = true, Width = 100,
                Default = tostring(savedSelections[itemInfo.UID] or ""),
                Callback = function(v)
                    onActionCallback("UpdateSendAmount", {
                        type = itemType,
                        uid = itemInfo.UID,
                        amount = tonumber(v) or 0
                    })
                end
            })
        end
    end
    
    populateTab(PetsTab, allItems.pets, "Pets")
    populateTab(EggsTab, allItems.eggs, "Eggs")
    populateTab(FruitsTab, allItems.fruits, "Fruits")
end

function Module.Show(actionCb, visibilityCb, savedCfg, players, mutations, allItems)
    onActionCallback = actionCb or function() end
    onVisibilityChanged_callback = visibilityCb or function() end
    
    createUI(players, mutations, savedCfg)
    Module.Populate(allItems, {
        unpack(savedCfg.SendListPets),
        unpack(savedCfg.SendListEggs),
        unpack(savedCfg.SendListFruits)
    })
    
    Window:Toggle()
    onVisibilityChanged_callback(Window.Visible)
end

return Module
