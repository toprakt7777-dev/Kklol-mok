-- [[ Rscripts Risk Notice ]]
-- This script is not verified by rscripts.net. Deal with caution.
--
-- Stay safe:
--   • Never log in on unofficial Roblox sites or lookalike domains.
--   • Real Roblox links use roblox.com (check the .com ending).
--   • Treat fake Roblox login / "claim reward" pages as phishing.
-- [[ End Rscripts Risk Notice ]]

-- ⚠️ PUT THIS AT THE VERY TOP OF YOUR SCRIPT (LINE 1) BEFORE ANYTHING ELSE! ⚠️

if not game:IsLoaded() then game.Loaded:Wait() end

-- // SCRIPT SOURCE CONFIGURATION FOR QUEUE ON TELEPORT
_G.BloxHubScriptUrl = _G.BloxHubScriptUrl or "https://raw.githubusercontent.com/huyyeuemhihi/Fluent/refs/heads/main/Fluentvip.lua"

-- // PREVIOUS SCRIPT CLEANUP
if _G.BloxHubCleanup then
    pcall(_G.BloxHubCleanup)
end

local Connections = {}
local function AddConnection(conn)
    if conn then table.insert(Connections, conn) end
    return conn
end

-- // Global Cleanup Registration
_G.BloxHubCleanup = function()
    for _, conn in ipairs(Connections) do
        if conn and conn.Connected then
            pcall(function() conn:Disconnect() end)
        end
    end
    table.clear(Connections)
end

-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local StatsService = game:GetService("Stats")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- // Core References
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Camera = Workspace.CurrentCamera or Workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
local ServerJoinTime = os.clock()

-- // Global Settings & Config System
local DefaultSettings = {
    PVPMode = false,
    FastAttack = true,
    SpamSoulGuitar = false,
    AutoClick = false,
    AutoEquip = true,
    EquipWeaponType = "Buddy Sword",
    BringMobs = true,
    SafeMode = false,
    WalkOnWater = false,
    Noclip = true,
    AutoRaceV4 = false,
    
    AutoFarmLevel = false,
    AutoFarmBoss = false,
    SelectedBoss = "",
    AutoFarmMaterial = false,
    SelectedMaterial = "",
    
    FarmMastery = false,
    MasteryWeaponType = "Blox Fruit",
    MasteryHPThreshold = 25,
    
    AutoRaid = false,
    SelectedChip = "Flame",
    AutoBuyChip = false,
    
    AutoBuyRandomFruit = false,
    AutoCollectFruits = false,
    AutoStoreFruits = false,
    
    AutoSeaEvents = false,
    AutoFactory = false,
    AutoPirateRaid = false,
    
    AimbotSkills = true,
    XMove100Hit = true,
    TargetPrediction = true,
    AimbotCamera = true,
    InstantLock = true,
    AimMethod = "Closest to LocalPlayer",
    TargetSelect = "",
    CameraSmoothness = 0.15,
    
    HitboxExpand = true,
    HitboxSize = 35,
    
    Crosshair = false,
    CrosshairStyle = "Plus (+)",
    ShowFOV = false,
    FOVRadius = 180,
    
    Spectate = false,
    
    AutoStats = false,
    StatType = "Melee",
    StatPoints = 1,
    
    SelectedIslandTeleport = "",
    TweenSpeed = 350,
    EscapeHeight = 500,
    PlayerESP = true,
    
    -- Bounty Hunt & Persistence Settings
    BountyHunt = false,
    AutoPortalTP = true,
    PortalDistanceThreshold = 1500,
    AutoServerHopWhenEmpty = true,
    AvoidSafeZonePlayers = true,
    MaxTargetDistance = 10000,
    SavedTeam = "Pirates",
    AutoLoadConfig = true,
    ServerHopRegion = "Singapore",
    ServerHopMaxPlayers = 10,

    -- 30M SERVER BOUNTY FILTER SETTINGS
    FilterMinServerBounty = true,
    MinServerBounty = 30000000
}

local Settings = {}
for k, v in pairs(DefaultSettings) do Settings[k] = v end

local ConfigFileName = "BloxHub_Config_V3.json"

local function SaveConfig()
    pcall(function()
        if writefile then
            writefile(ConfigFileName, HttpService:JSONEncode(Settings))
        end
    end)
end

local function LoadConfig()
    pcall(function()
        if isfile and isfile(ConfigFileName) then
            local decoded = HttpService:JSONDecode(readfile(ConfigFileName))
            if type(decoded) == "table" then
                for k, v in pairs(decoded) do
                    if Settings[k] ~= nil then
                        Settings[k] = v
                    end
                end
            end
        end
    end)
end

LoadConfig()

local IsServerHopping = false

-- // TOTAL SERVER BOUNTY CALCULATOR
local function GetTotalServerBounty()
    if IsServerHopping then return 0 end
    local totalBounty = 0
    pcall(function()
        for _, p in ipairs(Players:GetPlayers()) do
            local bountyVal = 0
            local leaderstats = p:FindFirstChild("leaderstats")
            if leaderstats then
                local b = leaderstats:FindFirstChild("Bounty / Honor") or leaderstats:FindFirstChild("Bounty") or leaderstats:FindFirstChild("Honor")
                if b and b:IsA("ValueBase") then
                    bountyVal = tonumber(b.Value) or 0
                end
            end
            if bountyVal == 0 then
                local data = p:FindFirstChild("Data")
                if data then
                    local b = data:FindFirstChild("Bounty") or data:FindFirstChild("Honor")
                    if b and b:IsA("ValueBase") then
                        bountyVal = tonumber(b.Value) or 0
                    end
                end
            end
            totalBounty = totalBounty + bountyVal
        end
    end)
    return totalBounty
end

-- // BLACK SCREEN & OVERLAY REMOVER
local function ClearLoadingOverlays()
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local chooseTeam = playerGui:FindFirstChild("ChooseTeam")
            if chooseTeam then chooseTeam:Destroy() end

            local loadingGui = playerGui:FindFirstChild("LoadingGui")
            if loadingGui then loadingGui:Destroy() end

            local blackFade = playerGui:FindFirstChild("Fade") or playerGui:FindFirstChild("BlackScreen")
            if blackFade then blackFade:Destroy() end
        end
        if Workspace.CurrentCamera then
            Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        end
    end)
end

ClearLoadingOverlays()

-- // TEAM ASSIGNMENT SYSTEM
local function JoinTeam(teamName)
    if IsServerHopping then return end
    teamName = teamName or Settings.SavedTeam or "Pirates"
    pcall(function()
        ClearLoadingOverlays()
        local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 5)
        local CommF_ = RemotesFolder and RemotesFolder:FindFirstChild("CommF_")
        if CommF_ then
            CommF_:InvokeServer("SetTeam2", teamName)
        end
    end)
end

task.spawn(function()
    task.wait(0.2)
    JoinTeam(Settings.SavedTeam)
end)

task.spawn(function()
    while task.wait(1) do
        if IsServerHopping then break end
        pcall(function()
            ClearLoadingOverlays()
            if LocalPlayer.Team == nil or LocalPlayer.Team.Name == "Neutral" or not LocalPlayer.Character then
                JoinTeam(Settings.SavedTeam)
            end
        end)
    end
end)

-- // SMOOTH MOVEMENT CONTROLLER & TWEEN STOPPER
local ActiveTween = nil
local LastTweenTarget = nil
local TweenBodyVel = nil

local function StopTween()
    if ActiveTween then
        pcall(function() ActiveTween:Cancel() end)
        ActiveTween = nil
    end
    if TweenBodyVel then
        pcall(function() TweenBodyVel:Destroy() end)
        TweenBodyVel = nil
    end
    LastTweenTarget = nil
end

-- // SAFE TELEPORT TEARDOWN & RE-EXECUTION QUEUE
local function QueueScriptOnTeleport()
    pcall(function()
        local queueFunc = queue_on_teleport 
            or (syn and syn.queue_on_teleport) 
            or (fluxus and fluxus.queue_on_teleport)
            or (getgenv and getgenv().queue_on_teleport)

        if queueFunc and type(queueFunc) == "function" then
            local scriptUrl = _G.BloxHubScriptUrl or "https://raw.githubusercontent.com/huyyeuemhihi/Fluent/refs/heads/main/Fluentvip.lua"
            queueFunc(string.format([[
                repeat task.wait() until game:IsLoaded()
                task.wait(1)
                pcall(function()
                    loadstring(game:HttpGet("%s"))()
                end)
            ]], scriptUrl))
        end
    end)
end

-- 1. Prime the queue immediately on script load
task.spawn(QueueScriptOnTeleport)

-- 2. Hook into Roblox's global OnTeleport event so ANY server movement auto-queues the script
AddConnection(LocalPlayer.OnTeleport:Connect(function()
    QueueScriptOnTeleport()
end))

local function PrepareForTeleport()
    IsServerHopping = true
    pcall(StopTween)
    pcall(SaveConfig)
    QueueScriptOnTeleport()
    
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                for _, obj in ipairs(part:GetChildren()) do
                    if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") or obj:IsA("BodyPosition") then
                        pcall(function() obj:Destroy() end)
                    end
                end
            end
        end
    end
