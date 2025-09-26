-- File: TradeLogic.lua
-- This module contains all the backend logic for the trading system.

local Module = {}

-- This function will be called by the main script's task runner.
-- It gathers items to send based on the configuration and sends them.
function Module.ExecuteTrade(tok, Configuration, Players, OwnedPetData, OwnedEggData, InventoryData, GiftRE, CharacterRE)
    local cfg = Configuration.Trade
    local targetPlayer = Players:FindFirstChild(cfg.TargetPlayer)

    if not targetPlayer then
        -- We'll handle notifications in the main script
        warn("[TradeLogic] Target player not found.")
        return
    end

    -- 1. Gather all items to send based on SendLists
    local itemsToSend = {}
    local function addItem(uid, type, amount)
        for i = 1, amount do
            table.insert(itemsToSend, {uid = uid, type = type})
        end
    end

    -- Gather Pets, Eggs, and Fruits from the SendList tables
    for uid, amount in pairs(cfg.SendListPets) do addItem(uid, "Pet", amount) end
    for uid, amount in pairs(cfg.SendListEggs) do addItem(uid, "Egg", amount) end
    for uid, amount in pairs(cfg.SendListFruits) do addItem(uid, "Fruit", amount) end

    -- Apply filters (Mutation, Ocean) here by removing items from itemsToSend
    -- (This logic can be added later for more complexity)

    if #itemsToSend == 0 then
        warn("[TradeLogic] No items to send.")
        return
    end

    -- 2. Send the items
    -- Teleport logic can be handled by the main script if needed
    
    for i, item in ipairs(itemsToSend) do
        if not tok.alive then break end
        
        pcall(function()
            CharacterRE:FireServer("Focus", item.uid)
            task.wait(0.5)
            GiftRE:FireServer(targetPlayer)
        end)
        
        -- Wait based on the configured send speed
        local waitTime = cfg.SendSpeed or 2.0
        local deadline = os.clock() + waitTime
        while tok.alive and os.clock() < deadline do task.wait() end
    end
end

return Module
