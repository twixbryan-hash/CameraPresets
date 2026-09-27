--[[
    CAMERA PRESETS - Ferramenta profissional de cinematografia para Roblox
    Executável em Delta (e outros executores)
    Apenas controle local de câmera para gravação de vídeos
    Sem exploits, sem vantagem competitiva, sem interação com outros jogadores
]]

-- ============================================================
-- 1. SERVIÇOS
-- ============================================================
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local StarterGui        = game:GetService("StarterGui")

local LocalPlayer       = Players.LocalPlayer
local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")
local Camera            = workspace.CurrentCamera

-- ============================================================
-- 2. CONFIGURAÇÕES
-- ============================================================
local CONFIG = {
    Theme = {
        Background      = Color3.fromRGB(18, 18, 22),
        Card            = Color3.fromRGB(28, 28, 34),
        CardHover       = Color3.fromRGB(38, 38, 46),
        Accent          = Color3.fromRGB(0, 180, 255),
        AccentDark      = Color3.fromRGB(0, 120, 180),
        TextPrimary     = Color3.fromRGB(240, 240, 245),
        TextSecondary   = Color3.fromRGB(160, 160, 170),
        Success         = Color3.fromRGB(80, 220, 120),
        Danger          = Color3.fromRGB(255, 80, 80),
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

-- ============================================================
-- 3. VARIÁVEIS
-- ============================================================
local Presets = {
    [1] = nil,
    [2] = nil,
    [3] = nil,
    [4] = nil,
    [5] = nil,
}

local CurrentTween      = nil
local CurrentFOVTween   = nil
local IsSmooth          = true
local TransitionDuration = CONFIG.DefaultDuration
local IsDragging        = false
local DragStart         = nil
local FrameStart        = nil
local UIVisible         = true
local IsMobile          = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local ScreenGui, MainFrame, TitleLabel, SubtitleLabel
local Cards = {}
local SmoothBtn, InstantBtn, DurationBox, ResetBtn, HideBtn
local DragHandle

-- ============================================================
-- 4. INTERFACE
-- ============================================================
local function CreateCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or CONFIG.CornerRadius)
    c.Parent = parent
    return c
end

local function CreateStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or CONFIG.Theme.Border
    s.Thickness = thickness or 1
    s.Transparency = 0.4
    s.Parent = parent
    return s
end

local function CreateShadow(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.Position = UDim2.new(0, -15, 0, -10)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Parent = parent
    return shadow
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
    CreateStroke(btn, CONFIG.Theme.Border, 1)
    
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
    CreateShadow(MainFrame)
    
    if IsMobile then
        local scale = CONFIG.MobileScale
        MainFrame.Size = UDim2.new(0, CONFIG.BaseSize.X.Offset * scale, 0, CONFIG.BaseSize.Y.Offset * scale)
        MainFrame.Position = UDim2.new(0.5, -MainFrame.Size.X.Offset/2, 0.15, 0)
    end
    
    DragHandle = Instance.new("Frame")
    DragHandle.Name = "DragHandle"
    DragHandle.Size = UDim2.new(1, 0, 0, 48)
    DragHandle.BackgroundTransparency = 1
    DragHandle.Parent = MainFrame
    
    TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(1, -20, 0, 28)
    TitleLabel.Position = UDim2.new(0, 12, 0, 10)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "CAMERA PRESETS"
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 18
    TitleLabel.TextColor3 = CONFIG.Theme.TextPrimary
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = MainFrame
    
    SubtitleLabel = Instance.new("TextLabel")
    SubtitleLabel.Name = "Subtitle"
    SubtitleLabel.Size = UDim2.new(1, -20, 0, 18)
    SubtitleLabel.Position = UDim2.new(0, 12, 0, 34)
    SubtitleLabel.BackgroundTransparency = 1
    SubtitleLabel.Text = "5 posições de câmera"
    SubtitleLabel.Font = Enum.Font.Gotham
    SubtitleLabel.TextSize = 13
    SubtitleLabel.TextColor3 = CONFIG.Theme.TextSecondary
    SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubtitleLabel.Parent = MainFrame
    
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
        card.Name = "CAM" .. i
        card.Size = UDim2.new(1, -24, 0, cardHeight)
        card.Position = UDim2.new(0, 12, 0, startY + (i-1) * (cardHeight + gap))
        card.BackgroundColor3 = CONFIG.Theme.Card
        card.BorderSizePixel = 0
        card.Parent = MainFrame
        CreateCorner(card, 10)
        CreateStroke(card, CONFIG.Theme.Border, 1)
        
        local camLabel = Instance.new("TextLabel")
        camLabel.Size = UDim2.new(0, 70, 0, 20)
        camLabel.Position = UDim2.new(0, 12, 0, 8)
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
        
        Cards[i] = {
            Frame = card,
            Status = status,
            Save = saveBtn,
            Go = goBtn,
            Delete = delBtn,
        }
    end
    
    local bottomY = startY + 5 * (cardHeight + gap) + 12
    
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
    SmoothBtn.Position = UDim2.new(0, 110, 0, bottomY - 5)
    SmoothBtn.Parent = MainFrame
    
    InstantBtn = CreateButton("INSTANTÂNEA", CONFIG.Theme.Card, UDim2.new(0, 110, 0, 30))
    InstantBtn.Position = UDim2.new(0, 205, 0, bottomY - 5)
    InstantBtn.Parent = MainFrame
    
    local durLabel = Instance.new("TextLabel")
    durLabel.Size = UDim2.new(0, 140, 0, 20)
    durLabel.Position = UDim2.new(0, 12, 0, bottomY + 40)
    durLabel.BackgroundTransparency = 1
    durLabel.Text = "Duração (segundos):"
    durLabel.Font = Enum.Font.Gotham
    durLabel.TextSize = 13
    durLabel.TextColor3 = CONFIG.Theme.TextSecondary
    durLabel.TextXAlignment = Enum.TextXAlignment.Left
    durLabel.Parent = MainFrame
    
    DurationBox = Instance.new("TextBox")
    DurationBox.Size = UDim2.new(0, 70, 0, 30)
    DurationBox.Position = UDim2.new(0, 160, 0, bottomY + 35)
    DurationBox.BackgroundColor3 = CONFIG.Theme.Card
    DurationBox.Text = tostring(CONFIG.DefaultDuration)
    DurationBox.Font = Enum.Font.GothamMedium
    DurationBox.TextSize = 14
    DurationBox.TextColor3 = CONFIG.Theme.TextPrimary
    DurationBox.PlaceholderText = "1.2"
    DurationBox.ClearTextOnFocus = false
    DurationBox.BorderSizePixel = 0
    DurationBox.Parent = MainFrame
    CreateCorner(DurationBox, CONFIG.ButtonRadius)
    CreateStroke(DurationBox)
    
    ResetBtn = CreateButton("Resetar Câmera", Color3.fromRGB(70, 50, 30), UDim2.new(0, 150, 0, 34))
    ResetBtn.Position = UDim2.new(0, 12, 0, bottomY + 80)
    ResetBtn.Parent = MainFrame
    
    HideBtn = CreateButton("Ocultar Interface", Color3.fromRGB(40, 40, 50), UDim2.new(0, 150, 0, 34))
    HideBtn.Position = UDim2.new(1, -162, 0, bottomY + 80)
    HideBtn.Parent = MainFrame
    
    MainFrame.Size = UDim2.new(0, MainFrame.Size.X.Offset, 0, bottomY + 130)
end

-- ============================================================
-- 5. PRESETS
-- ============================================================
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
    
    Presets[index] = {
        CFrame = Camera.CFrame,
        FOV = Camera.FieldOfView
    }
    UpdateCardVisual(index)
    
    local card = Cards[index].Frame
    local original = card.BackgroundColor3
    TweenService:Create(card, TweenInfo.new(0.15), {
        BackgroundColor3 = CONFIG.Theme.Accent
    }):Play()
    task.delay(0.2, function()
        TweenService:Create(card, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(32, 38, 34)
        }):Play()
    end)
end

local function DeletePreset(index)
    Presets[index] = nil
    UpdateCardVisual(index)
end

-- ============================================================
-- 6. SISTEMA DE CÂMERA
-- ============================================================
local function CancelCurrentTransition()
    if CurrentTween then
        CurrentTween:Cancel()
        CurrentTween = nil
    end
    if CurrentFOVTween then
        CurrentFOVTween:Cancel()
        CurrentFOVTween = nil
    end
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

-- ============================================================
-- 7. TRANSIÇÕES
-- ============================================================

-- ============================================================
-- 8. CONTROLES MOBILE + 9. CONTROLES PC
-- ============================================================
local function SetupDragging()
    local function onInputBegan(input, processed)
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
    end
    
    local function onInputChanged(input, processed)
        if not IsDragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - DragStart
            MainFrame.Position = UDim2.new(
                FrameStart.X.Scale,
                FrameStart.X.Offset + delta.X,
                FrameStart.Y.Scale,
                FrameStart.Y.Offset + delta.Y
            )
        end
    end
    
    local function onInputEnded(input, processed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            IsDragging = false
        end
    end
    
    UserInputService.InputBegan:Connect(onInputBegan)
    UserInputService.InputChanged:Connect(onInputChanged)
    UserInputService.InputEnded:Connect(onInputEnded)
end

local function SetupButtons()
    for i = 1, 5 do
        local card = Cards[i]
        
        card.Save.MouseButton1Click:Connect(function()
            SavePreset(i)
        end)
        
        card.Go.MouseButton1Click:Connect(function()
            ApplyPreset(i)
        end)
        
        card.Delete.MouseButton1Click:Connect(function()
            DeletePreset(i)
        end)
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
    
    SmoothBtn.MouseButton1Click:Connect(function()
        setSmooth(true)
    end)
    
    InstantBtn.MouseButton1Click:Connect(function()
        setSmooth(false)
    end)
    
    DurationBox.FocusLost:Connect(function()
        local num = tonumber(DurationBox.Text)
        if num then
            TransitionDuration = math.clamp(num, CONFIG.MinDuration, CONFIG.MaxDuration)
            DurationBox.Text = string.format("%.1f", TransitionDuration)
        else
            DurationBox.Text = string.format("%.1f", TransitionDuration)
        end
    end)
    
    ResetBtn.MouseButton1Click:Connect(function()
        ResetCamera()
    end)
    
    HideBtn.MouseButton1Click:Connect(function()
        ToggleUI(false)
    end)
end

-- ============================================================
-- 10. ANIMAÇÕES
-- ============================================================
local function AnimateOpen()
    MainFrame.Size = UDim2.new(0, MainFrame.Size.X.Offset * 0.85, 0, MainFrame.Size.Y.Offset * 0.85)
    MainFrame.BackgroundTransparency = 0.4
    
    local targetSize = UDim2.new(0, MainFrame.Size.X.Offset / 0.85, 0, MainFrame.Size.Y.Offset / 0.85)
    
    TweenService:Create(MainFrame, TweenInfo.new(CONFIG.OpenTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = targetSize,
        BackgroundTransparency = 0
    }):Play()
end

function ToggleUI(visible)
    UIVisible = visible
    if visible then
        MainFrame.Visible = true
        AnimateOpen()
    else
        local closeTween = TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, MainFrame.Size.X.Offset * 0.9, 0, MainFrame.Size.Y.Offset * 0.9)
        })
        closeTween:Play()
        closeTween.Completed:Connect(function()
            MainFrame.Visible = false
        end)
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.P then
        ToggleUI(not UIVisible)
    end
end)

-- ============================================================
-- 11. RESET + INICIALIZAÇÃO
-- ============================================================
local function Init()
    BuildUI()
    SetupDragging()
    SetupButtons()
    
    for i = 1, 5 do
        UpdateCardVisual(i)
    end
    
    SmoothBtn.BackgroundColor3 = CONFIG
