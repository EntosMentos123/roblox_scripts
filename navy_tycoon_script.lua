-- ESP Script | Toggle: Right Control

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- State
local ESPEnabled = false
local NamesEnabled = false
local BoxesEnabled = true
local FlyEnabled = false
local NoclipEnabled = false
local ESPColor = Color3.fromRGB(0, 255, 0)
local NameColor = Color3.fromRGB(0, 255, 0)
local FlySpeed = 50
local WalkSpeed = 16
local JumpPower = 50
local GuiVisible = true
local SpectateTarget = nil
local SpectateConnection = nil

local Colors = {
    { color = Color3.fromRGB(0, 255, 0)    },
    { color = Color3.fromRGB(255, 50, 50)   },
    { color = Color3.fromRGB(50, 150, 255)  },
    { color = Color3.fromRGB(255, 255, 255) },
    { color = Color3.fromRGB(255, 220, 0)   },
    { color = Color3.fromRGB(255, 100, 200) },
}

-- Theme
local BG        = Color3.fromRGB(18, 22, 35)
local HEADER_BG = Color3.fromRGB(24, 29, 45)
local ACCENT    = Color3.fromRGB(80, 200, 255)
local TEXT_ON   = Color3.fromRGB(210, 215, 230)
local TEXT_OFF  = Color3.fromRGB(100, 110, 140)
local GREEN_ON  = Color3.fromRGB(80, 220, 120)
local ROW_HOVER = Color3.fromRGB(26, 32, 50)
local ROW_SEL   = Color3.fromRGB(22, 65, 40)
local DIV_COL   = Color3.fromRGB(30, 37, 56)
local BLUE_SEL  = Color3.fromRGB(20, 50, 90)

local PANEL_W  = 180
local HEADER_H = 30
local ROW_H    = 26

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ClientGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer.PlayerGui

--------------------------------------------------------------------
-- Drag
--------------------------------------------------------------------
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

