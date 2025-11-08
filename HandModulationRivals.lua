local workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local LocalName = LocalPlayer.Name
local ViewModels = workspace:FindFirstChild("ViewModels") if not ViewModels then return end
local FirstPerson = ViewModels:FindFirstChild("FirstPerson") if not FirstPerson then return end


local currentMaterial = Enum.Material.Plastic
local currentColor = Color3.new(1, 1, 1)  -- Белый
local currentTransparency = 0

local function applyChanges()
    for _, obj in ipairs(FirstPerson:GetChildren()) do
        if string.sub(obj.Name, 1, #LocalName) == LocalName then
            local LeftArm = obj:FindFirstChild("LeftArm")
            local RightArm = obj:FindFirstChild("RightArm")

            if LeftArm and RightArm then
                for _, part in ipairs({LeftArm, RightArm}) do
                    local mesh = part:FindFirstChildOfClass("SpecialMesh") 
                    if mesh then mesh:Destroy() end
                    local texture = part:FindFirstChild("ShirtTexture") 
                    if texture then texture:Destroy() end
                    
                    part.Material = currentMaterial
                    part.Color = currentColor
                    part.Transparency = currentTransparency
                end
            end
            break
        end
    end
end

local function setMaterial(material)
    currentMaterial = material
    applyChanges()
end

local function setColor(color)
    currentColor = color
    applyChanges()
end

local function setTransparency(transparency)
    currentTransparency = transparency
    applyChanges()
end

RunService.Heartbeat:Connect(applyChanges)

return {
    setMaterial = setMaterial,
    setColor = setColor, 
    setTransparency = setTransparency
}
