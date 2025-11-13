if not game:IsLoaded() then 
    game.Loaded:Wait()
end

local SilentAim = {
    Enabled = false,
    TeamCheck = false,
    VisibleCheck = false,
    TargetPart = "HumanoidRootPart",
    FOVRadius = 130,
    HitChance = 100,
    ShowFOV = false,
    ShowSilentAimTarget = false
}

-- Сервисы
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- FOV Circle
local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1
fov_circle.NumSides = 100
fov_circle.Radius = SilentAim.FOVRadius
fov_circle.Filled = false
fov_circle.Visible = SilentAim.ShowFOV
fov_circle.Color = Color3.fromRGB(54, 57, 241)

-- Target Indicator (Vector drawings instead of image)
local target_circle = Drawing.new("Circle")
target_circle.Visible = false
target_circle.ZIndex = 999
target_circle.Radius = 12
target_circle.Thickness = 2
target_circle.Filled = false
target_circle.Color = Color3.fromRGB(255, 0, 0)

local target_cross1 = Drawing.new("Line")
target_cross1.Visible = false
target_cross1.ZIndex = 999
target_cross1.Thickness = 2
target_cross1.Color = Color3.fromRGB(255, 0, 0)

local target_cross2 = Drawing.new("Line")
target_cross2.Visible = false
target_cross2.ZIndex = 999
target_cross2.Thickness = 2
target_cross2.Color = Color3.fromRGB(255, 0, 0)

-- Вспомогательные функции
local function getMousePosition()
    return UserInputService:GetMouseLocation()
end

local function getPositionOnScreen(vector)
    local screenPos, onScreen = Camera:WorldToScreenPoint(vector)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

local function CalculateChance(percentage)
    percentage = math.floor(percentage)
    local chance = math.random(0, 100)
    return chance <= percentage
end

local function IsPlayerVisible(player)
    if not SilentAim.VisibleCheck then return true end
    
    local playerChar = player.Character
    local localChar = LocalPlayer.Character
    
    if not (playerChar and localChar) then return false end
    
    local playerRoot = playerChar:FindFirstChild("HumanoidRootPart")
    if not playerRoot then return false end
    
    local castPoints = {playerRoot.Position}
    local ignoreList = {localChar, playerChar}
    local obscuringObjects = #Camera:GetPartsObscuringTarget(castPoints, ignoreList)
    
    return obscuringObjects == 0
end

local function getClosestPlayer()
    if not SilentAim.TargetPart then return nil end
    
    local closestPlayer = nil
    local closestDistance = SilentAim.FOVRadius
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if SilentAim.TeamCheck and player.Team == LocalPlayer.Team then continue end
        
        local character = player.Character
        if not character then continue end
        
        if not IsPlayerVisible(player) then continue end
        
        local humanoid = character:FindFirstChild("Humanoid")
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        
        if not humanoid or not humanoidRootPart or humanoid.Health <= 0 then continue end
        
        local screenPos, onScreen = getPositionOnScreen(humanoidRootPart.Position)
        if not onScreen then continue end
        
        local mousePos = getMousePosition()
        local distance = (mousePos - screenPos).Magnitude
        
        if distance <= closestDistance then
            closestPlayer = {
                Part = character[SilentAim.TargetPart],
                Character = character,
                ScreenPosition = screenPos
            }
            closestDistance = distance
        end
    end
    
    return closestPlayer
end

-- Функция обновления индикатора цели
local function updateTargetIndicator(position, visible)
    target_circle.Visible = visible
    target_cross1.Visible = visible
    target_cross2.Visible = visible
    
    if visible and position then
        target_circle.Position = position
        
        -- Крест внутри круга
        local crossSize = 8
        target_cross1.From = Vector2.new(position.X - crossSize, position.Y - crossSize)
        target_cross1.To = Vector2.new(position.X + crossSize, position.Y + crossSize)
        
        target_cross2.From = Vector2.new(position.X + crossSize, position.Y - crossSize)
        target_cross2.To = Vector2.new(position.X - crossSize, position.Y + crossSize)
    end
