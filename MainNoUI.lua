--==============================================================
--                   nut.headless.lua (No-UI)
--         Headless build: ไม่โหลด/สร้าง UI ใด ๆ ทั้งสิ้น
--   อ่าน config จาก getgenv().MEOWYConfig แล้ว autostart งาน
--==============================================================

-- ป้องกันซ้ำ: ถ้ามี instance เก่า ให้ Destroy ก่อน
if getgenv().MeowyHeadless and typeof(getgenv().MeowyHeadless.Destroy) == "function" then
    pcall(function() getgenv().MeowyHeadless:Destroy() end)
end

repeat task.wait() until game:IsLoaded()

--==============================================================
--                      SERVICES & SHORTCUTS
--==============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local USERID = Player and Player.UserId or 0

--==============================================================
--                      LOGGER (แทน Notify)
--==============================================================
local function log(fmt, ...)
    local ok, msg = pcall(function()
        local s = ("[HEADLESS] " .. tostring(fmt)):format(...)
        print(s)
        return s
    end)
    return ok and msg or ""
end
local function warnlog(fmt, ...) warn(log(fmt, ...)) end

--==============================================================
--                      GAME PATHS (SAFE WAIT)
--==============================================================
local function waitFor(obj, name, t)
    local ok, r = pcall(function() return obj:WaitForChild(name, t or 30) end)
    if ok then return r end
    return nil
end

local GameRemoteEvents = waitFor(ReplicatedStorage, "Remote", 30) or Instance.new("Folder")
local PetRE         = waitFor(GameRemoteEvents, "PetRE", 5)
local CharacterRE   = waitFor(GameRemoteEvents, "CharacterRE", 5)
local ConveyorRE    = waitFor(GameRemoteEvents, "ConveyorRE", 5)
local FoodStoreRE   = waitFor(GameRemoteEvents, "FoodStoreRE", 5)
local LotteryRE     = waitFor(GameRemoteEvents, "LotteryRE", 5)
local FishingRE     = waitFor(GameRemoteEvents, "FishingRE", 5)

local ServerTime    = waitFor(ReplicatedStorage, "Time", 5)

local PlayerGui     = waitFor(Player, "PlayerGui", 60)
local Data          = PlayerGui and waitFor(PlayerGui, "Data", 60)

local InventoryData = Data and waitFor(Data, "Asset", 30)
local OwnedPetData  = Data and waitFor(Data, "Pets", 30)
local OwnedEggData  = Data and waitFor(Data, "Egg", 30)

local FoodStore     = Data and waitFor(Data, "FoodStore", 30)
local FoodStoreLST  = FoodStore and waitFor(FoodStore, "LST", 30)

local IslandName    = Player:GetAttribute("AssignedIslandName")
local Art           = waitFor(workspace, "Art", 60)
local Island        = Art and waitFor(Art, IslandName or "", 60)  -- เกาะของเรา

local PetFolder     = waitFor(workspace, "Pets", 60)
local Blocks        = waitFor(workspace, "PlayerBuiltBlocks", 60)

local EggsRoot      = waitFor(ReplicatedStorage, "Eggs", 30)
local EggBeltFolder = EggsRoot and waitFor(EggsRoot, IslandName or "", 30)

local InGameConfig  = waitFor(ReplicatedStorage, "Config", 30) -- ใช้ require ข้อมูล
local ResConveyor   = InGameConfig and waitFor(InGameConfig, "ResConveyor", 5)
local ResPet        = InGameConfig and waitFor(InGameConfig, "ResPet", 5)
local ResEgg        = InGameConfig and waitFor(InGameConfig, "ResEgg", 5)

local ResPetDB      = ResPet and require(ResPet) or {}
local ResEggDB      = ResEgg and require(ResEgg) or {}
local ConveyorDB    = ResConveyor and require(ResConveyor) or {}

--==============================================================
--                      CONFIGURATION (DEFAULT)
--==============================================================
local cfg = rawget(getgenv(), "MEOWYConfig") or {}
local function pick(v, def) return (v == nil) and def or v end

