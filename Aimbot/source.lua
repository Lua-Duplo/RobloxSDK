local SilentAimSettings = {
    Enabled = false,
    
    TeamCheck = false,
    VisibleCheck = false, 
    TargetPart = "HumanoidRootPart",
    
    FOVRadius = 130,
    FOVVisible = false,
    ShowSilentAimTarget = false,
    ShowTargetColor = Color3.fromRGB(54, 57, 241),
    
    MouseHitPrediction = false,
    MouseHitPredictionAmount = 0.165,
    HitChance = 100
}

-- variables
getgenv().SilentAimSettings = SilentAimSettings

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local WorldToScreen = Camera.WorldToScreenPoint
local WorldToViewportPoint = Camera.WorldToViewportPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local FindFirstChild = game.FindFirstChild
local RenderStepped = RunService.RenderStepped
local GetMouseLocation = UserInputService.GetMouseLocation

local resume = coroutine.resume 
local create = coroutine.create

local ValidTargetParts = {"Head", "HumanoidRootPart"}
local PredictionAmount = 0.165

-- Drawing objects
local mouse_box = Drawing.new("Square")
mouse_box.Visible = false
mouse_box.ZIndex = 999 
mouse_box.Color = SilentAimSettings.ShowTargetColor
mouse_box.Thickness = 20 
mouse_box.Size = Vector2.new(20, 20)
mouse_box.Filled = true 

local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1
fov_circle.NumSides = 100
fov_circle.Radius = SilentAimSettings.FOVRadius
fov_circle.Filled = false
fov_circle.Visible = SilentAimSettings.FOVVisible
fov_circle.ZIndex = 999
fov_circle.Transparency = 1
fov_circle.Color = Color3.fromRGB(54, 57, 241)

-- Configuration functions
local UniversalSilentAim = {}

function UniversalSilentAim:Toggle(state)
    SilentAimSettings.Enabled = state
    mouse_box.Visible = state and SilentAimSettings.ShowSilentAimTarget
end

function UniversalSilentAim:SetTeamCheck(state)
    SilentAimSettings.TeamCheck = state
end

function UniversalSilentAim:SetVisibleCheck(state)
    SilentAimSettings.VisibleCheck = state
end

function UniversalSilentAim:SetTargetPart(part)
    if table.find(ValidTargetParts, part) or part == "Random" then
        SilentAimSettings.TargetPart = part
    end
end

function UniversalSilentAim:SetHitChance(chance)
    SilentAimSettings.HitChance = math.clamp(chance, 0, 100)
end

function UniversalSilentAim:SetFOVVisible(state)
    SilentAimSettings.FOVVisible = state
    fov_circle.Visible = state
end

function UniversalSilentAim:SetFOVRadius(radius)
    SilentAimSettings.FOVRadius = radius
    fov_circle.Radius = radius
end

function UniversalSilentAim:SetShowTarget(state)
    SilentAimSettings.ShowSilentAimTarget = state
    mouse_box.Visible = state and SilentAimSettings.Enabled
end

function UniversalSilentAim:SetShowTargetColor(color)
    SilentAimSettings.ShowTargetColor = color
    mouse_box.Color = color
end

function UniversalSilentAim:SetPrediction(state)
    SilentAimSettings.MouseHitPrediction = state
end

function UniversalSilentAim:SetPredictionAmount(amount)
    SilentAimSettings.MouseHitPredictionAmount = amount
    PredictionAmount = amount
end

function UniversalSilentAim:GetSettings()
    return SilentAimSettings
end

function UniversalSilentAim:LoadSettings(settings)
    for key, value in pairs(settings) do
        if SilentAimSettings[key] ~= nil then
            SilentAimSettings[key] = value
        end
    end
    
    -- Update visual elements
    fov_circle.Radius = SilentAimSettings.FOVRadius
    fov_circle.Visible = SilentAimSettings.FOVVisible
    mouse_box.Color = SilentAimSettings.ShowTargetColor
    mouse_box.Visible = SilentAimSettings.Enabled and SilentAimSettings.ShowSilentAimTarget
    PredictionAmount = SilentAimSettings.MouseHitPredictionAmount
end

-- Export functions to global scope
getgenv().UniversalSilentAim = UniversalSilentAim

