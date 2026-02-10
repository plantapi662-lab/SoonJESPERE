-- SERVICES
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- STATE
local status = false
local points = {}
local toggleTP = false

-- SETTINGS (LAG SERVER)
local Settings = {
    LagEnabled = false,
    IsAutoLagging = false,
    AntiDeathEnabled = true,
    PacketRate = 5,
    MaxPacketRate = 50,
}

local blacklistedNames = {
    "PlaceCooldownFromChat", "AdminPanelService", "AdminPanel",
    "IntegrityCheckProcessor", "LocalizationTableAnalyticsSender",
    "LocalizationService", "Analytics", "Telemetry", "Logger",
    "Reporter", "CanChatWith", "SetPlayerBlockList", "UpdatePlayerBlockList",
    "NewPlayerGroupDetails", "UpdatePlayerProfileSettings",
    "ShowFriendJoinedPlayerToast", "ShowPlayerJoinedFriendsToast",
    "CreateOrJoinParty", "Update",
    "RE/Tools/Cooldown", "RE/FuseMachine/RevealNow", "RE/FuseMachine/FuseAnimation",
    "RE/NotificationService/Notify", "RE/PlotService/ClaimCoins",
    "RE/PlotService/Sell", "RE/PlotService/Open", "RE/PlotService/ToggleFriends",
    "RE/PlotService/CashCollected", "RE/ChatService/ChatMessage",
    "RE/SoundService/PlayClientSound", "RE/Snapshot/RealiableChannel",
    "RE/CommandsService/OpenCommandBar", "RE/TeleportService/Reconnect"
}

local priorityTargets = {
    "WhyAreTheyTargetingMe!!", "FisherMan", "Chat", "AFK", "CookiesService"
}

local TargetRemote = nil

-- Find remote like your script
local function findTarget()
    local foundRemotes = {}
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local fullName = v:GetFullName()
            local remoteName = v.Name
            local isBlacklisted = false

            for _, blacklisted in ipairs(blacklistedNames) do
                if string.find(fullName, blacklisted, 1, true) or string.find(remoteName, blacklisted, 1, true) then
                    isBlacklisted = true
                    break
                end
            end

            if not isBlacklisted then
                for _, priority in ipairs(priorityTargets) do
                    if string.find(remoteName, priority, 1, true) then
                        return v
                    end
                end
                table.insert(foundRemotes, v)
            end
        end
    end
    return #foundRemotes > 0 and foundRemotes[1] or nil
end

TargetRemote = findTarget()

-- UTILS : isOnMyCashPad (copié de ton script)
local function isOnMyCashPad()
    local char = player.Character
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then return false end

    for _, plot in ipairs(plotsFolder:GetChildren()) do
        if plot:IsA("Model") then
            local sign = plot:FindFirstChild("PlotSign")
            if sign and sign:FindFirstChild("YourBase") and sign.YourBase.Enabled then
                local cashPad = plot:FindFirstChild("CashPad", true)
                if cashPad then
                    local cashPos = cashPad:GetPivot().Position
                    if (root.Position - cashPos).Magnitude <= 5.5 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- GUI (comme ton script de base)
local gui = Instance.new("ScreenGui")
gui.Name = "NexoraHubInstant"
gui.Parent = CoreGui

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 300, 0, 320)
main.Position = UDim2.new(0.5, -150, 0.5, -160)
main.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
main.BorderSizePixel = 0
main.Active = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)

