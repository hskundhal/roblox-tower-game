-- CashDisplayClient.lua
-- Place this inside StarterPlayer -> StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Shared Game Phase (synced with server)
local gamePhaseValue = ReplicatedStorage:WaitForChild("GamePhase")

-- 1. Create the invisible overlay (ScreenGui)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomCashUI"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- CRITICAL: Ensures children are on top of parents
-- Make sure the UI doesn't delete itself when the player dies
screenGui.ResetOnSpawn = false 
screenGui.Parent = player:WaitForChild("PlayerGui")

-- 2. Create the labels (Cash, PT, Health, Wave)
local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "CashLabel"
cashLabel.Size = UDim2.new(0, 250, 0, 50) 
cashLabel.AnchorPoint = Vector2.new(1, 1)
cashLabel.Position = UDim2.new(1, -20, 1, -70) 
cashLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
cashLabel.BackgroundTransparency = 0.2
cashLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
cashLabel.Font = Enum.Font.FredokaOne 
cashLabel.TextSize = 28
cashLabel.TextStrokeTransparency = 0 
local cashCorner = Instance.new("UICorner")
cashCorner.CornerRadius = UDim.new(0, 10)
cashCorner.Parent = cashLabel
cashLabel.Parent = screenGui

local ptLabel = Instance.new("TextLabel")
ptLabel.Name = "PTLabel"
ptLabel.Size = UDim2.new(0, 250, 0, 50) 
ptLabel.AnchorPoint = Vector2.new(0, 0)
ptLabel.Position = UDim2.new(0, 20, 0, 80) 
ptLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40) 
ptLabel.BackgroundTransparency = 0.2 
ptLabel.TextColor3 = Color3.fromRGB(255, 255, 127) 
ptLabel.Font = Enum.Font.FredokaOne 
ptLabel.TextSize = 28
ptLabel.TextStrokeTransparency = 0 
local ptCorner = Instance.new("UICorner")
ptCorner.CornerRadius = UDim.new(0, 10)
ptCorner.Parent = ptLabel
ptLabel.Parent = screenGui

local healthLabel = Instance.new("TextLabel")
healthLabel.Name = "HealthLabel"
healthLabel.Size = UDim2.new(0, 250, 0, 50) 
healthLabel.AnchorPoint = Vector2.new(1, 1)
healthLabel.Position = UDim2.new(1, -20, 1, -130) 
healthLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40) 
healthLabel.BackgroundTransparency = 0.2 
healthLabel.TextColor3 = Color3.fromRGB(255, 85, 85) 
healthLabel.Font = Enum.Font.FredokaOne 
healthLabel.TextSize = 28
healthLabel.TextStrokeTransparency = 0 
local healthCorner = Instance.new("UICorner")
healthCorner.CornerRadius = UDim.new(0, 10)
healthCorner.Parent = healthLabel
healthLabel.Parent = screenGui

local waveLabel = Instance.new("TextLabel")
waveLabel.Name = "WaveLabel"
waveLabel.Size = UDim2.new(0, 300, 0, 50)
waveLabel.AnchorPoint = Vector2.new(0, 0)
waveLabel.Position = UDim2.new(0, 20, 0, 20) 
waveLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
waveLabel.BackgroundTransparency = 0.2
waveLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
waveLabel.Font = Enum.Font.FredokaOne
waveLabel.TextSize = 28
waveLabel.TextStrokeTransparency = 0 
local waveCorner = Instance.new("UICorner")
waveCorner.CornerRadius = UDim.new(0, 15)
waveCorner.Parent = waveLabel
waveLabel.Parent = screenGui

-- Bind Values
local leaderstats = player:WaitForChild("leaderstats")
local cashValue = leaderstats:WaitForChild("Cash")
local ptValue = leaderstats:WaitForChild("PT")
local gameSpeed = ReplicatedStorage:WaitForChild("GameSpeed")
local toggleSpeedEvent = ReplicatedStorage:WaitForChild("ToggleSpeedEvent")

local function updateCashDisplay() cashLabel.Text = "💵 Cash: " .. tostring(cashValue.Value) end
updateCashDisplay()
cashValue.Changed:Connect(updateCashDisplay)

local function updatePTDisplay() ptLabel.Text = "✨ PT: " .. tostring(ptValue.Value) end
updatePTDisplay()
ptValue.Changed:Connect(updatePTDisplay)

