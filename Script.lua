local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local MAX_RANGE = 1000
local LOBBY_CENTER = Vector3.new(44.952274322509766, 10.798693656921387, 9.138858795166016)
local LOBBY_RADIUS = 60

local parentGui
local success, _ = pcall(function()
    parentGui = game:GetService("CoreGui")
end)
if not success or not parentGui then
    parentGui = LocalPlayer:WaitForChild("PlayerGui")
end

if parentGui:FindFirstChild("MinimalXrayGui") then
    parentGui.MinimalXrayGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MinimalXrayGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = parentGui

local connections = {}
local fovRadius = 20
local fovActive = false
local aimActive = false
local aimStrength = 100
local noclipActive = false
local speedActive = false
local speedMultiplier = 2
local fullbrightActive = false
local infJumpActive = false
local smoothFallActive = false
local spinActive = false
local spinSpeed = 50
local tpBehindActive = false
local lockedTargetHead = nil
local lastLockedTargetRoot = nil

local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Ambient = Lighting.Ambient
}

local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.Parent = screenGui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(220, 220, 230)
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.2
fovStroke.Parent = fovCircle

local EXPANDED_WIDTH = 270
local MINIMIZED_WIDTH = 110
local EXPANDED_HEIGHT = 248
local MINIMIZED_HEIGHT = 32

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, EXPANDED_WIDTH, 0, EXPANDED_HEIGHT)
frame.Position = UDim2.new(0.5, -EXPANDED_WIDTH/2, 0.15, 0)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
frame.BackgroundTransparency = 0.05
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = true
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 8)
frameCorner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(45, 45, 58)
frameStroke.Thickness = 1
frameStroke.Transparency = 0.3
frameStroke.Parent = frame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -60, 0, 32)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
titleLabel.Text = "Xwol"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = frame

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 22, 0, 22)
minimizeBtn.Position = UDim2.new(1, -50, 0, 5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Text = "-"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 13
minimizeBtn.Parent = frame

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 5)
minCorner.Parent = minimizeBtn

local minStroke = Instance.new("UIStroke")
minStroke.Color = Color3.fromRGB(70, 70, 90)
minStroke.Thickness = 1
minStroke.Parent = minimizeBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -24, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 10.5
closeBtn.Parent = frame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = closeBtn

local closeStroke = Instance.new("UIStroke")
closeStroke.Color = Color3.fromRGB(70, 70, 90)
closeStroke.Thickness = 1
closeStroke.Parent = closeBtn

local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, 0, 1, -32)
contentContainer.Position = UDim2.new(0, 0, 0, 32)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = frame

local splitLine = Instance.new("Frame")
splitLine.Name = "SplitLine"
splitLine.Size = UDim2.new(0, 1, 1, -12)
splitLine.AnchorPoint = Vector2.new(0.5, 0)
splitLine.Position = UDim2.new(0.5, 0, 0, 6)
splitLine.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
splitLine.BorderSizePixel = 0
splitLine.ZIndex = 2
splitLine.Parent = contentContainer

