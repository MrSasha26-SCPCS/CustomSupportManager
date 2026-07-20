-- Settings

local mtfSpawnTime = 17
local ciSpawnTime = 12
local dt = 1

local Epsilon11Info = {
    single = {"MTFCommander"},
    others = {"MTFSniper", "MTFLieutenant", "MTFCadet"},
    transport = "helicopter",
    haveEquipment = {"MTFLieutenant"},
    isAutoSpawning = true,
    name = "<color=#0000BB>МОГ Epsilon-11</color>",
    acesMessageWithSCP = "MtfUnit Epsilon 11 HasEntered AllRemaining AwaitingRecontainment {scpCount} ScpSubject",
    acesMessageNoSCP = "MtfUnit Epsilon 11 HasEntered AllRemaining NoSCPsLeft",
    team = "MTF"
}

local DefaultCIInfo = {
    others = {"ChaosInsurgency"},
    transport = "car",
    isAutoSpawning = true,
    name = "<color=#00BB00>Отряд Повстанцев Хаоса</color>",
    acesMessageWithSCP = "attention . unauthorized personnel detected at surface area . allremaining",
    acesMessageNoSCP = "attention . unauthorized personnel detected at surface area . allremaining",
    team = "ClassD"
}

--

local json = require "json"

local GameObject = CS.UnityEngine.GameObject

-- Local functions
local function getLen(table)
    local count = 0
    for key, val in pairs(table) do
        count = count + 1
    end
    return count
end

local function mergeTables(t1, t2)
    for key, value in pairs(t2) do
        t1[key] = value
    end
    return t1
end

local function findInactiveRoom(name)
    local netRooms = CS.UnityEngine.Resources.FindObjectsOfTypeAll(typeof(CS.NetRoom))
    for i = 0, netRooms.Length - 1 do
        local netRoom = netRooms[i]
        if netRoom.roomObj.name == name then
            return netRoom.roomObj
        end
    end
    return nil
end

local function getIndex(tab, val)
    for i, value in ipairs(tab) do
        if value == val then
            return i
        end
    end
    return -1
end