local healthEvent = ReplicatedStorage:WaitForChild("UpdateBaseHealth")
local getHealthFunction = ReplicatedStorage:WaitForChild("GetInitialHealth")
healthEvent.OnClientEvent:Connect(function(cur, max) healthLabel.Text = "❤️ Health: " .. cur .. " / " .. max end)
local sh, mh = getHealthFunction:InvokeServer()
healthLabel.Text = "❤️ Health: " .. sh .. " / " .. mh

local waveEvent = ReplicatedStorage:WaitForChild("UpdateWave")
waveEvent.OnClientEvent:Connect(function(cur, max) waveLabel.Text = "Wave " .. cur .. " / " .. max end)

-- Speed Button
local speedButton = Instance.new("TextButton")
speedButton.Name = "SpeedButton"
speedButton.Size = UDim2.new(0, 100, 0, 50)
speedButton.AnchorPoint = Vector2.new(1, 0)
speedButton.Position = UDim2.new(1, -20, 0, 20) 
speedButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
speedButton.BackgroundTransparency = 0.2
speedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
speedButton.Font = Enum.Font.FredokaOne
speedButton.TextSize = 24
local sbCorner = Instance.new("UICorner")
sbCorner.CornerRadius = UDim.new(0, 10)
sbCorner.Parent = speedButton
speedButton.Parent = screenGui

local function updateSpeedText()
	speedButton.Text = "⏩ " .. gameSpeed.Value .. "x"
    local c = Color3.fromRGB(255, 255, 255)
	if gameSpeed.Value == 5 then c = Color3.fromRGB(255, 0, 255) -- Purple for 5x 
    elseif gameSpeed.Value == 4 then c = Color3.fromRGB(0, 255, 255) -- Blue for 4x
    elseif gameSpeed.Value == 3 then c = Color3.fromRGB(255, 85, 85) -- Red for 3x
	elseif gameSpeed.Value == 2 then c = Color3.fromRGB(255, 170, 0) -- Orange for 2x
	end
    speedButton.TextColor3 = c
end
updateSpeedText()
gameSpeed.Changed:Connect(updateSpeedText)
speedButton.MouseButton1Click:Connect(function() toggleSpeedEvent:FireServer() end)


-- Tower Selection Bar
local selectEvent = ReplicatedStorage:WaitForChild("SelectTowerEvent")
local barFrame = Instance.new("Frame")
barFrame.Name = "TowerBar"
barFrame.Size = UDim2.new(0, 500, 0, 80)
barFrame.AnchorPoint = Vector2.new(0, 1)
barFrame.Position = UDim2.new(0, 20, 1, -20) 
barFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
barFrame.BackgroundTransparency = 0.4
barFrame.ZIndex = 50 -- On Top of Gacha Screen
barFrame.Parent = screenGui
Instance.new("UICorner", barFrame).CornerRadius = UDim.new(0, 15)
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 10)
layout.Parent = barFrame

local TOWER_COLORS = {
    ["BasicTower"] = Color3.fromRGB(240, 190, 40), -- Vibrant Gold Noob Yellow
    ["FastNoob"] = Color3.fromRGB(0, 170, 255),    -- Bright Cyan/Blue
    ["StrongNoob"] = Color3.fromRGB(255, 120, 0),  -- Deep Orange
    ["ALL OUT NOOB"] = Color3.fromRGB(255, 0, 0),  -- True Red
    ["Locked"] = Color3.fromRGB(15, 15, 15)
}

local TOWER_NAMES = {
    ["BasicTower"] = "Basic",
    ["FastNoob"] = "Fast",
    ["StrongNoob"] = "Strong",
    ["ALL OUT NOOB"] = "ALL OUT"
}

local towerInventory = {
    {name = "BasicTower", icon = "Basic", cost = 100, multiplier = 1},
    {name = "Locked", icon = "?", cost = 0, multiplier = 1},
    {name = "Locked", icon = "?", cost = 0, multiplier = 1},
    {name = "Locked", icon = "?", cost = 0, multiplier = 1},
    {name = "Locked", icon = "?", cost = 0, multiplier = 1},
}

