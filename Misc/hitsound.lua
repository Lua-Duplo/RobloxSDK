local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local DEFAULT_SOUND_ID = "97643101798871"
local currentSoundId = DEFAULT_SOUND_ID

local function setupDamageSoundSystem(character)
    local humanoid = character:WaitForChild("Humanoid")
    
    local function playDamageSound()
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. currentSoundId
        sound.Volume = 0.5
        sound.Parent = SoundService
        sound:Play()
        
        game:GetService("Debris"):AddItem(sound, sound.TimeLength + 1)
    end

    local function setupRemoteListener()
        local damageEvent
        while not damageEvent do
            wait(1)
            for _, item in pairs(ReplicatedStorage:GetChildren()) do
                if item:IsA("RemoteEvent") and (
                    string.lower(item.Name):find("damage") or 
                    string.lower(item.Name):find("hit") or
                    string.lower(item.Name):find("attack")
                ) then
                    damageEvent = item
                    break
                end
            end
        end
        
        damageEvent.OnClientEvent:Connect(function(target, damage)
            if target and target:IsA("Model") then
                local targetHumanoid = target:FindFirstChild("Humanoid")
                if targetHumanoid and target ~= character then
                    playDamageSound()
                end
            end
        end)
    end

    local function setupToolListener()
        local function onChildAdded(child)
            if child:IsA("Tool") then
                child.Activated:Connect(function()
                    playDamageSound()
                end)
            end
        end
        
        character.ChildAdded:Connect(onChildAdded)
        
        for _, child in pairs(character:GetChildren()) do
            if child:IsA("Tool") then
                onChildAdded(child)
            end
        end
    end

    local function setupHumanoidListener()
        humanoid.GetPropertyChangedSignal("Health"):Connect(function()
            local recentDamage = humanoid:GetAttribute("LastDamageSource")
            if recentDamage and recentDamage == player then
                playDamageSound()
            end
        end)
    end

    coroutine.wrap(setupRemoteListener)()
    setupToolListener()
    setupHumanoidListener()
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

function DamageSoundModule.playSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. currentSoundId
    sound.Volume = 0.5
    sound.Parent = SoundService
    sound:Play()
    
    game:GetService("Debris"):AddItem(sound, sound.TimeLength + 1)
end

function DamageSoundModule.init()
    player.CharacterAdded:Connect(function(character)
        setupDamageSoundSystem(character)
    end)

    if player.Character then
        setupDamageSoundSystem(player.Character)
    end
    
    print("Damage sound system initialized - will play when dealing damage to others")
end

return DamageSoundModule
