--==============================================================
--                   nut.headless.lua (No-UI)
--         Headless build: ไม่โหลด/สร้าง UI ใด ๆ ทั้งสิ้น
--  เพิ่ม: AutoLike, AutoLottery, CheckMinCoin, SmartFeed(+Blacklist)
--  ลบ:   AutoPlace, AutoHatch, AutoSell
--==============================================================

-- ถ้ามี instance เก่า ให้ Destroy ก่อน
if getgenv().MeowyHeadless and typeof(getgenv().MeowyHeadless.Destroy) == "function" then
    pcall(function() getgenv().MeowyHeadless:Destroy() end)
end

repeat task.wait() until game:IsLoaded()

----------------------------------------------------------------
-- Services & Shortcuts
----------------------------------------------------------------
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService         = game:GetService("RunService")
local VirtualUser        = game:GetService("VirtualUser")

local Player  = Players.LocalPlayer
local USERID  = Player and Player.UserId or 0

----------------------------------------------------------------
-- Logger (แทน Notify)
----------------------------------------------------------------
local function log(fmt, ...)
    local ok, s = pcall(function() return ("[HEADLESS] "..fmt):format(...) end)
    s = ok and s or tostring(fmt)
    print(s)
    return s
end
local function warnlog(fmt, ...) warn(log(fmt, ...)) end

----------------------------------------------------------------
-- Safe Wait
----------------------------------------------------------------
local function waitFor(obj, name, t)
    local ok, r = pcall(function() return obj:WaitForChild(name, t or 30) end)
    return ok and r or nil
end

----------------------------------------------------------------
-- Game Paths
----------------------------------------------------------------
local RemoteFolder  = waitFor(ReplicatedStorage, "Remote", 30) or Instance.new("Folder")
local PetRE         = waitFor(RemoteFolder, "PetRE", 5)
local CharacterRE   = waitFor(RemoteFolder, "CharacterRE", 5)
local ConveyorRE    = waitFor(RemoteFolder, "ConveyorRE", 5)
local FoodStoreRE   = waitFor(RemoteFolder, "FoodStoreRE", 5)
local LotteryRE     = waitFor(RemoteFolder, "LotteryRE", 5)
local FishingRE     = waitFor(RemoteFolder, "FishingRE", 5)

local ServerTime    = waitFor(ReplicatedStorage, "Time", 5)

local PlayerGui     = waitFor(Players.LocalPlayer, "PlayerGui", 60)
local Data          = PlayerGui and waitFor(PlayerGui, "Data", 60)

local InventoryData = Data and waitFor(Data, "Asset", 30)
local OwnedPetData  = Data and waitFor(Data, "Pets", 30)
local OwnedEggData  = Data and waitFor(Data, "Egg", 30)

local FoodStore     = Data and waitFor(Data, "FoodStore", 30)
local FoodStoreLST  = FoodStore and waitFor(FoodStore, "LST", 30)

local Art           = waitFor(workspace, "Art", 60)
local IslandName    = Player:GetAttribute("AssignedIslandName")
local Island        = Art and waitFor(Art, IslandName or "", 60)

local PetFolder     = waitFor(workspace, "Pets", 60)
local EggsRoot      = waitFor(ReplicatedStorage, "Eggs", 30)
local EggBeltFolder = EggsRoot and waitFor(EggsRoot, IslandName or "", 30)

local InGameConfig  = waitFor(ReplicatedStorage, "Config", 30)
local ResConveyor   = InGameConfig and waitFor(InGameConfig, "ResConveyor", 5)
local ConveyorDB    = ResConveyor and require(ResConveyor) or {}

----------------------------------------------------------------
-- Config Mapping (จาก getgenv().MEOWYConfig)
----------------------------------------------------------------
local cfg = rawget(getgenv(), "MEOWYConfig") or {}
local function pick(v, d) return (v == nil) and d or v end

