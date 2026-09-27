--[[
    CAMERA PRESETS v3
    Presets + Follow Camera + Menu Flutuante
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- ==================== CONFIG ====================
local CONFIG = {
    Theme = {
        Background = Color3.fromRGB(15, 15, 19),
        Card = Color3.fromRGB(25, 25, 31),
        Accent = Color3.fromRGB(0, 190, 255),
        AccentDark = Color3.fromRGB(0, 130, 190),
        TextPrimary = Color3.fromRGB(245, 245, 250),
        TextSecondary = Color3.fromRGB(150, 150, 160),
        Success = Color3.fromRGB(70, 220, 130),
        Danger = Color3.fromRGB(255, 75, 75),
        Border = Color3.fromRGB(42, 42, 52),
    },
    BaseSize = UDim2.new(0, 360, 0, 720),
    MobileScale = 0.88,
    CornerRadius = 14,
    ButtonRadius = 8,
    DefaultDuration = 1.2,
    MinDuration = 0.1,
    MaxDuration = 8.0,
}

-- ==================== VARIÁVEIS ====================
local Presets = {[1]=nil,[2]=nil,[3]=nil,[4]=nil,[5]=nil}
local CurrentTween, CurrentFOVTween = nil, nil
local IsSmooth = true
local TransitionDuration = CONFIG.DefaultDuration
local IsDraggingMain, IsDraggingFloat = false, false
local DragStart, FrameStart = nil, nil
local UIVisible = true
local IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- Follow System
local FollowEnabled = false
local FollowConnection = nil
local TargetPlayer = LocalPlayer
local FollowDistance = 8
local FollowHeight = 2
local FollowOffset = 0
local FollowSmoothness = 0.12
local FollowLookAt = true
local FollowHead = true

local ScreenGui, MainFrame, FloatBtn
local Cards = {}
local SmoothBtn, InstantBtn, DurationBox, ResetBtn
local TargetLabel, DistBox, HeightBox, OffsetBox, SmoothBox
local FollowToggleBtn, ModeBtn, HeadBtn

-- ==================== FUNÇÕES AUX ====================
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
    btn.TextSize = 12
    btn.TextColor3 = CONFIG.Theme.TextPrimary
    btn.BackgroundColor3 = color or CONFIG.Theme.Card
    btn.Size = size or UDim2.new(0, 80, 0, 30)
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    CreateCorner(btn, CONFIG.ButtonRadius)
    CreateStroke(btn)
    return btn
end

local function CreateLabel(text, size, position, parent)
    local lbl = Instance.new("TextLabel")
    lbl.Size = size
    lbl.Position = position
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = CONFIG.Theme.TextSecondary
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
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

    -- Botão Flutuante
    FloatBtn = Instance.new("TextButton")
    FloatBtn.Name = "FloatButton"
    FloatBtn.Size = UDim2.new(0, 52, 0, 52)
    FloatBtn.Position = UDim2.new(1, -68, 0.45, 0)
    FloatBtn.BackgroundColor3 = CONFIG.Theme.Accent
    FloatBtn.Text = "CAM"
    FloatBtn.Font = Enum.Font.GothamBold
    FloatBtn.TextSize = 13
    FloatBtn.TextColor3 = Color3.new(1,1,1)
    FloatBtn.AutoButtonColor = false
    FloatBtn.BorderSizePixel = 0
    FloatBtn.Parent = ScreenGui
    CreateCorner(FloatBtn, 26)
    CreateStroke(FloatBtn, 1.5)

    -- Frame Principal
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "Main"
    MainFrame.Size = CONFIG.BaseSize
    MainFrame.Position = UDim2.new(0.5, -CONFIG.BaseSize.X.Offset/2, 0.08, 0)
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
        MainFrame.Position = UDim2.new(0.5, -MainFrame.Size.X.Offset/2, 0.06, 0)
    end

    -- Título
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 26)
    title.Position = UDim2.new(0, 14, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "CAMERA PRESETS"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 17
    title.TextColor3 = CONFIG.Theme.TextPrimary
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = MainFrame

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -20, 0, 16)
    subtitle.Position = UDim2.new(0, 14, 0, 32)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Presets + Follow Camera"
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 12
    subtitle.TextColor3 = CONFIG.Theme.TextSecondary
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = MainFrame

    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, -28, 0, 1)
    sep.Position = UDim2.new(0, 14, 0, 54)
    sep.BackgroundColor3 = CONFIG.Theme.Border
    sep.BorderSizePixel = 0
    sep.Parent = MainFrame

    -- ===== PRESETS =====
    local startY = 68
    local cardHeight = 58
    local gap = 7

    for i = 1, 5 do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -28, 0, cardHeight)
        card.Position = UDim2.new(0, 14, 0, startY + (i-1)*(cardHeight + gap))
        card.BackgroundColor3 = CONFIG.Theme.Card
        card.BorderSizePixel = 0
        card.Parent = MainFrame
        CreateCorner(card, 10)
        CreateStroke(card)

        local camLabel = Instance.new("TextLabel")
        camLabel.Size = UDim2.new(0, 60, 0, 18)
        camLabel.Position = UDim2.new(0, 12, 0, 7)
        camLabel.BackgroundTransparency = 1
        camLabel.Text = "CAM " .. i
        camLabel.Font = Enum.Font.GothamBold
        camLabel.TextSize = 13
        camLabel.TextColor3 = CONFIG.Theme.TextPrimary
        camLabel.TextXAlignment = Enum.TextXAlignment.Left
        camLabel.Parent = card

        local status = Instance.new("TextLabel")
        status.Name = "Status"
        status.Size = UDim2.new(0, 80, 0, 16)
        status.Position = UDim2.new(0, 12, 0, 28)
        status.BackgroundTransparency = 1
        status.Text = "Vazio"
        status.Font = Enum.Font.Gotham
        status.TextSize = 11
        status.TextColor3 = CONFIG.Theme.TextSecondary
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.Parent = card

        local saveBtn = CreateButton("Salvar", CONFIG.Theme.AccentDark, UDim2.new(0, 64, 0, 26))
        saveBtn.Position = UDim2.new(1, -210, 0.5, -13)
        saveBtn.Parent = card

        local goBtn = CreateButton("Ir", Color3.fromRGB(35, 110, 65), UDim2.new(0, 48, 0, 26))
        goBtn.Position = UDim2.new(1, -140, 0.5, -13)
        goBtn.Parent = card

        local delBtn = CreateButton("Apagar", Color3.fromRGB(95, 40, 40), UDim2.new(0, 58, 0, 26))
        delBtn.Position = UDim2.new(1, -86, 0.5, -13)
        delBtn.Parent = card

        Cards[i] = {Frame = card, Status = status, Save = saveBtn, Go = goBtn, Delete = delBtn}
    end

    local bottomY = startY + 5*(cardHeight + gap) + 14

    -- Transição
    CreateLabel("Transição:", UDim2.new(0, 90, 0, 18), UDim2.new(0, 14, 0, bottomY), MainFrame)

    SmoothBtn = CreateButton("SUAVE", CONFIG.Theme.Accent, UDim2.new(0, 78, 0, 28))
    SmoothBtn.Position = UDim2.new(0, 100, 0, bottomY - 5)
    SmoothBtn.Parent = MainFrame

    InstantBtn = CreateButton("INSTANTÂNEA", CONFIG.Theme.Card, UDim2.new(0, 100, 0, 28))
    InstantBtn.Position = UDim2.new(0, 186, 0, bottomY - 5)
    InstantBtn.Parent = MainFrame

    CreateLabel("Duração:", UDim2.new(0, 70, 0, 18), UDim2.new(0, 14, 0, bottomY + 36), MainFrame)

    DurationBox = Instance.new("TextBox")
    DurationBox.Size = UDim2.new(0, 60, 0, 28)
    DurationBox.Position = UDim2.new(0, 90, 0, bottomY + 30)
    DurationBox.BackgroundColor3 = CONFIG.Theme.Card
    DurationBox.Text = tostring(CONFIG.DefaultDuration)
    DurationBox.Font = Enum.Font.GothamMedium
    DurationBox.TextSize = 13
    DurationBox.TextColor3 = CONFIG.Theme.TextPrimary
    DurationBox.ClearTextOnFocus = false
    DurationBox.BorderSizePixel = 0
    DurationBox.Parent = MainFrame
    CreateCorner(DurationBox, CONFIG.ButtonRadius)
    CreateStroke(DurationBox)

    -- ===== FOLLOW SECTION =====
    local followY = bottomY + 70

    local followTitle = Instance.new("TextLabel")
    followTitle.Size = UDim2.new(1, -28, 0, 20)
    followTitle.Position = UDim2.new(0, 14, 0, followY)
    followTitle.BackgroundTransparency = 1
    followTitle.Text = "CÂMERA FOLLOW"
    followTitle.Font = Enum.Font.GothamBold
    followTitle.TextSize = 14
    followTitle.TextColor3 = CONFIG.Theme.Accent
    followTitle.TextXAlignment = Enum.TextXAlignment.Left
    followTitle.Parent = MainFrame

    -- Target
    CreateLabel("Alvo:", UDim2.new(0, 50, 0, 18), UDim2.new(0, 14, 0, followY + 28), MainFrame)

    TargetLabel = Instance.new("TextLabel")
    TargetLabel.Size = UDim2.new(0, 140, 0, 26)
    TargetLabel.Position = UDim2.new(0, 60, 0, followY + 24)
    TargetLabel.BackgroundColor3 = CONFIG.Theme.Card
    TargetLabel.Text = LocalPlayer.Name
    TargetLabel.Font = Enum.Font.GothamMedium
    TargetLabel.TextSize = 12
    TargetLabel.TextColor3 = CONFIG.Theme.TextPrimary
    TargetLabel.BorderSizePixel = 0
    TargetLabel.Parent = MainFrame
    CreateCorner(TargetLabel, 6)
    CreateStroke(TargetLabel)

    local prevBtn = CreateButton("<", CONFIG.Theme.Card, UDim2.new(0, 32, 0, 26))
    prevBtn.Position = UDim2.new(0, 208, 0, followY + 24)
    prevBtn.Parent = MainFrame

    local nextBtn = CreateButton(">", CONFIG.Theme.Card, UDim2.new(0, 32, 0, 26))
    nextBtn.Position = UDim2.new(0, 246, 0, followY + 24)
    nextBtn.Parent = MainFrame

    -- Mode
    ModeBtn = CreateButton("Olhar para Personagem", CONFIG.Theme.AccentDark, UDim2.new(1, -28, 0, 28))
    ModeBtn.Position = UDim2.new(0, 14, 0, followY + 60)
    ModeBtn.Parent = MainFrame

    HeadBtn = CreateButton("Seguir Cabeça: ON", Color3.fromRGB(40, 90, 50), UDim2.new(1, -28, 0, 28))
    HeadBtn.Position = UDim2.new(0, 14, 0, followY + 96)
    HeadBtn.Parent = MainFrame

    -- Sliders / Values
    CreateLabel("Distância:", UDim2.new(0, 70, 0, 18), UDim2.new(0, 14, 0, followY + 136), MainFrame)
    DistBox = Instance.new("TextBox")
    DistBox.Size = UDim2.new(0, 60, 0, 26)
    DistBox.Position = UDim2.new(0, 90, 0, followY + 132)
    DistBox.BackgroundColor3 = CONFIG.Theme.Card
    DistBox.Text = "8"
    DistBox.Font = Enum.Font.GothamMedium
    DistBox.TextSize = 13
    DistBox.TextColor3 = CONFIG.Theme.TextPrimary
    DistBox.ClearTextOnFocus = false
    DistBox.BorderSizePixel = 0
    DistBox.Parent = MainFrame
    CreateCorner(DistBox, 6)
    CreateStroke(DistBox)

    CreateLabel("Altura:", UDim2.new(0, 50, 0, 18), UDim2.new(0, 170, 0, followY + 136), MainFrame)
    HeightBox = Instance.new("TextBox")
    HeightBox.Size = UDim2.new(0, 60, 0, 26)
    HeightBox.Position = UDim2.new(0, 220, 0, followY + 132)
    HeightBox.BackgroundColor3 = CONFIG.Theme.Card
    HeightBox.Text = "2"
    HeightBox.Font = Enum.Font.GothamMedium
    HeightBox.TextSize = 13
    HeightBox.TextColor3 = CONFIG.Theme.TextPrimary
    HeightBox.ClearTextOnFocus = false
    HeightBox.BorderSizePixel = 0
    HeightBox.Parent = MainFrame
    CreateCorner(HeightBox, 6)
    CreateStroke(HeightBox)

    CreateLabel("Offset:", UDim2.new(0, 50, 0, 18), UDim2.new(0, 14, 0, followY + 172), MainFrame)
    OffsetBox = Instance.new("TextBox")
    OffsetBox.Size = UDim2.new(0, 60, 0, 26)
    OffsetBox.Position = UDim2.new(0, 70, 0, followY + 168)
    OffsetBox.BackgroundColor3 = CONFIG.Theme.Card
    OffsetBox.Text = "0"
    OffsetBox.Font = Enum.Font.GothamMedium
    OffsetBox.TextSize = 13
    OffsetBox.TextColor3 = CONFIG.Theme.TextPrimary
    OffsetBox.ClearTextOnFocus = false
    OffsetBox.BorderSizePixel = 0
    OffsetBox.Parent = MainFrame
    CreateCorner(OffsetBox, 6)
    CreateStroke(OffsetBox)

    CreateLabel("Suavidade:", UDim2.new(0, 70, 0, 18), UDim2.new(0, 150, 0, followY + 172), MainFrame)
    SmoothBox = Instance.new("TextBox")
    SmoothBox.Size = UDim2.new(0, 60, 0, 26)
    SmoothBox.Position = UDim2.new(0, 230, 0, followY + 168)
    SmoothBox.BackgroundColor3 = CONFIG.Theme.Card
    SmoothBox.Text = "0.12"
    SmoothBox.Font = Enum.Font.GothamMedium
    SmoothBox.TextSize = 13
    SmoothBox.TextColor3 = CONFIG.Theme.TextPrimary
    SmoothBox.ClearTextOnFocus = false
    SmoothBox.BorderSizePixel = 0
    SmoothBox.Parent = MainFrame
    CreateCorner(SmoothBox, 6)
    CreateStroke(SmoothBox)

    -- Follow Toggle
    FollowToggleBtn = CreateButton("ATIVAR FOLLOW", Color3.fromRGB(30, 100, 60), UDim2.new(1, -28, 0, 34))
    FollowToggleBtn.Position = UDim2.new(0, 14, 0, followY + 210)
    FollowToggleBtn.Parent = MainFrame

    -- Reset
    ResetBtn = CreateButton("RESETAR CÂMERA", Color3.fromRGB(80, 45, 25), UDim2.new(1, -28, 0, 34))
    ResetBtn.Position = UDim2.new(0, 14, 0, followY + 254)
    ResetBtn.Parent = MainFrame

    MainFrame.Size = UDim2.new(0, MainFrame.Size.X.Offset, 0, followY + 305)

    -- Bind cycle buttons
    prevBtn.MouseButton1Click:Connect(function()
        local list = Players:GetPlayers()
        local idx = table.find(list, TargetPlayer) or 1
        idx = idx - 1
        if idx < 1 then idx = #list end
        TargetPlayer = list[idx]
        TargetLabel.Text = TargetPlayer.Name
    end)

    nextBtn.MouseButton1Click:Connect(function()
        local list = Players:GetPlayers()
        local idx = table.find(list, TargetPlayer) or 1
        idx = idx + 1
        if idx > #list then idx = 1 end
        TargetPlayer = list[idx]
        TargetLabel.Text = TargetPlayer.Name
    end)
