-- CashDisplayClient.lua
-- Place this inside StarterPlayer -> StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- 1. Create the invisible overlay (ScreenGui)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomCashUI"
-- Make sure the UI doesn't delete itself when the player dies
screenGui.ResetOnSpawn = false 
-- Put it in the player's screen
screenGui.Parent = player:WaitForChild("PlayerGui")

-- 2. Create the actual Text Box (TextLabel)
local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "CashLabel"
-- Size: 250 pixels wide, 50 pixels tall
cashLabel.Size = UDim2.new(0, 250, 0, 50) 
-- AnchorPoint: Centers the box horizontally (0.5), and aligns it to the bottom (1)
cashLabel.AnchorPoint = Vector2.new(0.5, 1)
-- Position: Exactly in the middle of the screen horizontally (0.5), and 30 pixels up from the bottom edge
cashLabel.Position = UDim2.new(0.5, 0, 1, -30)

-- 3. Make it look nice!
cashLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Dark gray background
cashLabel.BackgroundTransparency = 0.2 -- Make it slightly see-through
cashLabel.TextColor3 = Color3.fromRGB(85, 255, 127) -- Bright green text
cashLabel.Font = Enum.Font.FredokaOne -- A fun, bold font
cashLabel.TextSize = 28
cashLabel.TextStrokeTransparency = 0 -- Adds a black outline to the text so it's easy to read
cashLabel.Text = "Loading Cash..."
-- Add slightly rounded corners
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = cashLabel

-- Put the label onto the screen
cashLabel.Parent = screenGui


-- 4. Connect the label to the actual money value!
local leaderstats = player:WaitForChild("leaderstats")
local cashValue = leaderstats:WaitForChild("Cash")

-- This function updates the text on screen to whatever the current Cash value is
local function updateCashDisplay()
	cashLabel.Text = "💵 Cash: " .. tostring(cashValue.Value)
end

-- Update it once immediately when the game loads
updateCashDisplay()

-- Update it automatically every single time the Cash value goes up or down
cashValue.Changed:Connect(updateCashDisplay)

---------------------------------------------------
-- PT (PUNCH TOKENS) DISPLAY
---------------------------------------------------
local ptValue = leaderstats:WaitForChild("PT")

local ptLabel = Instance.new("TextLabel")
ptLabel.Name = "PTLabel"
ptLabel.Size = UDim2.new(0, 250, 0, 50) 
ptLabel.AnchorPoint = Vector2.new(0.5, 1)
ptLabel.Position = UDim2.new(0.5, 0, 1, -150)
ptLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40) 
ptLabel.BackgroundTransparency = 0.2 
ptLabel.TextColor3 = Color3.fromRGB(255, 255, 127) -- Yellowish text
ptLabel.Font = Enum.Font.FredokaOne 
ptLabel.TextSize = 28
ptLabel.TextStrokeTransparency = 0 
ptLabel.Text = "✨ PT: 0"

local ptCorner = Instance.new("UICorner")
ptCorner.CornerRadius = UDim.new(0, 10)
ptCorner.Parent = ptLabel
ptLabel.Parent = screenGui

local function updatePTDisplay()
	ptLabel.Text = "✨ PT: " .. tostring(ptValue.Value)
end
updatePTDisplay()
ptValue.Changed:Connect(updatePTDisplay)

---------------------------------------------------
-- BASE HEALTH DISPLAY
---------------------------------------------------
local healthLabel = Instance.new("TextLabel")
healthLabel.Name = "HealthLabel"
healthLabel.Size = UDim2.new(0, 250, 0, 50) 
-- AnchorPoint: Centers the box horizontally (0.5), and aligns it to the bottom (1)
healthLabel.AnchorPoint = Vector2.new(0.5, 1)
-- Position: Exactly in the middle of the screen horizontally (0.5), and 90 pixels up from the bottom edge
-- (This places it exactly 10 pixels above the Cash box!)
healthLabel.Position = UDim2.new(0.5, 0, 1, -90)

healthLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40) 
healthLabel.BackgroundTransparency = 0.2 
healthLabel.TextColor3 = Color3.fromRGB(255, 85, 85) -- Bright red text
healthLabel.Font = Enum.Font.FredokaOne 
healthLabel.TextSize = 28
healthLabel.TextStrokeTransparency = 0 
healthLabel.Text = "❤️ Base Health: Loading..."

local healthCorner = Instance.new("UICorner")
healthCorner.CornerRadius = UDim.new(0, 10)
healthCorner.Parent = healthLabel

