local workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local LocalName = LocalPlayer.Name
local ViewModels = workspace:FindFirstChild("ViewModels") if not ViewModels then return end
local FirstPerson = ViewModels:FindFirstChild("FirstPerson") if not FirstPerson then return end
local currentMaterial, currentColor, currentTransparency

local function applyChanges()
    if not currentMaterial then return end -- wait for call function updateHands

    for _, obj in ipairs(FirstPerson:GetChildren()) do
        if string.sub(obj.Name, 1, #LocalName) == LocalName then
            local LeftArm = obj:FindFirstChild("LeftArm")
            local RightArm = obj:FindFirstChild("RightArm")

            if LeftArm and RightArm then
                for _, part in ipairs({LeftArm, RightArm}) do
                    local mesh = part:FindFirstChildOfClass("SpecialMesh") if mesh then mesh:Destroy() end
                    local texture = part:FindFirstChild("ShirtTexture") if texture then texture:Destroy() end
                    part.Material = currentMaterial
                    part.Color = currentColor
                    part.Transparency = currentTransparency
                end
            end
            break -- only first founded
        end
    end
end

local function updateHands(material, color, transparency)
    currentMaterial = material
    currentColor = color
    currentTransparency = transparency
end
RunService.Heartbeat:Connect(applyChanges)
return {
    updateHands = updateHands,
    applyChanges = applyChanges
}
--updateHands(Enum.Material.Neon, Color3.new(1, 0, 0), 0.5)
