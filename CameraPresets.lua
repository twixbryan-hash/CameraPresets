--[[
    CAMERA PRESETS v2
    Menu flutuante + Interface melhorada
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- ==================== CONFIG ====================
local CONFIG = {
    Theme = {
        Background = Color3.fromRGB(16, 16, 20),
        Card = Color3.fromRGB(26, 26, 32),
        CardHover = Color3.fromRGB(34, 34, 42),
        Accent = Color3.fromRGB(0, 190, 255),
        AccentDark = Color3.fromRGB(0, 130, 190),
        TextPrimary = Color3.fromRGB(245, 245, 250),
        TextSecondary = Color3.fromRGB(155, 155, 165),
        Success = Color3.fromRGB(70, 220, 130),
        Danger = Color3.fromRGB(255, 75, 75),
        Border = Color3.fromRGB(45, 45, 55),
    },
    BaseSize = UDim2.new(0, 340, 0, 540),
    MobileScale = 0.90,
    CornerRadius = 16,
    ButtonRadius = 9,
    DefaultDuration = 1.2,
    MinDuration = 0.1,
    MaxDuration = 8.0,
}

local Presets = {[1]=nil,[2]=nil,[3]=nil,[4]=nil,[5]=nil}
local CurrentTween, CurrentFOVTween = nil, nil
local IsSmooth = true
local TransitionDuration = CONFIG.DefaultDuration
local IsDraggingMain = false
local IsDraggingFloat = false
local DragStart, FrameStart = nil, nil
local UIVisible = true
local IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local ScreenGui, MainFrame, FloatBtn
local Cards = {}
local SmoothBtn, InstantBtn, DurationBox, ResetBtn

-- ==================== FUNÇÕES AUXILIARES ====================
local function CreateCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or CONFIG.CornerRadius)
    c.Parent = parent
end

local function CreateStroke(parent, thickness)
    local s = Instance.new("UIStroke")
    s.Color = CONFIG.Theme.Border
    s.Thickness = thickness or 1
    s.Transparency = 0.35
    s.Parent = parent
end

local function CreateButton(text, color, size)
    local btn = Instance.new("TextButton")
    btn.Text = text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextColor3 = CONFIG.Theme.TextPrimary
    btn.BackgroundColor3 = color or CONFIG.Theme.Card
    btn.Size = size or UDim2.new(0, 90, 0, 34)
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    CreateCorner(btn, CONFIG.ButtonRadius)
    CreateStroke(btn)
    return btn
end

-- ==================== INTERFACE ====================
local function BuildUI()
    if PlayerGui:FindFirstChild("CameraPresetsUI") then
        PlayerGui.CameraPresetsUI:Destroy()
    end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CameraPresetsUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = PlayerGui

    -- ===== BOTÃO FLUTUANTE =====
    FloatBtn = Instance.new("TextButton")
    FloatBtn.Name = "FloatButton"
    FloatBtn.Size = UDim2.new(0, 54, 0, 54)
    FloatBtn.Position = UDim2.new(1, -70, 0.5, -27)
    FloatBtn.BackgroundColor3 = CONFIG.Theme.Accent
    FloatBtn.Text = "CAM"
    FloatBtn.Font = Enum.Font.GothamBold
    FloatBtn.TextSize = 14
    FloatBtn.TextColor3 = Color3.new(1,1,1)
    FloatBtn.AutoButtonColor = false
    FloatBtn.BorderSizePixel = 0
    FloatBtn.Parent = ScreenGui
    CreateCorner(FloatBtn, 27)
    CreateStroke(FloatBtn, 1.5)

    -- ===== FRAME PRINCIPAL =====
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "Main"
    MainFrame.Size = CONFIG.BaseSize
    MainFrame.Position = UDim2.new(0.5, -CONFIG.BaseSize.X.Offset/2, 0.5, -CONFIG.BaseSize.Y.Offset/2)
    MainFrame.BackgroundColor3 = CONFIG.Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Visible = true
    MainFrame.Parent = ScreenGui
    CreateCorner(MainFrame)
    CreateStroke(MainFrame, 1.5)

    if IsMobile then
        local scale = CONFIG.MobileScale
        MainFrame.Size = UDim2.new(0, CONFIG.BaseSize.X.Offset * scale, 0, CONFIG.BaseSize.Y.Offset * scale)
        MainFrame.Position = UDim2.new(0.5, -MainFrame.Size.X.Offset/2, 0.1, 0)
    end

    -- Título
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 28)
    title.Position = UDim2.new(0, 14, 0, 12)
    title.BackgroundTransparency = 1
    title.Text = "CAMERA PRESETS"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = CONFIG.Theme.TextPrimary
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = MainFrame

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -20, 0, 18)
    subtitle.Position = UDim2.new(0, 14, 0, 36)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "5 posições de câmera"
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 13
    subtitle.TextColor3 = CONFIG.Theme.TextSecondary
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = MainFrame

    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, -28, 0, 1)
    sep.Position = UDim2.new(0, 14, 0, 62)
    sep.BackgroundColor3 = CONFIG.Theme.Border
    sep.BorderSizePixel = 0
    sep.Parent = MainFrame

    -- Cards
    local startY = 78
    local cardHeight = 64
    local gap = 9

    for i = 1, 5 do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -28, 0, cardHeight)
        card.Position = UDim2.new(0, 14, 0, startY + (i-1)*(cardHeight + gap))
        card.BackgroundColor3 = CONFIG.Theme.Card
        card.BorderSizePixel = 0
        card.Parent = MainFrame
        CreateCorner(card, 12)
        CreateStroke(card)

        local camLabel = Instance.new("TextLabel")
        camLabel.Size = UDim2.new(0, 70, 0, 20)
        camLabel.Position = UDim2.new(0, 14, 0, 9)
        camLabel.BackgroundTransparency = 1
        camLabel.Text = "CAM " .. i
        camLabel.Font = Enum.Font.GothamBold
        camLabel.TextSize = 14
        camLabel.TextColor3 = CONFIG.Theme.TextPrimary
        camLabel.TextXAlignment = Enum.TextXAlignment.Left
        camLabel.Parent = card

        local status = Instance.new("TextLabel")
        status.Name = "Status"
        status.Size = UDim2.new(0, 90, 0, 18)
        status.Position = UDim2.new(0, 14, 0, 32)
        status.BackgroundTransparency = 1
        status.Text = "Vazio"
        status.Font = Enum.Font.Gotham
        status.TextSize = 12
        status.TextColor3 = CONFIG.Theme.TextSecondary
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.Parent = card

        local saveBtn = CreateButton("Salvar", CONFIG.Theme.AccentDark, UDim2.new(0, 72, 0, 30))
        saveBtn.Position = UDim2.new(1, -232, 0.5, -15)
        saveBtn.Parent = card

        local goBtn = CreateButton("Ir", Color3.fromRGB(35, 110, 65), UDim2.new(0, 56, 0, 30))
        goBtn.Position = UDim2.new(1, -152, 0.5, -15)
        goBtn.Parent = card

        local delBtn = CreateButton("Apagar", Color3.fromRGB(95, 40, 40), UDim2.new(0, 66, 0, 30))
        delBtn.Position = UDim2.new(1, -88, 0.5, -15)
        delBtn.Parent = card

        Cards[i] = {Frame = card, Status = status, Save = saveBtn, Go = goBtn, Delete = delBtn}
    end

    local bottomY = startY + 5*(cardHeight + gap) + 16

    -- Controles inferiores
    local transLabel = Instance.new("TextLabel")
    transLabel.Size = UDim2.new(0, 100, 0, 20)
    transLabel.Position = UDim2.new(0, 14, 0, bottomY)
    transLabel.BackgroundTransparency = 1
    transLabel.Text = "Transição:"
    transLabel.Font = Enum.Font.Gotham
    transLabel.TextSize = 13
    transLabel.TextColor3 = CONFIG.Theme.TextSecondary
    transLabel.TextXAlignment = Enum.TextXAlignment.Left
    transLabel.Parent = MainFrame

    SmoothBtn = CreateButton("SUAVE", CONFIG.Theme.Accent, UDim2.new(0, 88, 0, 32))
    SmoothBtn.Position = UDim2.new(0, 110, 0, bottomY - 6)
    SmoothBtn.Parent = MainFrame

    InstantBtn = CreateButton("INSTANTÂNEA", CONFIG.Theme.Card, UDim2.new(0, 112, 0, 32))
    InstantBtn.Position = UDim2.new(0, 208, 0, bottomY - 6)
    InstantBtn.Parent = MainFrame

    local durLabel = Instance.new("TextLabel")
    durLabel.Size = UDim2.new(0, 140, 0, 20)
    durLabel.Position = UDim2.new(0, 14, 0, bottomY + 42)
    durLabel.BackgroundTransparency = 1
    durLabel.Text = "Duração (segundos):"
    durLabel.Font = Enum.Font.Gotham
    durLabel.TextSize = 13
    durLabel.TextColor3 = CONFIG.Theme.TextSecondary
    durLabel.TextXAlignment = Enum.TextXAlignment.Left
    durLabel.Parent = MainFrame

    DurationBox = Instance.new("TextBox")
    DurationBox.Size = UDim2.new(0, 70, 0, 32)
    DurationBox.Position = UDim2.new(0, 160, 0, bottomY + 36)
    DurationBox.BackgroundColor3 = CONFIG.Theme.Card
    DurationBox.Text = tostring(CONFIG.DefaultDuration)
    DurationBox.Font = Enum.Font.GothamMedium
    DurationBox.TextSize = 14
    DurationBox.TextColor3 = CONFIG.Theme.TextPrimary
    DurationBox.ClearTextOnFocus = false
    DurationBox.BorderSizePixel = 0
    DurationBox.Parent = MainFrame
    CreateCorner(DurationBox, CONFIG.ButtonRadius)
    CreateStroke(DurationBox)

    ResetBtn = CreateButton("Resetar Câmera", Color3.fromRGB(75, 50, 30), UDim2.new(1, -28, 0, 38))
    ResetBtn.Position = UDim2.new(0, 14, 0, bottomY + 85)
    ResetBtn.Parent = MainFrame

    MainFrame.Size = UDim2.new(0, MainFrame.Size.X.Offset, 0, bottomY + 140)
