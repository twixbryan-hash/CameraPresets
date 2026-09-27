--[[
    CAMERA PRESETS - Ferramenta profissional de cinematografia para Roblox
    Executável em Delta (e outros executores)
    Apenas controle local de câmera para gravação de vídeos
]]

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local LocalPlayer       = Players.LocalPlayer
local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")
local Camera            = workspace.CurrentCamera

local CONFIG = {
    Theme = {
        Background      = Color3.fromRGB(18, 18, 22),
        Card            = Color3.fromRGB(28, 28, 34),
        Accent          = Color3.fromRGB(0, 180, 255),
        AccentDark      = Color3.fromRGB(0, 120, 180),
        TextPrimary     = Color3.fromRGB(240, 240, 245),
        TextSecondary   = Color3.fromRGB(160, 160, 170),
        Success         = Color3.fromRGB(80, 220, 120),
        Border          = Color3.fromRGB(50, 50, 60),
    },
    BaseSize            = UDim2.new(0, 340, 0, 520),
    MobileScale         = 0.92,
    CornerRadius        = 14,
    ButtonRadius        = 8,
    DefaultDuration     = 1.2,
    MinDuration         = 0.1,
    MaxDuration         = 8.0,
    OpenTime            = 0.35,
    ButtonPressScale    = 0.94,
}

local Presets = {[1]=nil,[2]=nil,[3]=nil,[4]=nil,[5]=nil}
local CurrentTween, CurrentFOVTween = nil, nil
local IsSmooth = true
local TransitionDuration = CONFIG.DefaultDuration
local IsDragging = false
local DragStart, FrameStart = nil, nil
local UIVisible = true
local IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local ScreenGui, MainFrame
local Cards = {}
local SmoothBtn, InstantBtn, DurationBox, ResetBtn, HideBtn

local function CreateCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or CONFIG.CornerRadius)
    c.Parent = parent
end

local function CreateStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or CONFIG.Theme.Border
    s.Thickness = thickness or 1
    s.Transparency = 0.4
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
    
    local originalSize = btn.Size
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), {
            Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset * CONFIG.ButtonPressScale,
                             originalSize.Y.Scale, originalSize.Y.Offset * CONFIG.ButtonPressScale)
        }):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {Size = originalSize}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {Size = originalSize}):Play()
    end)
    return btn