local Configuration = {
    Main = {
        AutoCollect         = pick(cfg.AutoCollect,  false),
        Collect_Delay       = pick(cfg.AutoCollectDelay, 3),
        AutoUpgradeConveyor = pick(cfg.AutoUpgrade,  false),
        AutoUnlockTiles     = pick(cfg.AutoUnlockFarm, false),
    },
    Fishing = {
        Auto = pick(cfg.AutoFish, false),
        Bait = cfg.FishingBait or "FishingBait1",
    },
    Pet = {
        AutoFeed       = pick(cfg.AutoFeed, false),
        SmartFeed      = pick(cfg.SmartFeed, false),
        SmartFeedDelay = tonumber(cfg.SmartFeedDelay) or 15,
        SmartFeed_Blacklist = cfg.SmartFeedBlacklist or {}, -- { FruitName = true }
    },
    Egg = {
        AutoBuyEgg     = pick(cfg.AutoBuy, false),
        AutoBuyEgg_Delay = 3,
        CheckMinCoin   = pick(cfg.CheckMinCoin, false),
        MinCoin        = tonumber(cfg.MinCoin) or 0,
        Filters = {
            Types     = (cfg.EggFilters and cfg.EggFilters.Types) or {},
            Mutations = (cfg.EggFilters and cfg.EggFilters.Mutations) or {},
        }
    },
    Shop = {
        Food = {
            AutoBuy      = pick(cfg.AutoBuyFruit, false),
            AutoBuy_Delay= 10,
            Foods        = cfg.BuyFoods or {}, -- { Pear=true, ... }
        }
    },
    Event = {
        AutoClaim       = pick(cfg.AutoClaim, false),
        AutoClaim_Delay = tonumber(cfg.AutoClaimDelay) or 3,
        AutoLike        = pick(cfg.AutoLike, false),
        AutoLottery     = pick(cfg.AutoLottery, false),
    },
    Perf = {
        Disable3D  = pick(cfg.Disable3D, false),
        FPSLock    = pick(cfg.FPSLock, false),
        FPSValue   = tonumber(cfg.FPSValue) or 60,
        HideGameUI = pick(cfg.HideGameUI, false),
    },
    AntiAFK = pick(cfg.AntiAFK, true),
}

----------------------------------------------------------------
-- Performance
----------------------------------------------------------------
local _setfps = rawget(getgenv(), "setfpscap") or rawget(_G, "setfpscap") or (syn and syn.set_fps_cap)
local function Set3D(on) pcall(function() RunService:Set3dRenderingEnabled(on) end) end
local function ApplyFPS()
    if not _setfps then return end
    if Configuration.Perf.FPSLock then
        _setfps(math.max(5, math.floor(Configuration.Perf.FPSValue or 60)))
    else
        _setfps(1000)
    end
end
local _uiHidden = false
local function ApplyHideGameUI(on)
    local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") then
            if on then
                if gui.Name ~= "PerfWhite" then gui.Enabled = false end
            else
                gui.Enabled = true
            end
        end
    end
    _uiHidden = on
end
local function ApplyPerf()
    ApplyFPS()
    Set3D(not Configuration.Perf.Disable3D)
    ApplyHideGameUI(Configuration.Perf.HideGameUI)
end

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function EnsureDataRefs()
    if not PlayerGui or not PlayerGui.Parent then PlayerGui = waitFor(Players.LocalPlayer, "PlayerGui", 5) end
    if not Data or not Data.Parent then Data = PlayerGui and waitFor(PlayerGui, "Data", 5) end
    if Data then
        if not InventoryData or not InventoryData.Parent then InventoryData = waitFor(Data, "Asset", 5) end
        if not OwnedPetData or not OwnedPetData.Parent then OwnedPetData = waitFor(Data, "Pets", 5) end
        if not OwnedEggData or not OwnedEggData.Parent then OwnedEggData = waitFor(Data, "Egg", 5) end
    end
end

local function getCash()
    return (InventoryData and tonumber(InventoryData:GetAttribute("Coin"))) or 0
end