end

-- ==================== LÓGICA ====================
local function UpdateCardVisual(index)
    local data = Presets[index]
    local card = Cards[index]
    if not card then return end
    if data then
        card.Status.Text = "Salvo ✓"
        card.Status.TextColor3 = CONFIG.Theme.Success
        card.Frame.BackgroundColor3 = Color3.fromRGB(30, 38, 34)
    else
        card.Status.Text = "Vazio"
        card.Status.TextColor3 = CONFIG.Theme.TextSecondary
        card.Frame.BackgroundColor3 = CONFIG.Theme.Card
    end
end

local function SavePreset(index)
    if not Camera then return end
    Presets[index] = {CFrame = Camera.CFrame, FOV = Camera.FieldOfView}
    UpdateCardVisual(index)
end

local function DeletePreset(index)
    Presets[index] = nil
    UpdateCardVisual(index)
end

local function CancelCurrentTransition()
    if CurrentTween then CurrentTween:Cancel() CurrentTween = nil end
    if CurrentFOVTween then CurrentFOVTween:Cancel() CurrentFOVTween = nil end
end

local function ApplyPreset(index)
    local data = Presets[index]
    if not data then return end
    CancelCurrentTransition()
    Camera.CameraType = Enum.CameraType.Scriptable

    if IsSmooth then
        local duration = math.clamp(TransitionDuration, CONFIG.MinDuration, CONFIG.MaxDuration)
        local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        CurrentTween = TweenService:Create(Camera, info, {CFrame = data.CFrame})
        CurrentFOVTween = TweenService:Create(Camera, info, {FieldOfView = data.FOV})
        CurrentTween:Play()
        CurrentFOVTween:Play()
        CurrentTween.Completed:Connect(function()
            CurrentTween = nil
            CurrentFOVTween = nil
        end)
    else
        Camera.CFrame = data.CFrame
        Camera.FieldOfView = data.FOV
    end