local function createControl(parent, labelText, yPos, height, isRightSide, hasSlider, minVal, maxVal, currentVal, onUpdate, onToggle)
    local xPos = isRightSide and 140 or 8
    local blockWidth = 122

    local bgCard = Instance.new("Frame")
    bgCard.Size = UDim2.new(0, blockWidth, 0, height)
    bgCard.Position = UDim2.new(0, xPos, 0, yPos)
    bgCard.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    bgCard.BorderSizePixel = 0
    bgCard.Parent = parent

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 6)
    cardCorner.Parent = bgCard

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(32, 32, 42)
    cardStroke.Thickness = 1
    cardStroke.Parent = bgCard

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 65, 0, 16)
    label.Position = UDim2.new(0, 8, 0, 6)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(180, 180, 190)
    label.Text = labelText
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = bgCard

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(0, 30, 0, 16)
    track.Position = UDim2.new(1, -38, 0, 6)
    track.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = bgCard

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local trackStroke = Instance.new("UIStroke")
    trackStroke.Color = Color3.fromRGB(50, 50, 60)
    trackStroke.Thickness = 1
    trackStroke.Parent = track

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(0, 2, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
    knob.Parent = track

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local currentState = false
    local sTrack, sFill, sKnob, valText, valPrefix
    local colorMin = Color3.fromRGB(45, 45, 55)
    local colorMax = Color3.fromRGB(120, 120, 150)

    if hasSlider then
        local initialAlpha = math.clamp((currentVal - minVal) / (maxVal - minVal), 0, 1)

        valPrefix = Instance.new("TextLabel")
        valPrefix.Size = UDim2.new(0, 22, 0, 14)
        valPrefix.Position = UDim2.new(0, 8, 0, 27)
        valPrefix.BackgroundTransparency = 1
        valPrefix.TextColor3 = Color3.fromRGB(90, 90, 100)
        valPrefix.Text = "Val:"
        valPrefix.Font = Enum.Font.GothamMedium
        valPrefix.TextSize = 9.5
        valPrefix.TextXAlignment = Enum.TextXAlignment.Left
        valPrefix.Parent = bgCard

        valText = Instance.new("TextLabel")
        valText.Size = UDim2.new(0, 24, 0, 14)
        valText.Position = UDim2.new(1, -32, 0, 27)
        valText.BackgroundTransparency = 1
        valText.TextColor3 = Color3.fromRGB(90, 90, 100)
        valText.Text = tostring(currentVal)
        valText.Font = Enum.Font.GothamMedium
        valText.TextSize = 9.5
        valText.TextXAlignment = Enum.TextXAlignment.Right
        valText.Parent = bgCard

        local sliderWidth = 52
        sTrack = Instance.new("TextButton")
        sTrack.Size = UDim2.new(0, sliderWidth, 0, 5)
        sTrack.Position = UDim2.new(0, 34, 0, 31)
        sTrack.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        sTrack.Text = ""
        sTrack.AutoButtonColor = false
        sTrack.Parent = bgCard

        local sCorner = Instance.new("UICorner")
        sCorner.CornerRadius = UDim.new(1, 0)
        sCorner.Parent = sTrack

        sFill = Instance.new("Frame")
        sFill.Size = UDim2.new(initialAlpha, 0, 1, 0)
        sFill.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        sFill.BorderSizePixel = 0
        sFill.Parent = sTrack

        local sFillCorner = Instance.new("UICorner")
        sFillCorner.CornerRadius = UDim.new(1, 0)
        sFillCorner.Parent = sFill

        sKnob = Instance.new("Frame")
        sKnob.Size = UDim2.new(0, 9, 0, 9)
        sKnob.Position = UDim2.new(1, -4, 0.5, -4.5)
        sKnob.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
        sKnob.Parent = sFill

        local sKnobCorner = Instance.new("UICorner")
        sKnobCorner.CornerRadius = UDim.new(1, 0)
        sKnobCorner.Parent = sKnob

        local dragging = false
        local function updateSlider(input)
            if not currentState then return end
            local trackPos = sTrack.AbsolutePosition.X
            local trackWidth = sTrack.AbsoluteSize.X
            if trackWidth <= 0 then return end
            local relativeX = math.clamp(input.Position.X - trackPos, 0, trackWidth)
            local alpha = relativeX / trackWidth
            local calculatedVal = math.floor(minVal + (maxVal - minVal) * alpha + 0.5)
            sFill.Size = UDim2.new(alpha, 0, 1, 0)
            
            sFill.BackgroundColor3 = colorMin:Lerp(colorMax, alpha)
            
            valText.Text = tostring(calculatedVal)
            if onUpdate then
                onUpdate(calculatedVal)
            end
        end

        table.insert(connections, sTrack.InputBegan:Connect(function(input)
            if not currentState then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateSlider(input)
            end
        end))

        table.insert(connections, UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateSlider(input)
            end
        end))

        table.insert(connections, UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))
    end

    track.MouseButton1Click:Connect(function()
        currentState = not currentState
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        if currentState then
            TweenService:Create(track, tweenInfo, {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}):Play()
            TweenService:Create(knob, tweenInfo, {Position = UDim2.new(1, -14, 0.5, -6), BackgroundColor3 = Color3.fromRGB(210, 210, 220)}):Play()
            TweenService:Create(label, tweenInfo, {TextColor3 = Color3.fromRGB(240, 240, 255)}):Play()
            TweenService:Create(cardStroke, tweenInfo, {Color = Color3.fromRGB(55, 55, 75)}):Play()

            if hasSlider and sTrack and sFill and sKnob and valText and valPrefix then
                local activeAlpha = sFill.Size.X.Scale
                TweenService:Create(sTrack, tweenInfo, {BackgroundColor3 = Color3.fromRGB(35, 35, 45)}):Play()
                TweenService:Create(sFill, tweenInfo, {BackgroundColor3 = colorMin:Lerp(colorMax, activeAlpha)}):Play()
                TweenService:Create(sKnob, tweenInfo, {BackgroundColor3 = Color3.fromRGB(210, 210, 220)}):Play()
                TweenService:Create(valText, tweenInfo, {TextColor3 = Color3.fromRGB(160, 160, 175)}):Play()
                TweenService:Create(valPrefix, tweenInfo, {TextColor3 = Color3.fromRGB(160, 160, 175)}):Play()
            end
        else
            TweenService:Create(track, tweenInfo, {BackgroundColor3 = Color3.fromRGB(30, 30, 35)}):Play()
            TweenService:Create(knob, tweenInfo, {Position = UDim2.new(0, 2, 0.5, -6), BackgroundColor3 = Color3.fromRGB(120, 120, 130)}):Play()
            TweenService:Create(label, tweenInfo, {TextColor3 = Color3.fromRGB(180, 180, 190)}):Play()
            TweenService:Create(cardStroke, tweenInfo, {Color = Color3.fromRGB(32, 32, 42)}):Play()

            if hasSlider and sTrack and sFill and sKnob and valText and valPrefix then
                TweenService:Create(sTrack, tweenInfo, {BackgroundColor3 = Color3.fromRGB(25, 25, 30)}):Play()
                TweenService:Create(sFill, tweenInfo, {BackgroundColor3 = Color3.fromRGB(30, 30, 35)}):Play()
                TweenService:Create(sKnob, tweenInfo, {BackgroundColor3 = Color3.fromRGB(90, 90, 100)}):Play()
                TweenService:Create(valText, tweenInfo, {TextColor3 = Color3.fromRGB(90, 90, 100)}):Play()
                TweenService:Create(valPrefix, tweenInfo, {TextColor3 = Color3.fromRGB(90, 90, 100)}):Play()
            end
        end
        if onToggle then
            onToggle(currentState)
        end
    end)

    return track