local function getRoot(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        if inst.PrimaryPart then return inst.PrimaryPart end
        local rp = inst:FindFirstChild("HumanoidRootPart") or inst:FindFirstChild("RootPart")
        if rp and rp:IsA("BasePart") then return rp end
        for _, d in ipairs(inst:GetDescendants()) do
            if d:IsA("BasePart") then return d end
        end
    end
    return nil
end

----------------------------------------------------------------
-- Task Manager
----------------------------------------------------------------
local TaskMgr = {}
do
    local reg = {}
    function TaskMgr.start(name, fn)
        TaskMgr.stop(name)
        local tok = { alive = true, name = name }
        reg[name] = tok
        task.spawn(function()
            local ok, err = pcall(fn, tok)
            if not ok then warnlog("Task %s crashed: %s", name, tostring(err)) end
        end)
        log("Task start: %s", name)
    end
    function TaskMgr.stop(name)
        local t = reg[name]
        if t then t.alive = false; reg[name] = nil; log("Task stop: %s", name) end
    end
    function TaskMgr.stopAll()
        for k, t in pairs(reg) do t.alive = false; reg[k] = nil end
        log("Task stopAll")
    end
    function TaskMgr.isRunning(name) return reg[name] ~= nil end
end
local function waitAlive(tok, sec)
    local until_ = os.clock() + (tonumber(sec) or 0)
    repeat task.wait() until not tok.alive or os.clock() >= until_
    return tok.alive
end

----------------------------------------------------------------
-- TASKS
----------------------------------------------------------------

-- 1) AutoCollect : เคลมเงินจากสัตว์ที่วางอยู่
local function task_AutoCollect(tok)
    while tok.alive do
        if PetFolder then
            for _, m in ipairs(PetFolder:GetChildren()) do
                if not tok.alive then break end
                if m:GetAttribute("UserId") == USERID then
                    local re = m:FindFirstChild("RE", true)
                    if re then pcall(function() re:FireServer("Claim") end) end
                    task.wait(0.05)
                end
            end
        end
        if not waitAlive(tok, Configuration.Main.Collect_Delay or 3) then break end
    end
end

-- 2) AutoUpgrade Conveyor
local function nextConveyorIndex()
    local env = Island and Island:FindFirstChild("ENV")
    local conv = env and env:FindFirstChild("Conveyor")
    if not conv then return 1 end
    local maxIdx = 0
    for _, c in ipairs(conv:GetChildren()) do
        local num = tonumber((c.Name or ""):match("(%d+)$"))
        if num and num > maxIdx then maxIdx = num end
    end
    return maxIdx + 1
end
local function task_AutoUpgrade(tok)
    while tok.alive do
        local idx = nextConveyorIndex()
        local conf = ConveyorDB and ConveyorDB["Conveyor"..tostring(idx)]
        local cost = (conf and tonumber(conf.Cost)) or math.huge
        if getCash() >= cost then
            if ConveyorRE then pcall(function() ConveyorRE:FireServer("Upgrade", idx) end) end
            task.wait(2)
        else
            if not waitAlive(tok, 2) then break end
        end
    end
end

-- 3) AutoUnlock Tiles
local function lockedTiles()
    local out = {}
    local env = Island and Island:FindFirstChild("ENV")
    local locks = env and env:FindFirstChild("Locks")
    if not locks then return out end
    for _, model in ipairs(locks:GetChildren()) do
        local farm = model:FindFirstChild("Farm")
        if farm and farm:IsA("BasePart") and farm.Transparency == 0 then
            local cost = tonumber(farm:GetAttribute("LockCost")) or math.huge
            table.insert(out, { farm = farm, cost = cost })
        end
    end
    table.sort(out, function(a,b) return (a.cost or math.huge) < (b.cost or math.huge) end)
    return out
end
local function task_AutoUnlock(tok)
    while tok.alive do
        local list = lockedTiles()
        if #list == 0 then break end
        local cash = getCash()
        local did = false
        for _, it in ipairs(list) do
            if not tok.alive then break end
            if cash >= (it.cost or math.huge) then
                if CharacterRE then pcall(function() CharacterRE:FireServer("Unlock", it.farm) end) end
                cash = cash - (it.cost or 0)
                did = true
                task.wait(0.2)
            else
                break
            end
        end
        if not did and not waitAlive(tok, 2) then break end
    end
