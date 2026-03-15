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
