-- TowerPlacementServer.lua
-- Place this inside ServerScriptService
-- This script handles the server-side logic of actually spawning the tower
-- and charging the player money (if you had an economy)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local placementEvent = Instance.new("RemoteEvent")
placementEvent.Name = "PlaceTowerEvent"
placementEvent.Parent = ReplicatedStorage

-- Find or create the folder where towers are stored in Workspace for cleanup
local workspaceTowers = workspace:FindFirstChild("Towers")
if not workspaceTowers then
	workspaceTowers = Instance.new("Folder")
	workspaceTowers.Name = "Towers"
	workspaceTowers.Parent = workspace
end

-- Find the folder where tower models are stored in ReplicatedStorage
local towerFolder = ReplicatedStorage:WaitForChild("Towers")

-- When the client asks to place a tower, this function runs
placementEvent.OnServerEvent:Connect(function(player, towerName, targetPosition)
	-- Ensure the player actually has enough money!
	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	local towerCost = 100
	
	if not cash or cash.Value < towerCost then
		warn(player.Name .. " tried to place a tower but doesn't have enough cash!")
		return -- Stop the function here, don't spawn the tower
	end
	
	-- If they have enough money, charge them!
	cash.Value = cash.Value - towerCost
	
	-- Check if the tower exists in ReplicatedStorage
	local towerToSpawn = towerFolder:FindFirstChild(towerName)
	
	if towerToSpawn then
		-- Clone the tower
		local newTower = towerToSpawn:Clone()
		
		-- Move it to the position the player clicked
		-- We use the towerToSpawn's existing rotation so it doesn't fall over!
		local targetCFrame = CFrame.new(targetPosition + Vector3.new(0, newTower.PrimaryPart.Size.Y / 2, 0))
		-- Combine the new position with the model's saved rotation
		newTower:PivotTo(targetCFrame * towerToSpawn:GetPivot().Rotation)
		
		-- Put it in the Towers folder so everyone can see it and it can be cleared easily!
		newTower.Parent = workspaceTowers
		
		print(player.Name .. " successfully placed a " .. towerName .. "!")
	else
		warn("Tower " .. towerName .. " not found in ReplicatedStorage.Towers!")
	end
end)