local function distributeRoles(targets, group)
    local roles = {}

    if group.single ~= nil then
        if #group.single > 0 then
            for _, className in ipairs(group.single) do 
                if #targets > 0 then    
                    local randomIndex = math.random(1, #targets)     
                    local target = targets[randomIndex]   
                    roles[target] = className
                    table.remove(targets, randomIndex)
                else
                    break
                end
            end
        end
    end

    if group.others ~= nil then
        if #group.others > 0 then
            while #targets > 0 do    
                for i, className in ipairs(group.others) do 
                    for j = 1, i do    
                        if #targets > 0 then  
                            local randomIndex = math.random(1, #targets)     
                            local target = targets[randomIndex]   
                            roles[target] = className
                            table.remove(targets, randomIndex)
                        else
                            break
                        end
                    end
                end
            end
        end
    end

    return roles
end

---@class CSM:CS.Akequ.Base.Room
CSM = {}

CSM.SM = nil
CSM.isRoundStarted = false
CSM.defaultGroups = {}
CSM.onCallGroups = {}
CSM.dt = dt
CSM.enabled = true

function CSM:Init()
    if self.main.netEvent.isServer then
        -- Чтение данных из json
        local groups = {Epsilon11 = Epsilon11Info, 
        DefaultCI = DefaultCIInfo}
        
        local file = io.open("groups.json", "r")
        if file then
            local content = file:read("*a")
            groups = mergeTables(groups, json.decode(content))
        end

        -- Разделение отрядов        
        for groupName, groupInfo in pairs(groups) do
            if groupInfo.isAutoSpawning then
                self.defaultGroups[groupName] = groupInfo
            else
                self.onCallGroups[groupName] = groupInfo
            end
        end

        -- Присваивание значений переменным
        self.SM = GameObject.FindObjectOfType(typeof(CS.SupportManager))
        self.SM.enabled = false
        self.timeToDefaultSpawn = math.random(CS.Config.GetInt("min_time_to_respawn", 6*60), CS.Config.GetInt("max_time_to_respawn", 7*60))

        -- Хуки
        CS.HookManager.Add("onRoundStart", function(obj)
            self:onRoundStarted()
        end)
        CS.HookManager.Add("onCSMSetActive", function(obj)
            self.enabled = obj[0]
        end)
    end
end

function CSM:Update()
    if not self.main.netEvent.isServer then return end
    if self.isRoundStarted and self.enabled then
        self.dt = self.dt - CS.UnityEngine.Time.deltaTime
        if self.dt <= 0 then
            self.dt = dt
            self:PluginUpdate()
        end
    end
end

-- SERVER
function CSM:PluginUpdate()
    if not self.isRoundStarted then return end
    
    self.timeToDefaultSpawn = self.timeToDefaultSpawn - dt
    if self.timeToDefaultSpawn <= 0 then
        self.timeToDefaultSpawn = math.random(CS.Config.GetInt("min_time_to_respawn", 360), CS.Config.GetInt("max_time_to_respawn", 420))
    
        local randomIndex = math.random(1, getLen(self.defaultGroups))

        local i = 1
        for groupName, _ in pairs(self.defaultGroups) do
            if i == randomIndex then
                self:Spawn(self.defaultGroups[groupName])
            end
            i = i + 1
        end
    end
end

function CSM:onRoundStarted()
    self.isRoundStarted = true

    CS.HookManager.Add("CSM_onSupportRequest", function(obj)
        local groupName = obj[0]
        if groupName ~= nil then
            if self.defaultGroups[groupName] ~= nil then
                if not self.enabled or CS.Config.GetInt("min_time_to_respawn", 6*60) - self.timeToDefaultSpawn > CS.Config.GetInt("add_time", 120) then    
                    self:Spawn(self.defaultGroups[groupName])
                    self.timeToDefaultSpawn = self.timeToDefaultSpawn + CS.Config.GetInt("add_time", 120)
                else
                    self.main:Invoke(function()
                        self:Spawn(self.defaultGroups[groupName])
                        self.timeToDefaultSpawn = self.timeToDefaultSpawn + CS.Config.GetInt("add_time", 120)
                    end, CS.Config.GetInt("add_time", 120))
                end
            elseif self.onCallGroups[groupName] ~= nil then
                if not self.enabled or CS.Config.GetInt("min_time_to_respawn", 6*60) - self.timeToDefaultSpawn > CS.Config.GetInt("add_time", 120) then    
                    self:Spawn(self.onCallGroups[groupName])
                    self.timeToDefaultSpawn = self.timeToDefaultSpawn + CS.Config.GetInt("add_time", 120)
                else
                    self.main:Invoke(function()
                        self:Spawn(self.onCallGroups[groupName])
                        self.timeToDefaultSpawn = self.timeToDefaultSpawn + CS.Config.GetInt("add_time", 120)
                    end, CS.Config.GetInt("add_time", 120))
                end
            end
        end
    end)
end

function CSM:Spawn(group)
    local time = 0
    local team = nil
    if group.transport ~= nil then    
        if group.transport == "helicopter" then    
            self.SM.enabled = true     
            team = "MTF"
            CS.HookManager.Run("onSupportRequest", team)
            time = mtfSpawnTime
        elseif group.transport == "car" then
            self.SM.enabled = true
            team = "CI"
            CS.HookManager.Run("onSupportRequest", team)
            time = ciSpawnTime
        end
    end

    self.main:Invoke(function() 
        local players = GameObject.FindObjectsByType(typeof(CS.Player), CS.UnityEngine.FindObjectsSortMode.None)
        local targets = {}

        for i = 0, players.Length - 1 do
            local player = players[i]

            if player.playerClass:GetType() == typeof(CS.Akequ.Classes.Spectator) then
                table.insert(targets, player)
            end
        end

        if #targets == 0 then
            CS.HookManager.Run("onSupportDeclined")
            return
        end

        local scps = self:getSCPs(players)

        local roles = distributeRoles(targets, group)

        for player, role in pairs(roles) do
            player:SetClass(role)
            if group.haveEquipment ~= nil then    
                if getIndex(group.haveEquipment, role) ~= -1 then
                    if getIndex(scps, "SCP-173") ~= -1 then   
                        player:GiveItem("SCP173CageBox")
                    end
                    if getIndex(scps, "SCP-096") ~= -1 then   
                        player:GiveItem("SCP096Bag")
                    end
                end
            end
        end

        if #scps > 0 then    
            if group.acesMessageWithSCP ~= nil then
                self:PlayACESMessage(group.acesMessageWithSCP, #scps)
            end
        else
            if group.acesMessageNoSCP ~= nil then
                self:PlayACESMessage(group.acesMessageNoSCP, #scps)
            end
        end

        if team ~= nil then    
            CS.HookManager.Run("onSupportSpawned", team)
        end
    end, time)

    self.main:Invoke(function()
        self.SM.enabled = false
    end, time + 5)
end

function CSM:getSCPs(players)
    local scps = {}
    
    for i = 0, players.Length - 1 do
        local player = players[i]
        local playerClass = player.playerClass
        
        if playerClass.GetTeamID and playerClass.GetName then
            local teamID = playerClass:GetTeamID()
            if teamID == "SCP" then
                table.insert(scps, playerClass:GetName())
            end
        end
    end
    
    return scps
end

function CSM:PlayACESMessage(message, scpCount)
    if not message then return end
    message = string.gsub(message, "{scpCount}", tostring(scpCount))
    if CS.ACES and CS.ACES.singleton then
        CS.ACES.singleton:AddPhraseToQueue(message, true, false, false, true)
    end
end

return CSM