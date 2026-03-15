-- TowerUpgradeClient.lua
-- Place this inside StarterPlayer -> StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local upgradeEvent = ReplicatedStorage:WaitForChild("UpgradeTowerEvent")

-- 1. Create the Upgrade UI
local screenGui = player:WaitForChild("PlayerGui"):WaitForChild("CustomCashUI") -- Reuse the existing GUI container

local upgradeFrame = Instance.new("Frame")
upgradeFrame.Name = "UpgradeMenu"
upgradeFrame.Size = UDim2.new(0, 200, 0, 150)
upgradeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
upgradeFrame.Position = UDim2.new(0.5, 250, 0.5, 0) -- To the right of the center
upgradeFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
upgradeFrame.Visible = false
upgradeFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = upgradeFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.FredokaOne
title.TextSize = 20
title.Text = "Noob Upgrade"
title.Parent = upgradeFrame

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 60)
infoLabel.Position = UDim2.new(0, 0, 0, 40)
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
infoLabel.Font = Enum.Font.SourceSans
infoLabel.TextSize = 18
infoLabel.Text = "Level: 1\nCost: $100"
infoLabel.Parent = upgradeFrame

local upgradeButton = Instance.new("TextButton")
upgradeButton.Size = UDim2.new(0.8, 0, 0, 40)
upgradeButton.Position = UDim2.new(0.1, 0, 1, -50)
upgradeButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
upgradeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
upgradeButton.Font = Enum.Font.FredokaOne
upgradeButton.TextSize = 18
upgradeButton.Text = "UPGRADE"
upgradeButton.Parent = upgradeFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = upgradeButton

-- 2. Logic to detect tower clicks
local selectedTower = nil

local function openUpgradeMenu(tower)
    selectedTower = tower
    local level = tower:GetAttribute("Level") or 1
    local cost = level * 100
    
    infoLabel.Text = "Level: " .. level .. "\nCost: $" .. cost
    upgradeFrame.Visible = true
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local target = mouse.Target
        if target then
            -- Find if the target is part of a tower
            local model = target:FindFirstAncestorOfClass("Model")
            if model and model.Parent == workspace:FindFirstChild("Towers") then
                openUpgradeMenu(model)
            else
                upgradeFrame.Visible = false
                selectedTower = nil
            end
        else
            upgradeFrame.Visible = false
            selectedTower = nil
        end
    end
end)

upgradeButton.MouseButton1Click:Connect(function()
    if selectedTower then
        upgradeEvent:FireServer(selectedTower)
        -- The attribute change on server will trigger TowerPunchServer update
        -- We wait a tiny bit to update the UI text
        task.wait(0.1)
        if selectedTower then
            openUpgradeMenu(selectedTower)
        end
    end
end)