end

local xrayActive = false
local function applyHighlight(char)
    if not char or char == LocalPlayer.Character then return end
    if not char:FindFirstChild("HumanoidRootPart") then
        char:WaitForChild("HumanoidRootPart", 3)
    end
    if char and not char:FindFirstChild("XrayHL") then
        local hl = Instance.new("Highlight")
        hl.Name = "XrayHL"
        hl.Adornee = char
        hl.FillTransparency = 1
        hl.OutlineTransparency = 0
        hl.OutlineColor = Color3.fromRGB(255, 60, 60)
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = char
    end
end

local function removeHighlight(char)
    if char then
        local hl = char:FindFirstChild("XrayHL")
        if hl then hl:Destroy() end
    end
end

local function removeAnimations(char)
    if not char then return end
    local animateScript = char:FindFirstChild("Animate")
    if animateScript then
        animateScript.Disabled = true
        animateScript:Destroy()
    end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            animator:Destroy()
        end
    end
end

local function trackPlayer(plr)
    if plr == LocalPlayer then return end
    if plr.Character then
        if xrayActive then applyHighlight(plr.Character) end
        removeAnimations(plr.Character)
    end
    table.insert(connections, plr.CharacterAdded:Connect(function(char)
        if xrayActive then applyHighlight(char) end
        task.wait(0.5)
        removeAnimations(char)
    end))
end

for _, plr in pairs(Players:GetPlayers()) do
    trackPlayer(plr)
end
table.insert(connections, Players.PlayerAdded:Connect(trackPlayer))

createControl(contentContainer, "X-Ray", 6, 28, false, false, 0, 0, 0, nil, function(state)
    xrayActive = state
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character then
            if xrayActive then applyHighlight(plr.Character) else removeHighlight(plr.Character) end
        end
    end
end)

createControl(contentContainer, "Speed", 40, 46, false, true, 1, 5, speedMultiplier, function(val)
    speedMultiplier = val
end, function(state)
    speedActive = state
end)

createControl(contentContainer, "NoClip", 92, 28, false, false, 0, 0, 0, nil, function(state)
    noclipActive = state
end)

createControl(contentContainer, "Inf Jump", 126, 28, false, false, 0, 0, 0, nil, function(state)
    infJumpActive = state
end)

createControl(contentContainer, "Spin", 160, 46, false, true, 10, 200, spinSpeed, function(val)
    spinSpeed = val
end, function(state)
    spinActive = state
end)

createControl(contentContainer, "Fullbright", 6, 28, true, false, 0, 0, 0, nil, function(state)
    fullbrightActive = state
    if not fullbrightActive then
        Lighting.Brightness = originalLighting.Brightness
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.FogEnd = originalLighting.FogEnd
        Lighting.GlobalShadows = originalLighting.GlobalShadows
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        Lighting.Ambient = originalLighting.Ambient
    end
end)