end


-- // OPTIMIZED FAST BLOX FRUITS SERVER BROWSER HOPPER
local function ServerHop(maxPlayers, region)
    if IsServerHopping then return end
    PrepareForTeleport()

    maxPlayers = maxPlayers or Settings.ServerHopMaxPlayers or 10
    region = region or Settings.ServerHopRegion or "Singapore"

    task.spawn(function()
        ClearLoadingOverlays()

        local serverBrowserRemote = ReplicatedStorage:FindFirstChild("__ServerBrowser")
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)

        if serverBrowserRemote then
            for page = 1, 100 do
                if not IsServerHopping then break end

                pcall(function()
                    if playerGui and playerGui:FindFirstChild("ServerBrowser") and playerGui.ServerBrowser:FindFirstChild("Frame") then
                        playerGui.ServerBrowser.Frame.Filters.SearchRegion.TextBox.Text = region
                    end
                end)

                local success, response = pcall(function()
                    return serverBrowserRemote:InvokeServer(page)
                end)

                if success and type(response) == "table" then
                    for jobId, info in pairs(response) do
                        if jobId ~= game.JobId and type(info) == "table" then
                            local count = tonumber(info.Count) or 0
                            local isPrivate = string.find(tostring(info.Private), "true") ~= nil

                            if count > 0 and count < 12 and count <= maxPlayers and not isPrivate then
                                local teleported = pcall(function()
                                    serverBrowserRemote:InvokeServer("teleport", jobId)
                                end)

                                if teleported then
                                    task.wait(8)
                                    return
                                end
                            end
                        end
                    end
                end
                task.wait(0.2)
            end
        end

        local placeId = game.PlaceId
        local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        local candidateServers = {}

        local apiEndpoints = {
            string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100", placeId),
            string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", placeId)
        }

        for _, url in ipairs(apiEndpoints) do
            local rawResult = nil
            pcall(function()
                if req then
                    local res = req({ Url = url, Method = "GET" })
                    rawResult = res and res.Body
                else
                    rawResult = game:HttpGet(url)
                end
            end)

            if rawResult and type(rawResult) == "string" then
                local decodeOk, data = pcall(function() return HttpService:JSONDecode(rawResult) end)
                if decodeOk and data and data.data then
                    for _, server in ipairs(data.data) do
                        if type(server) == "table" and server.id ~= game.JobId then
                            local playing = tonumber(server.playing) or 0
                            local maxCap = tonumber(server.maxPlayers) or 12
                            
                            if playing > 0 and playing < maxCap and playing <= maxPlayers then
                                table.insert(candidateServers, server.id)
                            end
                        end
                    end
                end
            end
            if #candidateServers >= 5 then break end
            task.wait(0.3)
        end

        if #candidateServers > 0 then
            local targetJobId = candidateServers[math.random(1, #candidateServers)]
            pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, targetJobId, LocalPlayer)
            end)
            task.wait(6)
        else
            pcall(function()
                TeleportService:Teleport(placeId, LocalPlayer)
            end)
            task.wait(6)
        end

        task.wait(3)
        IsServerHopping = false
    end)
end

AddConnection(TeleportService.TeleportInitFailed:Connect(function()
    IsServerHopping = false
    ClearLoadingOverlays()
end))

local CharacterData = {
    Character = nil,
    Humanoid = nil,
    RootPart = nil
}

local LocalPlayerDeathCount = 0

local function TrackLocalPlayerDeath(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then
        AddConnection(hum.Died:Connect(function()
            LocalPlayerDeathCount = LocalPlayerDeathCount + 1
            if LocalPlayerDeathCount >= 3 then
                task.spawn(function()
                    if not IsServerHopping then
                        pcall(function()
                            if UIControls and UIControls.HuntStatusParagraph then
                                UIControls.HuntStatusParagraph:SetDesc("Died 3 times! Initiating Server Hop...")
                            end
                        end)
                        ServerHop()
                    end
                end)
            end
        end))
    end
end

local function UpdateCharacterReferences()
    local char = Workspace:FindFirstChild("Characters") and Workspace.Characters:FindFirstChild(LocalPlayer.Name) or LocalPlayer.Character
    if char then
        CharacterData.Character = char
        CharacterData.Humanoid = char:FindFirstChildOfClass("Humanoid")
        CharacterData.RootPart = char:FindFirstChild("HumanoidRootPart")
    else
        CharacterData.Character = nil
        CharacterData.Humanoid = nil
        CharacterData.RootPart = nil
    end
end

AddConnection(LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    UpdateCharacterReferences()
    ClearLoadingOverlays()
    JoinTeam(Settings.SavedTeam)
    TrackLocalPlayerDeath(char)
end))
UpdateCharacterReferences()
if LocalPlayer.Character then
    TrackLocalPlayerDeath(LocalPlayer.Character)
end

local PORTAL_DESTINATIONS = {
    ["Haunted Ship"]  = Vector3.new(937, 125, 32879),
    ["Dark Arena"]    = Vector3.new(3948, 13, -3479),
    ["Cafe"]          = Vector3.new(-382, 74, 356),
    ["Mansion"]       = Vector3.new(-494, 339, 593),
    ["Winter Castle"] = Vector3.new(5544.71, 60.13, -6359.08),
    ["Lab"]           = Vector3.new(-5541, 230, -5898),
    ["Graveyard"]     = Vector3.new(-5710, 126, -775),
    ["Colosseum"]     = Vector3.new(-1836, 46, 1642),
    ["Snow"]          = Vector3.new(1210, 429, -4663),
    ["Raid"]          = Vector3.new(-6495, 95, -4897),
    ["Lava"]          = Vector3.new(-5208, 184, -5505),
    ["Doghouse"]      = Vector3.new(-1984, 125, -82),
    ["Skull"]         = Vector3.new(-2956.24, 123.39, -9981.06),
    ["Docks 1"]       = Vector3.new(-923, 8, 1810),
    ["Docks 2"]       = Vector3.new(-13, 39, 2708),
    ["Docks 3"]       = Vector3.new(-1944, 9, -2594),
    ["Docks 4"]       = Vector3.new(-5798, 1, -5021),
    ["Remote"]        = Vector3.new(4766, 8, 2911)
}

local SelectedPortalDestination = "Cafe"

local Modules = ReplicatedStorage:WaitForChild("Modules", 10)
local Net = Modules and Modules:WaitForChild("Net", 10)
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)

local CommF_ = RemotesFolder and RemotesFolder:FindFirstChild("CommF_")
local Register_Attack = Net and Net:FindFirstChild("RE/RegisterAttack")
local Register_Hit = Net and Net:FindFirstChild("RE/RegisterHit")
local ComboEvent = RemotesFolder and (RemotesFolder:FindFirstChild("Combo") or RemotesFolder:WaitForChild("Combo", 5))
local RequestGateway = RemotesFolder and RemotesFolder:FindFirstChild("RequestGateway")

if RequestGateway then
    RequestGateway.OnClientInvoke = function(options)
        return SelectedPortalDestination
    end
end

local function GetNetworkPing()
    local ping = 0.03
    pcall(function()
        local item = StatsService.Network.ServerStatsItem["Data Ping"]
        if item then
            ping = math.clamp(item:GetValue() / 1000, 0.01, 0.35)
        end
    end)
    return ping
end

local function GetLocalPlayerHealth()
    local char = CharacterData.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            return hum.Health, hum.MaxHealth
        end
    end
    return 0, 100
end

local function ApplyAntiStun()
    local char = CharacterData.Character
    if not char then return end
    local hum = CharacterData.Humanoid
    local root = CharacterData.RootPart
    
    if hum then
        hum.PlatformStand = false
        hum.Sit = false
    end
    
    if root then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
        for _, obj in ipairs(root:GetChildren()) do
            if (obj:IsA("BodyVelocity") and obj.Name ~= "TweenBV") or obj:IsA("BodyGyro") or obj:IsA("BodyPosition") then
                pcall(function() obj:Destroy() end)
            end
        end
    end
end

local PlaceId = game.PlaceId
local World1 = PlaceId == 2753915549 or PlaceId == 85211729168715
local World2 = PlaceId == 4442272183 or PlaceId == 79091703265657
local World3 = PlaceId == 7449423635 or PlaceId == 100117331123089

local HitValidator = {
    LastHitTime = 0,
    LastHitDamage = 0,
    TotalHitCount = 0
}

local TargetKillCounts = {}

if ComboEvent and ComboEvent:IsA("RemoteEvent") then
    AddConnection(ComboEvent.OnClientEvent:Connect(function(...)
        local args = {...}
        local damage = args[1]
        if typeof(damage) == "number" and damage > 0 then
            HitValidator.LastHitTime = os.clock()
            HitValidator.LastHitDamage = damage
            HitValidator.TotalHitCount = HitValidator.TotalHitCount + 1
        end
    end))
end

function HitValidator:WasHitRecently(thresholdSeconds)
    return (os.clock() - self.LastHitTime) <= (thresholdSeconds or 1.5)
end

function HitValidator:GetLastHitDamage()
    return self.LastHitDamage
end

