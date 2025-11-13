return function()
    local ChromaticCrosshair = {}
    
    -- сервисы
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    
    -- кфг
    local Config = {
        Enabled = false,
        RotationSpeed = 0.05,
        UseRainbowColor = true,
        StaticColor = Color3.fromRGB(255, 0, 0),
        LineCount = 4,
        Radius = 7,
        LineLength = 15,
        Thickness = 2,
        DotRadius = 2,
        LabelText = "iinstality.xyz",
        LabelSize = 16,
        HideMouse = true
    }
    
    -- объекты прицела
    local CrosshairLines = {}
    local Dot, Label
    local connection
    local angle = 0
    
    local function getColor(timeOffset)
        if Config.UseRainbowColor then
            local hue = (tick() + timeOffset) % 5 / 5
            return Color3.fromHSV(hue, 1, 1)
        else
            return Config.StaticColor
        end
    end
    
    local function createDrawings()
        -- очистка старых
        destroyDrawings()
        
        for i = 1, Config.LineCount do
            local line = Drawing.new("Line")
            line.Thickness = Config.Thickness
            line.Visible = Config.Enabled
            table.insert(CrosshairLines, line)
        end

        Dot = Drawing.new("Circle")
        Dot.Radius = Config.DotRadius
        Dot.Filled = true
        Dot.Visible = Config.Enabled
        
        Label = Drawing.new("Text")
        Label.Text = Config.LabelText
        Label.Size = Config.LabelSize
        Label.Center = true
        Label.Outline = true
        Label.Visible = Config.Enabled
        Label.Font = 2
    end
    
    -- удаление Drawing
    local function destroyDrawings()
        for _, line in ipairs(CrosshairLines) do
            if line then
                line:Remove()
            end
        end
        CrosshairLines = {}
        
        if Dot then
            Dot:Remove()
            Dot = nil
        end
        
        if Label then
            Label:Remove()
            Label = nil
        end
    end
    
    -- управление видимости мыши
    local function updateMouseVisibility()
        if Config.HideMouse then
            UserInputService.MouseIconEnabled = not Config.Enabled
        else
            UserInputService.MouseIconEnabled = true
        end
    end
    
    -- цикл анимки
    local function startAnimation()
        if connection then
            connection:Disconnect()
        end
        
        connection = RunService.RenderStepped:Connect(function()
            if not Config.Enabled then return end
            
            local mousePos = UserInputService:GetMouseLocation()
            local center = Vector2.new(mousePos.X, mousePos.Y)
            local currentColor = getColor(0)
            
            -- обновление линий
            for i, line in ipairs(CrosshairLines) do
                local a = angle + (math.pi * 2 / Config.LineCount) * (i - 1)
                local from = Vector2.new(
                    center.X + math.cos(a) * Config.Radius,
                    center.Y + math.sin(a) * Config.Radius
                )
                local to = Vector2.new(
                    center.X + math.cos(a) * (Config.Radius + Config.LineLength),
                    center.Y + math.sin(a) * (Config.Radius + Config.LineLength)
                )
                line.From = from
                line.To = to
                line.Color = currentColor
                line.Visible = true
            end
            
            -- обновление точки
            Dot.Position = center
            Dot.Color = currentColor
            Dot.Visible = true
            
            -- обновление текста
            Label.Position = Vector2.new(center.X, center.Y + 25)
            Label.Color = currentColor
            Label.Visible = true
            
            angle += Config.RotationSpeed
        end)
    end
    
    local function stopAnimation()
        if connection then
            connection:Disconnect()
            connection = nil
        end
        
        -- скрыть все объекты
        for _, line in ipairs(CrosshairLines) do
            if line then
                line.Visible = false
            end
        end
        
        if Dot then
            Dot.Visible = false
        end
        
        if Label then
            Label.Visible = false
        end
        
        -- обратно мышку
        UserInputService.MouseIconEnabled = true
    end
    
    -- паблик методы
    function ChromaticCrosshair:Toggle(state)
        if state ~= nil then
            Config.Enabled = state
        else
            Config.Enabled = not Config.Enabled
        end
        
        if Config.Enabled then
            createDrawings()
            startAnimation()
            updateMouseVisibility()
        else
            stopAnimation()
            updateMouseVisibility()
        end
        
        return Config.Enabled
    end
    
    function ChromaticCrosshair:SetRotationSpeed(speed)
        Config.RotationSpeed = speed
    end
    
    function ChromaticCrosshair:SetRainbowMode(enabled)
        Config.UseRainbowColor = enabled
    end
    
    function ChromaticCrosshair:SetStaticColor(color)
        Config.StaticColor = color
    end
    
    function ChromaticCrosshair:SetLineCount(count)
        Config.LineCount = count
        if Config.Enabled then
            self:Toggle(false)
            self:Toggle(true)
        end
    end
    
    function ChromaticCrosshair:SetRadius(radius)
        Config.Radius = radius
    end
    
    function ChromaticCrosshair:SetLineLength(length)
        Config.LineLength = length
    end
    
    function ChromaticCrosshair:SetThickness(thickness)
        Config.Thickness = thickness
        if Config.Enabled then
            for _, line in ipairs(CrosshairLines) do
                line.Thickness = thickness
            end
        end
    end
    
    function ChromaticCrosshair:SetLabelText(text)
        Config.LabelText = text
        if Label then
            Label.Text = text
        end
    end
    
    function ChromaticCrosshair:SetHideMouse(hide)
        Config.HideMouse = hide
        updateMouseVisibility()
    end
    
    function ChromaticCrosshair:GetConfig()
        return table.clone(Config)
    end
    
    function ChromaticCrosshair:Destroy()
        stopAnimation()
        destroyDrawings()
        Config.Enabled = false
        updateMouseVisibility()
    end
    
    -- после респавна
    local function init()
        createDrawings()
        
        Players.LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.5)
            updateMouseVisibility()
        end)
    end
    
    init()
    
    return ChromaticCrosshair
end