-- โครงหลักของค่าในสคริปต์
local Configuration = {
    Main = {
        AutoCollect        = pick(cfg.AutoCollect, false),
        Collect_Delay      = pick(cfg.AutoCollectDelay, 3),
        AutoUpgradeConveyor= pick(cfg.AutoUpgrade, false),
        AutoUnlockTiles    = pick(cfg.AutoUnlockFarm, false),
    },
    Fishing = {
        Auto = pick(cfg.AutoFish, false),
        Bait = cfg.FishingBait or "FishingBait1",
    },
    Pet = {
        AutoFeed       = pick(cfg.AutoFeed, false),
        AutoPlacePet   = pick(cfg.AutoPlace or cfg.AutoPlacePet, false),
        AutoPlacePet_Delay = 1.0,
        SmartPet       = false, -- ปิดไว้ (เวอร์ชันเบา)
    },
    Egg = {
        AutoHatch      = pick(cfg.AutoHatch, false),
        AutoBuyEgg     = pick(cfg.AutoBuy, false),
        AutoPlaceEgg   = pick(cfg.AutoPlace or cfg.AutoPlaceEgg, false),
        AutoBuyEgg_Delay = 3,
        AutoPlaceEgg_Delay = 1.0,
        Hatch_Delay    = 15,
        PlaceArea      = "Any",  -- Any | Land | Water
        HatchArea      = "Any",
        CheckMinCoin   = false,
        MinCoin        = 0,
        Filters = {
            Types     = (cfg.EggFilters and cfg.EggFilters.Types) or {},
            Mutations = (cfg.EggFilters and cfg.EggFilters.Mutations) or {},
        }
    },
    Shop = {
        Food = {
            AutoBuy = pick(cfg.AutoBuyFruit, false),
            AutoBuy_Delay = 10,
            Foods = cfg.BuyFoods or {}
        }
    },
    Event = {
        AutoClaim       = pick(cfg.AutoClaim, false),
        AutoClaim_Delay = tonumber(cfg.AutoClaimDelay) or 3.0,
        AutoLottery     = false,
        AutoLike        = false
    },
    Sell = {
        Enabled              = pick(cfg.AutoSell, false),
        Egg_Types            = (cfg.Sell and cfg.Sell.Egg_Types) or {},
        Egg_Mutations        = (cfg.Sell and cfg.Sell.Egg_Mutations) or {},
        Pet_Income_Threshold = (cfg.Sell and tonumber(cfg.Sell.Pet_Income_Threshold)) or 0,
    },
    Perf = {
        Disable3D  = pick(cfg.Disable3D, false),
        FPSLock    = pick(cfg.FPSLock, false),
        FPSValue   = tonumber(cfg.FPSValue) or 60,
        HidePets   = pick(cfg.HidePets, false),
        HideEggs   = pick(cfg.HideEggs, false),
        HideEffects= pick(cfg.HideEffects, false),
        HideGameUI = pick(cfg.HideGameUI, false),
    },
    AntiAFK = pick(cfg.AntiAFK, true),
}

--==============================================================
--                  PERF (Disable3D / FPS Lock / Hide)
--==============================================================
local _setfps = rawget(getgenv(), "setfpscap") or rawget(_G, "setfpscap") or (syn and syn.set_fps_cap)
local function Perf_Set3DEnabled(enable)
    pcall(function() RunService:Set3dRenderingEnabled(enable) end)
end
local function ApplyFPS()
    if not _setfps then return end
    if Configuration.Perf.FPSLock then
        local cap = math.max(5, math.floor(Configuration.Perf.FPSValue or 60))
        _setfps(cap)
        log("FPS locked to %d", cap)
    else
        _setfps(1000)
        log("FPS unlocked")
    end
end
local _uiHidden = false
local function ApplyHideGameUI(on)
    local pg = Player:FindFirstChild("PlayerGui")
    if not pg then return end
    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") then
            if on then
                if gui.Name ~= "PerfWhite" then
                    gui.Enabled = false
                end
            else
                gui.Enabled = true
            end
        end
    end
    _uiHidden = on
end
local function ApplyPerf()
    ApplyFPS()
    Perf_Set3DEnabled(not Configuration.Perf.Disable3D)
    ApplyHideGameUI(Configuration.Perf.HideGameUI)
end

--==============================================================
--                       UTILS / HELPERS
--==============================================================
local function getCash()
    if not InventoryData then return 0 end
    local v = InventoryData:GetAttribute("Coin")
    return tonumber(v) or 0
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

