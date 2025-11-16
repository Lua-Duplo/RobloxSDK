local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer

local DEFAULT_SOUND_ID = "97643101798871"
local currentSoundId = DEFAULT_SOUND_ID

local function setupDamageSoundSystem(character)
    local humanoid = character:WaitForChild("Humanoid")
    local lastHealth = humanoid.Health

    local function onHealthChanged(newHealth)
        if newHealth < lastHealth then
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://" .. currentSoundId
            sound.Volume = 0.5
            sound.Parent = SoundService
            sound:Play()
            
            game:GetService("Debris"):AddItem(sound, sound.TimeLength + 1)
        end
        lastHealth = newHealth
    end

    humanoid.HealthChanged:Connect(onHealthChanged)
end

local DamageSoundModule = {}

function DamageSoundModule.setSound(soundId)
    if soundId and tonumber(soundId) then
        currentSoundId = tostring(soundId)
        print("Damage sound changed to: " .. currentSoundId)
        return true
    else
        warn("Invalid sound ID: " .. tostring(soundId))
        return false
    end
end

function DamageSoundModule.resetSound()
    currentSoundId = DEFAULT_SOUND_ID
    print("Damage sound reset to default")
end

function DamageSoundModule.getCurrentSound()
    return currentSoundId
end

function DamageSoundModule.getDefaultSound()
    return DEFAULT_SOUND_ID
end

-- Initialize the system
function DamageSoundModule.init()
    -- Handle character respawn
    player.CharacterAdded:Connect(function(character)
        setupDamageSoundSystem(character)
    end)

    -- Handle initial character
    if player.Character then
        setupDamageSoundSystem(player.Character)
    end
    
    print("Damage sound system initialized")
end

return DamageSoundModule