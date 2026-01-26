
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera


-- Window
local Window = WindUI:CreateWindow({
    Title = "DVX Hub",
    Author = "DVX",
    Folder = "DVX Hub"
})

local TabPlayer = Window:Tab({ Title = "Player"})
local TabTP     = Window:Tab({ Title = "Teleport"})
local TabESP    = Window:Tab({ Title = "ESP"})

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
    Title = "ESP สี",
    Callback = function(v)
        ESP.Wall = v
        RefreshESP()
    end
})

TabESP:Toggle({
    Title = "ESP ชื่อ+ระยะ",
    Callback = function(v)
        ESP.Name = v
        RefreshESP()
    end
})

TabESP:Toggle({
    Title = "ESP เว้นชี้ตำแหน่ง",
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

TabPlayer:Button({
    Title = "Fly",
    Callback = function()
        loadstring("\108\111\97\100\115\116\114\105\110\103\40\103\97\109\101\58\72\116\116\112\71\101\116\40\40\39\104\116\116\112\115\58\47\47\103\105\115\116\46\103\105\116\104\117\98\117\115\101\114\99\111\110\116\101\110\116\46\99\111\109\47\109\101\111\122\111\110\101\89\84\47\98\102\48\51\55\100\102\102\57\102\48\97\55\48\48\49\55\51\48\52\100\100\100\54\55\102\100\99\100\51\55\48\47\114\97\119\47\101\49\52\101\55\52\102\52\50\53\98\48\54\48\100\102\53\50\51\51\52\51\99\102\51\48\98\55\56\55\48\55\52\101\98\51\99\53\100\50\47\97\114\99\101\117\115\37\50\53\50\48\120\37\50\53\50\48\102\108\121\37\50\53\50\48\50\37\50\53\50\48\111\98\102\108\117\99\97\116\111\114\39\41\44\116\114\117\101\41\41\40\41")()
    end
})


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