local function getPivot(inst)
    if not inst then return nil end
    local ok, cf = pcall(function() return inst:GetPivot() end)
    if ok and cf then return cf end
    local r = getRoot(inst)
    return r and r.CFrame or nil
end

local function EnsureDataRefs()
    if not PlayerGui or not PlayerGui.Parent then PlayerGui = waitFor(Player, "PlayerGui", 5) end
    if not Data or not Data.Parent then Data = PlayerGui and waitFor(PlayerGui, "Data", 5) end
    if Data then
        if not InventoryData or not InventoryData.Parent then InventoryData = waitFor(Data, "Asset", 5) end
        if not OwnedPetData or not OwnedPetData.Parent then OwnedPetData = waitFor(Data, "Pets", 5) end
        if not OwnedEggData or not OwnedEggData.Parent then OwnedEggData = waitFor(Data, "Egg", 5) end
    end
end

--==============================================================
--                       GRID / TILES (ง่าย)
--==============================================================
local PlotIndex = { Land = {}, Water = {}, Any = {} }
do
    if Island then
        for _, p in ipairs(Island:GetDescendants()) do
            if p:IsA("BasePart") and (p.Name:match("^Farm_split_") or p.Name:match("^WaterFarm_split_")) then
                local area = p.Name:match("^Water") and "Water" or "Land"
                table.insert(PlotIndex[area], p)
                table.insert(PlotIndex.Any, p)
            end
        end
        table.sort(PlotIndex.Land,  function(a,b) return a.Position.Z < b.Position.Z end)
        table.sort(PlotIndex.Water, function(a,b) return a.Position.Z < b.Position.Z end)
        table.sort(PlotIndex.Any,   function(a,b) return a.Position.Z < b.Position.Z end)
    end
end

local function centerOf(part)
    return part.Position + Vector3.new(0, part.Size.Y * 0.5, 0)
end

local function occupiedKeys()
    local occ = {}
    EnsureDataRefs()
    -- จากไข่ที่วาง
    if OwnedEggData then
        for _, egg in ipairs(OwnedEggData:GetChildren()) do
            local di = egg:FindFirstChild("DI")
            if di then
                local x, z = di:GetAttribute("X"), di:GetAttribute("Z")
                if tonumber(x) and tonumber(z) then
                    occ[("%d,%d"):format(math.floor(x + 0.5), math.floor(z + 0.5))] = true
                end
            end
        end
    end
    -- จากสัตว์ที่วาง
    if PetFolder then
        for _, m in ipairs(PetFolder:GetChildren()) do
            if m:GetAttribute("UserId") == USERID then
                local cf = getPivot(m)
                if cf then
                    local p = cf.Position
                    occ[("%d,%d"):format(math.floor(p.X + 0.5), math.floor(p.Z + 0.5))] = true
                end
            end
        end
    end
    return occ
end

local function freeTiles(area)
    local list = (area == "Land" or area == "Water") and PlotIndex[area] or PlotIndex.Any
    local occ = occupiedKeys()
    local out = {}
    for _, part in ipairs(list) do
        local key = ("%d,%d"):format(math.floor(part.Position.X + 0.5), math.floor(part.Position.Z + 0.5))
        if not occ[key] then
            table.insert(out, part)
        end
    end
    return out
end

--==============================================================
--                       TASK MANAGER
--==============================================================
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
        local tok = reg[name]
        if tok then tok.alive = false; reg[name] = nil; log("Task stop: %s", name) end
    end
    function TaskMgr.stopAll()
        for k, tok in pairs(reg) do tok.alive = false; reg[k] = nil end
        log("Task stopAll")
    end
    function TaskMgr.isRunning(name) return reg[name] ~= nil end
end

local function waitAlive(tok, sec)
    local t = tonumber(sec) or 0
    if t <= 0 then task.wait(); return tok.alive end
    local until_ = os.clock() + t
    while tok.alive and os.clock() < until_ do task.wait() end
    return tok.alive
end

--==============================================================
--                       TASKS (CORE)
--==============================================================