healthLabel.Parent = screenGui

-- Connect the label to the Health Event we made on the server!
local healthEvent = ReplicatedStorage:WaitForChild("UpdateBaseHealth")
local getHealthFunction = ReplicatedStorage:WaitForChild("GetInitialHealth")

healthEvent.OnClientEvent:Connect(function(currentHealth, maxHealth)
	healthLabel.Text = "❤️ Base Health: " .. currentHealth .. " / " .. maxHealth
end)

-- Ask the server directly for the current health right now!
local startingHealth, maxHealth = getHealthFunction:InvokeServer()
healthLabel.Text = "❤️ Base Health: " .. startingHealth .. " / " .. maxHealth

---------------------------------------------------
-- TOWER SELECTION BAR
---------------------------------------------------

-- Create a BindableEvent for communication
local selectEvent = ReplicatedStorage:FindFirstChild("SelectTowerEvent")
if not selectEvent then
    selectEvent = Instance.new("BindableEvent")
    selectEvent.Name = "SelectTowerEvent"
    selectEvent.Parent = ReplicatedStorage
end

local barFrame = Instance.new("Frame")
barFrame.Name = "TowerBar"
barFrame.Size = UDim2.new(0, 500, 0, 80)
barFrame.AnchorPoint = Vector2.new(0.5, 1)
barFrame.Position = UDim2.new(0.5, 0, 1, -150)
barFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
barFrame.BackgroundTransparency = 0.4
barFrame.Parent = screenGui

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 15)
barCorner.Parent = barFrame

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 10)
layout.Parent = barFrame

local towerInventory = {
    {name = "BasicTower", icon = "Noob", cost = 100},
    {name = "Locked", icon = "?", cost = 0},
    {name = "Locked", icon = "?", cost = 0},
    {name = "Locked", icon = "?", cost = 0},
    {name = "Locked", icon = "?", cost = 0},
}

for i, data in ipairs(towerInventory) do
    local slot = Instance.new("TextButton")
    slot.Name = "Slot" .. i
    slot.Size = UDim2.new(0, 80, 0, 70)
    slot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    slot.TextColor3 = Color3.fromRGB(255, 255, 255)
    slot.TextSize = 14
    slot.Font = Enum.Font.FredokaOne
    slot.Text = data.icon .. "\n$" .. data.cost
    
    if data.name == "Locked" then
        slot.Text = "Locked"
        slot.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        slot.BackgroundTransparency = 0.5
    end
    
    local slotCorner = Instance.new("UICorner")
    slotCorner.CornerRadius = UDim.new(0, 8)
    slotCorner.Parent = slot
    
    slot.MouseButton1Click:Connect(function()
        if data.name ~= "Locked" then
            selectEvent:Fire(data.name)
        end
    end)
    
    slot.Parent = barFrame
end

---------------------------------------------------
-- GACHA / ROLL UI
---------------------------------------------------
local rollFunction = ReplicatedStorage:WaitForChild("RollTowerFunction")

local rollButton = Instance.new("TextButton")
rollButton.Name = "RollButton"
rollButton.Size = UDim2.new(0, 150, 0, 40)
rollButton.AnchorPoint = Vector2.new(1, 1)
rollButton.Position = UDim2.new(1, -20, 1, -20) -- Bottom Right
rollButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
rollButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rollButton.Font = Enum.Font.FredokaOne
rollButton.TextSize = 20
rollButton.Text = "🎲 ROLL (50 PT)"
rollButton.Parent = screenGui

local rollCorner = Instance.new("UICorner")
rollCorner.CornerRadius = UDim.new(0, 8)
rollCorner.Parent = rollButton

rollButton.MouseButton1Click:Connect(function()
    local newTower = rollFunction:InvokeServer()
    if newTower then
        print("GACHA: Unlocked " .. newTower)
        
        -- Find first locked slot to replace
        for i, data in ipairs(towerInventory) do
            if data.name == "Locked" then
                data.name = newTower
                data.icon = newTower:sub(1,1) .. " Noob" -- Simple icon
                data.cost = 150 -- Default price for new ones
                
                -- Update the button text
                local button = barFrame:FindFirstChild("Slot" .. i)
                if button then
                    button.Text = data.icon .. "\n$" .. data.cost
                    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    button.BackgroundTransparency = 0
                end
                break
            end
        end
    else
        print("GACHA: Not enough PT or error!")
        rollButton.Text = "NOT ENOUGH PT"
        task.wait(1)
        rollButton.Text = "🎲 ROLL (50 PT)"
    end
end)