end

-- 4) AutoBuyFood
local function task_AutoBuyFood(tok)
    while tok.alive do
        if FoodStoreLST and FoodStoreRE then
            for foodName, stock in pairs(FoodStoreLST:GetAttributes()) do
                if not tok.alive then break end
                if (tonumber(stock) or 0) > 0 and Configuration.Shop.Food.Foods[foodName] then
                    pcall(function() FoodStoreRE:FireServer(foodName) end)
                    task.wait(0.1)
                end
            end
        end
        if not waitAlive(tok, Configuration.Shop.Food.AutoBuy_Delay or 10) then break end
    end
end

-- 5) AutoFeed (พื้นฐาน)
local function firstAllowedFruit(inventoryMap)
    -- ใช้รายการ BuyFoods เป็นลิสต์นำ
    local list = {}
    for name, allowed in pairs(Configuration.Shop.Food.Foods) do
        if allowed then table.insert(list, name) end
    end
    table.sort(list)
    for _, name in ipairs(list) do
        if (tonumber(inventoryMap[name] or 0) or 0) > 0 then return name end
    end
    -- fallback: อะไรก็ได้ที่ลงท้าย Fruit
    for name, n in pairs(inventoryMap) do
        if tostring(name):match("Fruit") and (tonumber(n) or 0) > 0 then return name end
    end
    return nil
end
local function isBigPet(model)
    local root = getRoot(model)
    if not root then return false end
    local gui = root:FindFirstChild("GUI", true)
    return gui and (gui:FindFirstChild("BigPetGUI", true) ~= nil) or false
end
local function task_AutoFeed(tok)
    while tok.alive do
        EnsureDataRefs()
        local inv = (InventoryData and InventoryData:GetAttributes()) or {}
        local fruit = firstAllowedFruit(inv)
        if fruit and PetFolder and PetRE and CharacterRE then
            for _, m in ipairs(PetFolder:GetChildren()) do
                if not tok.alive then break end
                if m:GetAttribute("UserId") == USERID and isBigPet(m) then
                    local uidNode = OwnedPetData and OwnedPetData:FindFirstChild(m.Name)
                    local onCD = uidNode and uidNode:GetAttribute("Feed")
                    if not onCD then
                        pcall(function()
                            CharacterRE:FireServer("Focus", fruit)
                            task.wait(0.25)
                            PetRE:FireServer("Feed", m.Name)
                            task.wait(0.25)
                            CharacterRE:FireServer("Focus")
                        end)
                    end
                end
            end
        end
        if not waitAlive(tok, 10) then break end
    end
end

-- 6) SmartFeed (+Blacklist)
-- แนวคิด: ดู inventory → เลือกผลไม้ "ที่มี" และ "ไม่โดน blacklist" ตามลำดับความสำคัญ
local FRUIT_PRIORITY = {
    "DragonFruit","GoldMango","VoltGinkgo","ColossalPinecone","BloodstoneCycad",
    "DeepseaPearlFruit","Pineapple","Durian","Pear","Pumpkin","CandyCorn"
}
local function pickSmartFruit(inv, blacklist)
    -- 1) เคารพ blacklist
    local deny = {}
    for k, v in pairs(blacklist or {}) do if v then deny[k] = true end end
    -- 2) ไล่ตาม priority
    for _, name in ipairs(FRUIT_PRIORITY) do
        local have = tonumber(inv[name] or 0) or 0
        if have > 0 and not deny[name] then
            return name
        end
    end
    -- 3) เผื่อชื่ออื่น ๆ ใน inventory ที่ลงท้าย Fruit
    for name, n in pairs(inv) do
        if tostring(name):match("Fruit") and (tonumber(n) or 0) > 0 and not deny[name] then
            return name
        end
    end
    return nil
