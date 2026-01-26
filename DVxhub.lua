--==================================================
-- Load WindUI
--==================================================
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

--==================================================
-- Services
--==================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--==================================================
-- Window
--==================================================
local Window = WindUI:CreateWindow({
    Title = "DVX Hub",
    Author = "DVX",
    Folder = "DVX Hub"
})

local TabPlayer = Window:Tab({ Title = "Player", Icon = "person" })
local TabTP     = Window:Tab({ Title = "Teleport", Icon = "location" })
local TabESP    = Window:Tab({ Title = "ESP", Icon = "eye" })

--==================================================
-- ESP SYSTEM
--==================================================
local ESP = {
    Wall   = false,
    Name   = false,
    Tracer = false
}

local ESPColor = Color3.fromRGB(255,60,60)
local ESPObjects = {}

local function ClearESP(plr)
    if ESPObjects[plr] then
        for _,v in pairs(ESPObjects[plr]) do
            if typeof(v) == "RBXScriptConnection" then
                v:Disconnect()
            elseif v and v.Destroy then
                v:Destroy()
            elseif v and v.Remove then
                v:Remove()
            end
        end
        ESPObjects[plr] = nil
    end
end

local function CreateESP(plr, char)
    if plr == LP or not char then return end
    ClearESP(plr)

    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not hrp or not head then return end

    local objs = {}

    -- Wall ESP
    if ESP.Wall then
        local hl = Instance.new("Highlight")
        hl.FillColor = ESPColor
        hl.OutlineColor = ESPColor
        hl.FillTransparency = 0.6
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = char
        hl.Parent = Workspace
        objs.Highlight = hl
    end

    -- Name + Distance
    local txt
    if ESP.Name then
        local gui = Instance.new("BillboardGui")
        gui.Adornee = head
        gui.Size = UDim2.new(0,180,0,28)
        gui.StudsOffset = Vector3.new(0,2.7,0)
        gui.AlwaysOnTop = true
        gui.MaxDistance = math.huge

        txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1,0,1,0)
        txt.BackgroundTransparency = 1
        txt.TextColor3 = ESPColor
        txt.TextStrokeTransparency = 0.25
        txt.TextSize = 14
        txt.Font = Enum.Font.GothamBold
        txt.Parent = gui

        gui.Parent = head
        objs.NameTag = gui
    end

    -- Tracer
    local line
    if ESP.Tracer then
        line = Drawing.new("Line")
        line.Color = ESPColor
        line.Thickness = 1
        line.Transparency = 1
        objs.Tracer = line
    end

    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not hrp.Parent or not LP.Character then
            ClearESP(plr)
            conn:Disconnect()
            return
        end

        local myHRP = LP.Character:FindFirstChild("HumanoidRootPart")
        if myHRP and txt then
            local dist = math.floor((myHRP.Position - hrp.Position).Magnitude)
            txt.Text = plr.Name .. " [" .. dist .. "]"
        end

        if line then
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            line.Visible = onScreen
            if onScreen then
                line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                line.To   = Vector2.new(pos.X, pos.Y)
            end
        end
    end)

    objs.Connection = conn
    ESPObjects[plr] = objs
end

local function RefreshESP()
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            CreateESP(p, p.Character)
        end
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        if ESP.Wall or ESP.Name or ESP.Tracer then
            CreateESP(p, char)
        end
    end)
end)

Players.PlayerRemoving:Connect(ClearESP)

--================ ESP UI =================
TabESP:Toggle({
    Title = "ESP Wall (Highlight)",
    Callback = function(v)
        ESP.Wall = v
        RefreshESP()
    end
})

TabESP:Toggle({
    Title = "ESP Name + Distance",
    Callback = function(v)
        ESP.Name = v
        RefreshESP()
    end
})

TabESP:Toggle({
    Title = "ESP Tracer Line",
    Callback = function(v)
        ESP.Tracer = v
        RefreshESP()
    end
})

--==================================================
-- PLAYER
--==================================================
TabPlayer:Slider({
    Title = "WalkSpeed",
    Value = {Min=16, Max=700, Default=16},
    Callback = function(v)
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = v end
    end
})

TabPlayer:Slider({
    Title = "JumpPower",
    Value = {Min=50, Max=500, Default=50},
    Callback = function(v)
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then
            h.UseJumpPower = true
            h.JumpPower = v
        end
    end
})

local noclip = false
TabPlayer:Toggle({
    Title = "Noclip",
    Callback = function(v)
        noclip = v
    end
})

RunService.Stepped:Connect(function()
    if noclip and LP.Character then
        for _,p in ipairs(LP.Character:GetChildren()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end
end)

--==================================================
-- TELEPORT / SPECTATE
--==================================================
local target
local spectating = false

local function PlayerList()
    local t = {}
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(t, p.Name) end
    end
    return t
end

local Drop = TabTP:Dropdown({
    Title = "Select Player",
    Options = PlayerList(),
    Callback = function(v)
        target = Players:FindFirstChild(v)
    end
})

TabTP:Button({
    Title = "Teleport",
    Callback = function()
        if not target or not target.Character then return end
        local r1 = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local r2 = target.Character:FindFirstChild("HumanoidRootPart")
        if r1 and r2 then
            r1.CFrame = r2.CFrame * CFrame.new(0,3,0)
        end
    end
})

TabTP:Button({
    Title = "Spectate",
    Callback = function()
        if not target or not target.Character then return end
        local hum = target.Character:FindFirstChildOfClass("Humanoid")
        local myHum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if not hum or not myHum then return end
        spectating = not spectating
        Camera.CameraSubject = spectating and hum or myHum
    end
})

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    Drop:Refresh(PlayerList(), true)
end)

Players.PlayerRemoving:Connect(function()
    task.wait(0.5)
    Drop:Refresh(PlayerList(), true)
end)