-- 1) Auto Collect (เก็บเงินจากสัตว์ที่วาง)
local function task_AutoCollect(tok)
    while tok.alive do
        if PetFolder then
            for _, m in ipairs(PetFolder:GetChildren()) do
                if not tok.alive then break end
                if m:GetAttribute("UserId") == USERID then
                    local re = m:FindFirstChild("RE", true)
                    if re then pcall(function() re:FireServer("Claim") end) end
                end
            end
        end
        if not waitAlive(tok, Configuration.Main.Collect_Delay or 3) then break end
    end
end

-- 2) Auto Upgrade Conveyor
local function nextConveyorIndex()
    local env = Island and Island:FindFirstChild("ENV")
    local conv = env and env:FindFirstChild("Conveyor")
    if not conv then return 1 end
    local maxIdx = 0
    for _, c in ipairs(conv:GetChildren()) do
        local num = tonumber(string.match(c.Name or "", "(%d+)$"))
        if num and num > maxIdx then maxIdx = num end
    end
    return maxIdx + 1
end
local function task_AutoUpgrade(tok)
    while tok.alive do
        local idx = nextConveyorIndex()
        local conf = ConveyorDB and ConveyorDB["Conveyor"..tostring(idx)]
        local cost = (conf and tonumber(conf.Cost)) or 9e18
        if getCash() >= cost then
            if ConveyorRE then pcall(function() ConveyorRE:FireServer("Upgrade", idx) end) end
            task.wait(2)
        else
            if not waitAlive(tok, 2) then break end
        end
    end
end

-- 3) Auto Unlock Tiles
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

-- 4) Auto Buy Food
local function task_AutoBuyFood(tok)
    while tok.alive do
        if FoodStoreLST and FoodStoreRE then
            for foodName, n in pairs(FoodStoreLST:GetAttributes()) do
                if not tok.alive then break end
                if (tonumber(n) or 0) > 0 and (Configuration.Shop.Food.Foods[foodName] == true) then
                    pcall(function() FoodStoreRE:FireServer(foodName) end)
                    task.wait(0.12)
                end
            end
        end
        if not waitAlive(tok, Configuration.Shop.Food.AutoBuy_Delay or 10) then break end
    end
end

-- 5) Auto Feed (แบบเบา: เลือกผลไม้ที่อนุญาตตัวแรกที่มี)
local function firstAllowedFruit()
    local inv = InventoryData and InventoryData:GetAttributes() or {}
    -- ถ้ากำหนด Foods ไว้ ให้หยิบตามลิสต์นั้นก่อน
    local lst = {}
    for k, v in pairs(Configuration.Shop.Food.Foods) do if v then table.insert(lst, k) end end
    table.sort(lst)
    for _, name in ipairs(lst) do
        if (tonumber(inv[name] or 0) or 0) > 0 then return name end
    end
    -- fallback: หยิบอะไรก็ได้ที่เหลือ
    for name, cnt in pairs(inv) do
        if (tonumber(cnt) or 0) > 0 and tostring(name):match("Fruit") then
            return name
        end
    end
    return nil
end

local function task_AutoFeed(tok)
    while tok.alive do
        if not (PetFolder and PetRE and CharacterRE) then
            if not waitAlive(tok, 2) then break end
        else
            local fruit = firstAllowedFruit()
            if fruit then
                for _, m in ipairs(PetFolder:GetChildren()) do
                    if not tok.alive then break end
                    if m:GetAttribute("UserId") == USERID then
                        -- ให้อาหารเฉพาะ Big Pet (มี GUI BigPetGUI)
                        local root = getRoot(m)
                        local hasBig = false
                        if root then
                            local gui = root:FindFirstChild("GUI", true)
                            hasBig = gui and (gui:FindFirstChild("BigPetGUI", true) ~= nil)
                        end
                        if hasBig then
                            -- เช็คคูลดาวน์จาก Data/Pets/<UID>/Feed (ถ้าไม่มี ให้ลองเลี้ยง)
                            local uid = m.Name
                            local okToFeed = true
                            local node = OwnedPetData and OwnedPetData:FindFirstChild(uid)
                            if node and node:GetAttribute("Feed") then okToFeed = false end

                            if okToFeed then
                                pcall(function()
                                    CharacterRE:FireServer("Focus", fruit)
                                    task.wait(0.3)
                                    PetRE:FireServer("Feed", uid)
                                    task.wait(0.3)
                                    CharacterRE:FireServer("Focus")
                                end)
                            end
                        end
                    end
                end
            end
            if not waitAlive(tok, 10) then break end
        end
    end
