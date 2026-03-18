-- TowerPlacementServer.lua
-- Place this inside ServerScriptService
-- This script handles the server-side logic of actually spawning the tower
-- and charging the player money (if you had an economy)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Centralized Events
local placementEvent = ReplicatedStorage:FindFirstChild("PlaceTowerEvent")
if not placementEvent then
	placementEvent = Instance.new("RemoteEvent")
	placementEvent.Name = "PlaceTowerEvent"
	placementEvent.Parent = ReplicatedStorage
end

local selectEvent = ReplicatedStorage:FindFirstChild("SelectTowerEvent")
if not selectEvent then
	-- BindableEvent is perfect for Client-UI to talk to Client-Placement
	selectEvent = Instance.new("BindableEvent")
	selectEvent.Name = "SelectTowerEvent"
	selectEvent.Parent = ReplicatedStorage
end

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
placementEvent.OnServerEvent:Connect(function(player, towerName, targetPosition, damageMultiplier)
	-- Ensure the player actually has enough money!
	damageMultiplier = damageMultiplier or 1 -- Default to 1 if not provided

	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	local towerCost = (towerName == "ALL OUT NOOB") and 300 or 100

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
		-- For character models (Noob), the Torso is 3 studs above the feet
		local heightOffset = 3 
		local finalCFrame = CFrame.new(targetPosition + Vector3.new(0, heightOffset, 0))

		newTower:PivotTo(finalCFrame)

		-- NEW: Set the initial level and randomized multiplier for upgrades
		newTower:SetAttribute("Level", 1)
		newTower:SetAttribute("DamageMultiplier", damageMultiplier)

		-- Put it in the Towers folder so everyone can see it and it can be cleared easily!
		newTower.Parent = workspaceTowers

		print(player.Name .. " successfully placed a " .. towerName .. "!")
	else
		warn("Tower " .. towerName .. " not found in ReplicatedStorage.Towers!")
	end
end)

-- NEW: Tower Upgrade Logic
local upgradeEvent = ReplicatedStorage:FindFirstChild("UpgradeTowerEvent")
if not upgradeEvent then
	upgradeEvent = Instance.new("RemoteEvent")
	upgradeEvent.Name = "UpgradeTowerEvent"
	upgradeEvent.Parent = ReplicatedStorage
end

upgradeEvent.OnServerEvent:Connect(function(player, towerToUpgrade)
	if not towerToUpgrade or not towerToUpgrade:IsDescendantOf(workspaceTowers) then return end

	local currentLevel = towerToUpgrade:GetAttribute("Level") or 1
	local upgradeCost = currentLevel * 100 -- Cost: $100, $200, $300...

	local cash = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Cash")
	if cash and cash.Value >= upgradeCost then
		cash.Value = cash.Value - upgradeCost
		towerToUpgrade:SetAttribute("Level", currentLevel + 1)
		print(player.Name .. " upgraded " .. towerToUpgrade.Name .. " to Level " .. (currentLevel + 1))
	else
		warn(player.Name .. " doesn't have enough cash to upgrade! (Needs " .. upgradeCost .. ")")
	end
end)

-- NEW: Gacha Roll Logic
local rollFunction = ReplicatedStorage:FindFirstChild("RollTowerFunction")
if not rollFunction then
	rollFunction = Instance.new("RemoteFunction")
	rollFunction.Name = "RollTowerFunction"
	rollFunction.Parent = ReplicatedStorage
end

local AVAILABLE_TOWERS = {"BasicTower", "FastNoob", "StrongNoob", "ALL OUT NOOB"} -- These must exist in RT.Towers
local ROLL_COST = 20

rollFunction.OnServerInvoke = function(player)
	-- RESTRICTION: Only roll in Lobby
	if _G.GamePhase and _G.GamePhase ~= "Lobby" then
		return nil
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local pt = leaderstats and leaderstats:FindFirstChild("PT")

	if pt and pt.Value >= ROLL_COST then
		pt.Value = pt.Value - ROLL_COST

		-- Rarity-based selection
		local roll = math.random(1, 100)
		local reward = "BasicTower"

		if roll <= 5 then
			reward = "ALL OUT NOOB" -- 5% chance
		elseif roll <= 20 then
			reward = "StrongNoob" -- 15% chance (5 to 20)
		elseif roll <= 50 then
			reward = "FastNoob" -- 30% chance (20 to 50)
		else
			reward = "BasicTower" -- 50% chance
		end

		-- RANDOMIZED STATS: 0.8 to 1.5
		local multiplier = math.floor((0.8 + math.random() * 0.7) * 100) / 100

		print(player.Name .. " rolled " .. reward .. " with x" .. multiplier .. " damage!")
		return {name = reward, multiplier = multiplier}
	else
		return nil -- Not enough PT
	end
end