end

-- ==================== LÓGICA PRESETS ====================
local function UpdateCardVisual(index)
    local data = Presets[index]
    local card = Cards[index]
    if not card then return end
    if data then
        card.Status.Text = "Salvo ✓"
        card.Status.TextColor3 = CONFIG.Theme.Success
        card.Frame.BackgroundColor3 = Color3.fromRGB(28, 36, 32)
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
    if FollowEnabled then return end -- não mistura com follow
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

-- ==================== FOLLOW SYSTEM ====================
local function StopFollow()
    FollowEnabled = false
    if FollowConnection then
        FollowConnection:Disconnect()
        FollowConnection = nil
    end
    FollowToggleBtn.Text = "ATIVAR FOLLOW"
    FollowToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 60)
end

local function StartFollow()
    StopFollow()
    FollowEnabled = true
    Camera.CameraType = Enum.CameraType.Scriptable
    FollowToggleBtn.Text = "DESATIVAR FOLLOW"
    FollowToggleBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)

    FollowConnection = RunService.RenderStepped:Connect(function()
        if not FollowEnabled or not TargetPlayer then return end
        local char = TargetPlayer.Character
        if not char then return end

        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local targetPart = (FollowHead and head) or root
        if not targetPart then return end

        local targetPos = targetPart.Position + Vector3.new(0, FollowHeight, 0)
        local lookVector = root and root.CFrame.LookVector or Vector3.new(0, 0, -1)

        local camPos
        if FollowLookAt then
            camPos = targetPos - (lookVector * FollowDistance) + (root.CFrame.RightVector * FollowOffset)
        else
            camPos = targetPos + Vector3.new(0, 0, FollowDistance) + Vector3.new(FollowOffset, 0, 0)
        end

        local desired = CFrame.lookAt(camPos, targetPos)
        Camera.CFrame = Camera.CFrame:Lerp(desired, FollowSmoothness)
    end)
end

local function ResetCamera()
    StopFollow()
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

-- ==================== ARRASTAR + BOTÕES ====================
local function SetupDragging()
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position

            -- Main Frame
            if MainFrame.Visible then
                local absPos = MainFrame.AbsolutePosition
                local absSize = MainFrame.AbsoluteSize
                if pos.X >= absPos.X and pos.X <= absPos.X + absSize.X and pos.Y >= absPos.Y and pos.Y <= absPos.Y + 50 then
                    IsDraggingMain = true
                    DragStart = pos
                    FrameStart = MainFrame.Position
                end
            end

            -- Float Button
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
        if input.UserInputType \~= Enum.