--------------------------------------------------------------------
-- Fade
--------------------------------------------------------------------
local function fadeIn(frame)
    frame.Visible = true
    local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(frame, info, {BackgroundTransparency = 0}):Play()
    for _, d in ipairs(frame:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
            TweenService:Create(d, info, {TextTransparency = 0}):Play()
        end
    end
end

local function fadeOut(frame)
    local info = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local t = TweenService:Create(frame, info, {BackgroundTransparency = 1})
    for _, d in ipairs(frame:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
            TweenService:Create(d, info, {TextTransparency = 1}):Play()
        end
    end
    t:Play()
    t.Completed:Connect(function() frame.Visible = false end)
end

--------------------------------------------------------------------
-- Panel factory
--------------------------------------------------------------------
local allPanels = {}

local function makePanel(title, xOffset, yOffset, rowDefs)
    local totalH = HEADER_H + #rowDefs * ROW_H + math.max(0, #rowDefs - 1) + 6

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, PANEL_W, 0, totalH)
    frame.Position = UDim2.new(0.5, xOffset, 0.5, yOffset)
    frame.BackgroundColor3 = BG
    frame.BorderSizePixel = 0
    frame.Visible = true
    frame.Parent = ScreenGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, HEADER_H)
    header.BackgroundColor3 = HEADER_BG
    header.BorderSizePixel = 0
    header.ZIndex = 2
    header.Parent = frame
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 5)

    local hFill = Instance.new("Frame")
    hFill.Size = UDim2.new(1, 0, 0, 6)
    hFill.Position = UDim2.new(0, 0, 1, -6)
    hFill.BackgroundColor3 = HEADER_BG
    hFill.BorderSizePixel = 0
    hFill.ZIndex = 2
    hFill.Parent = header

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3 = ACCENT
    bar.BorderSizePixel = 0
    bar.ZIndex = 3
    bar.Parent = header

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -14, 1, 0)
    titleLbl.Position = UDim2.new(0, 12, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = ACCENT
    titleLbl.TextSize = 13
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 3
    titleLbl.Parent = header

    makeDraggable(frame, header)

    for i, def in ipairs(rowDefs) do
        local yOff = HEADER_H + (i - 1) * (ROW_H + 1) + 3
        def(frame, yOff)
        if i < #rowDefs then
            local div = Instance.new("Frame")
            div.Size = UDim2.new(1, 0, 0, 1)
            div.Position = UDim2.new(0, 0, 0, yOff + ROW_H)
            div.BackgroundColor3 = DIV_COL
            div.BorderSizePixel = 0
            div.ZIndex = 2
            div.Parent = frame
        end
    end

    table.insert(allPanels, frame)
    return frame
end

--------------------------------------------------------------------
-- Search registry
--------------------------------------------------------------------
local searchItems = {}
local function reg(label, fn) table.insert(searchItems, {label = label, action = fn}) end

--------------------------------------------------------------------
-- Row types
--------------------------------------------------------------------
local function toggleRow(label, default, onChange)
    return function(parent, yOff)
        local state = default
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, 0, 0, ROW_H)
        row.Position = UDim2.new(0, 0, 0, yOff)
        row.BackgroundColor3 = state and ROW_SEL or BG
        row.BorderSizePixel = 0
        row.Text = ""
        row.AutoButtonColor = false
        row.ZIndex = 2
        row.Parent = parent

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -32, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = state and TEXT_ON or TEXT_OFF
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 3
        lbl.Parent = row

        local check = Instance.new("TextLabel")
        check.Size = UDim2.new(0, 22, 1, 0)
        check.Position = UDim2.new(1, -24, 0, 0)
        check.BackgroundTransparency = 1
        check.Text = state and "✓" or ""
        check.TextColor3 = GREEN_ON
        check.TextSize = 13
        check.Font = Enum.Font.GothamBold
        check.ZIndex = 3
        check.Parent = row

        local function update()
            row.BackgroundColor3 = state and ROW_SEL or BG
            lbl.TextColor3 = state and TEXT_ON or TEXT_OFF
            check.Text = state and "✓" or ""
        end

        row.MouseButton1Click:Connect(function()
            state = not state; update(); onChange(state)
        end)
        row.MouseEnter:Connect(function()
            if not state then row.BackgroundColor3 = ROW_HOVER end
        end)
        row.MouseLeave:Connect(function()
            if not state then row.BackgroundColor3 = BG end
        end)
        reg(label, function() state = not state; update(); onChange(state) end)
    end
end

local function valueRow(label, default, min, max, step, onChange)
    return function(parent, yOff)
        local val = default
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, ROW_H)
        row.Position = UDim2.new(0, 0, 0, yOff)
        row.BackgroundColor3 = BG
        row.BorderSizePixel = 0
        row.ZIndex = 2
        row.Parent = parent

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 80, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = TEXT_OFF
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 3
        lbl.Parent = row

        local minus = Instance.new("TextButton")
        minus.Size = UDim2.new(0, 18, 0, 18)
        minus.Position = UDim2.new(1, -58, 0.5, -9)
        minus.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
        minus.BorderSizePixel = 0
        minus.Text = "-"
        minus.TextColor3 = TEXT_ON
        minus.TextSize = 14
        minus.Font = Enum.Font.GothamBold
        minus.ZIndex = 3
        minus.Parent = row
        Instance.new("UICorner", minus).CornerRadius = UDim.new(0, 3)

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0, 26, 1, 0)
        valLbl.Position = UDim2.new(1, -38, 0, 0)
        valLbl.BackgroundTransparency = 1
        valLbl.Text = tostring(val)
        valLbl.TextColor3 = ACCENT
        valLbl.TextSize = 11
        valLbl.Font = Enum.Font.GothamBold
        valLbl.ZIndex = 3
        valLbl.Parent = row

        local plus = Instance.new("TextButton")
        plus.Size = UDim2.new(0, 18, 0, 18)
        plus.Position = UDim2.new(1, -16, 0.5, -9)
        plus.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
        plus.BorderSizePixel = 0
        plus.Text = "+"
        plus.TextColor3 = TEXT_ON
        plus.TextSize = 14
        plus.Font = Enum.Font.GothamBold
        plus.ZIndex = 3
        plus.Parent = row
        Instance.new("UICorner", plus).CornerRadius = UDim.new(0, 3)

        minus.MouseButton1Click:Connect(function()
            val = math.max(min, val - step)
            valLbl.Text = tostring(val)
            onChange(val)
        end)
        plus.MouseButton1Click:Connect(function()
            val = math.min(max, val + step)
            valLbl.Text = tostring(val)
            onChange(val)
        end)
    end