end

-- 6) Auto Buy Egg (จากสายพาน เกณฑ์เบื้องต้น: ผ่านฟิลเตอร์ Types/Mutations)
local function task_AutoBuyEgg(tok)
    while tok.alive do
        if EggBeltFolder and CharacterRE then
            for _, egg in ipairs(EggBeltFolder:GetChildren()) do
                if not tok.alive then break end
                local uid = egg.Name
                local t   = egg:GetAttribute("T") or "BasicEgg"
                local m   = egg:GetAttribute("M") or "None"

                local typeOK = (next(Configuration.Egg.Filters.Types) == nil) or (Configuration.Egg.Filters.Types[t] == true)
                local mutOK  = (next(Configuration.Egg.Filters.Mutations) == nil) or (Configuration.Egg.Filters.Mutations[m] == true)
                local moneyOK= (not Configuration.Egg.CheckMinCoin) or (getCash() >= (Configuration.Egg.MinCoin or 0))

                if typeOK and mutOK and moneyOK then
                    pcall(function() CharacterRE:FireServer("BuyEgg", uid) end)
                    task.wait(0.15)
                end
            end
        end
        if not waitAlive(tok, Configuration.Egg.AutoBuyEgg_Delay or 3) then break end
    end
end

-- Helper: area จากประเภทไข่ (ใช้ ResEggDB.Category == "Ocean" -> Water)
local function eggAreaOfType(typeName)
    local d = ResEggDB[typeName]
    if d and tostring(d.Category) == "Ocean" then return "Water" end
    return "Land"
end

-- 7) Auto Place Egg
local function waitPlacedEgg(uid, timeout)
    local t0 = os.clock() + (timeout or 6)
    while os.clock() < t0 do
        if Blocks and Blocks:FindFirstChild(uid) then return true end
        EnsureDataRefs()
        local node = OwnedEggData and OwnedEggData:FindFirstChild(uid)
        if node and node:FindFirstChild("DI") then return true end
        task.wait(0.1)
    end
    return false
end
local function task_AutoPlaceEgg(tok)
    while tok.alive do
        EnsureDataRefs()
        if not OwnedEggData or not CharacterRE then
            if not waitAlive(tok, 2) then break end
        else
            -- รวบรวมไข่ที่ยังไม่วาง
            local list = {}
            for _, node in ipairs(OwnedEggData:GetChildren()) do
                if not node:FindFirstChild("DI") then table.insert(list, node) end
            end
            -- วนวาง
            for _, node in ipairs(list) do
                if not tok.alive then break end
                local uid = node.Name
                local t   = node:GetAttribute("T") or "BasicEgg"
                local m   = node:GetAttribute("M") or "None"

                -- ฟิลเตอร์
                local typeOK = (next(Configuration.Egg.Filters.Types) == nil) or (Configuration.Egg.Filters.Types[t] == true)
                local mutOK  = (next(Configuration.Egg.Filters.Mutations) == nil) or (Configuration.Egg.Filters.Mutations[m] == true)
                if not (typeOK and mutOK) then continue end

                -- เลือกพื้นที่
                local wantArea = Configuration.Egg.PlaceArea or "Any"
                if wantArea == "Any" then wantArea = eggAreaOfType(t) end
                local free = freeTiles(wantArea)
                if #free == 0 then break end

                local dstPart = table.remove(free, 1)
                local dst = centerOf(dstPart)

                pcall(function()
                    CharacterRE:FireServer("Focus", uid)
                    task.wait(0.2)
                    CharacterRE:FireServer("Place", { DST = dst, ID = uid })
                    task.wait(0.2)
                    CharacterRE:FireServer("Focus")
                end)

                waitPlacedEgg(uid, 6)
                if not waitAlive(tok, Configuration.Egg.AutoPlaceEgg_Delay or 1.0) then break end
            end
            if not waitAlive(tok, 1.0) then break end
        end
    end
end

