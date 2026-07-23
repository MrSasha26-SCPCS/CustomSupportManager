-- Settings
local Epsilon11Info = {
    name = "<color=#0000BB>МОГ Epsilon-11</color>",
    team = "MTF"
}

local DefaultCIInfo = {
    name = "<color=#00BB00>Отряд Повстанцев Хаоса</color>",
    team = "ClassD"
}
--

local json = require "json"

local GameObject = CS.UnityEngine.GameObject
local UIManager = CS.UIManager

-- Local funcitons
local function mergeTables(t1, t2)
    for key, value in pairs(t2) do
        t1[key] = value
    end
    return t1
end

---@class CSM_AP:CS.Akequ.Base.AdminPanel
CSM_AP = {}

CSM_AP.groups = {}
CSM_AP.groupsNames = {}

function CSM_AP:Init()
    if self.main.adminPanel.isClient then    
        self.main:SendToServer("SendGroups")
    elseif self.main.adminPanel.isServer then
        self.groups = {Epsilon11 = Epsilon11Info, 
        DefaultCI = DefaultCIInfo}
        
        -- Import data
        local file = io.open("csm_sets.json", "r")
        if file then
            local content = file:read("*a")
            local importedTable = json.decode(content)
            if importedTable ~= nil then
                if importedTable.groups ~= nil then
                    self.groups = mergeTables(self.groups, importedTable.groups)
                end
            end
        end 

        for groupName, groupInfo in pairs(self.groups) do
            if groupInfo.name ~= nil then
                table.insert(self.groupsNames, groupInfo.name)
            end
        end
    end
end

function CSM_AP:GetName()
    return "CSM"
end

function CSM_AP:OnOpen()
    self.main.adminPanel:CreateHeader("Custom Support Manager")
    self.main.adminPanel:CreateHeader("ВКЛ/ВЫКЛ")
    local enable_btn = self.main.adminPanel:CreateButton("<color=green>Включить</color>")
    UIManager.BindAction(enable_btn:GetComponent(typeof(CS.UnityEngine.UI.Button)).onClick, function() self.main:SendToServer("CSMSetActive", true) end)
    local disable_btn = self.main.adminPanel:CreateButton("<color=red>Выключить</color>")
    UIManager.BindAction(disable_btn:GetComponent(typeof(CS.UnityEngine.UI.Button)).onClick, function() self.main:SendToServer("CSMSetActive", false) end)
    self.main.adminPanel:CreateHeader("Вызов группы")
    if self.groupsNames ~= nil then
        for _, groupName in pairs(self.groupsNames) do
            local groupCall_btn = self.main.adminPanel:CreateButton(groupName)
            UIManager.BindAction(groupCall_btn:GetComponent(typeof(CS.UnityEngine.UI.Button)).onClick, function() self.main:SendToServer("RequestSupport", groupName) end)
        end
    end
end

-- SERVER
function CSM_AP:CSMSetActive(status)
    CS.HookManager.Run("onCSMSetActive", status)
end

function CSM_AP:RequestSupport(gotGroupName, conn)
    for groupName, groupInfo in pairs(self.groups) do
        if groupInfo.name ~= nil then
            if groupInfo.name == gotGroupName then    
                CS.HookManager.Run("CSM_onSupportRequest", groupName)
                break
            end
        end
    end
end

function CSM_AP:SendGroups(conn)
    local groupsNames_str = ""
    for _, groupName in ipairs(self.groupsNames) do
        groupsNames_str = groupsNames_str .. groupName .. "|"
    end
    self.main:SendToClient("GetGroups", conn, groupsNames_str)
end

-- CLIENT
function CSM_AP:GetGroups(groupsNames_str)    
    local groupName = ""
    --                                                    чо это
    for s in string.gmatch(groupsNames_str, "[%z\1-\127\194-\244][\128-\191]*") do
        if s ~= "|" then    
            groupName = groupName .. s
        else
            table.insert(self.groupsNames, groupName)
            groupName = ""
        end
    end
end

return CSM_AP