for i, data in ipairs(towerInventory) do
    local slot = Instance.new("TextButton")
    slot.Name = "Slot" .. i
    slot.Size = UDim2.new(0, 80, 0, 70)
    slot.BackgroundColor3 = TOWER_COLORS[data.name] or TOWER_COLORS["Locked"]
    slot.TextColor3 = Color3.fromRGB(255, 255, 255)
    slot.TextSize = 16
    slot.Font = Enum.Font.FredokaOne
    slot.Text = "<b>" .. data.icon .. "</b>\n$" .. data.cost
    slot.ZIndex = 51 -- Above barFrame
    slot.RichText = true
    slot.BackgroundTransparency = (data.name == "Locked") and 0.5 or 0
    
    if data.name == "Locked" then
        slot.Text = "Locked"
    end
    Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 8)
    slot.MouseButton1Click:Connect(function()
        if data.name ~= "Locked" then selectEvent:Fire(data.name, data.multiplier) end
    end)
    slot.Parent = barFrame
end

-- Elevator Vote UI
local onElevatorEvent = ReplicatedStorage:WaitForChild("OnElevatorEvent")
local castVoteEvent   = ReplicatedStorage:WaitForChild("CastVoteEvent")
local voteUpdateEvent = ReplicatedStorage:WaitForChild("VoteUpdateEvent")

local voteFrame = Instance.new("Frame")
voteFrame.Name = "VoteFrame"
voteFrame.Size = UDim2.new(0, 400, 0, 180)
voteFrame.AnchorPoint = Vector2.new(0.5, 0)
voteFrame.Position = UDim2.new(0.5, 0, 0, 50)
voteFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
voteFrame.BackgroundTransparency = 0.1
voteFrame.Visible = false
voteFrame.ZIndex = 40 -- Ensure it's above other elements
voteFrame.Parent = screenGui
Instance.new("UICorner", voteFrame).CornerRadius = UDim.new(0, 20)

local voteTitle = Instance.new("TextLabel")
voteTitle.Size = UDim2.new(1, 0, 0, 45)
voteTitle.BackgroundTransparency = 1
voteTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
voteTitle.Font = Enum.Font.FredokaOne
voteTitle.TextSize = 28
voteTitle.Text = "LEVEL SELECTION"
voteTitle.Parent = voteFrame 

local tallyLabel = Instance.new("TextLabel")
tallyLabel.Name = "TallyLabel"
tallyLabel.Size = UDim2.new(1, 0, 0, 28)
tallyLabel.Position = UDim2.new(0, 0, 1, -30)
tallyLabel.BackgroundTransparency = 1
tallyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
tallyLabel.Font = Enum.Font.FredokaOne
tallyLabel.TextSize = 18
tallyLabel.Text = "Step on, then tap a level!"
tallyLabel.Parent = voteFrame

local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.new(1, -24, 0, 70)
btnRow.Position = UDim2.new(0, 12, 0, 50)
btnRow.BackgroundTransparency = 1
btnRow.Parent = voteFrame
local btnLayout2 = Instance.new("UIListLayout")
btnLayout2.FillDirection = Enum.FillDirection.Horizontal
btnLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
btnLayout2.VerticalAlignment = Enum.VerticalAlignment.Center
btnLayout2.Padding = UDim.new(0, 6)
btnLayout2.Parent = btnRow

local DIFF_COLORS = {
    Color3.fromRGB(0, 255, 100),   -- Vibrant Green
    Color3.fromRGB(0, 170, 255),   -- Sky Blue
    Color3.fromRGB(225, 180, 0),   -- Golden Yellow
    Color3.fromRGB(255, 120, 0),   -- Vivid Orange
    Color3.fromRGB(255, 40, 40)    -- Bright Red
}
for diff = 1, 5 do
    local btn = Instance.new("TextButton")
    btn.Name = "Diff" .. diff
    btn.Size = UDim2.new(0, 64, 0, 60)
    btn.BackgroundColor3 = DIFF_COLORS[diff]
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.FredokaOne
    btn.TextSize = 18
    btn.Text = "Lv " .. diff
    btn.BackgroundTransparency = 0 -- Fully opaque for maximum vibrance
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    btn.MouseButton1Click:Connect(function()
        castVoteEvent:FireServer(diff)
        for _, child in ipairs(btnRow:GetChildren()) do 
            if child:IsA("TextButton") then child.BackgroundTransparency = 0.5 end 
        end
        btn.BackgroundTransparency = 0
    end)
    btn.Parent = btnRow
end

onElevatorEvent.OnClientEvent:Connect(function(elevatorName)
    if elevatorName and gamePhaseValue.Value == "Lobby" then
        voteFrame.Visible = true
        voteTitle.Text = "LEVEL SELECTION"
        tallyLabel.Text = "Selected: " .. elevatorName .. " | Tap a level!"
        for _, child in ipairs(btnRow:GetChildren()) do 
            if child:IsA("TextButton") then child.BackgroundTransparency = 0 end 
        end
    else
        voteFrame.Visible = false
    end
end)

