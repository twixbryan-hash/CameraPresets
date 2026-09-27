--[[
    CAMERA PRESETS v5
    Presets + Follow Camera + Menu Flutuante
    Feito para gravação na própria experiência
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- CAMERA
--==================================================

local function GetCamera()
    return workspace.CurrentCamera
end

--==================================================
-- CONFIG
--==================================================

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

    BaseWidth = 360,
    BaseHeight = 720,
    MobileScale = 0.88,

    CornerRadius = 14,
    ButtonRadius = 8,

    DefaultDuration = 1.2,
    MinDuration = 0.1,
    MaxDuration = 8,

    FollowDistance = 8,
    FollowHeight = 2,
    FollowOffset = 0,
    FollowSmoothness = 0.12,
}

--==================================================
-- VARIABLES
--==================================================

local Presets = {}

local CurrentTween = nil
local CurrentFOVTween = nil

local IsSmooth = true
local TransitionDuration = CONFIG.DefaultDuration

local FollowEnabled = false
local FollowConnection = nil

local TargetPlayer = LocalPlayer
local TargetIndex = 1

local FollowDistance = CONFIG.FollowDistance
local FollowHeight = CONFIG.FollowHeight
local FollowOffset = CONFIG.FollowOffset
local FollowSmoothness = CONFIG.FollowSmoothness

local FollowLookAt = true
local FollowHead = true

local IsMobile =
    UserInputService.TouchEnabled
    and not UserInputService.MouseEnabled

local ScreenGui
local MainFrame
local FloatBtn

local Cards = {}

local SmoothBtn
local InstantBtn
local DurationBox
local ResetBtn

local TargetLabel
local DistBox
local HeightBox
local OffsetBox
local SmoothBox

local FollowToggleBtn
local ModeBtn
local HeadBtn

local DraggingObject = nil
local DragStart = nil
local ObjectStart = nil
local DragMoved = false

--==================================================
-- AUXILIARY
--==================================================

local function CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(
        0,
        radius or CONFIG.CornerRadius
    )
    corner.Parent = parent
    return corner
end

local function CreateStroke(parent, thickness)
    local stroke = Instance.new("UIStroke")

    stroke.Color = CONFIG.Theme.Border
    stroke.Thickness = thickness or 1
    stroke.Transparency = 0.35

    stroke.Parent = parent

    return stroke
end

local function CreateButton(text, color, size)
    local button = Instance.new("TextButton")

    button.Text = text
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 12
    button.TextColor3 = CONFIG.Theme.TextPrimary

    button.BackgroundColor3 =
        color or CONFIG.Theme.Card

    button.Size =
        size or UDim2.fromOffset(80, 30)

    button.AutoButtonColor = false
    button.BorderSizePixel = 0

    CreateCorner(button, CONFIG.ButtonRadius)
    CreateStroke(button)

    return button
end

local function CreateLabel(text, size, position, parent)
    local label = Instance.new("TextLabel")

    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1

    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextColor3 =
        CONFIG.Theme.TextSecondary

    label.TextXAlignment =
        Enum.TextXAlignment.Left

    label.Parent = parent

    return label
end

local function CreateTextBox(text, size, position, parent)
    local box = Instance.new("TextBox")

    box.Size = size
    box.Position = position

    box.BackgroundColor3 =
        CONFIG.Theme.Card

    box.Text = tostring(text)

    box.Font = Enum.Font.GothamMedium
    box.TextSize = 12
    box.TextColor3 =
        CONFIG.Theme.TextPrimary

    box.PlaceholderColor3 =
        CONFIG.Theme.TextSecondary

    box.ClearTextOnFocus = false
    box.BorderSizePixel = 0

    box.Parent = parent

    CreateCorner(box, CONFIG.ButtonRadius)
    CreateStroke(box)

    return box
end

local function GetNumber(text, fallback)
    local number = tonumber(text)

    if number == nil then
        return fallback
    end

    return number
end

--==================================================
-- PLAYER LIST
--==================================================

local function GetPlayers()
    return Players:GetPlayers()
end

local function UpdateTargetLabel()
    if not TargetLabel then
        return
    end

    if TargetPlayer then
        TargetLabel.Text =
            TargetPlayer.Name
    else
        TargetLabel.Text = "Nenhum alvo"
    end
end

local function SetTargetByIndex(index)
    local playerList = GetPlayers()

    if #playerList == 0 then
        TargetPlayer = nil
        TargetIndex = 1
        UpdateTargetLabel()
        return
    end

    TargetIndex =
        ((index - 1) % #playerList) + 1

    TargetPlayer =
        playerList[TargetIndex]

    UpdateTargetLabel()
end

local function ChangeTarget(amount)
    local playerList = GetPlayers()

    if #playerList == 0 then
        return
    end

    local currentIndex = 1

    for i, player in ipairs(playerList) do
        if player == TargetPlayer then
            currentIndex = i
            break
        end
    end

    SetTargetByIndex(
        currentIndex + amount
    )
end

--==================================================
-- CARD VISUAL
--==================================================

local function UpdateCardVisual(index)
    local card = Cards[index]

    if not card then
        return
    end

    if Presets[index] then
        card.Status.Text = "Salvo ✓"
        card.Status.TextColor3 =
            CONFIG.Theme.Success

        card.Frame.BackgroundColor3 =
            Color3.fromRGB(28, 36, 32)
    else
        card.Status.Text = "Vazio"
        card.Status.TextColor3 =
            CONFIG.Theme.TextSecondary

        card.Frame.BackgroundColor3 =
            CONFIG.Theme.Card
    end
end

--==================================================
-- TRANSITION
--==================================================

local function CancelTransition()
    if CurrentTween then
        CurrentTween:Cancel()
        CurrentTween = nil
    end

    if CurrentFOVTween then
        CurrentFOVTween:Cancel()
        CurrentFOVTween = nil
    end
end

--==================================================
-- PRESETS
--==================================================

local function SavePreset(index)
    local Camera = GetCamera()

    if not Camera then
        return
    end

    Presets[index] = {
        CFrame = Camera.CFrame,
        FOV = Camera.FieldOfView,
    }

    UpdateCardVisual(index)
end

local function DeletePreset(index)
    Presets[index] = nil
    UpdateCardVisual(index)
end

local function ApplyPreset(index)
    local preset = Presets[index]

    if not preset then
        return
    end

    if FollowEnabled then
        return
    end

    local Camera = GetCamera()

    if not Camera then
        return
    end

    CancelTransition()

    Camera.CameraType =
        Enum.CameraType.Scriptable

    if not IsSmooth then
        Camera.CFrame = preset.CFrame
        Camera.FieldOfView = preset.FOV
        return
    end

    local duration = math.clamp(
        TransitionDuration,
        CONFIG.MinDuration,
        CONFIG.MaxDuration
    )

    local info = TweenInfo.new(
        duration,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.InOut
    )

    CurrentTween = TweenService:Create(
        Camera,
        info,
        {
            CFrame = preset.CFrame
        }
    )

    CurrentFOVTween = TweenService:Create(
        Camera,
        info,
        {
            FieldOfView = preset.FOV
        }
    )

    CurrentTween:Play()
    CurrentFOVTween:Play()

    local tweenReference = CurrentTween

    CurrentTween.Completed:Connect(function()
        if CurrentTween == tweenReference then
            CurrentTween = nil
            CurrentFOVTween = nil
        end
    end)
end

--==================================================
-- FOLLOW
--==================================================

local function StopFollow()
    FollowEnabled = false

    if FollowConnection then
        FollowConnection:Disconnect()
        FollowConnection = nil
    end

    if FollowToggleBtn then
        FollowToggleBtn.Text =
            "ATIVAR FOLLOW"

        FollowToggleBtn.BackgroundColor3 =
            Color3.fromRGB(30, 100, 60)
    end
end

local function StartFollow()
    local Camera = GetCamera()

    if not Camera then
        return
    end

    StopFollow()

    FollowEnabled = true

    Camera.CameraType =
        Enum.CameraType.Scriptable

    if FollowToggleBtn then
        FollowToggleBtn.Text =
            "DESATIVAR FOLLOW"

        FollowToggleBtn.BackgroundColor3 =
            Color3.fromRGB(120, 40, 40)
    end

    FollowConnection =
        RunService.RenderStepped:Connect(function()
            if not FollowEnabled then
                return
            end

            if not TargetPlayer then
                return
            end

            local character =
                TargetPlayer.Character

            if not character then
                return
            end

            local root =
                character:FindFirstChild(
                    "HumanoidRootPart"
                )

            local head =
                character:FindFirstChild("Head")

            if not root then
                return
            end

            local targetPart

            if FollowHead and head then
                targetPart = head
            else
                targetPart = root
            end

            local targetPosition =
                targetPart.Position
                + Vector3.new(
                    0,
                    FollowHeight,
                    0
                )

            local lookVector =
                root.CFrame.LookVector

            local rightVector =
                root.CFrame.RightVector

            local cameraPosition

            if FollowLookAt then
                cameraPosition =
                    targetPosition
                    - (lookVector * FollowDistance)
                    + (rightVector * FollowOffset)
            else
                cameraPosition =
                    targetPosition
                    - (lookVector * FollowDistance)
                    + (rightVector * FollowOffset)
            end

            local desiredCFrame =
                CFrame.lookAt(
                    cameraPosition,
                    targetPosition
                )

            local smoothness =
                math.clamp(
                    FollowSmoothness,
                    0.01,
                    1
                )

            Camera.CFrame =
                Camera.CFrame:Lerp(
                    desiredCFrame,
                    smoothness
                )
        end)
end

--==================================================
-- RESET
--==================================================

local function ResetCamera()
    StopFollow()
    CancelTransition()

    local Camera = GetCamera()

    if not Camera then
        return
    end

    Camera.CameraType =
        Enum.CameraType.Custom

    local character =
        LocalPlayer.Character

    if character then
        local humanoid =
            character:FindFirstChildOfClass(
                "Humanoid"
            )

        if humanoid then
            Camera.CameraSubject =
                humanoid
        end
    end
end

--==================================================
-- UPDATE FOLLOW VALUES
--==================================================

local function UpdateFollowValues()
    FollowDistance = math.max(
        0,
        GetNumber(
            DistBox and DistBox.Text,
            CONFIG.FollowDistance
        )
    )

    FollowHeight = GetNumber(
        HeightBox and HeightBox.Text,
        CONFIG.FollowHeight
    )

    FollowOffset = GetNumber(
        OffsetBox and OffsetBox.Text,
        CONFIG.FollowOffset
    )

    FollowSmoothness = math.clamp(
        GetNumber(
            SmoothBox and SmoothBox.Text,
            CONFIG.FollowSmoothness
        ),
        0.01,
        1
    )

    if DistBox then
        DistBox.Text =
            string.format(
                "%.2f",
                FollowDistance
            )
    end

    if HeightBox then
        HeightBox.Text =
            string.format(
                "%.2f",
                FollowHeight
            )
    end

    if OffsetBox then
        OffsetBox.Text =
            string.format(
                "%.2f",
                FollowOffset
            )
    end

    if SmoothBox then
        SmoothBox.Text =
            string.format(
                "%.2f",
                FollowSmoothness
            )
    end
end

--==================================================
-- BUILD UI
--==================================================

local function BuildUI()

    local old =
        PlayerGui:FindFirstChild(
            "CameraPresetsUI"
        )

    if old then
        old:Destroy()
    end

    Cards = {}

    ScreenGui =
        Instance.new("ScreenGui")

    ScreenGui.Name =
        "CameraPresetsUI"

    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior =
        Enum.ZIndexBehavior.Sibling

    ScreenGui.DisplayOrder = 999
    ScreenGui.IgnoreGuiInset = true

    ScreenGui.Parent = PlayerGui

    --================================================
    -- FLOAT BUTTON
    --================================================

    FloatBtn =
        Instance.new("TextButton")

    FloatBtn.Name =
        "FloatButton"

    FloatBtn.Size =
        UDim2.fromOffset(52, 52)

    FloatBtn.Position =
        UDim2.new(
            1,
            -68,
            0.45,
            0
        )

    FloatBtn.BackgroundColor3 =
        CONFIG.Theme.Accent

    FloatBtn.Text = "CAM"

    FloatBtn.Font =
        Enum.Font.GothamBold

    FloatBtn.TextSize = 13

    FloatBtn.TextColor3 =
        Color3.new(1, 1, 1)

    FloatBtn.AutoButtonColor = false
    FloatBtn.BorderSizePixel = 0

    FloatBtn.Parent = ScreenGui

    CreateCorner(FloatBtn, 26)
    CreateStroke(FloatBtn, 1.5)

    --================================================
    -- MAIN FRAME
    --================================================

    MainFrame =
        Instance.new("Frame")

    MainFrame.Name = "Main"

    MainFrame.Size =
        UDim2.fromOffset(
            CONFIG.BaseWidth,
            CONFIG.BaseHeight
        )

    MainFrame.Position =
        UDim2.new(
            0.5,
            -CONFIG.BaseWidth / 2,
            0.04,
            0
        )

    MainFrame.BackgroundColor3 =
        CONFIG.Theme.Background

    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Visible = true

    MainFrame.Parent = ScreenGui

    CreateCorner(MainFrame)
    CreateStroke(MainFrame, 1.5)

    local scale = 1

    if IsMobile then
        scale = CONFIG.MobileScale
    end

    MainFrame.Size =
        UDim2.fromOffset(
            CONFIG.BaseWidth * scale,
            CONFIG.BaseHeight * scale
        )

    MainFrame.Position =
        UDim2.new(
            0.5,
            -(CONFIG.BaseWidth * scale) / 2,
            IsMobile and 0.025 or 0.04,
            0
        )

    --================================================
    -- HEADER
    --================================================

    local title =
        Instance.new("TextLabel")

    title.Size =
        UDim2.new(1, -20, 0, 26)

    title.Position =
        UDim2.fromOffset(14, 10)

    title.BackgroundTransparency = 1
    title.Text = "CAMERA PRESETS"

    title.Font =
        Enum.Font.GothamBold

    title.TextSize = 17

    title.TextColor3 =
        CONFIG.Theme.TextPrimary

    title.TextXAlignment =
        Enum.TextXAlignment.Left

    title.Parent = MainFrame

    local subtitle =
        Instance.new("TextLabel")

    subtitle.Size =
        UDim2.new(1, -20, 0, 16)

    subtitle.Position =
        UDim2.fromOffset(14, 32)

    subtitle.BackgroundTransparency = 1

    subtitle.Text =
        "Presets + Follow Camera"

    subtitle.Font =
        Enum.Font.Gotham

    subtitle.TextSize = 12

    subtitle.TextColor3 =
        CONFIG.Theme.TextSecondary

    subtitle.TextXAlignment =
        Enum.TextXAlignment.Left

    subtitle.Parent = MainFrame

    local separator =
        Instance.new("Frame")

    separator.Size =
        UDim2.new(1, -28, 0, 1)

    separator.Position =
        UDim2.fromOffset(14, 54)

    separator.BackgroundColor3 =
        CONFIG.Theme.Border

    separator.BorderSizePixel = 0

    separator.Parent = MainFrame

    --================================================
    -- PRESETS
    --================================================

    local startY = 68
    local cardHeight = 58
    local gap = 7

    for i = 1, 5 do

        local card =
            Instance.new("Frame")

        card.Size =
            UDim2.new(
                1,
                -28,
                0,
                cardHeight
            )

        card.Position =
            UDim2.new(
                0,
                14,
                0,
                startY
                    + (i - 1)
                    * (cardHeight + gap)
            )

        card.BackgroundColor3 =
            CONFIG.Theme.Card

        card.BorderSizePixel = 0

        card.Parent = MainFrame

        CreateCorner(card, 10)
        CreateStroke(card)

        local camLabel =
            Instance.new("TextLabel")

        camLabel.Size =
            UDim2.fromOffset(60, 18)

        camLabel.Position =
            UDim2.fromOffset(12, 7)

        camLabel.BackgroundTransparency = 1

        camLabel.Text =
            "CAM " .. i

        camLabel.Font =
            Enum.Font.GothamBold

        camLabel.TextSize = 13

        camLabel.TextColor3 =
            CONFIG.Theme.TextPrimary

        camLabel.TextXAlignment =
            Enum.TextXAlignment.Left

        camLabel.Parent = card

        local status =
            Instance.new("TextLabel")

        status.Size =
            UDim2.fromOffset(80, 16)

        status.Position =
            UDim2.fromOffset(12, 28)

        status.BackgroundTransparency = 1
        status.Text = "Vazio"

        status.Font =
            Enum.Font.Gotham

        status.TextSize = 11

        status.TextColor3 =
            CONFIG.Theme.TextSecondary

        status.TextXAlignment =
            Enum.TextXAlignment.Left

        status.Parent = card

        local saveBtn =
            CreateButton(
                "Salvar",
                CONFIG.Theme.AccentDark,
                UDim2.fromOffset(64, 26)
            )

        saveBtn.Position =
            UDim2.new(
                1,
                -210,
                0.5,
                -13
            )

        saveBtn.Parent = card

        local goBtn =
            CreateButton(
                "Ir",
                Color3.fromRGB(35, 110, 65),
                UDim2.fromOffset(48, 26)
            )

        goBtn.Position =
            UDim2.new(
                1,
                -140,
                0.5,
                -13
            )

        goBtn.Parent = card
                local deleteBtn =
            CreateButton(
                "Apagar",
                Color3.fromRGB(95, 40, 40),
                UDim2.fromOffset(58, 26)
            )

        deleteBtn.Position =
            UDim2.new(
                1,
                -86,
                0.5,
                -13
            )

        deleteBtn.Parent = card

        Cards[i] = {
            Frame = card,
            Status = status,
            Save = saveBtn,
            Go = goBtn,
            Delete = deleteBtn,
        }

        saveBtn.MouseButton1Click:Connect(
            function()
                SavePreset(i)
            end
        )

        goBtn.MouseButton1Click:Connect(
            function()
                ApplyPreset(i)
            end
        )

        deleteBtn.MouseButton1Click:Connect(
            function()
                DeletePreset(i)
            end
        )
    end

    --================================================
    -- TRANSITION
    --================================================

    local bottomY =
        startY
        + 5 * (cardHeight + gap)
        + 14

    CreateLabel(
        "Transição:",
        UDim2.fromOffset(90, 18),
        UDim2.fromOffset(14, bottomY),
        MainFrame
    )

    SmoothBtn =
        CreateButton(
            "SUAVE",
            CONFIG.Theme.Accent,
            UDim2.fromOffset(78, 28)
        )

    SmoothBtn.Position =
        UDim2.fromOffset(
            100,
            bottomY - 5
        )

    SmoothBtn.Parent = MainFrame

    InstantBtn =
        CreateButton(
            "INSTANTÂNEA",
            CONFIG.Theme.Card,
            UDim2.fromOffset(100, 28)
        )

    InstantBtn.Position =
        UDim2.fromOffset(
            186,
            bottomY - 5
        )

    InstantBtn.Parent = MainFrame

    CreateLabel(
        "Duração:",
        UDim2.fromOffset(70, 18),
        UDim2.fromOffset(
            14,
            bottomY + 36
        ),
        MainFrame
    )

    DurationBox =
        CreateTextBox(
            CONFIG.DefaultDuration,
            UDim2.fromOffset(60, 28),
            UDim2.fromOffset(
                90,
                bottomY + 30
            ),
            MainFrame
        )

    SmoothBtn.MouseButton1Click:Connect(
        function()
            IsSmooth = true

            SmoothBtn.BackgroundColor3 =
                CONFIG.Theme.Accent

            InstantBtn.BackgroundColor3 =
                CONFIG.Theme.Card
        end
    )

    InstantBtn.MouseButton1Click:Connect(
        function()
            IsSmooth = false

            SmoothBtn.BackgroundColor3 =
                CONFIG.Theme.Card

            InstantBtn.BackgroundColor3 =
                CONFIG.Theme.Accent
        end
    )

    DurationBox.FocusLost:Connect(
        function()
            local value =
                GetNumber(
                    DurationBox.Text,
                    CONFIG.DefaultDuration
                )

            TransitionDuration =
                math.clamp(
                    value,
                    CONFIG.MinDuration,
                    CONFIG.MaxDuration
                )

            DurationBox.Text =
                string.format(
                    "%.2f",
                    TransitionDuration
                )
        end
    )

    --================================================
    -- FOLLOW
    --================================================

    local followY =
        bottomY + 70

    local followTitle =
        Instance.new("TextLabel")

    followTitle.Size =
        UDim2.new(1, -28, 0, 20)

    followTitle.Position =
        UDim2.fromOffset(
            14,
            followY
        )

    followTitle.BackgroundTransparency = 1
    followTitle.Text = "CÂMERA FOLLOW"

    followTitle.Font =
        Enum.Font.GothamBold

    followTitle.TextSize = 14

    followTitle.TextColor3 =
        CONFIG.Theme.Accent

    followTitle.TextXAlignment =
        Enum.TextXAlignment.Left

    followTitle.Parent = MainFrame

    CreateLabel(
        "Alvo:",
        UDim2.fromOffset(50, 18),
        UDim2.fromOffset(
            14,
            followY + 28
        ),
        MainFrame
    )

    TargetLabel =
        Instance.new("TextLabel")

    TargetLabel.Size =
        UDim2.fromOffset(140, 26)

    TargetLabel.Position =
        UDim2.fromOffset(
            60,
            followY + 24
        )

    TargetLabel.BackgroundColor3 =
        CONFIG.Theme.Card

    TargetLabel.Text =
        LocalPlayer.Name

    TargetLabel.Font =
        Enum.Font.GothamMedium

    TargetLabel.TextSize = 12

    TargetLabel.TextColor3 =
        CONFIG.Theme.TextPrimary

    TargetLabel.BorderSizePixel = 0

    TargetLabel.Parent = MainFrame

    CreateCorner(TargetLabel, 6)
    CreateStroke(TargetLabel)

    local prevBtn =
        CreateButton(
            "<",
            CONFIG.Theme.Card,
            UDim2.fromOffset(32, 26)
        )

    prevBtn.Position =
        UDim2.fromOffset(
            208,
            followY + 24
        )

    prevBtn.Parent = MainFrame

    local nextBtn =
        CreateButton(
            ">",
            CONFIG.Theme.Card,
            UDim2.fromOffset(32, 26)
        )

    nextBtn.Position =
        UDim2.fromOffset(
            246,
            followY + 24
        )

    nextBtn.Parent = MainFrame

    ModeBtn =
        CreateButton(
            "Olhar para Personagem: ON",
            CONFIG.Theme.AccentDark,
            UDim2.new(1, -28, 0, 28)
        )

    ModeBtn.Position =
        UDim2.fromOffset(
            14,
            followY + 60
        )

    ModeBtn.Parent = MainFrame

    HeadBtn =
        CreateButton(
            "Seguir Cabeça: ON",
            Color3.fromRGB(40, 90, 50),
            UDim2.new(1, -28, 0, 28)
        )

    HeadBtn.Position =
        UDim2.fromOffset(
            14,
            followY + 96
        )

    HeadBtn.Parent = MainFrame

        --================================================
    -- FOLLOW VALUES
    --================================================

    CreateLabel(
        "Distância:",
        UDim2.fromOffset(65, 18),
        UDim2.fromOffset(
            14,
            followY + 134
        ),
        MainFrame
    )

    DistBox =
        CreateTextBox(
            FollowDistance,
            UDim2.fromOffset(
                58,
                26
            ),
            UDim2.fromOffset(
                82,
                followY + 130
            ),
            MainFrame
        )

    CreateLabel(
        "Altura:",
        UDim2.fromOffset(55, 18),
        UDim2.fromOffset(
            150,
            followY + 134
        ),
        MainFrame
    )

    HeightBox =
        CreateTextBox(
            FollowHeight,
            UDim2.fromOffset(
                58,
                26
            ),
            UDim2.fromOffset(
                204,
                followY + 130
            ),
            MainFrame
        )

    CreateLabel(
        "Offset:",
        UDim2.fromOffset(55, 18),
        UDim2.fromOffset(
            14,
            followY + 170
        ),
        MainFrame
    )

    OffsetBox =
        CreateTextBox(
            FollowOffset,
            UDim2.fromOffset(
                58,
                26
            ),
            UDim2.fromOffset(
                82,
                followY + 166
            ),
            MainFrame
        )

    CreateLabel(
        "Suavidade:",
        UDim2.fromOffset(70, 18),
        UDim2.fromOffset(
            150,
            followY + 170
        ),
        MainFrame
    )

    SmoothBox =
        CreateTextBox(
            FollowSmoothness,
            UDim2.fromOffset(
                58,
                26
            ),
            UDim2.fromOffset(
                220,
                followY + 166
            ),
            MainFrame
        )

    --================================================
    -- FOLLOW BUTTON
    --================================================

    FollowToggleBtn =
        CreateButton(
            "ATIVAR FOLLOW",
            Color3.fromRGB(30, 100, 60),
            UDim2.new(
                1,
                -28,
                0,
                30
            )
        )

    FollowToggleBtn.Position =
        UDim2.fromOffset(
            14,
            followY + 202
        )

    FollowToggleBtn.Parent = MainFrame

    --================================================
    -- RESET
    --================================================

    ResetBtn =
        CreateButton(
            "RESETAR CÂMERA",
            Color3.fromRGB(80, 50, 50),
            UDim2.new(
                1,
                -28,
                0,
                30
            )
        )

    ResetBtn.Position =
        UDim2.fromOffset(
            14,
            followY + 240
        )

    ResetBtn.Parent = MainFrame

    --================================================
    -- TARGET BUTTONS
    --================================================

    prevBtn.MouseButton1Click:Connect(
        function()
            ChangeTarget(-1)
        end
    )

    nextBtn.MouseButton1Click:Connect(
        function()
            ChangeTarget(1)
        end
    )

    --================================================
    -- MODE BUTTON
    --================================================

    ModeBtn.MouseButton1Click:Connect(
        function()
            FollowLookAt = not FollowLookAt

            if FollowLookAt then
                ModeBtn.Text =
                    "Olhar para Personagem: ON"

                ModeBtn.BackgroundColor3 =
                    CONFIG.Theme.AccentDark
            else
                ModeBtn.Text =
                    "Olhar para Personagem: OFF"

                ModeBtn.BackgroundColor3 =
                    CONFIG.Theme.Card
            end
        end
    )

    --================================================
    -- HEAD BUTTON
    --================================================

    HeadBtn.MouseButton1Click:Connect(
        function()
            FollowHead = not FollowHead

            if FollowHead then
                HeadBtn.Text =
                    "Seguir Cabeça: ON"

                HeadBtn.BackgroundColor3 =
                    Color3.fromRGB(40, 90, 50)
            else
                HeadBtn.Text =
                    "Seguir Cabeça: OFF"

                HeadBtn.BackgroundColor3 =
                    CONFIG.Theme.Card
            end
        end
    )

    --================================================
    -- VALUE BOXES
    --================================================

    DistBox.FocusLost:Connect(
        UpdateFollowValues
    )

    HeightBox.FocusLost:Connect(
        UpdateFollowValues
    )

    OffsetBox.FocusLost:Connect(
        UpdateFollowValues
    )

    SmoothBox.FocusLost:Connect(
        UpdateFollowValues
    )

    --================================================
    -- FOLLOW TOGGLE
    --================================================

    FollowToggleBtn.MouseButton1Click:Connect(
        function()
            UpdateFollowValues()

            if FollowEnabled then
                StopFollow()
            else
                StartFollow()
            end
        end
    )

    --================================================
    -- RESET
    --================================================

    ResetBtn.MouseButton1Click:Connect(
        function()
            ResetCamera()
        end
    )

    --================================================
    -- FLOAT BUTTON
    --================================================

    FloatBtn.MouseButton1Click:Connect(
        function()
            if DragMoved then
                return
            end

            MainFrame.Visible =
                not MainFrame.Visible
        end
    )

    --================================================
    -- INITIAL VISUALS
    --================================================

    for i = 1, 5 do
        UpdateCardVisual(i)
    end

    UpdateTargetLabel()
    UpdateFollowValues()
end

--==================================================
-- DRAG SYSTEM
--==================================================

local function BeginDrag(object, input)
    DraggingObject = object
    DragStart = input.Position
    ObjectStart = object.Position
    DragMoved = false
end

local function UpdateDrag(input)
    if not DraggingObject then
        return
    end

    local delta =
        input.Position - DragStart

    if math.abs(delta.X) > 5
        or math.abs(delta.Y) > 5 then
        DragMoved = true
    end

    DraggingObject.Position =
        UDim2.new(
            ObjectStart.X.Scale,
            ObjectStart.X.Offset + delta.X,
            ObjectStart.Y.Scale,
            ObjectStart.Y.Offset + delta.Y
        )
end

local function EndDrag()
    DraggingObject = nil
    DragStart = nil
    ObjectStart = nil

    task.delay(
        0.05,
        function()
            DragMoved = false
        end
    )
end

local function ConnectDrag(object)
    object.InputBegan:Connect(
        function(input)
            if input.UserInputType ==
                Enum.UserInputType.MouseButton1
                or input.UserInputType ==
                Enum.UserInputType.Touch then

                BeginDrag(
                    object,
                    input
                )
            end
        end
    )
end

ConnectDrag(FloatBtn)

UserInputService.InputChanged:Connect(
    function(input)
        if not DraggingObject then
            return
        end

        if input.UserInputType ==
            Enum.UserInputType.MouseMovement
            or input.UserInputType ==
            Enum.UserInputType.Touch then

            UpdateDrag(input)
        end
    end
)

UserInputService.InputEnded:Connect(
    function(input)
        if input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or input.UserInputType ==
            Enum.UserInputType.Touch then

            if DraggingObject then
                EndDrag()
            end
        end
    end
)

--==================================================
-- PLAYER EVENTS
--==================================================

Players.PlayerRemoving:Connect(
    function(player)
        if player == TargetPlayer then
            local playerList =
                GetPlayers()

            if #playerList > 0 then
                SetTargetByIndex(1)
            else
                TargetPlayer = nil
                UpdateTargetLabel()
            end
        end
    end
)

Players.PlayerAdded:Connect(
    function()
        task.defer(
            function()
                if not TargetPlayer then
                    SetTargetByIndex(1)
                end
            end
        )
    end
)

--==================================================
-- CHARACTER RESPAWN
--==================================================

LocalPlayer.CharacterAdded:Connect(
    function()
        task.wait(0.5)

        if not FollowEnabled then
            local Camera = GetCamera()

            if Camera then
                Camera.CameraType =
                    Enum.CameraType.Custom
            end
        end
    end
)

--==================================================
-- BUILD
--==================================================

BuildUI()

print(
    "[CameraPresets] Sistema carregado com sucesso."
)