-- DRAG
local dragging, dragStart, startPos
local function startDrag(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end
local function updateDrag(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end
local function stopDrag(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end
main.InputBegan:Connect(startDrag)
UserInputService.InputChanged:Connect(updateDrag)
UserInputService.InputEnded:Connect(stopDrag)

-- TITLE
local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 70)
title.Position = UDim2.new(0, 0, 0, 6)
title.BackgroundTransparency = 1
title.RichText = true
title.Text = '<font color="rgb(255,255,255)">NEXORAHUB </font><font color="rgb(0,140,255)">INSTANT</font>'
title.Font = Enum.Font.GothamBlack
title.TextSize = 26
title.TextWrapped = true
title.TextYAlignment = Enum.TextYAlignment.Center

-- BUTTON CREATOR
local function button(text, y, bg, txtColor)
    local b = Instance.new("TextButton", main)
    b.Size = UDim2.new(0.85, 0, 0, 42)
    b.Position = UDim2.new(0.075, 0, 0, y)
    b.BackgroundColor3 = bg
    b.Text = text
    b.TextColor3 = txtColor or Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 16
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
    return b
end

local gray = Color3.fromRGB(50, 50, 55)
local blue = Color3.fromRGB(0, 140, 255)

-- BUTTONS
local statusBtn = button("Status: Off", 80, gray, Color3.fromRGB(255, 80, 80))
local setBtn = button("Set Points (0/2)", 130, gray, Color3.new(1,1,1))
local resetBtn = button("Reset Points", 130, gray, blue)
local tpBtn = button("TELEPORT", 190, blue, Color3.new(1,1,1))
local lagBtn = button("LAG SERVER: OFF [X]", 240, gray, Color3.new(1,1,1))

resetBtn.Visible = false

-- STATUS
statusBtn.MouseButton1Click:Connect(function()
    status = not status
    if status then
        statusBtn.Text = "Status: On"
        statusBtn.TextColor3 = Color3.fromRGB(90, 255, 90)
    else
        statusBtn.Text = "Status: Off"
        statusBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
end)

-- SET POINTS
setBtn.MouseButton1Click:Connect(function()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    if #points >= 2 then return end

    table.insert(points, player.Character.HumanoidRootPart.CFrame)
    setBtn.Text = "Set Points (" .. #points .. "/2)"

    if #points == 2 then
        setBtn.Visible = false
        resetBtn.Visible = true
    end
end)

-- RESET
resetBtn.MouseButton1Click:Connect(function()
    points = {}
    toggleTP = false
    setBtn.Text = "Set Points (0/2)"
    setBtn.Visible = true
    resetBtn.Visible = false
end)

-- LAG VISUALS
local function UpdateLagVisuals()
    local isActive = Settings.LagEnabled or Settings.IsAutoLagging
    if isActive then
        lagBtn.Text = "LAG SERVER: ON [X]"
        lagBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
        lagBtn.BackgroundColor3 = Color3.fromRGB(50, 40, 10)
    else
        lagBtn.Text = "LAG SERVER: OFF [X]"
        lagBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        lagBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    end
end

lagBtn.MouseButton1Click:Connect(function()
    Settings.LagEnabled = not Settings.LagEnabled
    UpdateLagVisuals()
end)

-- TELEPORT (avec lag EXACTEMENT comme ton script)
tpBtn.MouseButton1Click:Connect(function()
    if not status then
        tpBtn.Text = "STATUS OFF ❌"
        task.wait(1)
        tpBtn.Text = "TELEPORT"
        return
    end

    if #points < 2 then
        tpBtn.Text = "POINTS MANQUANTS ❌"
        task.wait(1)
        tpBtn.Text = "TELEPORT"
        return
    end

    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then

        -- Sauvegarde de l'état avant TP
        local prevLag = Settings.LagEnabled
        local prevPacket = Settings.PacketRate

        -- Active lag + packetrate = 20 pendant 3 secondes
        Settings.LagEnabled = true
        Settings.PacketRate = 30
        UpdateLagVisuals()

        task.wait(2)

        -- TP
        toggleTP = not toggleTP
        player.Character.HumanoidRootPart.CFrame =
            toggleTP and points[1] or points[2]

        -- ⚠️ Après TP : lag reste 1 seconde
        task.wait(0)

        -- IMPORTANT : Si lag était ON avant, on le garde ON
        -- Sinon, on le remet OFF
        Settings.LagEnabled = prevLag
        Settings.PacketRate = prevPacket
        UpdateLagVisuals()
    end
end)



-- HEARTBEAT (exactement comme ton script)
RunService.Heartbeat:Connect(function()
    local shouldLag = Settings.LagEnabled or Settings.IsAutoLagging

    if shouldLag and TargetRemote and not isOnMyCashPad() then
        local payload = string.rep("X", 2000)
        for i = 1, Settings.PacketRate do
            pcall(function()
                TargetRemote:FireServer("d80e2217-36b8-4bdc-9a46-2281c6f70b28", payload)
            end)
        end
    end
end)
