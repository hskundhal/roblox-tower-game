-- GameLobbyClient.lua
-- Place this inside StarterPlayer -> StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local startGameEvent = ReplicatedStorage:WaitForChild("StartGameEvent")

-- 1. Create the Lobby UI
local screenGui = player:WaitForChild("PlayerGui"):WaitForChild("CustomCashUI")

local lobbyFrame = Instance.new("Frame")
lobbyFrame.Name = "LobbyMenu"
lobbyFrame.Size = UDim2.new(0, 400, 0, 350)
lobbyFrame.AnchorPoint = Vector2.new(0.5, 0.5)
lobbyFrame.Position = UDim2.new(0.5, 0, 0.5, -50)
lobbyFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
lobbyFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 15)
uiCorner.Parent = lobbyFrame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 60)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.FredokaOne
title.TextSize = 32
title.Text = "SELECT DIFFICULTY"
title.Parent = lobbyFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Parent = lobbyFrame

-- Create 5 Buttons
for i = 1, 5 do
    local btn = Instance.new("TextButton")
    btn.Name = "Level" .. i
    btn.Size = UDim2.new(0.8, 0, 0, 45)
    btn.BackgroundColor3 = Color3.fromHSV(0.3 * (1 - (i/5)), 0.8, 0.6) -- Green to Red
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.FredokaOne
    btn.TextSize = 22
    btn.Text = "LEVEL " .. i
    
    if i == 5 then btn.Text = "LEVEL 5 (EXTREME)" end
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        print("LOBBY: Starting Level " .. i)
        lobbyFrame.Visible = false
        startGameEvent:FireServer(i)
    end)
    
    btn.Parent = lobbyFrame
end

-- Show the lobby whenever the game ends (check for base health updates?)
-- For now, just show it on join.
lobbyFrame.Visible = true

-- Listen for the game ending to show the menu again
-- (Since GameManager resets, we can just check if base health returns to max)
local updateHealthEvent = ReplicatedStorage:WaitForChild("UpdateBaseHealth")
updateHealthEvent.OnClientEvent:Connect(function(current, max)
    if current == max and not lobbyFrame.Visible then
        -- This is a simple way to detect the "Waiting" phase
        -- task.wait(5)
        -- lobbyFrame.Visible = true
    end
end)