-- 8) Auto Hatch
local function task_AutoHatch(tok)
    while tok.alive do
        EnsureDataRefs()
        if not OwnedEggData then if not waitAlive(tok, 2) then break end else
            for _, node in ipairs(OwnedEggData:GetChildren()) do
                if not tok.alive then break end
                local di = node:FindFirstChild("DI")
                if di and node:GetAttribute("D") and ServerTime and (ServerTime.Value >= node:GetAttribute("D")) then
                    -- ตรวจ area (ถ้ากำหนด)
                    local areaWant = Configuration.Egg.HatchArea or "Any"
                    if areaWant ~= "Any" then
                        local x, z = di:GetAttribute("X"), di:GetAttribute("Z")
                        local area = "Land"
                        -- ถ้ากระเบื้องที่มีน้ำ: - ใช้วิธีง่าย ๆ: ดูจากชื่อฟาร์มไม่ได้ ต้องอนุมาน -> ข้าม check รายละเอียด เพื่อความเสถียร
                        -- (เวอร์ชันเบา: ไม่กรอง area ตอน hatch)
                    end
                    local mdl = Blocks and Blocks:FindFirstChild(node.Name)
                    local rp  = mdl and getRoot(mdl)
                    local rf  = rp and rp:FindFirstChild("RF")
                    if rf and rf.InvokeServer then pcall(function() rf:InvokeServer("Hatch") end) end
                end
            end
            if not waitAlive(tok, Configuration.Egg.Hatch_Delay or 15) then break end
        end
    end
end

-- 9) Auto Sell (ปลอดภัย: จะ “ไม่ขายอะไรเลย” หากไม่ตั้งฟิลเตอร์)
local function SellEgg(uid)
    if not PetRE or not CharacterRE then return end
    pcall(function()
        CharacterRE:FireServer("Focus", uid)
        task.wait(0.1)
        PetRE:FireServer("Sell", uid, true)
        task.wait(0.1)
        CharacterRE:FireServer("Focus")
    end)
end
local function SellPet(uid)
    if not PetRE or not CharacterRE then return end
    pcall(function()
        CharacterRE:FireServer("Focus", uid)
        task.wait(0.1)
        PetRE:FireServer("Sell", uid)
        task.wait(0.1)
        CharacterRE:FireServer("Focus")
    end)
end

local function task_AutoSell(tok)
    while tok.alive do
        EnsureDataRefs()
        local did = false

        -- Egg filters
        if Configuration.Sell and OwnedEggData then
            for _, node in ipairs(OwnedEggData:GetChildren()) do
                if not tok.alive then break end
                if not node:FindFirstChild("DI") then
                    local t = node:GetAttribute("T") or "BasicEgg"
                    local m = node:GetAttribute("M") or "None"
                    local typeOK = (next(Configuration.Sell.Egg_Types) ~= nil) and (Configuration.Sell.Egg_Types[t] == true)
                    local mutOK  = (next(Configuration.Sell.Egg_Mutations) == nil and m == "None")
                                   or (next(Configuration.Sell.Egg_Mutations) ~= nil and Configuration.Sell.Egg_Mutations[m] == true)
                    if typeOK and mutOK then
                        SellEgg(node.Name)
                        did = true
                        task.wait(0.2)
                    end
                end
            end
        end

        -- Pet threshold (เฉพาะที่ “ยังไม่ได้วาง” เท่านั้น)
        if Configuration.Sell and OwnedPetData and Configuration.Sell.Pet_Income_Threshold and Configuration.Sell.Pet_Income_Threshold > 0 then
            for _, node in ipairs(OwnedPetData:GetChildren()) do
                if not tok.alive then break end
                if not PetFolder:FindFirstChild(node.Name) then
                    -- เวอร์ชันเบา: ไม่มี income index -> ข้ามฟีเจอร์ขายสัตว์ (ปลอดภัยกว่า)
                    -- (คุณสามารถเพิ่มตัวอ่าน income เฉพาะเกมของคุณมาผูกที่นี่ได้เอง)
                end
            end
        end

        if not did and not waitAlive(tok, 3.0) then break end
    end
end

-- 10) Auto Claim (Event Tasks)
local function locateEventRE()
    for _, v in ipairs(ReplicatedStorage:GetChildren()) do
        local name = tostring(v)
        local base = name:match("^(.*)Event$")
        if base then
            local re = GameRemoteEvents:FindFirstChild(base .. "RE")
            if re then return re end
        end
    end
    return nil