voteUpdateEvent.OnClientEvent:Connect(function(tally, timerSecs)
    local parts = {}
    for d = 1, 5 do if tally[d] and tally[d] > 0 then table.insert(parts, "Lv" .. d .. ":" .. tally[d]) end end
    tallyLabel.Text = "⏱ " .. timerSecs .. "s  " .. (#parts > 0 and table.concat(parts, "  ") or "")
end)

-- GACHA / ROLL SCREEN UI
local rollFunction = ReplicatedStorage:WaitForChild("RollTowerFunction")
local gachaFrame = Instance.new("Frame")
gachaFrame.Name = "GachaScreen"
gachaFrame.Size = UDim2.new(0, 600, 0, 450)
gachaFrame.AnchorPoint = Vector2.new(0.5, 0.5)
gachaFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
gachaFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
gachaFrame.BorderSizePixel = 0
gachaFrame.Visible = false
gachaFrame.ZIndex = 20
gachaFrame.Parent = screenGui
Instance.new("UICorner", gachaFrame).CornerRadius = UDim.new(0, 20)
local gfStroke = Instance.new("UIStroke")
gfStroke.Thickness = 3
gfStroke.Color = Color3.fromRGB(255, 170, 0)
gfStroke.Parent = gachaFrame

local gachaTitle = Instance.new("TextLabel")
gachaTitle.Size = UDim2.new(1, 0, 0, 60)
gachaTitle.BackgroundTransparency = 1
gachaTitle.Font = Enum.Font.FredokaOne
gachaTitle.TextSize = 36
gachaTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
gachaTitle.Text = "GACHA SHOP"
gachaTitle.ZIndex = 21
gachaTitle.Parent = gachaFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.TextSize = 24
closeBtn.ZIndex = 22
closeBtn.Parent = gachaFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)
closeBtn.MouseButton1Click:Connect(function() gachaFrame.Visible = false end)

local optionsContainer = Instance.new("Frame")
optionsContainer.Size = UDim2.new(1, -40, 0, 250)
optionsContainer.Position = UDim2.new(0, 20, 0, 80)
optionsContainer.BackgroundTransparency = 1
optionsContainer.ZIndex = 21
optionsContainer.Parent = gachaFrame
local optLayout = Instance.new("UIListLayout")
optLayout.FillDirection = Enum.FillDirection.Horizontal
optLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
optLayout.Padding = UDim.new(0, 15)
optLayout.Parent = optionsContainer

local REWARDS_DATA = {
    {name = "FastNoob", chance = "60%", color = Color3.fromRGB(80, 160, 230)},
    {name = "StrongNoob", chance = "30%", color = Color3.fromRGB(230, 120, 40)},
    {name = "ALL OUT NOOB", chance = "10%", color = Color3.fromRGB(255, 50, 50)}
}

local gachaCards = {}

for _, data in ipairs(REWARDS_DATA) do
    local card = Instance.new("Frame")
    card.Name = data.name
    card.Size = UDim2.new(0, 180, 1, 0)
    card.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    card.ZIndex = 22
    card.Parent = optionsContainer
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
    
    local nl = Instance.new("TextLabel")
    nl.Size = UDim2.new(1, 0, 0, 40)
    nl.BackgroundTransparency = 1
    nl.Font = Enum.Font.FredokaOne
    nl.TextSize = 18
    nl.TextColor3 = data.color
    nl.Text = TOWER_NAMES[data.name] or data.name
    nl.ZIndex = 23
    nl.Parent = card
    
    local pl = Instance.new("TextLabel")
    pl.Size = UDim2.new(1, 0, 0, 30)
    pl.Position = UDim2.new(0, 0, 1, -40)
    pl.BackgroundTransparency = 1
    pl.Font = Enum.Font.FredokaOne
    pl.TextSize = 20
    pl.TextColor3 = Color3.fromRGB(255, 255, 255)
    pl.Text = "Chance: " .. data.chance
    pl.ZIndex = 23
    pl.Parent = card

    -- Owned Overlay
    local ownedOverlay = Instance.new("Frame")
    ownedOverlay.Name = "OwnedOverlay"
    ownedOverlay.Size = UDim2.new(1, 0, 1, 0)
    ownedOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    ownedOverlay.BackgroundTransparency = 0.6
    ownedOverlay.ZIndex = 24
    ownedOverlay.Visible = false
    ownedOverlay.Parent = card
    Instance.new("UICorner", ownedOverlay).CornerRadius = UDim.new(0, 12)
    
    local xLabel = Instance.new("TextLabel")
    xLabel.Size = UDim2.new(1, 0, 1, 0)
    xLabel.BackgroundTransparency = 1
    xLabel.Font = Enum.Font.FredokaOne
    xLabel.TextSize = 60
    xLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    xLabel.Text = "X\nOWNED"
    xLabel.ZIndex = 25
    xLabel.Parent = ownedOverlay

    gachaCards[data.name] = ownedOverlay