end

-- Основной хук
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(...)
    local method = getnamecallmethod()
    local args = {...}
    local self = args[1]
    
    if SilentAim.Enabled and self == workspace and method == "Raycast" and CalculateChance(SilentAim.HitChance) then
        if #args >= 3 and typeof(args[2]) == "Vector3" and typeof(args[3]) == "Vector3" then
            local targetData = getClosestPlayer()
            if targetData and targetData.Part then
                local origin = args[2]
                local direction = (targetData.Part.Position - origin).Unit * 1000
                args[3] = direction
                return oldNamecall(unpack(args))
            end
        end
    end
    
    return oldNamecall(...)
end)

-- Обновление индикатора цели
RunService.RenderStepped:Connect(function()
    -- Обновление FOV круга
    if SilentAim.ShowFOV then
        fov_circle.Position = getMousePosition()
    end
    
    -- Обновление индикатора цели
    if SilentAim.ShowSilentAimTarget and SilentAim.Enabled then
        local targetData = getClosestPlayer()
        if targetData and targetData.Part then
            local screenPos, onScreen = getPositionOnScreen(targetData.Part.Position)
            if onScreen then
                updateTargetIndicator(screenPos, true)
            else
                updateTargetIndicator(nil, false)
            end
        else
            updateTargetIndicator(nil, false)
        end
    else
        updateTargetIndicator(nil, false)
    end
end)

-- Функции для управления настройками
function SilentAim:Toggle(state)
    if state ~= nil then
        self.Enabled = state
    else
        self.Enabled = not self.Enabled
    end
    
    -- Скрываем индикатор при выключении
    if not self.Enabled then
        updateTargetIndicator(nil, false)
    end
    
    return self.Enabled
end

function SilentAim:SetTeamCheck(state)
    self.TeamCheck = state
end

function SilentAim:SetVisibleCheck(state)
    self.VisibleCheck = state
end

function SilentAim:SetTargetPart(part)
    if part == "Head" or part == "HumanoidRootPart" then
        self.TargetPart = part
    end
end

function SilentAim:SetFOVRadius(radius)
    self.FOVRadius = radius
    fov_circle.Radius = radius
end

function SilentAim:SetHitChance(chance)
    self.HitChance = math.clamp(chance, 0, 100)
end

function SilentAim:SetShowFOV(state)
    self.ShowFOV = state
    fov_circle.Visible = state
end

function SilentAim:SetShowSilentAimTarget(state)
    self.ShowSilentAimTarget = state
    if not state then
        updateTargetIndicator(nil, false)
    end
end

function SilentAim:SetFOVColor(color)
    fov_circle.Color = color
end

function SilentAim:SetTargetColor(color)
    target_circle.Color = color
    target_cross1.Color = color
    target_cross2.Color = color
end

function SilentAim:SetTargetSize(size)
    if type(size) == "number" then
        target_circle.Radius = size
        local crossSize = size - 4
        -- Крест будет обновляться автоматически в updateTargetIndicator
    end
end

function SilentAim:SetTargetThickness(thickness)
    target_circle.Thickness = thickness
    target_cross1.Thickness = thickness
    target_cross2.Thickness = thickness
end

-- Горячие клавиши (опционально)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.RightAlt then
        SilentAim:Toggle()
    end
end)

-- Очистка при отключении
function SilentAim:Destroy()
    if fov_circle then
        fov_circle:Remove()
    end
    if target_circle then
        target_circle:Remove()
    end
    if target_cross1 then
        target_cross1:Remove()
    end
    if target_cross2 then
        target_cross2:Remove()
    end
    if oldNamecall then
        hookmetamethod(game, "__namecall", oldNamecall)
    end
end

-- Экспорт
return SilentAim