end

local function task_AutoClaim(tok)
    local EventRE = locateEventRE()
    local EventTaskData
    if Data then
        for _, f in ipairs(Data:GetChildren()) do
            if tostring(f):match("EventTaskData$") then EventTaskData = f; break end
        end
    end
    while tok.alive do
        if EventRE and EventTaskData then
            local Tasks = EventTaskData:FindFirstChild("Tasks")
            if Tasks then
                for _, q in ipairs(Tasks:GetChildren()) do
                    if not tok.alive then break end
                    pcall(function()
                        EventRE:FireServer({ event = "claimreward", id = q:GetAttribute("Id") })
                    end)
                    task.wait(0.5)
                end
            end
        end
        if not waitAlive(tok, Configuration.Event.AutoClaim_Delay or 3.0) then break end
    end
end

-- 11) Auto Lottery (ออฟไว้เป็นดีฟอลต์)
local function task_AutoLottery(tok)
    while tok.alive do
        if InventoryData and LotteryRE then
            local n = tonumber(InventoryData:GetAttribute("LotteryTicket")) or 0
            if n > 0 then pcall(function() LotteryRE:FireServer({event="lottery", count=1}) end) end
        end
        if not waitAlive(tok, 60) then break end
    end
end

-- 12) Auto Fishing (เวอร์ชันเบา)
local fishingState = { didFocus=false, lockedPos=nil }
local function defaultFishPos()
    local ch = Player.Character
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

-- 13) Anti AFK
local function task_AntiAFK(tok)
    while tok.alive do
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        if not waitAlive(tok, 30) then break end
    end
end

--==============================================================
--                      AUTOSTART (ตาม FLAGS)
--==============================================================
local function autostart()
    ApplyPerf()

    local function StartIf(flag, name, fn)
        if flag then TaskMgr.start(name, fn) else TaskMgr.stop(name) end
    end

    StartIf(Configuration.AntiAFK,                   "AntiAFK",            task_AntiAFK)
    StartIf(Configuration.Main.AutoCollect,          "AutoCollect",        task_AutoCollect)
    StartIf(Configuration.Main.AutoUpgradeConveyor,  "AutoUpgrade",        task_AutoUpgrade)
    StartIf(Configuration.Main.AutoUnlockTiles,      "AutoUnlockTiles",    task_AutoUnlock)
    StartIf(Configuration.Shop.Food.AutoBuy,         "AutoBuyFood",        task_AutoBuyFood)
    StartIf(Configuration.Pet.AutoFeed,              "AutoFeed",           task_AutoFeed)
    StartIf(Configuration.Egg.AutoBuyEgg,            "AutoBuyEgg",         task_AutoBuyEgg)
    StartIf(Configuration.Egg.AutoPlaceEgg,          "AutoPlaceEgg",       task_AutoPlaceEgg)
    StartIf(Configuration.Egg.AutoHatch,             "AutoHatch",          task_AutoHatch)
    StartIf(Configuration.Event.AutoClaim,           "AutoClaim",          task_AutoClaim)
    StartIf(Configuration.Event.AutoLottery,         "AutoLottery",        task_AutoLottery)
    StartIf(Configuration.Fishing.Auto,              "AutoFishing",        task_AutoFishing)
    StartIf(Configuration.Sell.Enabled,              "AutoSell",           task_AutoSell)
end

--==============================================================
--                      CONTROLLER (Destroy)
--==============================================================
local Controller = {}
function Controller:Destroy()
    TaskMgr.stopAll()
    -- คืนค่าประสิทธิภาพ
    pcall(function()
        if _setfps then _setfps(1000) end
        Perf_Set3DEnabled(true)
        if _uiHidden then ApplyHideGameUI(false) end
    end)
    -- Failsafe: unanchor
    pcall(function()
        local ch = Player.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = false end
    end)
    log("Destroyed previous headless instance.")
end
getgenv().MeowyHeadless = Controller

--==============================================================
--                      BOOT
--==============================================================
log("Loaded headless script. Game: %s", (MarketplaceService:GetProductInfo(game.PlaceId).Name or ""))
task.defer(autostart)