end

local function colorRow(label, onChange)
    return function(parent, yOff)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, ROW_H)
        row.Position = UDim2.new(0, 0, 0, yOff)
        row.BackgroundColor3 = BG
        row.BorderSizePixel = 0
        row.ZIndex = 2
        row.Parent = parent

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 68, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = TEXT_OFF
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 3
        lbl.Parent = row

        local SW = 14
        local GAP = 3
        local totalSwW = #Colors * SW + (#Colors - 1) * GAP
        local startX = PANEL_W - totalSwW - 10
        local selected = nil

        for i, entry in ipairs(Colors) do
            local sw = Instance.new("TextButton")
            sw.Size = UDim2.new(0, SW, 0, SW)
            sw.Position = UDim2.new(0, startX + (i-1)*(SW+GAP), 0.5, -SW/2)
            sw.BackgroundColor3 = entry.color
            sw.BorderSizePixel = 0
            sw.Text = ""
            sw.ZIndex = 3
            sw.Parent = row
            Instance.new("UICorner", sw).CornerRadius = UDim.new(0, 2)
            sw.MouseButton1Click:Connect(function()
                if selected then selected.BorderSizePixel = 0 end
                sw.BorderSizePixel = 2
                sw.BorderColor3 = Color3.fromRGB(255, 255, 255)
                selected = sw
                onChange(entry.color)
            end)
        end
    end
end

--------------------------------------------------------------------
-- Spectate panel (custom, not using makePanel so we can resize it)
--------------------------------------------------------------------
local SPEC_W = 180
local specEnabled = false

local specFrame = Instance.new("Frame")
specFrame.Size = UDim2.new(0, SPEC_W, 0, HEADER_H)
specFrame.Position = UDim2.new(0.5, 20 + PANEL_W + 10, 0.5, -80)
specFrame.BackgroundColor3 = BG
specFrame.BorderSizePixel = 0
specFrame.ClipsDescendants = true
specFrame.Visible = true
specFrame.Parent = ScreenGui
Instance.new("UICorner", specFrame).CornerRadius = UDim.new(0, 5)

-- Header
local specHeader = Instance.new("Frame")
specHeader.Size = UDim2.new(1, 0, 0, HEADER_H)
specHeader.BackgroundColor3 = HEADER_BG
specHeader.BorderSizePixel = 0
specHeader.ZIndex = 2
specHeader.Parent = specFrame
Instance.new("UICorner", specHeader).CornerRadius = UDim.new(0, 5)

local specHFill = Instance.new("Frame")
specHFill.Size = UDim2.new(1, 0, 0, 6)
specHFill.Position = UDim2.new(0, 0, 1, -6)
specHFill.BackgroundColor3 = HEADER_BG
specHFill.BorderSizePixel = 0
specHFill.ZIndex = 2
specHFill.Parent = specHeader

local specBar = Instance.new("Frame")
specBar.Size = UDim2.new(0, 3, 1, 0)
specBar.BackgroundColor3 = ACCENT
specBar.BorderSizePixel = 0
specBar.ZIndex = 3
specBar.Parent = specHeader

local specTitle = Instance.new("TextLabel")
specTitle.Size = UDim2.new(1, -44, 1, 0)
specTitle.Position = UDim2.new(0, 12, 0, 0)
specTitle.BackgroundTransparency = 1
specTitle.Text = "Spectate"
specTitle.TextColor3 = ACCENT
specTitle.TextSize = 13
specTitle.Font = Enum.Font.GothamBold
specTitle.TextXAlignment = Enum.TextXAlignment.Left
specTitle.ZIndex = 3
specTitle.Parent = specHeader