local function TrackPlayerKills(p)
    if p == LocalPlayer then return end
    AddConnection(p.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid", 10)
        if hum then
            AddConnection(hum.Died:Connect(function()
                if HitValidator.LastHitTime > 0 and (os.clock() - HitValidator.LastHitTime) < 5 then
                    TargetKillCounts[p.UserId] = (TargetKillCounts[p.UserId] or 0) + 1
                end
            end))
        end
    end))
end

for _, p in ipairs(Players:GetPlayers()) do
    TrackPlayerKills(p)
end

AddConnection(Players.PlayerAdded:Connect(function(p)
    TrackPlayerKills(p)
end))

local IslandTeleports = {}
if World1 then
    IslandTeleports = {
        ["Starter Island"] = CFrame.new(979, 16, 1405),
        ["Jungle"] = CFrame.new(-1612, 36, 149),
        ["Pirate Village"] = CFrame.new(-1141, 4, 3831),
        ["Desert"] = CFrame.new(894, 6, 4390),
        ["Middle Town"] = CFrame.new(-690, 15, 1582),
        ["Frozen Village"] = CFrame.new(1285, 7, -1325),
        ["Marine Fortress"] = CFrame.new(-5035, 28, 4325),
        ["Skypiea"] = CFrame.new(-4832, 717, -2622),
        ["Prison"] = CFrame.new(4875, 5, 735),
        ["Colosseum"] = CFrame.new(-1428, 7, 301),
        ["Magma Village"] = CFrame.new(-5241, 8, 8404),
        ["Underwater City"] = CFrame.new(61163, 11, 1819),
        ["Fountain City"] = CFrame.new(5127, 59, 4105)
    }
elseif World2 then
    IslandTeleports = {
        ["Cafe / Rose Kingdom"] = CFrame.new(-382, 73, 297),
        ["Ushron / Factory"] = CFrame.new(432, 116, -428),
        ["Green Zone"] = CFrame.new(-2385, 73, -3022),
        ["Graveyard Island"] = CFrame.new(-5414, 48, -725),
        ["Snow Mountain"] = CFrame.new(609, 401, -5372),
        ["Cold Area"] = CFrame.new(-6026, 15, -4971),
        ["Hot Area"] = CFrame.new(-5488, 15, -5251),
        ["Cursed Ship"] = CFrame.new(923, 125, 32852),
        ["Ice Castle"] = CFrame.new(6148, 294, -6741),
        ["Forgotten Island"] = CFrame.new(-3032, 236, -10146)
    }
elseif World3 then
    IslandTeleports = {
        ["Port Town"] = CFrame.new(-290, 7, 5343),
        ["Hydra Island"] = CFrame.new(5228, 604, 345),
        ["Great Tree"] = CFrame.new(2280, 25, -6722),
        ["Floating Turtle"] = CFrame.new(-13274, 332, -7628),
        ["Castle on the Sea"] = CFrame.new(-5085, 314, -3150),
        ["Haunted Castle"] = CFrame.new(-9515, 142, 5520),
        ["Chocolate Land"] = CFrame.new(130, 24, -12110),
        ["Candy Island"] = CFrame.new(-2021, 38, -12028),
        ["Tiki Outpost"] = CFrame.new(-16106, 9, 452)
    }
end

local CurrentTargetPos = Vector3.zero
local CurrentTargetPart = nil
local CurrentTargetName = "None"

local HuntTargetPlayer = nil
local HuntTargetStartTime = 0
local IsInEscapeMode = false
local EscapeTargetPosition = nil
local LastPortalTPTime = 0
local IsPortalTeleporting = false
local SavedSettingsConfig = nil
local NoTargetStartTime = 0

local Fluent = nil
local Window = nil
local UIControls = {}
local isSyncingUI = false

local function DeepCopyTable(orig)
    local copy = {}
    for k, v in pairs(orig) do copy[k] = v end
    return copy
end

local function GetCenterScreen()
    if not Camera then return Vector2.new(800, 600) end
    return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

task.spawn(function()
    while task.wait(0.5) do
        if IsServerHopping then break end
        pcall(function()
            local char = CharacterData.Character
            if char and CommF_ then
                local busoActive = char:GetAttribute("BusoEnabled") 
                    or char:GetAttribute("HasBuso") 
                    or (char:FindFirstChild("BusoEnabled") and char.BusoEnabled.Value == true)
                    or char:FindFirstChild("HasBuso")
                
                if not busoActive then
                    CommF_:InvokeServer("Buso")
                end
            end
        end)
    end
end)

local function GetPredictedTargetPos(targetPart, projectileSpeed, gravity)
    if not targetPart or not targetPart.Parent then return Vector3.zero end
    local pos = targetPart.Position

    if Settings.TargetPrediction and CharacterData.RootPart then
        local velocity = targetPart.AssemblyLinearVelocity or targetPart.Velocity or Vector3.zero
        if velocity.Magnitude < 600 then
            local dist = (CharacterData.RootPart.Position - pos).Magnitude
            local speed = projectileSpeed or 2600
            local ping = GetNetworkPing()
            local timeToTarget = math.clamp((dist / speed) + ping, 0.008, 0.22)
            pos = pos + (velocity * timeToTarget)
            
            if gravity and gravity > 0 then
                pos = pos + Vector3.new(0, 0.5 * gravity * (timeToTarget ^ 2), 0)
            end
        end
    end

    return pos
end

pcall(function()
    local getrawmetatable = getrawmetatable or function() return getmetatable(game) end
    local setreadonly = setreadonly or make_writeable or function() end
    local mt = getrawmetatable(game)

    setreadonly(mt, false)

    local oldIndex = mt.__index
    local oldNamecall = mt.__namecall
    local isHooking = false

    mt.__index = newcclosure(function(self, index)
        if IsServerHopping then
            return oldIndex(self, index)
        end

        if not checkcaller() and not isHooking and (Settings.AimbotSkills or Settings.XMove100Hit or Settings.SpamSoulGuitar) then
            if self == LocalPlayer:GetMouse() then
                isHooking = true
                local idx = type(index) == "string" and string.lower(index) or ""
                if idx == "hit" or idx == "cframe" then
                    if CurrentTargetPart and CurrentTargetPart.Parent then
                        local predicted = GetPredictedTargetPos(CurrentTargetPart)
                        if predicted ~= Vector3.zero then
                            isHooking = false
                            return CFrame.new(predicted)
                        end
                    end
                elseif idx == "target" then
                    if CurrentTargetPart and CurrentTargetPart.Parent then
                        isHooking = false
                        return CurrentTargetPart
                    end
                elseif idx == "unitray" then
                    if CurrentTargetPart and CurrentTargetPart.Parent then
                        local predicted = GetPredictedTargetPos(CurrentTargetPart)
                        if predicted ~= Vector3.zero and Camera then
                            local dir = (predicted - Camera.CFrame.Position).Unit
                            isHooking = false
                            return Ray.new(Camera.CFrame.Position, dir)
                        end
                    end
                end
                isHooking = false
            end
        end
        return oldIndex(self, index)
    end)

    mt.__namecall = newcclosure(function(self, ...)
        if IsServerHopping then
            return oldNamecall(self, ...)
        end

        local method = getnamecallmethod and getnamecallmethod() or ""

        if not checkcaller() and not isHooking and (Settings.AimbotSkills or Settings.XMove100Hit or Settings.SpamSoulGuitar) then
            if method == "Raycast" or method == "raycast" then
                if CurrentTargetPart and CurrentTargetPart.Parent then
                    isHooking = true
                    local args = {...}
                    local origin = args[1]
                    local predicted = GetPredictedTargetPos(CurrentTargetPart)
                    if typeof(origin) == "Vector3" and predicted ~= Vector3.zero then
                        local dirLen = typeof(args[2]) == "Vector3" and args[2].Magnitude or 1000
                        args[2] = (predicted - origin).Unit * dirLen
                        isHooking = false
                        return oldNamecall(self, unpack(args))
                    end
                    isHooking = false
                end
            elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                if CurrentTargetPart and CurrentTargetPart.Parent then
                    isHooking = true
                    local args = {...}
                    local ray = args[1]
                    local predicted = GetPredictedTargetPos(CurrentTargetPart)
                    if typeof(ray) == "Ray" and predicted ~= Vector3.zero then
                        args[1] = Ray.new(ray.Origin, (predicted - ray.Origin).Unit * ray.Direction.Magnitude)
                        isHooking = false
                        return oldNamecall(self, unpack(args))
                    end
                    isHooking = false
                end
            elseif method == "FireServer" or method == "InvokeServer" then
                if CurrentTargetPart and CurrentTargetPart.Parent then
                    isHooking = true
                    local predicted = GetPredictedTargetPos(CurrentTargetPart)
                    if predicted ~= Vector3.zero then
                        local args = {...}
                        local modified = false

                        for i = 1, #args do
                            local arg = args[i]
                            if typeof(arg) == "Vector3" then
                                args[i] = predicted
                                modified = true
                            elseif typeof(arg) == "CFrame" then
                                args[i] = CFrame.new(predicted)
                                modified = true
                            end
                        end

                        if modified then
                            isHooking = false
                            return oldNamecall(self, unpack(args))
                        end
                    end
                    isHooking = false
                end
            end
        end

        return oldNamecall(self, ...)
    end)

    setreadonly(mt, true)
end)