end

local finalRollBtn = Instance.new("TextButton")
finalRollBtn.Size = UDim2.new(0, 300, 0, 60)
finalRollBtn.Position = UDim2.new(0.5, -150, 1, -80)
finalRollBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
finalRollBtn.Font = Enum.Font.FredokaOne
finalRollBtn.TextSize = 28
finalRollBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
finalRollBtn.Text = "ROLL NOW (20 PT)"
finalRollBtn.ZIndex = 22
finalRollBtn.Parent = gachaFrame
Instance.new("UICorner", finalRollBtn).CornerRadius = UDim.new(0, 30)

finalRollBtn.MouseButton1Click:Connect(function()
    local currentOwned = {}
    for _, item in ipairs(towerInventory) do
        if item.name ~= "Locked" then table.insert(currentOwned, item.name) end
    end

    local res = rollFunction:InvokeServer(currentOwned)
    if res then
        finalRollBtn.Text = "SUCCESS!"
        task.wait(0.5)
        for i, data in ipairs(towerInventory) do
            if data.name == "Locked" then
                data.name = res.name
                data.multiplier = res.multiplier
                local displayName = TOWER_NAMES[res.name] or res.name
                data.icon = displayName
                data.cost = (res.name == "ALL OUT NOOB") and 300 or 100
                
                local btn = barFrame:FindFirstChild("Slot" .. i)
                if btn then
                    btn.Text = "<b>" .. displayName .. "</b>\n$" .. data.cost
                    btn.BackgroundColor3 = TOWER_COLORS[res.name] or TOWER_COLORS["BasicTower"]
                    btn.BackgroundTransparency = 0
                    btn.RichText = true
                end
                break
            end
        end
        -- Refresh Gacha overlays immediately
        for name, overlay in pairs(gachaCards) do
            local isOwned = false
            for _, inv in ipairs(towerInventory) do
                if inv.name == name then isOwned = true break end
            end
            overlay.Visible = isOwned
        end
        
        gachaFrame.Visible = false
        finalRollBtn.Text = "ROLL NOW (20 PT)"
    else
        finalRollBtn.Text = "NO PT / ERROR"
        task.wait(1)
        finalRollBtn.Text = "ROLL NOW (20 PT)"
    end
end)

local rollHUD = Instance.new("TextButton")
rollHUD.Size = UDim2.new(0, 150, 0, 40)
rollHUD.AnchorPoint = Vector2.new(1, 1)
rollHUD.Position = UDim2.new(1, -20, 1, -20)
rollHUD.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
rollHUD.TextColor3 = Color3.fromRGB(255, 255, 255)
rollHUD.Font = Enum.Font.FredokaOne
rollHUD.TextSize = 20
rollHUD.Text = "🎲 ROLL (20 PT)"
rollHUD.Parent = screenGui
Instance.new("UICorner", rollHUD).CornerRadius = UDim.new(0, 8)
rollHUD.MouseButton1Click:Connect(function() 
    if gamePhaseValue.Value == "Lobby" then 
        -- Update "Owned" status on Gacha Cards
        for name, overlay in pairs(gachaCards) do
            local isOwned = false
            for _, inv in ipairs(towerInventory) do
                if inv.name == name then isOwned = true break end
            end
            overlay.Visible = isOwned
        end
        gachaFrame.Visible = true 
    end 
end)

-- Phase Toggling
local function onPhaseChanged()
    local phase = gamePhaseValue.Value
    local isLobby = (phase == "Lobby")
    ptLabel.Visible = true
    rollHUD.Visible = isLobby
    cashLabel.Visible = not isLobby
    healthLabel.Visible = not isLobby
    barFrame.Visible = not isLobby
    waveLabel.Visible = not isLobby
    speedButton.Visible = not isLobby
    if not isLobby then voteFrame.Visible = false end -- Only hide on game start
end
onPhaseChanged()
gamePhaseValue.Changed:Connect(onPhaseChanged)