-- Toggle button in header
local specToggleBtn = Instance.new("TextButton")
specToggleBtn.Size = UDim2.new(0, 36, 0, 20)
specToggleBtn.Position = UDim2.new(1, -42, 0.5, -10)
specToggleBtn.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
specToggleBtn.BorderSizePixel = 0
specToggleBtn.Text = "OFF"
specToggleBtn.TextColor3 = TEXT_OFF
specToggleBtn.TextSize = 11
specToggleBtn.Font = Enum.Font.GothamBold
specToggleBtn.ZIndex = 3
specToggleBtn.Parent = specHeader
Instance.new("UICorner", specToggleBtn).CornerRadius = UDim.new(0, 3)

makeDraggable(specFrame, specHeader)

-- Player list container (shown when expanded)
local playerListFrame = Instance.new("Frame")
playerListFrame.Size = UDim2.new(1, 0, 1, -HEADER_H)
playerListFrame.Position = UDim2.new(0, 0, 0, HEADER_H)
playerListFrame.BackgroundTransparency = 1
playerListFrame.BorderSizePixel = 0
playerListFrame.ZIndex = 2
playerListFrame.Parent = specFrame

local playerListLayout = Instance.new("UIListLayout")
playerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
playerListLayout.Padding = UDim.new(0, 1)
playerListLayout.Parent = playerListFrame

-- Current spectate label below toggle
local specCurrentLbl = Instance.new("TextLabel")
specCurrentLbl.Size = UDim2.new(1, -14, 0, ROW_H)
specCurrentLbl.Position = UDim2.new(0, 10, 0, HEADER_H + 2)
specCurrentLbl.BackgroundTransparency = 1
specCurrentLbl.Text = "None"
specCurrentLbl.TextColor3 = TEXT_OFF
specCurrentLbl.TextSize = 11
specCurrentLbl.Font = Enum.Font.Gotham
specCurrentLbl.TextXAlignment = Enum.TextXAlignment.Left
specCurrentLbl.ZIndex = 3
specCurrentLbl.Parent = specFrame

-- Divider under current label
local specDiv = Instance.new("Frame")
specDiv.Size = UDim2.new(1, 0, 0, 1)
specDiv.Position = UDim2.new(0, 0, 0, HEADER_H + ROW_H + 2)
specDiv.BackgroundColor3 = DIV_COL
specDiv.BorderSizePixel = 0
specDiv.ZIndex = 2
specDiv.Parent = specFrame

local selectedPlayerBtn = nil

local function stopSpectate()
    SpectateTarget = nil
    if SpectateConnection then
        SpectateConnection:Disconnect()
        SpectateConnection = nil
    end
    -- restore camera
    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Custom
    local char = LocalPlayer.Character
    if char then
        cam.CameraSubject = char:FindFirstChildOfClass("Humanoid")
    end
    specCurrentLbl.Text = "None"
    specCurrentLbl.TextColor3 = TEXT_OFF
    if selectedPlayerBtn then
        selectedPlayerBtn.BackgroundColor3 = BG
        selectedPlayerBtn = nil
    end
end

local function startSpectate(player, btn)
    stopSpectate()
    if player == LocalPlayer then return end
    SpectateTarget = player
    specCurrentLbl.Text = player.DisplayName
    specCurrentLbl.TextColor3 = ACCENT
    if selectedPlayerBtn then selectedPlayerBtn.BackgroundColor3 = BG end
    selectedPlayerBtn = btn
    btn.BackgroundColor3 = BLUE_SEL

    local function attachCam()
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local cam = workspace.CurrentCamera
            cam.CameraType = Enum.CameraType.Follow
            cam.CameraSubject = hum
        end
    end

    attachCam()
    SpectateConnection = RunService.RenderStepped:Connect(function()
        if not specEnabled then
            stopSpectate()
            return
        end
        attachCam()
    end)
end

local playerButtons = {}