end
local function task_SmartFeed(tok)
    while tok.alive do
        EnsureDataRefs()
        local inv = (InventoryData and InventoryData:GetAttributes()) or {}
        local fruit = pickSmartFruit(inv, Configuration.Pet.SmartFeed_Blacklist)
        if fruit and PetFolder and PetRE and CharacterRE then
            for _, m in ipairs(PetFolder:GetChildren()) do
                if not tok.alive then break end
                if m:GetAttribute("UserId") == USERID and isBigPet(m) then
                    local uidNode = OwnedPetData and OwnedPetData:FindFirstChild(m.Name)
                    local onCD = uidNode and uidNode:GetAttribute("Feed")
                    if not onCD then
                        pcall(function()
                            CharacterRE:FireServer("Focus", fruit)
                            task.wait(0.25)
                            PetRE:FireServer("Feed", m.Name)
                            task.wait(0.25)
                            CharacterRE:FireServer("Focus")
                        end)
                    end
                end
            end
        end
        if not waitAlive(tok, Configuration.Pet.SmartFeedDelay or 15) then break end
    end
end

-- 7) AutoBuyEgg (+CheckMinCoin + Filters)
local function task_AutoBuyEgg(tok)
    while tok.alive do
        EnsureDataRefs()
        if Configuration.Egg.CheckMinCoin and getCash() < (Configuration.Egg.MinCoin or 0) then
            if not waitAlive(tok, Configuration.Egg.AutoBuyEgg_Delay or 3) then break end
        else
            if EggBeltFolder and CharacterRE then
                for _, egg in ipairs(EggBeltFolder:GetChildren()) do
                    if not tok.alive then break end
                    local t = egg:GetAttribute("T") or "BasicEgg"
                    local m = egg:GetAttribute("M") or "None"
                    local typeOK = (next(Configuration.Egg.Filters.Types) == nil) or (Configuration.Egg.Filters.Types[t] == true)
                    local mutOK  = (next(Configuration.Egg.Filters.Mutations) == nil) or (Configuration.Egg.Filters.Mutations[m] == true)
                    if typeOK and mutOK then
                        pcall(function() CharacterRE:FireServer("BuyEgg", egg.Name) end)
                        task.wait(0.12)
                    end
                end
            end
            if not waitAlive(tok, Configuration.Egg.AutoBuyEgg_Delay or 3) then break end
        end
    end
end

-- 8) AutoClaim (Event Tasks)
local function locateEventRE()
    for _, v in ipairs(ReplicatedStorage:GetChildren()) do
        local base = tostring(v):match("^(.*)Event$")
        if base then
            local re = RemoteFolder:FindFirstChild(base.."RE")
            if re then return re end
        end
    end
    return nil
end
local function task_AutoClaim(tok)
    local EventRE, EventTaskData
    if Data then
        for _, f in ipairs(Data:GetChildren()) do
            if tostring(f):match("EventTaskData$") then EventTaskData = f break end
        end
    end
    EventRE = locateEventRE()
    while tok.alive do
        if EventRE and EventTaskData then
            local Tasks = EventTaskData:FindFirstChild("Tasks")
            if Tasks then
                for _, q in ipairs(Tasks:GetChildren()) do
                    if not tok.alive then break end
                    pcall(function() EventRE:FireServer({event="claimreward", id=q:GetAttribute("Id")}) end)
                    task.wait(0.4)
                end
            end
        end
        if not waitAlive(tok, Configuration.Event.AutoClaim_Delay or 3) then break end
    end
end

-- 9) AutoLottery
local function task_AutoLottery(tok)
    while tok.alive do
        EnsureDataRefs()
        if InventoryData and LotteryRE then
            local n = tonumber(InventoryData:GetAttribute("LotteryTicket")) or 0
            if n > 0 then
                pcall(function() LotteryRE:FireServer({event="lottery", count=1}) end)
            end
        end
        if not waitAlive(tok, 60) then break end
    end
end

