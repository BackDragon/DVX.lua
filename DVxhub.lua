-- Load WindUI
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Window
local Window = WindUI:CreateWindow({
    Title = "DVX hub",
    Author = "Dvx",
    Folder = "DVX Hub"
})

-- Tabs
local TabPlayer = Window:Tab({ Title = "Player", Icon = "person" })
local TabTP     = Window:Tab({ Title = "Teleport", Icon = "location" })
local TabESP    = Window:Tab({ Title = "ESP", Icon = "eye" })

-------------------------------------------------
-- ESP
-------------------------------------------------
local ESPEnabled, NameTagEnabled = false, false
local ESPObjects = {}
local ESPColor = Color3.fromRGB(255,60,60)

local function CreateESP(plr)
    if not plr.Character then return end
    if ESPObjects[plr] then return end

    local h = Instance.new("Highlight")
    h.FillColor = ESPColor
    h.FillTransparency = 0.5
    h.OutlineTransparency = 0.25
    h.Adornee = plr.Character
    h.Parent = Workspace
    ESPObjects[plr] = {Highlight = h}
end

local function RemoveESP(plr)
    if ESPObjects[plr] then
        for _,v in pairs(ESPObjects[plr]) do v:Destroy() end
        ESPObjects[plr] = nil
    end
end

TabESP:Toggle({
    Title = "ESP Player",
    Callback = function(v)
        ESPEnabled = v
        for _,p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                if v then CreateESP(p) else RemoveESP(p) end
            end
        end
    end
})

Players.PlayerAdded:Connect(function(p)
    task.wait(1)
    if ESPEnabled then CreateESP(p) end
end)
Players.PlayerRemoving:Connect(RemoveESP)

-------------------------------------------------
-- PLAYER
-------------------------------------------------
TabPlayer:Slider({
    Title = "WalkSpeed",
    Value = {Min = 16, Max = 700, Default = 16},
    Callback = function(v)
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = v end
    end
})

TabPlayer:Slider({
    Title = "JumpPower",
    Value = {Min = 50, Max = 500, Default = 50},
    Callback = function(v)
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then
            h.UseJumpPower = true
            h.JumpPower = v
        end
    end
})

-- Noclip
local noclip = false
TabPlayer:Toggle({
    Title = "Noclip",
    Callback = function(v)
        noclip = v
    end
})

RunService.Stepped:Connect(function()
    if noclip and LP.Character then
        for _,p in pairs(LP.Character:GetChildren()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

-- FullBright
local fbConn
TabPlayer:Toggle({
    Title = "FullBright",
    Callback = function(v)
        if v then
            fbConn = RunService.RenderStepped:Connect(function()
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogEnd = 1e10
                Lighting.GlobalShadows = false
            end)
        else
            if fbConn then fbConn:Disconnect() end
            Lighting.GlobalShadows = true
        end
    end
})

-- Fly (โหลดสคริปต์เดิม)
TabPlayer:Button({
    Title = "Fly",
    Callback = function()
        loadstring("\108\111\97\100\115\116\114\105\110\103\40\103\97\109\101\58\72\116\116\112\71\101\116\40\40\39\104\116\116\112\115\58\47\47\103\105\115\116\46\103\105\116\104\117\98\117\115\101\114\99\111\110\116\101\110\116\46\99\111\109\47\109\101\111\122\111\110\101\89\84\47\98\102\48\51\55\100\102\102\57\102\48\97\55\48\48\49\55\51\48\52\100\100\100\54\55\102\100\99\100\51\55\48\47\114\97\119\47\101\49\52\101\55\52\102\52\50\53\98\48\54\48\100\102\53\50\51\51\52\51\99\102\51\48\98\55\56\55\48\55\52\101\98\51\99\53\100\50\47\97\114\99\101\117\115\37\50\53\50\48\120\37\50\53\50\48\102\108\121\37\50\53\50\48\50\37\50\53\50\48\111\98\102\108\117\99\97\116\111\114\39\41\44\116\114\117\101\41\41\40\41")()
    end
})

-------------------------------------------------
-- TP / SPECTATE
-------------------------------------------------
local target, spectate = nil, false

local function PlayerList()
    local t = {}
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(t, p.Name) end
    end
    return t
end

local Drop = TabTP:Dropdown({
    Title = "Select Player",
    Options = PlayerList(),
    Callback = function(v)
        target = Players:FindFirstChild(v[1])
    end
})

TabTP:Button({
    Title = "Teleport",
    Callback = function()
        if not target then return end
        local r1 = LP.Character:FindFirstChild("HumanoidRootPart")
        local r2 = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if r1 and r2 then
            r1.CFrame = r2.CFrame + Vector3.new(0,3,0)
        end
    end
})

TabTP:Button({
    Title = "Spectate",
    Callback = function()
        if not target then return end
        spectate = not spectate
        Camera.CameraSubject = spectate and target.Character:WaitForChild("Humanoid")
            or LP.Character:WaitForChild("Humanoid")
    end
})

Players.PlayerAdded:Connect(function()
    task.wait(1)
    Drop:Refresh(PlayerList(), true)
end)
Players.PlayerRemoving:Connect(function()
    task.wait(1)
    Drop:Refresh(PlayerList(), true)
end)