local function rebuildPlayerList()
    -- clear existing buttons
    for _, b in ipairs(playerButtons) do b:Destroy() end
    playerButtons = {}

    local playerList = Players:GetPlayers()
    local count = 0
    for _, player in ipairs(playerList) do
        if player == LocalPlayer then continue end
        count = count + 1

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, ROW_H)
        btn.BackgroundColor3 = BG
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ZIndex = 3
        btn.LayoutOrder = count
        btn.Parent = playerListFrame

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -10, 1, 0)
        nameLbl.Position = UDim2.new(0, 10, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = player.DisplayName
        nameLbl.TextColor3 = TEXT_OFF
        nameLbl.TextSize = 12
        nameLbl.Font = Enum.Font.Gotham
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.ZIndex = 4
        nameLbl.Parent = btn

        btn.MouseEnter:Connect(function()
            if btn ~= selectedPlayerBtn then btn.BackgroundColor3 = ROW_HOVER end
        end)
        btn.MouseLeave:Connect(function()
            if btn ~= selectedPlayerBtn then btn.BackgroundColor3 = BG end
        end)
        btn.MouseButton1Click:Connect(function()
            if SpectateTarget == player then
                stopSpectate()
            else
                startSpectate(player, btn)
            end
        end)

        table.insert(playerButtons, btn)
    end

    -- resize specFrame: header + currentRow + div + player rows + padding
    local expandedH = HEADER_H + ROW_H + 2 + count * (ROW_H + 1) + 6
    local collapsedH = HEADER_H
    specFrame.Size = UDim2.new(0, SPEC_W, 0, specEnabled and expandedH or collapsedH)
end

-- Spectate toggle
local function setSpecEnabled(state)
    specEnabled = state
    specToggleBtn.Text = state and "ON" or "OFF"
    specToggleBtn.TextColor3 = state and GREEN_ON or TEXT_OFF
    specToggleBtn.BackgroundColor3 = state and ROW_SEL or Color3.fromRGB(28, 34, 52)

    if state then
        rebuildPlayerList()
    else
        stopSpectate()
        specFrame.Size = UDim2.new(0, SPEC_W, 0, HEADER_H)
    end
end

specToggleBtn.MouseButton1Click:Connect(function()
    setSpecEnabled(not specEnabled)
end)

-- Auto-refresh player list when players join/leave
Players.PlayerAdded:Connect(function()
    if specEnabled then rebuildPlayerList() end
end)
Players.PlayerRemoving:Connect(function(p)
    if SpectateTarget == p then stopSpectate() end
    if specEnabled then rebuildPlayerList() end
end)

table.insert(allPanels, specFrame)

--------------------------------------------------------------------
-- Visual panel
--------------------------------------------------------------------
makePanel("Visual", -200, -80, {
    toggleRow("ESP",   false, function(s) ESPEnabled   = s end),
    toggleRow("Boxes", true,  function(s) BoxesEnabled = s end),
    toggleRow("Names", false, function(s) NamesEnabled = s end),
    colorRow("Box Color",  function(c) ESPColor  = c end),
    colorRow("Name Color", function(c) NameColor = c end),
})

--------------------------------------------------------------------
-- Movement panel
--------------------------------------------------------------------
makePanel("Movement", 20, -80, {
    toggleRow("Fly", false, function(s)
        FlyEnabled = s
        if not s then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if root then
                local bg = root:FindFirstChild("FlyGyro")
                local bv = root:FindFirstChild("FlyVelocity")
                if bg then bg:Destroy() end
                if bv then bv:Destroy() end
            end
            if hum then hum.PlatformStand = false end
        end
    end),
    toggleRow("Noclip", false, function(s) NoclipEnabled = s end), -- ADD THIS
    valueRow("Fly Speed",   FlySpeed,   10,  300, 10, function(v) FlySpeed = v end),
    valueRow("Walk Speed",  WalkSpeed,  16,  100, 2,  function(v)
        WalkSpeed = v
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = WalkSpeed end
    end),
    valueRow("Jump Power",  JumpPower,  0,   300, 5,  function(v)
        JumpPower = v
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.JumpPower = JumpPower end
    end),
})

--------------------------------------------------------------------
-- Search panel
--------------------------------------------------------------------
local SW_W, SW_H = 200, 36

local searchPanel = Instance.new("Frame")
searchPanel.Size = UDim2.new(0, SW_W, 0, SW_H)
searchPanel.Position = UDim2.new(0.5, -SW_W/2, 0.5, 60)
searchPanel.BackgroundColor3 = HEADER_BG
searchPanel.BorderSizePixel = 0
searchPanel.ZIndex = 20
searchPanel.Parent = ScreenGui
Instance.new("UICorner", searchPanel).CornerRadius = UDim.new(0, 5)

local sAccent = Instance.new("Frame")
sAccent.Size = UDim2.new(0, 3, 1, 0)
sAccent.BackgroundColor3 = ACCENT
sAccent.BorderSizePixel = 0
sAccent.ZIndex = 21
sAccent.Parent = searchPanel
Instance.new("UICorner", sAccent).CornerRadius = UDim.new(0, 5)

local sIcon = Instance.new("TextLabel")
sIcon.Size = UDim2.new(0, 24, 1, 0)
sIcon.Position = UDim2.new(0, 6, 0, 0)
sIcon.BackgroundTransparency = 1
sIcon.Text = "🔍"
sIcon.TextSize = 12
sIcon.Font = Enum.Font.Gotham
sIcon.ZIndex = 21
sIcon.Parent = searchPanel

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -36, 1, -8)
searchBox.Position = UDim2.new(0, 30, 0, 4)
searchBox.BackgroundTransparency = 1
searchBox.Text = ""
searchBox.PlaceholderText = "Search settings..."
searchBox.PlaceholderColor3 = TEXT_OFF
searchBox.TextColor3 = TEXT_ON
searchBox.TextSize = 12
searchBox.Font = Enum.Font.Gotham
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.ZIndex = 21
searchBox.Parent = searchPanel