createControl(contentContainer, "FOV", 40, 46, true, true, 20, 300, fovRadius, function(val)
    fovRadius = val
    fovCircle.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
end, function(state)
    fovActive = state
    fovCircle.Visible = fovActive
end)

createControl(contentContainer, "Aim", 92, 46, true, true, 1, 100, aimStrength, function(val)
    aimStrength = val
end, function(state)
    aimActive = state
end)

createControl(contentContainer, "Smooth Fall", 144, 28, true, false, 0, 0, 0, nil, function(state)
    smoothFallActive = state
end)

createControl(contentContainer, "TP Behind", 178, 28, true, false, 0, 0, 0, nil, function(state)
    tpBehindActive = state
    if not state then
        lockedTargetHead = nil
        if lastLockedTargetRoot then
            pcall(function() lastLockedTargetRoot.Anchored = false end)
            lastLockedTargetRoot = nil
        end
    end
end)

local function neutralizeFallDamage(character)
    for _, desc in ipairs(character:GetDescendants()) do
        if desc:IsA("LocalScript") or desc:IsA("ModuleScript") then
            local name = desc.Name:lower()
            if name:find("fall") or name:find("damage") or name:find("ragdoll") or name:find("flinger") then
                pcall(function()
                    desc.Disabled = true
                    desc:Destroy()
                end)
            end
        end
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        table.insert(connections, humanoid.StateChanged:Connect(function(_, newState)
            if newState == Enum.HumanoidStateType.Freefall or newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.FallingDown then
                pcall(function()
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                end)
            end
        end))
    end
end

local function setupCharacter(char)
    neutralizeFallDamage(char)
    table.insert(connections, char.DescendantAdded:Connect(function(desc)
        if desc:IsA("LocalScript") or desc:IsA("ModuleScript") then
            local name = desc.Name:lower()
            if name:find("fall") or name:find("damage") or name:find("ragdoll") or name:find("flinger") then
                pcall(function()
                    desc.Disabled = true
                    desc:Destroy()
                end)
            end
        end
    end))
end

if LocalPlayer.Character then
    setupCharacter(LocalPlayer.Character)
end
table.insert(connections, LocalPlayer.CharacterAdded:Connect(function(char)
    lockedTargetHead = nil
    if lastLockedTargetRoot then
        pcall(function() lastLockedTargetRoot.Anchored = false end)
        lastLockedTargetRoot = nil
    end
    setupCharacter(char)
end))

local function isInLobby(pos)
    if not LOBBY_CENTER or LOBBY_RADIUS <= 0 then return false end
    return (pos - LOBBY_CENTER).Magnitude <= LOBBY_RADIUS
end

local function getClosestTargetInFOV(center)
    local closestTarget = nil
    local shortestDistance = math.huge
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local head = char:FindFirstChild("Head")
            local root = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            
            if head and root and humanoid and humanoid.Health > 0 then
                if not isInLobby(root.Position) then
                    local worldDist = localRoot and (localRoot.Position - root.Position).Magnitude or math.huge
                    if worldDist <= MAX_RANGE then
                        local headScreenPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
                        if headOnScreen then
                            local dist = (Vector2.new(headScreenPos.X, headScreenPos.Y) - center).Magnitude
                            if (not fovActive or dist <= fovRadius) and dist < shortestDistance then
                                shortestDistance = dist
                                closestTarget = head
                            end
                        end
                    end
                end
            end
        end
    end

    return closestTarget
end

local function getAutoSwitchTarget()
    local closestTarget = nil
    local shortestDistance = math.huge
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local head = char:FindFirstChild("Head")
            local root = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            
            if head and root and humanoid and humanoid.Health > 0 then
                if not isInLobby(root.Position) then
                    local worldDist = (localRoot.Position - root.Position).Magnitude
                    if worldDist <= MAX_RANGE then
                        if worldDist < shortestDistance then
                            shortestDistance = worldDist
                            closestTarget = head
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end

