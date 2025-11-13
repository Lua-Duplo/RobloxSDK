local function CreateChromaticCrosshair()
    local ChromaticCrosshair = {}
    
    -- Сервисы
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    
    -- Конфигурация по умолчанию
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
        LabelText = "CHROMATIC",
        LabelSize = 16,
        HideMouse = true
    }
    
    -- Объекты прицела
    local CrosshairLines = {}
    local Dot, Label
    local connection
    local angle = 0
    
    -- Функция для получения цвета
    local function getColor(timeOffset)
        if Config.UseRainbowColor then
            local hue = (tick() + timeOffset) % 5 / 5
            return Color3.fromHSV(hue, 1, 1)
        else
            return Config.StaticColor
        end
    end
    
    -- Создание объектов Drawing
    local function createDrawings()
        -- Очистка старых объектов
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
        
        -- Создание линий
        for i = 1, Config.LineCount do
            local line = Drawing.new("Line")
            line.Thickness = Config.Thickness
            line.Visible = Config.Enabled
            table.insert(CrosshairLines, line)
        end
        
        -- Создание точки
        Dot = Drawing.new("Circle")
        Dot.Radius = Config.DotRadius
        Dot.Filled = true
        Dot.Visible = Config.Enabled
        
        -- Создание текста
        Label = Drawing.new("Text")
        Label.Text = Config.LabelText
        Label.Size = Config.LabelSize
        Label.Center = true
        Label.Outline = true
        Label.Visible = Config.Enabled
        Label.Font = 2
    end
    
    -- Управление видимостью мыши
    local function updateMouseVisibility()
        UserInputService.MouseIconEnabled = not (Config.Enabled and Config.HideMouse)
    end
    
    -- Основной цикл анимации
    local function startAnimation()
        if connection then
            connection:Disconnect()
        end
        
        connection = RunService.RenderStepped:Connect(function()
            if not Config.Enabled then return end
            
            local mousePos = UserInputService:GetMouseLocation()
            local center = Vector2.new(mousePos.X, mousePos.Y)
            local currentColor = getColor(0)
            
            -- Обновление линий прицела
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
            
            -- Обновление точки
            if Dot then
                Dot.Position = center
                Dot.Color = currentColor
                Dot.Visible = true
            end
            
            -- Обновление текста
            if Label then
                Label.Position = Vector2.new(center.X, center.Y + 25)
                Label.Color = currentColor
                Label.Visible = true
            end
            
            angle += Config.RotationSpeed
        end)
    end
    
    -- Остановка анимации
    local function stopAnimation()
        if connection then
            connection:Disconnect()
            connection = nil
        end
        
        -- Скрываем все объекты
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
        
        -- Восстанавливаем курсор мыши
        UserInputService.MouseIconEnabled = true
    end
    
    -- Публичные методы
    function ChromaticCrosshair:Toggle(state)
        if state ~= nil then
            Config.Enabled = state
        else
            Config.Enabled = not Config.Enabled
        end
        
        if Config.Enabled then
            createDrawings()
            startAnimation()
        else
            stopAnimation()
        end
        updateMouseVisibility()
        
        return Config.Enabled
    end
    
    function ChromaticCrosshair:SetRotationSpeed(speed)
        Config.RotationSpeed = speed or 0.05
    end
    
    function ChromaticCrosshair:SetRainbowMode(enabled)
        Config.UseRainbowColor = enabled
    end
    
    function ChromaticCrosshair:SetStaticColor(color)
        if color then
            Config.StaticColor = color
        end
    end
    
    function ChromaticCrosshair:SetLineCount(count)
        if count and count > 0 then
            Config.LineCount = count
            if Config.Enabled then
                self:Toggle(false)
                self:Toggle(true)
            end
        end
    end
    
    function ChromaticCrosshair:SetRadius(radius)
        if radius then
            Config.Radius = radius
        end
    end
    
    function ChromaticCrosshair:SetLineLength(length)
        if length then
            Config.LineLength = length
        end
    end
    
    function ChromaticCrosshair:SetThickness(thickness)
        if thickness then
            Config.Thickness = thickness
            if Config.Enabled then
                for _, line in ipairs(CrosshairLines) do
                    if line then
                        line.Thickness = thickness
                    end
                end
            end
        end
    end
    
    function ChromaticCrosshair:SetLabelText(text)
        if text then
            Config.LabelText = text
            if Label then
                Label.Text = text
            end
        end
    end
    
    function ChromaticCrosshair:SetHideMouse(hide)
        Config.HideMouse = hide
        updateMouseVisibility()
    end
    
    function ChromaticCrosshair:GetConfig()
        local configCopy = {}
        for k, v in pairs(Config) do
            configCopy[k] = v
        end
        return configCopy
    end
    
    function ChromaticCrosshair:Destroy()
        stopAnimation()
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
        
        Config.Enabled = false
        UserInputService.MouseIconEnabled = true
    end
    
    -- Инициализация
    createDrawings()
    
    -- Обработчик респавна
    Players.LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        updateMouseVisibility()
    end)
    
    return ChromaticCrosshair
end

return CreateChromaticCrosshair