end

local function ResetCamera()
    CancelCurrentTransition()
    Camera.CameraType = Enum.CameraType.Custom
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            Camera.CameraSubject = humanoid
        end
    end
end

local function ToggleMainUI()
    UIVisible = not UIVisible
    MainFrame.Visible = UIVisible
end

-- ==================== ARRASTAR ====================
local function SetupDragging()
    -- Arrastar frame principal
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position
            local absPos = MainFrame.AbsolutePosition
            local absSize = MainFrame.AbsoluteSize
            if MainFrame.Visible and pos.X >= absPos.X and pos.X <= absPos.X + absSize.X and pos.Y >= absPos.Y and pos.Y <= absPos.Y + 50 then
                IsDraggingMain = true
                DragStart = pos
                FrameStart = MainFrame.Position
            end

            -- Arrastar botão flutuante
            local fPos = FloatBtn.AbsolutePosition
            local fSize = FloatBtn.AbsoluteSize
            if pos.X >= fPos.X and pos.X <= fPos.X + fSize.X and pos.Y >= fPos.Y and pos.Y <= fPos.Y + fSize.Y then
                IsDraggingFloat = true
                DragStart = pos
                FrameStart = FloatBtn.Position
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType \~= Enum.UserInputType.MouseMovement and input.UserInputType \~= Enum.UserInputType.Touch then return end
        if IsDraggingMain then
            local delta = input.Position - DragStart
            MainFrame.Position = UDim2.new(FrameStart.X.Scale, FrameStart.X.Offset + delta.X, FrameStart.Y.Scale, FrameStart.Y.Offset + delta.Y)
        elseif IsDraggingFloat then
            local delta = input.Position - DragStart
            FloatBtn.Position = UDim2.new(FrameStart.X.Scale, FrameStart.X.Offset + delta.X, FrameStart.Y.Scale, FrameStart.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            IsDraggingMain = false
            IsDraggingFloat = false
        end
    end)