table.insert(connections, RunService.Stepped:Connect(function(dt)
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")

    if noclipActive then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    if speedActive and humanoid and rootPart and humanoid.MoveDirection.Magnitude > 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Climbing and not humanoid.PlatformStand and not humanoid.Sit then
        local currentSpeed = humanoid.WalkSpeed
        if currentSpeed > 0 then
            rootPart.CFrame = rootPart.CFrame + (humanoid.MoveDirection * (currentSpeed * (speedMultiplier - 1) * 0.016))
        end
    end

    if smoothFallActive and rootPart then
        local vel = rootPart.AssemblyLinearVelocity
        if vel.Y < -15 then
            rootPart.AssemblyLinearVelocity = Vector3.new(vel.X, -15, vel.Z)
        end
    end

    if infJumpActive and humanoid and rootPart then
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or humanoid.Jump then
            rootPart.AssemblyLinearVelocity = Vector3.new(rootPart.AssemblyLinearVelocity.X, 35, rootPart.AssemblyLinearVelocity.Z)
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end

    if fullbrightActive then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Ambient = Color3.new(1, 1, 1)
    end

    if tpBehindActive and rootPart then
        local viewportSize = Camera.ViewportSize
        local center = Vector2.new(viewportSize.X * 0.5, viewportSize.Y * 0.5)

        local isTargetValid = false
        if lockedTargetHead and lockedTargetHead.Parent then
            local targetChar = lockedTargetHead.Parent
            local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
            if targetHum and targetHum.Health > 0 and targetRoot then
                if not isInLobby(targetRoot.Position) then
                    local worldDist = (rootPart.Position - targetRoot.Position).Magnitude
                    if worldDist <= MAX_RANGE then
                        isTargetValid = true
                    end
                end
            end
        end

        if not isTargetValid then
            if lastLockedTargetRoot then
                pcall(function() lastLockedTargetRoot.Anchored = false end)
                lastLockedTargetRoot = nil
            end
            lockedTargetHead = getAutoSwitchTarget()
            if not lockedTargetHead then
                lockedTargetHead = getClosestTargetInFOV(center)
            end
        end

        if lockedTargetHead and lockedTargetHead.Parent then
            local targetChar = lockedTargetHead.Parent
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                if lastLockedTargetRoot and lastLockedTargetRoot ~= targetRoot then
                    pcall(function() lastLockedTargetRoot.Anchored = false end)
                end
                lastLockedTargetRoot = targetRoot

                targetRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                targetRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                targetRoot.Anchored = true

                rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                rootPart.CFrame = targetRoot.CFrame * CFrame.new(0, 0.5, 1)
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, lockedTargetHead.Position)
            end
        else
            if lastLockedTargetRoot then
                pcall(function() lastLockedTargetRoot.Anchored = false end)
                lastLockedTargetRoot = nil
            end
        end
    else
        if lastLockedTargetRoot then
            pcall(function() lastLockedTargetRoot.Anchored = false end)
            lastLockedTargetRoot = nil
        end
    end
end))

table.insert(connections, RunService.RenderStepped:Connect(function(dt)
    local char = LocalPlayer.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")

    if spinActive and rootPart then
        local angle = os.clock() * (spinSpeed * 0.2)
        local currentPos = rootPart.Position
        rootPart.CFrame = CFrame.new(currentPos) * CFrame.Angles(0, angle, 0)
    end

    local viewportSize = Camera.ViewportSize
    local center = Vector2.new(viewportSize.X * 0.5, viewportSize.Y * 0.5)

    if fovCircle.Visible then
        fovCircle.Position = UDim2.new(0, center.X, 0, center.Y)
    end

    if aimActive and not tpBehindActive then
        local target = getClosestTargetInFOV(center)
        if target then
            local currentCF = Camera.CFrame
            local targetCF = CFrame.lookAt(currentCF.Position, target.Position)
            if aimStrength >= 100 then
                Camera.CFrame = targetCF
            else
                Camera.CFrame = currentCF:Lerp(targetCF, math.clamp((aimStrength / 100) * 20 * dt, 0.01, 1))
            end
        end
    end
end))

local isMinimized = false
table.insert(connections, minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    if isMinimized then
        minimizeBtn.Text = "+"
        splitLine.Visible = false
        TweenService:Create(frame, tweenInfo, {Size = UDim2.new(0, MINIMIZED_WIDTH, 0, MINIMIZED_HEIGHT)}):Play()
    else
        minimizeBtn.Text = "-"
        splitLine.Visible = true
        TweenService:Create(frame, tweenInfo, {Size = UDim2.new(0, EXPANDED_WIDTH, 0, EXPANDED_HEIGHT)}):Play()
    end
end))

closeBtn.MouseButton1Click:Connect(function()
    if lastLockedTargetRoot then
        pcall(function() lastLockedTargetRoot.Anchored = false end)
    end
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    connections = nil
    Lighting.Brightness = originalLighting.Brightness
    Lighting.ClockTime = originalLighting.ClockTime
    Lighting.FogEnd = originalLighting.FogEnd
    Lighting.GlobalShadows = originalLighting.GlobalShadows
    Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    Lighting.Ambient = originalLighting.Ambient
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character then removeHighlight(plr.Character) end
    end
    screenGui:Destroy()
end)
