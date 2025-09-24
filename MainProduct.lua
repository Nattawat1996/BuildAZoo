local function runAutoCollectPet(tok)
    local function passArea(uid)
        local want = Configuration.Pet.Filters.Area or "Any"
        return want == "Any" or petArea(uid) == want
    end

    while tok.alive do
        local CollectMode = Configuration.Pet.Filters.CollectMode or "All"
        local function claimDel(UID, PetData)
            if PetData.RE then pcall(function() PetData.RE:FireServer("Claim") end) end
            pcall(function() CharacterRE:FireServer("Del", UID) end)
        end

        for UID, PetData in pairs(OwnedPets) do
            if not tok.alive then break end
            if not (PetData and not PetData.IsBig and passArea(UID)) then continue end
            
            local shouldCollect = false
            if CollectMode == "All" then
                shouldCollect = true
            elseif CollectMode == "Match" then
                local petType = PetData.Type
                local petMuta = PetData.Mutate or "None"
                
                local passTypeCheck = not next(Configuration.Pet.Filters.Types) or Configuration.Pet.Filters.Types[petType]
                local passMutaCheck = not next(Configuration.Pet.Filters.Mutations) or Configuration.Pet.Filters.Mutations[petMuta]

                if passTypeCheck and passMutaCheck then
                    shouldCollect = true
                end
            elseif CollectMode == "Income <=" then
                local threshold = tonumber(Configuration.Pet.Filters.IncomeBelow) or 0
                local ps = tonumber(PetData.ProduceSpeed) or 0
                shouldCollect = (ps <= threshold)
            end
            
            if shouldCollect then
                claimDel(UID, PetData)
                task.wait(0.2)
            end
        end
        
        local delay = tonumber(Configuration.Pet.CollectPet_Delay) or 5
        if not _waitAlive(tok, delay) then break end
    end
end