local function IsPlayerInSafeZone(player)
    if not player then return true end
    
    if player:GetAttribute("InSafeZone") == true or player:GetAttribute("SafeZone") == true then 
        return true 
    end
    
    local char = player.Character
    if char then
        if char:GetAttribute("InSafeZone") == true 
            or char:GetAttribute("SafeZone") == true 
            or char:FindFirstChild("SafeZone") 
            or char:FindFirstChild("InSafeZone") 
            or char:FindFirstChildOfClass("ForceField") then
            return true 
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local safeZonesFolder = Workspace:FindFirstChild("SafeZones") or (Workspace:FindFirstChild("_WorldOrigin") and Workspace._WorldOrigin:FindFirstChild("SafeZones"))
            if safeZonesFolder then
                for _, zone in ipairs(safeZonesFolder:GetChildren()) do
                    if zone:IsA("BasePart") then
                        local halfSize = zone.Size / 2
                        local localPos = zone.CFrame:PointToObjectSpace(hrp.Position)
                        if math.abs(localPos.X) <= halfSize.X and math.abs(localPos.Y) <= halfSize.Y and math.abs(localPos.Z) <= halfSize.Z then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

local function IsPlayerPvPDisabled(player)
    if not player then return true end
    
    if player:GetAttribute("PvpDisabled") == true or player:GetAttribute("PVPDisabled") == true then 
        return true 
    end
    
    local data = player:FindFirstChild("Data")
    if data then
        local pvpVal = data:FindFirstChild("PvpDisabled") or data:FindFirstChild("PVPDisabled")
        if pvpVal and pvpVal:IsA("ValueBase") and pvpVal.Value == true then 
            return true 
        end
    end
    
    local char = player.Character
    if char then
        if char:FindFirstChildOfClass("ForceField") then 
            return true 
        end
        
        local pvpVal = char:FindFirstChild("PvpDisabled") or char:FindFirstChild("PVPDisabled")
        if pvpVal and pvpVal:IsA("ValueBase") and pvpVal.Value == true then 
            return true 
        end
        
        if char:GetAttribute("PvpDisabled") == true or char:GetAttribute("PVPDisabled") == true then 
            return true 
        end
    end
    return false
end

local function GetPlayerLevel(player)
    player = player or LocalPlayer
    if not player then return 1 end

    local data = player:FindFirstChild("Data")
    if data then
        local levelVal = data:FindFirstChild("Level")
        if levelVal and levelVal:IsA("ValueBase") then
            return tonumber(levelVal.Value) or 1
        end
    end

    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local levelVal = leaderstats:FindFirstChild("Level") or leaderstats:FindFirstChild("Lvl")
        if levelVal and levelVal:IsA("ValueBase") then
            return tonumber(levelVal.Value) or 1
        end
    end

    return 1
end

local function GetPlayerTeam(player)
    if not player or not player.Team then return "Neutral" end
    return tostring(player.Team.Name)
end

local function EquipToolByName(toolName)
    local char = CharacterData.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not char then return nil end

    local function MatchesTool(tool)
        if not tool or not tool:IsA("Tool") then return false end
        local name = string.lower(tool.Name)
        local query = string.lower(toolName)
        if name == query or string.find(name, query) then return true end
        if (query == "soul guitar" or query == "skull guitar") and (name == "soul guitar" or name == "skull guitar") then
            return true
        end
        if query == "portal" and (string.find(name, "portal") or string.find(name, "door")) then
            return true
        end
        return false
    end

    for _, tool in ipairs(char:GetChildren()) do
        if MatchesTool(tool) then return tool end
    end

    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if MatchesTool(tool) then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:EquipTool(tool)
                    task.wait()
                    return char:FindFirstChild(tool.Name) or tool
                end
            end
        end
    end
    return nil
end

local function EquipToolByToolTip(toolType)
    if toolType == "Buddy Sword" or toolType == "Melee" then
        EquipToolByName("Buddy Sword")
        return
    end

    local char = CharacterData.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not char or not backpack then return end

    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and (tool.ToolTip == toolType or tool.Name == toolType) then return end
    end

    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and (tool.ToolTip == toolType or tool.Name == toolType) then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:EquipTool(tool) end
            break
        end
    end
end

local function SendKeyPress(keyCode)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.01)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
end

local function SafeTweenTo(targetCFrame, speed)
    if IsServerHopping then
        StopTween()
        return
    end

    local root = CharacterData.RootPart
    local char = CharacterData.Character
    if not root or not char then return end

    speed = speed or Settings.TweenSpeed or 350
    local distance = (root.Position - targetCFrame.Position).Magnitude

    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end

    if distance <= 5 then
        StopTween()
        root.CFrame = targetCFrame
        root.AssemblyLinearVelocity = Vector3.zero
        return
    end

    if distance <= 45 then
        StopTween()
        local dir = (targetCFrame.Position - root.Position).Unit
        root.CFrame = CFrame.new(root.Position + (dir * math.min(distance, speed * 0.1)), targetCFrame.Position + targetCFrame.LookVector * 10)
        root.AssemblyLinearVelocity = Vector3.zero
        return
    end

    if not TweenBodyVel or TweenBodyVel.Parent ~= root then
        if TweenBodyVel then pcall(function() TweenBodyVel:Destroy() end) end
        TweenBodyVel = Instance.new("BodyVelocity")
        TweenBodyVel.Name = "TweenBV"
        TweenBodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        TweenBodyVel.Velocity = Vector3.zero
        TweenBodyVel.Parent = root
    end

    if LastTweenTarget and (LastTweenTarget.Position - targetCFrame.Position).Magnitude < 20 and ActiveTween and ActiveTween.PlaybackState == Enum.PlaybackState.Playing then
        return
    end

    StopTween()

    LastTweenTarget = targetCFrame
    local duration = distance / math.max(speed, 50)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    ActiveTween = TweenService:Create(root, tweenInfo, { CFrame = targetCFrame })
    ActiveTween:Play()
end

local function PerformPortalTeleport(destinationName)
    if IsPortalTeleporting or IsServerHopping or not destinationName then return end
    IsPortalTeleporting = true
    
    SelectedPortalDestination = destinationName
    
    local root = CharacterData.RootPart
    if root then
        StopTween()
        
        local barrier = Instance.new("Part")
        barrier.Name = "PortalTempBarrier"
        barrier.Size = Vector3.new(15, 1, 15)
        barrier.CFrame = root.CFrame - Vector3.new(0, 3.5, 0)
        barrier.Anchored = true
        barrier.Transparency = 1
        barrier.CanCollide = true
        barrier.Parent = Workspace

        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        EquipToolByName("Portal")
        task.wait(0.1)
        SendKeyPress(Enum.KeyCode.C)
        
        task.wait(1.0)
        pcall(function() barrier:Destroy() end)
    end

    IsPortalTeleporting = false
end

local function FireSoulGuitarSpam()
    if not Settings.SpamSoulGuitar or IsServerHopping then return end

    local char = CharacterData.Character
    if not char then return end

    local sgTool = EquipToolByName("Soul Guitar") or EquipToolByName("Skull Guitar")
    if not sgTool then return end

    local targetPos = Vector3.zero

    if CurrentTargetPart and CurrentTargetPart.Parent then
        local targetChar = CurrentTargetPart.Parent
        local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
        if targetPlayer and (IsPlayerInSafeZone(targetPlayer) or IsPlayerPvPDisabled(targetPlayer)) then
            return
        end
        targetPos = GetPredictedTargetPos(CurrentTargetPart)
    else
        local mouse = LocalPlayer:GetMouse()
        if mouse then
            pcall(function() targetPos = mouse.Hit.Position end)
        end
    end

    if targetPos == Vector3.zero then return end

    local toolRemote = sgTool:FindFirstChild("RemoteEvent") or sgTool:FindFirstChildOfClass("RemoteEvent")
    if toolRemote then
        pcall(function()
            toolRemote:FireServer(targetPos)
        end)
    end

    SendKeyPress(Enum.KeyCode.Z)
    SendKeyPress(Enum.KeyCode.X)
end

task.spawn(function()
    while task.wait(0.015) do
        if Settings.SpamSoulGuitar and not IsServerHopping then
            pcall(FireSoulGuitarSpam)
        end
    end
end)

local LastV4Attempt = 0
local function TriggerRaceV4()
    if not Settings.AutoRaceV4 or IsServerHopping then return end
    if (tick() - LastV4Attempt) < 1.0 then return end
    LastV4Attempt = tick()

    pcall(function()
        local char = CharacterData.Character
        if not char then return end

        local raceTrans = char:FindFirstChild("RaceTrans") or char:FindFirstChild("RaceEnergy")
        if not raceTrans then return end

        SendKeyPress(Enum.KeyCode.Y)
    end)
end