-- 10) AutoLike
local function task_AutoLike(tok)
    local liked = {}
    while tok.alive do
        local me = Players.LocalPlayer
        local candidates = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= me and not liked[plr.UserId] then
                table.insert(candidates, plr.UserId)
            end
        end
        if #candidates == 0 then
            -- ไม่มีคนให้กด like เพิ่ม รอสักพักแล้ววนใหม่
            if not waitAlive(tok, 10) then break end
        else
            for _, uid in ipairs(candidates) do
                if not tok.alive then break end
                pcall(function()
                    if CharacterRE then CharacterRE:FireServer("GiveLike", uid) end
                end)
                liked[uid] = true
                task.wait(1.0)
            end
        end
    end
end

-- 11) AutoFishing (เบา)
local fishingState = { didFocus=false, lockedPos=nil }
local function defaultFishPos()
    local ch = Players.LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    local p = hrp and hrp.Position or workspace.CurrentCamera.CFrame.Position
    return p + Vector3.new(2,10,0)
end
local function task_AutoFishing(tok)
    while tok.alive do
        if FishingRE and CharacterRE then
            if not fishingState.didFocus then
                pcall(function() CharacterRE:FireServer("Focus", "FishRob") end)
                fishingState.didFocus = true
            end
            fishingState.lockedPos = fishingState.lockedPos or defaultFishPos()
            pcall(function()
                CharacterRE:FireServer("Focus", "FishRob")
                FishingRE:FireServer("Start")
                FishingRE:FireServer("Throw", { NoMove = true, Bait = Configuration.Fishing.Bait, Pos = fishingState.lockedPos })
                FishingRE:FireServer("POUT", { NoMove = true, SUC = 1 })
            end)
        end
        if not waitAlive(tok, 0.05) then break end
    end
end

-- 12) AntiAFK
local function task_AntiAFK(tok)
    while tok.alive do
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        if not waitAlive(tok, 30) then break end
    end
end

----------------------------------------------------------------
-- AUTOSTART
----------------------------------------------------------------
local function autostart()
    ApplyPerf()

    local function StartIf(flag, name, fn)
        if flag then TaskMgr.start(name, fn) else TaskMgr.stop(name) end
    end

    StartIf(Configuration.AntiAFK,                   "AntiAFK",        task_AntiAFK)
    StartIf(Configuration.Main.AutoCollect,          "AutoCollect",    task_AutoCollect)
    StartIf(Configuration.Main.AutoUpgradeConveyor,  "AutoUpgrade",    task_AutoUpgrade)
    StartIf(Configuration.Main.AutoUnlockTiles,      "AutoUnlockTiles","task_AutoUnlock") -- typo safe
    if Configuration.Main.AutoUnlockTiles then TaskMgr.start("AutoUnlockTiles", task_AutoUnlock) end

    StartIf(Configuration.Shop.Food.AutoBuy,         "AutoBuyFood",    task_AutoBuyFood)
    StartIf(Configuration.Pet.AutoFeed,              "AutoFeed",       task_AutoFeed)
    StartIf(Configuration.Pet.SmartFeed,             "SmartFeed",      task_SmartFeed)

    StartIf(Configuration.Egg.AutoBuyEgg,            "AutoBuyEgg",     task_AutoBuyEgg)

    StartIf(Configuration.Event.AutoClaim,           "AutoClaim",      task_AutoClaim)
    StartIf(Configuration.Event.AutoLike,            "AutoLike",       task_AutoLike)
    StartIf(Configuration.Event.AutoLottery,         "AutoLottery",    task_AutoLottery)

    StartIf(Configuration.Fishing.Auto,              "AutoFishing",    task_AutoFishing)
end

----------------------------------------------------------------
-- Controller (Destroy)
----------------------------------------------------------------
local Controller = {}
function Controller:Destroy()
    TaskMgr.stopAll()
    pcall(function()
        if _setfps then _setfps(1000) end
        Set3D(true)
        if _uiHidden then ApplyHideGameUI(false) end
    end)
    pcall(function()
        local ch = Players.LocalPlayer.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = false end
    end)
    log("Destroyed previous headless instance.")
end
getgenv().MeowyHeadless = Controller

----------------------------------------------------------------
-- Boot
----------------------------------------------------------------
log("Loaded headless script. Game: %s", (MarketplaceService:GetProductInfo(game.PlaceId).Name or ""))
task.defer(autostart)