-- Utility functions
function CalculateChance(Percentage)
    Percentage = math.floor(Percentage)
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100
    return chance <= Percentage / 100
end

function getPositionOnScreen(Vector)
    local Vec3, OnScreen = WorldToScreen(Camera, Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

function getMousePosition()
    return GetMouseLocation(UserInputService)
end

function IsPlayerVisible(Player)
    local PlayerCharacter = Player.Character
    local LocalPlayerCharacter = LocalPlayer.Character
    
    if not (PlayerCharacter or LocalPlayerCharacter) then return end 
    
    local PlayerRoot = FindFirstChild(PlayerCharacter, SilentAimSettings.TargetPart) or FindFirstChild(PlayerCharacter, "HumanoidRootPart")
    
    if not PlayerRoot then return end 
    
    local CastPoints, IgnoreList = {PlayerRoot.Position, LocalPlayerCharacter, PlayerCharacter}, {LocalPlayerCharacter, PlayerCharacter}
    local ObscuringObjects = #GetPartsObscuringTarget(Camera, CastPoints, IgnoreList)
    
    return ((ObscuringObjects == 0 and true) or (ObscuringObjects > 0 and false))
end

function getClosestPlayer()
    if not SilentAimSettings.TargetPart then return end
    local Closest
    local DistanceToMouse
    for _, Player in next, Players:GetPlayers() do
        if Player == LocalPlayer then continue end
        if SilentAimSettings.TeamCheck and Player.Team == LocalPlayer.Team then continue end

        local Character = Player.Character
        if not Character then continue end
        
        if SilentAimSettings.VisibleCheck and not IsPlayerVisible(Player) then continue end

        local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
        local Humanoid = FindFirstChild(Character, "Humanoid")
        if not HumanoidRootPart or not Humanoid or Humanoid and Humanoid.Health <= 0 then continue end

        local ScreenPosition, OnScreen = getPositionOnScreen(HumanoidRootPart.Position)
        if not OnScreen then continue end

        local Distance = (getMousePosition() - ScreenPosition).Magnitude
        if Distance <= (DistanceToMouse or SilentAimSettings.FOVRadius or 2000) then
            Closest = ((SilentAimSettings.TargetPart == "Random" and Character[ValidTargetParts[math.random(1, #ValidTargetParts)]]) or Character[SilentAimSettings.TargetPart])
            DistanceToMouse = Distance
        end
    end
    return Closest
end

-- Render loop
resume(create(function()
    RenderStepped:Connect(function()
        if SilentAimSettings.ShowSilentAimTarget and SilentAimSettings.Enabled then
            if getClosestPlayer() then 
                local Root = getClosestPlayer().Parent.PrimaryPart or getClosestPlayer()
                local RootToViewportPoint, IsOnScreen = WorldToViewportPoint(Camera, Root.Position);
                
                mouse_box.Visible = IsOnScreen
                mouse_box.Position = Vector2.new(RootToViewportPoint.X, RootToViewportPoint.Y)
            else 
                mouse_box.Visible = false 
                mouse_box.Position = Vector2.new()
            end
        end
        
        if SilentAimSettings.FOVVisible then 
            fov_circle.Position = getMousePosition()
        end
    end)
end))

-- Hooks
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    local self = Arguments[1]
    local chance = CalculateChance(SilentAimSettings.HitChance)
    
    if SilentAimSettings.Enabled and self == workspace and not checkcaller() and chance == true and Method == "Raycast" then
        local A_Origin = Arguments[2]

        local HitPart = getClosestPlayer()
        if HitPart then
            Arguments[3] = getDirection(A_Origin, HitPart.Position)
            return oldNamecall(unpack(Arguments))
        end
    end

    return oldNamecall(...)
end))

local oldIndex = nil 
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, Index)
    if self == Mouse and not checkcaller() and SilentAimSettings.Enabled and getClosestPlayer() then
        local HitPart = getClosestPlayer()
         
        if Index == "Target" or Index == "target" then 
            return HitPart
        elseif Index == "Hit" or Index == "hit" then 
            return ((SilentAimSettings.MouseHitPrediction and (HitPart.CFrame + (HitPart.Velocity * PredictionAmount))) or (not SilentAimSettings.MouseHitPrediction and HitPart.CFrame))
        end
    end

    return oldIndex(self, Index)
end))

return UniversalSilentAim