makeDraggable(searchPanel, searchPanel)

local resultsFrame = Instance.new("Frame")
resultsFrame.Size = UDim2.new(1, 0, 0, 0)
resultsFrame.Position = UDim2.new(0, 0, 1, 3)
resultsFrame.BackgroundColor3 = BG
resultsFrame.BorderSizePixel = 0
resultsFrame.ClipsDescendants = true
resultsFrame.ZIndex = 22
resultsFrame.Visible = false
resultsFrame.Parent = searchPanel
Instance.new("UICorner", resultsFrame).CornerRadius = UDim.new(0, 5)

local function updateSearch(query)
    for _, c in ipairs(resultsFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    query = query:lower()
    if query == "" then
        resultsFrame.Visible = false
        resultsFrame.Size = UDim2.new(1, 0, 0, 0)
        return
    end
    local matches = {}
    for _, item in ipairs(searchItems) do
        if item.label:lower():find(query) then
            table.insert(matches, item)
        end
    end
    if #matches == 0 then
        resultsFrame.Visible = false
        resultsFrame.Size = UDim2.new(1, 0, 0, 0)
        return
    end
    local count = math.min(#matches, 5)
    resultsFrame.Size = UDim2.new(1, 0, 0, count * 26)
    resultsFrame.Visible = true
    for i = 1, count do
        local item = matches[i]
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 26)
        btn.Position = UDim2.new(0, 0, 0, (i-1)*26)
        btn.BackgroundColor3 = BG
        btn.BorderSizePixel = 0
        btn.Text = item.label
        btn.TextColor3 = TEXT_ON
        btn.TextSize = 12
        btn.Font = Enum.Font.Gotham
        btn.ZIndex = 23
        btn.Parent = resultsFrame
        btn.MouseEnter:Connect(function() btn.BackgroundColor3 = ROW_HOVER end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3 = BG end)
        btn.MouseButton1Click:Connect(function()
            item.action()
            searchBox.Text = ""
            updateSearch("")
        end)
    end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    updateSearch(searchBox.Text)
end)

table.insert(allPanels, searchPanel)