local function ExecuteBuddySwordXSpam(targetPos)
    if IsServerHopping then return end
    pcall(function()
        local buddyTool = EquipToolByName("Buddy Sword")
        if not buddyTool then return end

        if targetPos and targetPos ~= Vector3.zero then
            local toolRemote = buddyTool:FindFirstChild("RemoteEvent") or buddyTool:FindFirstChildOfClass("RemoteEvent")
            if toolRemote then
                pcall(function()
                    toolRemote:FireServer(targetPos)
                end)
            end
        end

        SendKeyPress(Enum.KeyCode.X)
    end)
end

local IsComboRunning = false
local function ExecuteSmartCombo(targetPart)
    if IsComboRunning or IsServerHopping or not targetPart or not targetPart.Parent or IsInEscapeMode then return end
    IsComboRunning = true

    local function IsTargetValid()
        if not targetPart or not targetPart.Parent then return false end
        local parent = targetPart.Parent
        local hum = parent:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end

        if CharacterData.RootPart then
            local distance = (CharacterData.RootPart.Position - targetPart.Position).Magnitude
            if distance > 140 then return false end
        end

        local player = Players:GetPlayerFromCharacter(parent)
        if player then
            if IsPlayerInSafeZone(player) or IsPlayerPvPDisabled(player) then
                return false
            end
        end

        return true
    end

    local pool = {
        { Tool = "Godhuman", Key = Enum.KeyCode.Z },
        { Tool = "Godhuman", Key = Enum.KeyCode.X },
        { Tool = "Godhuman", Key = Enum.KeyCode.C },
        { Tool = "Buddy Sword", Key = Enum.KeyCode.Z },
        { Tool = "Buddy Sword", Key = Enum.KeyCode.X },
        { Tool = "Soul Guitar", Key = Enum.KeyCode.Z },
        { Tool = "Soul Guitar", Key = Enum.KeyCode.X }
    }

    task.spawn(function()
        for _, step in ipairs(pool) do
            if not IsTargetValid() or IsInEscapeMode or IsServerHopping then break end

            local equippedTool = EquipToolByName(step.Tool)
            if equippedTool then
                SendKeyPress(step.Key)
                task.wait(0.015)
            end
        end
        IsComboRunning = false
    end)
end

local function CanGetBounty(targetPlayer)
    if not targetPlayer or targetPlayer == LocalPlayer then return false end
    
    if (TargetKillCounts[targetPlayer.UserId] or 0) >= 3 then
        return false
    end

    if IsPlayerPvPDisabled(targetPlayer) then
        return false
    end

    if IsPlayerInSafeZone(targetPlayer) then
        return false
    end

    local targetChar = targetPlayer.Character
    local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    if targetHrp and CharacterData.RootPart then
        local dist = (targetHrp.Position - CharacterData.RootPart.Position).Magnitude
        local maxAllowedDist = Settings.MaxTargetDistance or 10000
        if dist > maxAllowedDist then
            return false
        end
    end
    
    local myLevel = GetPlayerLevel(LocalPlayer)
    local targetLevel = GetPlayerLevel(targetPlayer)
    
    if myLevel > 10 and targetLevel > 10 then
        if myLevel >= 2550 then
            if targetLevel < math.floor(2550 * 0.75) then return false end
        else
            local minLevel = math.floor(myLevel * 0.75)
            if targetLevel < minLevel then return false end
        end
    end

    local myTeam = GetPlayerTeam(LocalPlayer)
    local targetTeam = GetPlayerTeam(targetPlayer)
    if string.find(string.lower(myTeam), "marine") and string.find(string.lower(targetTeam), "marine") then
        return false
    end

    return true
end

local function GetPlayerList()
    local list = {}
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer then table.insert(list, v.Name) end
    end
    return list
end