end

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

    MainFrame = Instance.new("Frame")
    MainFrame.Name = "Main"
    MainFrame.Size = CONFIG.BaseSize
    MainFrame.Position = UDim2.new(0.5, -CONFIG.BaseSize.X.Offset/2, 0.5, -CONFIG.BaseSize.Y.Offset/2)
    MainFrame.BackgroundColor3 = CONFIG.Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    CreateCorner(MainFrame)
    CreateStroke(MainFrame, CONFIG.Theme.Border, 1.5)

    if IsMobile then
        local scale = CONFIG.MobileScale
        MainFrame.Size = UDim2.new(0, CONFIG.BaseSize.X.Offset * scale, 0, CONFIG.BaseSize.Y.Offset * scale)
        MainFrame.Position = UDim2.new(0.5, -MainFrame.Size.X.Offset/2, 0.12, 0)
    end

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 28)
    title.Position = UDim2.new(0, 12, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "CAMERA PRESETS"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = CONFIG.Theme.TextPrimary
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = MainFrame

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -20, 0, 18)
    subtitle.Position = UDim2.new(0, 12, 0, 34)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "5 posições de câmera"
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 13
    subtitle.TextColor3 = CONFIG.Theme.TextSecondary
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = MainFrame

    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, -24, 0, 1)
    sep.Position = UDim2.new(0, 12, 0, 58)
    sep.BackgroundColor3 = CONFIG.Theme.Border
    sep.BorderSizePixel = 0
    sep.Parent = MainFrame

    local startY = 72
    local cardHeight = 62
    local gap = 8

    for i = 1, 5 do
        local card = Instance.new("Frame")
        card.Name = "CAM"..i
        card.Size = UDim2.new(1, -24, 0, cardHeight)
        card.Position = UDim2.new(0, 12, 0, startY + (i-1)*(cardHeight+gap))
        card.BackgroundColor3 = CONFIG.Theme.Card
        card.BorderSizePixel = 0
        card.Parent = MainFrame
        CreateCorner(card, 10)
        CreateStroke(card)

        local camLabel = Instance.new("TextLabel")
        camLabel.Size = UDim2.new(0, 70, 0, 20)
        camLabel.Position = UDim2.new(0, 12, 0, 8)
        camLabel.BackgroundTransparency = 1
        camLabel.Text = "CAM "..i
        camLabel.Font = Enum.Font.GothamBold
        camLabel.TextSize = 14
        camLabel.TextColor3 = CONFIG.Theme.TextPrimary
        camLabel.TextXAlignment = Enum.TextXAlignment.Left
        camLabel.Parent = card

        local status = Instance.new("TextLabel")
        status.Name = "Status"
        status.Size = UDim2.new(0, 90, 0, 18)
        status.Position = UDim2.new(0, 12, 0, 30)
        status.BackgroundTransparency = 1
        status.Text = "Vazio"
        status.Font = Enum.Font.Gotham
        status.TextSize = 12
        status.TextColor3 = CONFIG.Theme.TextSecondary
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.Parent = card

        local saveBtn = CreateButton("Salvar", CONFIG.Theme.AccentDark, UDim2.new(0, 70, 0, 28))
        saveBtn.Position = UDim2.new(1, -230, 0.5, -14)
        saveBtn.Parent = card

        local goBtn = CreateButton("Ir", Color3.fromRGB(40, 100, 60), UDim2.new(0, 55, 0, 28))
        goBtn.Position = UDim2.new(1, -152, 0.5, -14)
        goBtn.Parent = card

        local delBtn = CreateButton("Apagar", Color3.fromRGB(90, 40, 40), UDim2.new(0, 65, 0, 28))
        delBtn.Position = UDim2.new(1, -90, 0.5, -14)
        delBtn.Parent = card

        Cards[i] = {Frame=card, Status=status, Save=saveBtn, Go=goBtn, Delete=delBtn}
    end

    local bottomY = startY + 5*(cardHeight+gap) + 12

    local transLabel = Instance.new("TextLabel")
    transLabel.Size = UDim2.new(0, 100, 0, 20)
    transLabel.Position = UDim2.new(0, 12, 0, bottomY)
    transLabel.BackgroundTransparency = 1
    transLabel.Text = "Transição:"
    transLabel.Font = Enum.Font.Gotham
    transLabel.TextSize = 13
    transLabel.TextColor3 = CONFIG.Theme.TextSecondary
    transLabel.TextXAlignment = Enum.TextXAlignment.Left
    transLabel.Parent = MainFrame

    SmoothBtn = CreateButton("SUAVE", CONFIG.Theme.Accent, UDim2.new(0, 85, 0, 30))
    SmoothBtn.Position = UDim2.new(0, 110, 0, bottomY-5)
    SmoothBtn.Parent = MainFrame

    InstantBtn = CreateButton("INSTANTÂNEA", CONFIG.Theme.Card, UDim2.new(0, 110, 0, 30))
    InstantBtn.Position = UDim2.new(0, 205, 0, bottomY-5)
    InstantBtn.Parent = MainFrame

    local durLabel = Instance.new("TextLabel")
    durLabel.Size = UDim2.new(0, 140, 0, 20)
    durLabel.Position = UDim2.new(0, 12, 0, bottomY+40)
    durLabel.BackgroundTransparency = 1
    durLabel.Text = "Duração (segundos):"
    durLabel.Font = Enum.Font.Gotham
    durLabel.TextSize = 13
    durLabel.TextColor3 = CONFIG.Theme.TextSecondary
    durLabel.TextXAlignment = Enum.TextXAlignment.Left
    durLabel.Parent = MainFrame

    DurationBox = Instance.new("TextBox")
    DurationBox.Size = UDim2.new(0, 70, 0, 30)
    DurationBox.Position = UDim2.new(0, 160, 0, bottomY+35)
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

    ResetBtn = CreateButton("Resetar Câmera", Color3.fromRGB(70, 50, 30), UDim2.new(0, 150, 0, 34))
    ResetBtn.Position = UDim2.new(0, 12, 0, bottomY+80)
    ResetBtn.Parent = MainFrame

    HideBtn = CreateButton("Ocultar Interface", Color3.fromRGB(40, 40, 50), UDim2.new(0, 150, 0, 34))
    HideBtn.Position = UDim2.new(1, -162, 0, bottomY+80)
    HideBtn.Parent = MainFrame

    MainFrame.Size = UDim2.new(0, MainFrame.Size.X.Offset, 0, bottomY+130)
end

local function UpdateCardVisual(index)
    local data = Presets[index]
    local card = Cards[index]
    if not card then return end
    if data then
        card.Status.Text = "Salvo ✓"
        card.Status.TextColor3 = CONFIG.Theme.Success
        card.Frame.BackgroundColor3 = Color3.fromRGB(32, 38, 34)
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
    
    local card = Cards[index].Frame
    TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = CONFIG.Theme.Accent}):Play()
    task.delay(0.2, function()
        TweenService:Create(card, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(32, 38, 34)}):Play()
    end)
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

local function SetupDragging()
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position
            local absPos = MainFrame.AbsolutePosition
            local absSize = MainFrame.AbsoluteSize
            if pos.X >= absPos.X and pos.X <= absPos.X + absSize.X and
               pos.Y >= absPos.Y and pos.Y <= absPos.Y + 48 then
                IsDragging = true
                DragStart = pos
                FrameStart = MainFrame.Position
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not IsDragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - DragStart
            MainFrame.Position = UDim2.new(
                FrameStart.X.Scale, FrameStart.X.Offset + delta.X,
                FrameStart.Y.Scale, FrameStart.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            IsDragging = false
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

    HideBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        UIVisible = false
    end)
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.P then
        if MainFrame then
            MainFrame.Visible = not MainFrame.Visible
            UIVisible = MainFrame.Visible
        end
    end
end)

-- Inicialização
BuildUI()
SetupDragging()
SetupButtons()

for i = 1, 5 do
    UpdateCardVisual(i)
end

SmoothBtn.BackgroundColor3 = CONFIG.Theme.Accent
InstantBtn.BackgroundColor3 = CONFIG.Theme.Card

print("[Camera Presets] Carregado com sucesso! Tecla P para mostrar/ocultar.")