--------------------------------------------------------------------
-- Fade in on load
--------------------------------------------------------------------
task.wait(0.05)
for _, p in ipairs(allPanels) do fadeIn(p) end

--------------------------------------------------------------------
-- Right Control toggle
--------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        GuiVisible = not GuiVisible
        for _, p in ipairs(allPanels) do
            if GuiVisible then fadeIn(p) else fadeOut(p) end
        end
    end
end)

--------------------------------------------------------------------
-- Respawn
--------------------------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum.WalkSpeed = WalkSpeed
    hum.JumpPower = JumpPower
    FlyEnabled = false
end)

--------------------------------------------------------------------
-- Fly
--------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")

    if FlyEnabled and root and hum then
        hum.PlatformStand = true
        local bg = root:FindFirstChild("FlyGyro") or Instance.new("BodyGyro")
        bg.Name = "FlyGyro"; bg.MaxTorque = Vector3.new(1e6,1e6,1e6)
        bg.P = 1e4; bg.CFrame = Camera.CFrame; bg.Parent = root

        local bv = root:FindFirstChild("FlyVelocity") or Instance.new("BodyVelocity")
        bv.Name = "FlyVelocity"; bv.MaxForce = Vector3.new(1e6,1e6,1e6); bv.P = 1e4

        local dir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W)           then dir += Camera.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)           then dir -= Camera.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)           then dir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)           then dir += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then dir += Vector3.new(0,1,0)        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0)        end

        bv.Velocity = dir.Magnitude > 0 and dir.Unit * FlySpeed or Vector3.new(0,0,0)
        bv.Parent = root
    elseif not FlyEnabled and root then
        local bg = root:FindFirstChild("FlyGyro")
        local bv = root:FindFirstChild("FlyVelocity")
        if bg then bg:Destroy() end
        if bv then bv:Destroy() end
        if hum then hum.PlatformStand = false end
    end
end)

--------------------------------------------------------------------
-- Noclip
--------------------------------------------------------------------<
RunService.Stepped:Connect(function()
    if NoclipEnabled then
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

--------------------------------------------------------------------
-- ESP
--------------------------------------------------------------------
local ESPObjects = {}

local function clearESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do pcall(function() obj:Remove() end) end
        ESPObjects[player] = nil
    end
end

local function setupESP(player)
    if player == LocalPlayer then return end
    clearESP(player)
    local box = Drawing.new("Square")
    box.Visible = false; box.Color = ESPColor; box.Thickness = 2; box.Filled = false
    local nameLabel = Drawing.new("Text")
    nameLabel.Visible = false; nameLabel.Color = NameColor; nameLabel.Size = 14
    nameLabel.Outline = true; nameLabel.Center = true; nameLabel.Text = player.DisplayName
    ESPObjects[player] = { box = box, nameLabel = nameLabel }
end

for _, p in ipairs(Players:GetPlayers()) do setupESP(p) end
Players.PlayerAdded:Connect(function(p)
    setupESP(p)
    p.CharacterAdded:Connect(function() task.wait(0.5) setupESP(p) end)
end)
Players.PlayerRemoving:Connect(clearESP)

RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local objs = ESPObjects[player]
        if not objs then continue end
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        if ESPEnabled and hrp and head then
            local rootScreen, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            local headScreen           = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local h = math.abs(headScreen.Y - rootScreen.Y) * 2.2
                local w = h * 0.55
                objs.box.Color    = ESPColor
                objs.box.Size     = Vector2.new(w, h)
                objs.box.Position = Vector2.new(rootScreen.X - w/2, headScreen.Y - 4)
                objs.box.Visible  = BoxesEnabled
                objs.nameLabel.Color    = NameColor
                objs.nameLabel.Position = Vector2.new(rootScreen.X, headScreen.Y - 18)
                objs.nameLabel.Text     = player.DisplayName
                objs.nameLabel.Visible  = NamesEnabled
            else
                objs.box.Visible = false; objs.nameLabel.Visible = false
            end
        else
            objs.box.Visible = false; objs.nameLabel.Visible = false
        end
    end
end)