end

local function SetupButtons()
    for i = 1, 5 do
        local card = Cards[i]
        card.Save.MouseButton1Click:Connect(function() SavePreset(i) end)
        card.Go.MouseButton1Click:Connect(function() ApplyPreset(i) end)
        card.Delete.MouseButton1Click:Connect(function() DeletePreset(i) end)
    end

    local function setSmooth(state)
        IsSmooth = state
        if state then
            SmoothBtn.BackgroundColor3 = CONFIG.Theme.Accent
            InstantBtn.BackgroundColor3 = CONFIG.Theme.Card
        else
            SmoothBtn.BackgroundColor3 = CONFIG.Theme.Card
            InstantBtn.BackgroundColor3 = CONFIG.Theme.Accent
        end
    end

    SmoothBtn.MouseButton1Click:Connect(function() setSmooth(true) end)
    InstantBtn.MouseButton1Click:Connect(function() setSmooth(false) end)

    DurationBox.FocusLost:Connect(function()
        local num = tonumber(DurationBox.Text)
        if num then
            TransitionDuration = math.clamp(num, CONFIG.MinDuration, CONFIG.MaxDuration)
            DurationBox.Text = string.format("%.1f", TransitionDuration)
        else
            DurationBox.Text = string.format("%.1f", TransitionDuration)
        end
    end)

    ResetBtn.MouseButton1Click:Connect(ResetCamera)
    FloatBtn.MouseButton1Click:Connect(ToggleMainUI)
end

-- ==================== INICIALIZAÇÃO ====================
BuildUI()
SetupDragging()
SetupButtons()

for i = 1, 5 do
    UpdateCardVisual(i)
end

SmoothBtn.BackgroundColor3 = CONFIG.Theme.Accent
InstantBtn.BackgroundColor3 = CONFIG.Theme.Card

print("[Camera Presets v2] Carregado! Botão CAM flutuante abre/fecha a interface.")