local function GetClosestBountyTarget()
    local closestPlayer = nil
    local shortestDistance = math.huge

    if CharacterData.RootPart then
        local myPos = CharacterData.RootPart.Position
        for _, p in ipairs(Players:GetPlayers()) do
            if CanGetBounty(p) then
                local char = p.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                
                if hrp and hum and hum.Health > 0 then
                    local dist = (hrp.Position - myPos).Magnitude
                    if dist < shortestDistance and dist <= (Settings.MaxTargetDistance or 10000) then
                        shortestDistance = dist
                        closestPlayer = p
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function GetClosestPlayerToLocalPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge

    if CharacterData.RootPart then
        local myPos = CharacterData.RootPart.Position
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not IsPlayerInSafeZone(p) and not IsPlayerPvPDisabled(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                local dist = (p.Character.HumanoidRootPart.Position - myPos).Magnitude
                if dist < shortestDistance and dist <= (Settings.MaxTargetDistance or 10000) then
                    shortestDistance = dist
                    closestPlayer = p
                end
            end
        end
    end
    return closestPlayer
end

local function GetClosestPlayerToCenterScreen()
    local closestPlayer = nil
    local shortestDistance = Settings.ShowFOV and Settings.FOVRadius or math.huge
    local center = GetCenterScreen()

    if not Camera then return nil end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not IsPlayerInSafeZone(p) and not IsPlayerPvPDisabled(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local hrp = p.Character.HumanoidRootPart
            if CharacterData.RootPart and (hrp.Position - CharacterData.RootPart.Position).Magnitude <= (Settings.MaxTargetDistance or 10000) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        closestPlayer = p
                    end
                end
            end
        end
    end
    return closestPlayer
end

local FastAttack = {}
local FastAttack_enemies = Workspace:FindFirstChild("Enemies") or Workspace
local FastAttack_characters = Workspace:FindFirstChild("Characters") or Workspace
local FastAttack_arms = { "RightLowerArm", "RightUpperArm", "LeftLowerArm", "LeftUpperArm", "RightHand", "LeftHand" }

function FastAttack:SuperFastAttack()
    if IsServerHopping then return end
    local char = CharacterData.Character
    local root = CharacterData.RootPart
    local hum = CharacterData.Humanoid
    if not char or not root or not hum or hum.Health <= 0 then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end

    local hitData = {}
    local primaryPart

    for _, list in ipairs({ FastAttack_enemies, FastAttack_characters }) do
        if list then
            for _, e in ipairs(list:GetChildren()) do
                if e ~= char and not e:GetAttribute("IsBoat") then
                    local targetPlayer = Players:GetPlayerFromCharacter(e)
                    
                    if targetPlayer then
                        if IsPlayerInSafeZone(targetPlayer) or IsPlayerPvPDisabled(targetPlayer) then
                            continue
                        end
                    end

                    local ehum = e:FindFirstChildOfClass("Humanoid")
                    local ebody = e:FindFirstChild("Head") or e.PrimaryPart
                    if ehum and ehum.Health > 0 and ebody and (ebody.Position - root.Position).Magnitude <= 90 then
                        local part = e:FindFirstChild(FastAttack_arms[math.random(#FastAttack_arms)]) or e.PrimaryPart
                        if part then
                            table.insert(hitData, { e, part })
                            primaryPart = part
                        end
                    end
                end
            end
        end
    end

    if #hitData == 0 or not primaryPart then return end

    local lcr = tool:FindFirstChild("LeftClickRemote")
    if lcr then
        pcall(function() lcr:FireServer((primaryPart.Position - root.Position).Unit, 1) end)
    end

    if Register_Attack then pcall(function() Register_Attack:FireServer(0) end) end
    if Register_Hit then pcall(function() Register_Hit:FireServer(primaryPart, hitData) end) end
end

task.spawn(function()
    while task.wait(0.03) do
        if Settings.FastAttack and not IsServerHopping then
            pcall(function() FastAttack:SuperFastAttack() end)
        end
    end
end)

local StopBountyGui = nil

local function CreateStopBountyButton(onStopClicked)
    if StopBountyGui then pcall(function() StopBountyGui:Destroy() end) end

    StopBountyGui = Instance.new("ScreenGui")
    StopBountyGui.Name = "StopBountyHuntGUI"
    StopBountyGui.ResetOnSpawn = false
    
    pcall(function()
        if gethui then
            StopBountyGui.Parent = gethui()
        else
            StopBountyGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end
    end)

    local btn = Instance.new("TextButton")
    btn.Name = "StopButton"
    btn.Parent = StopBountyGui
    btn.Size = UDim2.new(0, 220, 0, 50)
    btn.Position = UDim2.new(0.5, -110, 0.08, 0)
    btn.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    btn.Text = "🛑 STOP BOUNTY HUNT"
    btn.BorderSizePixel = 2

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        if onStopClicked then pcall(onStopClicked) end
    end)
end

local function RemoveStopBountyButton()
    if StopBountyGui then
        pcall(function() StopBountyGui:Destroy() end)
        StopBountyGui = nil
    end
end

local BuildUI

local function SyncUIControls()
    isSyncingUI = true
    pcall(function()
        if UIControls.AimMethodDropdown then UIControls.AimMethodDropdown:SetValue(Settings.AimMethod) end
        if UIControls.TeamDropdown then UIControls.TeamDropdown:SetValue(Settings.SavedTeam) end
        if UIControls.AimbotSkillsTog then UIControls.AimbotSkillsTog:SetValue(Settings.AimbotSkills) end
        if UIControls.SpamSoulGuitarTog then UIControls.SpamSoulGuitarTog:SetValue(Settings.SpamSoulGuitar) end
        if UIControls.XMove100HitTog then UIControls.XMove100HitTog:SetValue(Settings.XMove100Hit) end
        if UIControls.TargetPredictionTog then UIControls.TargetPredictionTog:SetValue(Settings.TargetPrediction) end
        if UIControls.AimbotCameraTog then UIControls.AimbotCameraTog:SetValue(Settings.AimbotCamera) end
        if UIControls.InstantLockTog then UIControls.InstantLockTog:SetValue(Settings.InstantLock) end
        if UIControls.CamSmoothnessSlider then UIControls.CamSmoothnessSlider:SetValue(Settings.CameraSmoothness) end
        if UIControls.HitboxExpandTog then UIControls.HitboxExpandTog:SetValue(Settings.HitboxExpand) end
        if UIControls.HitboxSizeSlider then UIControls.HitboxSizeSlider:SetValue(Settings.HitboxSize) end
        if UIControls.PlayerESPTog then UIControls.PlayerESPTog:SetValue(Settings.PlayerESP) end
        if UIControls.FastAttackTog then UIControls.FastAttackTog:SetValue(Settings.FastAttack) end
        if UIControls.AutoRaceV4Tog then UIControls.AutoRaceV4Tog:SetValue(Settings.AutoRaceV4) end
        if UIControls.BountyHuntToggle then UIControls.BountyHuntToggle:SetValue(Settings.BountyHunt) end
        if UIControls.AutoPortalTPTog then UIControls.AutoPortalTPTog:SetValue(Settings.AutoPortalTP) end
        if UIControls.AutoServerHopWhenEmptyTog then UIControls.AutoServerHopWhenEmptyTog:SetValue(Settings.AutoServerHopWhenEmpty) end
        if UIControls.FilterMinServerBountyTog then UIControls.FilterMinServerBountyTog:SetValue(Settings.FilterMinServerBounty) end
    end)
    isSyncingUI = false
end

local function SetBountyHuntMode(enabled)
    if enabled then
        SavedSettingsConfig = DeepCopyTable(Settings)

        Settings.AimMethod = "Closest to LocalPlayer"
        Settings.AimbotSkills = true
        Settings.XMove100Hit = true
        Settings.AimbotCamera = true
        Settings.InstantLock = true
        Settings.HitboxExpand = true
        Settings.HitboxSize = 35
        Settings.PlayerESP = true
        Settings.FastAttack = true
        Settings.AutoRaceV4 = true
        Settings.AutoPortalTP = true
        Settings.AutoServerHopWhenEmpty = true
        Settings.AvoidSafeZonePlayers = true
        Settings.FilterMinServerBounty = true
        Settings.BountyHunt = true
        Settings.PVPMode = true

        LocalPlayerDeathCount = 0
        HuntTargetPlayer = nil
        HuntTargetStartTime = 0
        NoTargetStartTime = 0

        if not Settings.PVPMode then
            BuildUI(true)
        else
            SyncUIControls()
        end

        SaveConfig()

        CreateStopBountyButton(function()
            SetBountyHuntMode(false)
        end)
    else
        Settings.BountyHunt = false
        LocalPlayerDeathCount = 0
        HuntTargetPlayer = nil
        IsInEscapeMode = false
        EscapeTargetPosition = nil
        IsPortalTeleporting = false
        IsServerHopping = false
        NoTargetStartTime = 0
        StopTween()
        RemoveStopBountyButton()

        if SavedSettingsConfig then
            for k, v in pairs(SavedSettingsConfig) do Settings[k] = v end
            SavedSettingsConfig = nil
        end

        SyncUIControls()
        SaveConfig()
    end
end

BuildUI = function(isPVPMode)
    StopTween()
    UIControls = {}

    pcall(function()
        if Fluent then Fluent:Destroy() Fluent = nil end
    end)

    task.wait(0.1)

    local ok, lib = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/huyyeuemhihi/Fluent/refs/heads/main/Fluentvip.lua"))()
    end)

    if not ok or not lib then return end

    Fluent = lib
    Settings.PVPMode = isPVPMode

    Window = Fluent:CreateWindow({
        Title = isPVPMode and "Blox Fruits Hub - PVP Edition" or "Blox Fruits Hub - Full Edition",
        SubTitle = isPVPMode and "Mode: PVP Exclusive" or "Mode: Standard Hub",
        TabWidth = 160,
        Size = UDim2.fromOffset(640, 480),
        Acrylic = false,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    })

    local Tabs = {}
    Tabs.Combat = Window:AddTab({ Title = "Combat", Icon = "rbxassetid://125736686613291" })
    
    if not isPVPMode then
        Tabs.MainFarm = Window:AddTab({ Title = "Main Farm", Icon = "rbxassetid://125736686613291" })
        Tabs.MasteryRaids = Window:AddTab({ Title = "Mastery & Raids", Icon = "rbxassetid://125736686613291" })
        Tabs.SeaEvents = Window:AddTab({ Title = "Sea & Events", Icon = "rbxassetid://125736686613291" })
        Tabs.Fruits = Window:AddTab({ Title = "Fruits & Items", Icon = "rbxassetid://125736686613291" })
        Tabs.LocalPlayer = Window:AddTab({ Title = "Stats & Team", Icon = "rbxassetid://125736686613291" })
    end

    Tabs.PVP = Window:AddTab({ Title = "PVP & Aimbot", Icon = "rbxassetid://125736686613291" })

    if isPVPMode then
        Tabs.AutoHunt = Window:AddTab({ Title = "Auto Hunt", Icon = "rbxassetid://125736686613291" })
    end

    Tabs.Teleport = Window:AddTab({ Title = "Teleports", Icon = "rbxassetid://125736686613291" })
    Tabs.ESP = Window:AddTab({ Title = "ESP & Visuals", Icon = "rbxassetid://125736686613291" })
    Tabs.Settings = Window:AddTab({ Title = "Config & Server", Icon = "rbxassetid://125736686613291" })

    UIControls.PVPModeSwitchTog = Tabs.Combat:AddToggle("PVPModeSwitchTog", {
        Title = "⚡ Switch Between PVP / Standard Mode",
        Default = isPVPMode,
        Callback = function(v)
            if isSyncingUI then return end
            pcall(function()
                if v ~= Settings.PVPMode then
                    for k in pairs(Settings) do
                        if type(Settings[k]) == "boolean" and k ~= "PVPMode" then Settings[k] = false end
                    end
                    SetBountyHuntMode(false)
                    BuildUI(v)
                end
            end)
        end
    })

    UIControls.FastAttackTog = Tabs.Combat:AddToggle("FastAttackTog", {
        Title = "Enable Fast Attack",
        Default = Settings.FastAttack,
        Callback = function(v) if isSyncingUI then return end pcall(function() Settings.FastAttack = v SaveConfig() end) end
    })

    UIControls.SpamSoulGuitarTog = Tabs.Combat:AddToggle("SpamSoulGuitarTog", {
        Title = "🔥 Spam Soul Guitar (Moves + M1 Aimbot)",
        Default = Settings.SpamSoulGuitar,
        Callback = function(v) if isSyncingUI then return end pcall(function() Settings.SpamSoulGuitar = v SaveConfig() end) end
    })

    UIControls.WeaponTypeDropdown = Tabs.Combat:AddDropdown("WeaponTypeDropdown", {
        Title = "Select Weapon ToolTip",
        Values = { "Buddy Sword", "Melee", "Sword", "Blox Fruit", "Gun" },
        Default = Settings.EquipWeaponType,
        Callback = function(v) if isSyncingUI then return end pcall(function() Settings.EquipWeaponType = v SaveConfig() end) end
    })

    UIControls.BringMobsTog = Tabs.Combat:AddToggle("BringMobsTog", {
        Title = "Bring Mobs (Mob Magnet)",
        Default = Settings.BringMobs,
        Callback = function(v) if isSyncingUI then return end pcall(function() Settings.BringMobs = v SaveConfig() end) end
    })

    Tabs.Combat:AddToggle("WalkWaterTog", {
        Title = "Walk On Water",
        Default = Settings.WalkOnWater,
        Callback = function(v) if isSyncingUI then return end pcall(function() Settings.WalkOnWater = v SaveConfig() end) end
    })

    Tabs.Combat:AddToggle("NoclipTog", {
        Title = "Noclip Mode",
        Default = Settings.Noclip,
        Callback = function(v) if isSyncingUI then return end pcall(function() Settings.Noclip = v SaveConfig() end) end
    })

    UIControls.AutoRaceV4Tog = Tabs.Combat:AddToggle("AutoRaceV4Tog", {
        Title = "Auto Turn On Race V4",
        Default = Settings.AutoRaceV4,
        Callback = function(v) if isSyncingUI then return end pcall(function() Settings.AutoRaceV4 = v SaveConfig() end) end
    })

    if not isPVPMode and Tabs.LocalPlayer then
        Tabs.LocalPlayer:AddDropdown("StatsTeamDropdown", {
            Title = "🚩 Choose Auto-Join Team",
            Values = { "Pirates", "Marines" },
            Default = Settings.SavedTeam or "Pirates",
            Callback = function(v)
                if isSyncingUI then return end
                pcall(function()
                    Settings.SavedTeam = v
                    SaveConfig()
                    JoinTeam(v)
                end)
            end
        })
    end

    UIControls.AimMethodDropdown = Tabs.PVP:AddDropdown("AimMethodDropdown", {
        Title = "Select Aim Target Method",
        Values = { "Closest to Center Screen", "Closest to LocalPlayer", "Selected Player" },
        Default = Settings.AimMethod,
        Callback = function(v) if isSyncingUI then return end pcall(function() Settings.AimMethod = v SaveConfig() end) end
    })

    UIControls.TargetDropdown = Tabs.PVP:AddDropdown("SelectTargetDropdown", {
        Title = "Select Target Player",
        Values = GetPlayerList(),
        Default = Settings.TargetSelect,
        Callback = function(v) if isSyncingUI then return end pcall(function() Settings.TargetSelect = v SaveConfig() end) end
    })

    UIControls.AimbotSkillsTog = Tabs.PVP:AddToggle("AimbotSkillsTog", {
        Title = "Skill Redirection Aimbot (100% Silent Aim)",
        Default = Settings.AimbotSkills,
        Callback = function(v) if isSyncingUI then return end pcall(function() Settings.AimbotSkills = v SaveConfig() end) end
    })

    UIControls.XMove100HitTog = Tabs.PVP:AddToggle("XMove100HitTog", {
        Title = "100% Buddy Sword X & Skill Auto-Lock",
        Default = Settings.XMove100Hit,
        Callback = function(v) if isSyncingUI then return end pcall(function() Settings.XMove100Hit = v SaveConfig() end) end
    })

    UIControls.TargetPredictionTog = Tabs.PVP:AddToggle("TargetPredictionTog", {
        Title = "Target Velocity Prediction",
        Default = Settings.TargetPrediction,
        Callback = function(v) if isSyncingUI then return end pcall(function() Settings.TargetPrediction = v SaveConfig() end) end
    })

    UIControls.AimbotCameraTog = Tabs.PVP:AddToggle("AimbotCameraTog", {
        Title = "Camera Lock On Target",
        Default = Settings.AimbotCamera,
        Callback = function(v) if isSyncingUI then return end pcall(function() Settings.AimbotCamera = v SaveConfig() end) end
    })

    UIControls.InstantLockTog = Tabs.PVP:AddToggle("InstantLockTog", {
        Title = "Instant Hard Lock (0 Delay)",
        Default = Settings.InstantLock,
        Callback = function(v) if isSyncingUI then return end pcall(function() Settings.InstantLock = v SaveConfig() end) end
    })

    UIControls.HitboxExpandTog = Tabs.PVP:AddToggle("HitboxExpandTog", {
        Title = "Expand Target Hitbox",
        Default = Settings.HitboxExpand,
        Callback = function(v) if isSyncingUI then return end pcall(function() Settings.HitboxExpand = v SaveConfig() end) end
    })

    UIControls.HitboxSizeSlider = Tabs.PVP:AddSlider("HitboxSizeSlider", {
        Title = "Hitbox Size Expansion",
        Min = 5,
        Max = 60,
        Default = Settings.HitboxSize,
        Rounding = 0,
        Callback = function(v) if isSyncingUI then return end pcall(function() Settings.HitboxSize = v SaveConfig() end) end
    })

    if isPVPMode and Tabs.AutoHunt then
        UIControls.HuntStatusParagraph = Tabs.AutoHunt:AddParagraph({
            Title = "Auto Bounty Hunt Status",
            Content = "Target: Searching..."
        })

        UIControls.BountyHuntToggle = Tabs.AutoHunt:AddToggle("BountyHuntTog", {
            Title = "Enable Auto Bounty Hunt",
            Default = Settings.BountyHunt,
            Callback = function(v)
                if isSyncingUI then return end
                pcall(function()
                    SetBountyHuntMode(v)
                end)
            end
        })

        UIControls.FilterMinServerBountyTog = Tabs.AutoHunt:AddToggle("FilterMinServerBountyTog", {
            Title = "🏆 Server Browser 30M+ Bounty Filter",
            Default = Settings.FilterMinServerBounty,
            Callback = function(v) if isSyncingUI then return end pcall(function() Settings.FilterMinServerBounty = v SaveConfig() end) end
        })

        UIControls.AutoPortalTPTog = Tabs.AutoHunt:AddToggle("AutoPortalTPTog", {
            Title = "🌀 Portal Fast Teleport on Island Jump",
            Default = Settings.AutoPortalTP,
            Callback = function(v) if isSyncingUI then return end pcall(function() Settings.AutoPortalTP = v SaveConfig() end) end
        })

        UIControls.AutoServerHopWhenEmptyTog = Tabs.AutoHunt:AddToggle("AutoServerHopWhenEmptyTog", {
            Title = "🔀 Auto Server Hop When No Target Available",
            Default = Settings.AutoServerHopWhenEmpty,
            Callback = function(v) if isSyncingUI then return end pcall(function() Settings.AutoServerHopWhenEmpty = v SaveConfig() end) end
        })

        Tabs.AutoHunt:AddSlider("PortalDistanceSlider", {
            Title = "Portal Teleport Trigger Distance (Studs)",
            Min = 500,
            Max = 4000,
            Default = Settings.PortalDistanceThreshold,
            Rounding = 0,
            Callback = function(v) if isSyncingUI then return end pcall(function() Settings.PortalDistanceThreshold = v SaveConfig() end) end
        })
    end

    local islandNames = {}
    for islandName in pairs(IslandTeleports) do table.insert(islandNames, islandName) end

    Tabs.Teleport:AddDropdown("IslandTeleportDropdown", {
        Title = "Select Target Island",
        Values = #islandNames > 0 and islandNames or {"No Teleports Available"},
        Default = islandNames[1] or "",
        Callback = function(v) if isSyncingUI then return end pcall(function() Settings.SelectedIslandTeleport = v SaveConfig() end) end
    })

    Tabs.Teleport:AddButton({
        Title = "Teleport to Selected Island",
        Callback = function()
            pcall(function()
                if Settings.SelectedIslandTeleport ~= "" and IslandTeleports[Settings.SelectedIslandTeleport] then
                    SafeTweenTo(IslandTeleports[Settings.SelectedIslandTeleport], Settings.TweenSpeed)
                end
            end)
        end
    })

    Tabs.Teleport:AddSlider("TweenSpeedSlider", {
        Title = "Tween Flight Speed",
        Min = 150,
        Max = 450,
        Default = Settings.TweenSpeed,
        Rounding = 0,
        Callback = function(v) if isSyncingUI then return end pcall(function() Settings.TweenSpeed = v SaveConfig() end) end
    })

    Tabs.Teleport:AddSlider("EscapeHeightSlider", {
        Title = "Sky Hover / Escape Height",
        Min = 100,
        Max = 1000,
        Default = Settings.EscapeHeight,
        Rounding = 0,
        Callback = function(v) if isSyncingUI then return end pcall(function() Settings.EscapeHeight = v SaveConfig() end) end
    })

    UIControls.PlayerESPTog = Tabs.ESP:AddToggle("PlayerESPTog", {
        Title = "Player Text ESP",
        Default = Settings.PlayerESP,
        Callback = function(v) if isSyncingUI then return end pcall(function() Settings.PlayerESP = v SaveConfig() end) end
    })

    UIControls.TeamDropdown = Tabs.Settings:AddDropdown("SavedTeamDropdownConfig", {
        Title = "🚩 Auto-Join Team Selection",
        Values = { "Pirates", "Marines" },
        Default = Settings.SavedTeam or "Pirates",
        Callback = function(v)
            if isSyncingUI then return end
            pcall(function()
                Settings.SavedTeam = v
                SaveConfig()
                JoinTeam(v)
            end)
        end
    })

    Tabs.Settings:AddButton({
        Title = "💾 Save Current Configuration",
        Callback = function()
            SaveConfig()
            Fluent:Notify({ Title = "Config Saved", Content = "Settings successfully written.", Duration = 2 })
        end
    })

    Tabs.Settings:AddButton({
        Title = "🔀 Server Hop",
        Callback = function() ServerHop() end
    })
end

BuildUI(Settings.PVPMode or Settings.BountyHunt)

if Settings.BountyHunt then
    task.spawn(function()
        task.wait(0.3)
        SetBountyHuntMode(true)
    end)
end

AddConnection(RunService.RenderStepped:Connect(function()
    if IsServerHopping then return end

    local targetPlayer = nil
    if Settings.BountyHunt and HuntTargetPlayer then
        targetPlayer = HuntTargetPlayer
    elseif Settings.AimMethod == "Closest to Center Screen" then
        targetPlayer = GetClosestPlayerToCenterScreen()
    elseif Settings.AimMethod == "Closest to LocalPlayer" then
        targetPlayer = GetClosestPlayerToLocalPlayer()
    elseif Settings.AimMethod == "Selected Player" and Settings.TargetSelect ~= "" then
        targetPlayer = Players:FindFirstChild(Settings.TargetSelect)
    end

    if targetPlayer and not IsPlayerInSafeZone(targetPlayer) and not IsPlayerPvPDisabled(targetPlayer) and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and targetPlayer.Character:FindFirstChild("Humanoid") and targetPlayer.Character.Humanoid.Health > 0 then
        local hrp = targetPlayer.Character.HumanoidRootPart
        local dist = CharacterData.RootPart and (hrp.Position - CharacterData.RootPart.Position).Magnitude or 0

        if dist <= (Settings.MaxTargetDistance or 10000) then
            CurrentTargetPart = hrp
            CurrentTargetName = targetPlayer.Name
            CurrentTargetPos = GetPredictedTargetPos(CurrentTargetPart)
        else
            CurrentTargetPart = nil
            CurrentTargetName = "None"
            CurrentTargetPos = Vector3.zero
        end
    else
        CurrentTargetPart = nil
        CurrentTargetName = "None"
        CurrentTargetPos = Vector3.zero
    end

    if Settings.AimbotCamera and CurrentTargetPart and CurrentTargetPart.Parent and Camera then
        local predictedPos = CurrentTargetPos ~= Vector3.zero and CurrentTargetPos or CurrentTargetPart.Position
        local currentCamCF = Camera.CFrame
        local targetCamCF = CFrame.new(currentCamCF.Position, predictedPos)
        
        if Settings.InstantLock then
            Camera.CFrame = targetCamCF
        else
            Camera.CFrame = currentCamCF:Lerp(targetCamCF, math.clamp(Settings.CameraSmoothness or 0.15, 0.01, 1))
        end
    end

    if Settings.HitboxExpand and CurrentTargetPart and CurrentTargetPart.Parent and CurrentTargetPart:IsDescendantOf(Workspace) then
        pcall(function()
            CurrentTargetPart.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
            CurrentTargetPart.Transparency = 0.7
            CurrentTargetPart.BrickColor = BrickColor.new("Really red")
            CurrentTargetPart.Material = Enum.Material.Neon
            CurrentTargetPart.CanCollide = false
        end)
    end
end))

AddConnection(RunService.Stepped:Connect(function()
    if IsServerHopping then return end
    if Settings.Noclip then
        local char = CharacterData.Character
        if char then
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end))

task.spawn(function()
    task.wait(15)
    while task.wait(5) do
        if IsServerHopping then break end
        if Settings.BountyHunt and Settings.FilterMinServerBounty then
            if not HitValidator:WasHitRecently(5.0) and not IsComboRunning then
                pcall(function()
                    local currentTotal = GetTotalServerBounty()
                    if currentTotal > 0 and currentTotal < Settings.MinServerBounty then
                        if UIControls and UIControls.HuntStatusParagraph then
                            UIControls.HuntStatusParagraph:SetDesc(string.format("Server Bounty: %.1fM (<30M) -> Hopping Server...", currentTotal / 1000000))
                        end
                        task.wait(1)
                        ServerHop()
                    end
                end)
            end
        end
    end
end)

local LastEnablePvpTime = 0

task.spawn(function()
    while task.wait(0.1) do
        if IsServerHopping then break end
        if Settings.BountyHunt then
            pcall(function()
                if (os.clock() - LastEnablePvpTime) >= 1.0 then
                    LastEnablePvpTime = os.clock()
                    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
                    local CommF_ = remotesFolder and remotesFolder:FindFirstChild("CommF_")
                    if CommF_ then CommF_:InvokeServer("EnablePvp") end
                end

                local myHealth, myMaxHealth = GetLocalPlayerHealth()
                if (myHealth / myMaxHealth < 0.3) or (HitValidator:WasHitRecently(1.0) and HitValidator:GetLastHitDamage() > 1000) then
                    IsInEscapeMode = true

                    local dynamicEscapeCF = nil
                    if HuntTargetPlayer and HuntTargetPlayer.Character and HuntTargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local targetPos = HuntTargetPlayer.Character.HumanoidRootPart.Position
                        dynamicEscapeCF = CFrame.new(targetPos.X, targetPos.Y + (Settings.EscapeHeight or 500), targetPos.Z)
                    elseif CharacterData.RootPart then
                        local myPos = CharacterData.RootPart.Position
                        dynamicEscapeCF = CFrame.new(myPos.X, myPos.Y + (Settings.EscapeHeight or 500), myPos.Z)
                    end

                    if dynamicEscapeCF then
                        SafeTweenTo(dynamicEscapeCF, Settings.TweenSpeed)
                    end

                    if UIControls.HuntStatusParagraph then
                        UIControls.HuntStatusParagraph:SetDesc("Status: Tweening Up & Healing (Maintaining Distance)")
                    end
                    return
                else
                    IsInEscapeMode = false
                    EscapeTargetPosition = nil
                end

                if HuntTargetPlayer then
                    local tChar = HuntTargetPlayer.Character
                    local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
                    if tHrp and CharacterData.RootPart then
                        local currentDist = (tHrp.Position - CharacterData.RootPart.Position).Magnitude
                        if currentDist > (Settings.MaxTargetDistance or 10000) then
                            HuntTargetPlayer = nil
                        end
                    end
                end

                if not HuntTargetPlayer or not CanGetBounty(HuntTargetPlayer) or (os.clock() - HuntTargetStartTime > 90) then
                    HuntTargetPlayer = GetClosestBountyTarget()
                    HuntTargetStartTime = os.clock()
                end

                if HuntTargetPlayer and CanGetBounty(HuntTargetPlayer) then
                    NoTargetStartTime = 0

                    local targetChar = HuntTargetPlayer.Character
                    local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                    local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")

                    if targetHrp and targetHum and targetHum.Health > 0 then
                        local targetPos = targetHrp.Position
                        local dist = CharacterData.RootPart and (targetPos - CharacterData.RootPart.Position).Magnitude or 0

                        if UIControls.HuntStatusParagraph then
                            local kills = TargetKillCounts[HuntTargetPlayer.UserId] or 0
                            local totalBountyM = string.format("%.1fM", GetTotalServerBounty() / 1000000)
                            UIControls.HuntStatusParagraph:SetDesc("Server Bounty: " .. totalBountyM .. " | Target: " .. HuntTargetPlayer.Name .. " | Dist: " .. math.floor(dist) .. "m | Kills: " .. kills .. "/3")
                        end

                        if Settings.AutoPortalTP and dist > Settings.PortalDistanceThreshold and (os.clock() - LastPortalTPTime > 12) then
                            local closestPortalName = "Cafe"
                            local minPortalDist = math.huge
                            for portalName, portalPos in pairs(PORTAL_DESTINATIONS) do
                                local d = (portalPos - targetPos).Magnitude
                                if d < minPortalDist then
                                    minPortalDist = d
                                    closestPortalName = portalName
                                end
                            end
                            PerformPortalTeleport(closestPortalName)
                            LastPortalTPTime = os.clock()
                            task.wait(1.2)
                        end

                        EquipToolByToolTip(Settings.EquipWeaponType)
                        
                        local standoffDistance = 12
                        local myPos = CharacterData.RootPart and CharacterData.RootPart.Position or targetPos
                        local dir = (targetPos - myPos)
                        local horizontalDir = Vector3.new(dir.X, 0, dir.Z)
                        if horizontalDir.Magnitude > 0 then
                            horizontalDir = horizontalDir.Unit
                        else
                            horizontalDir = Vector3.new(0, 0, 1)
                        end
                        
                        local idealPos = targetPos - (horizontalDir * standoffDistance) + Vector3.new(0, 6, 0)
                        local approachCF = CFrame.new(idealPos, targetPos)
                        SafeTweenTo(approachCF, Settings.TweenSpeed)

                        TriggerRaceV4()
                        ExecuteSmartCombo(targetHrp)
                        ExecuteBuddySwordXSpam(targetPos)
                        ApplyAntiStun()
                    else
                        NoTargetStartTime = os.clock()
                        if UIControls.HuntStatusParagraph then
                            UIControls.HuntStatusParagraph:SetDesc("Target: " .. HuntTargetPlayer.Name .. " (Waiting for respawn...)")
                        end
                    end
                else
                    if Settings.AutoServerHopWhenEmpty then
                        if HitValidator:WasHitRecently(3.0) or IsComboRunning then
                            NoTargetStartTime = os.clock()
                            return
                        end

                        if not IsServerHopping then
                            if NoTargetStartTime == 0 then
                                NoTargetStartTime = os.clock()
                            end

                            local elapsed = os.clock() - NoTargetStartTime
                            local waitTime = 5
                            local remaining = math.max(0, math.ceil(waitTime - elapsed))

                            if UIControls.HuntStatusParagraph then
                                UIControls.HuntStatusParagraph:SetDesc("Target: Searching... (Server Hop in " .. remaining .. "s)")
                            end

                            if elapsed >= waitTime then
                                NoTargetStartTime = os.clock()
                                if UIControls.HuntStatusParagraph then
                                    UIControls.HuntStatusParagraph:SetDesc("Target: Hopping via Server Browser...")
                                end
                                ServerHop()
                            end
                        end
                    else
                        NoTargetStartTime = 0
                        if UIControls.HuntStatusParagraph then
                            UIControls.HuntStatusParagraph:SetDesc("Target: Searching...")
                        end
                    end
                end
            end)
        end
    end
end)
