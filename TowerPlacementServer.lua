-- TowerPlacementServer.lua
-- Place this inside ServerScriptService
-- This script handles the server-side logic of actually spawning the tower
-- and charging the player money (if you had an economy)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Centralized Events & Folders (Create them immediately)
local function getOrCreate(className, name, parent)
	local existing = parent:FindFirstChild(name)
	if existing then return existing end
	local newObj = Instance.new(className)
	newObj.Name = name
	newObj.Parent = parent
	return newObj
end

local placementEvent = getOrCreate("RemoteEvent", "PlaceTowerEvent", ReplicatedStorage)
local upgradeEvent   = getOrCreate("RemoteEvent", "UpgradeTowerEvent", ReplicatedStorage)
local rollFunction   = getOrCreate("RemoteFunction", "RollTowerFunction", ReplicatedStorage)
-- BindableEvent is for Client-to-Client communication
local selectEvent    = getOrCreate("BindableEvent", "SelectTowerEvent", ReplicatedStorage)

local workspaceTowers = getOrCreate("Folder", "Towers", workspace)
local towerFolder     = ReplicatedStorage:WaitForChild("Towers", 5) or Instance.new("Folder", ReplicatedStorage)
if towerFolder.Name ~= "Towers" then towerFolder.Name = "Towers" end

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

-- Tower Upgrade Logic
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

-- Gacha Roll Logic
local AVAILABLE_TOWERS = {"BasicTower", "FastNoob", "StrongNoob", "ALL OUT NOOB"} -- These must exist in RT.Towers
local ROLL_COST = 20

rollFunction.OnServerInvoke = function(player, ownedTowers)
	-- RESTRICTION: Only roll in Lobby
	if _G.GamePhase and _G.GamePhase ~= "Lobby" then
		return nil
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local pt = leaderstats and leaderstats:FindFirstChild("PT")

	if pt and pt.Value >= ROLL_COST then
		-- Use ownedTowers directly from function parameters
		ownedTowers = ownedTowers or {}
		
		-- Filter pool: Basic is never rolled, and exclude already owned
		local pool = {
			{name = "ALL OUT NOOB", chance = 5},
			{name = "StrongNoob", chance = 15},
			{name = "FastNoob", chance = 30}
		}
		
		local availablePool = {}
		local totalWeight = 0
		for _, item in ipairs(pool) do
			local alreadyOwned = false
			for _, owned in ipairs(ownedTowers) do
				if owned == item.name then alreadyOwned = true break end
			end
			
			if not alreadyOwned then
				table.insert(availablePool, item)
				totalWeight = totalWeight + item.chance
			end
		end

		if #availablePool == 0 then
			print(player.Name .. " already owns all unique towers!")
			return nil -- All owned
		end

		pt.Value = pt.Value - ROLL_COST

		-- Rarity-based selection from available pool
		local roll = math.random(1, totalWeight)
		local reward = availablePool[1].name
		local currentWeight = 0
		for _, item in ipairs(availablePool) do
			currentWeight = currentWeight + item.chance
			if roll <= currentWeight then
				reward = item.name
				break
			end
		end

		-- RANDOMIZED STATS: 0.8 to 1.5
		local multiplier = math.floor((0.8 + math.random() * 0.7) * 100) / 100

		print(player.Name .. " rolled " .. reward .. " with x" .. multiplier .. " damage!")
		return {name = reward, multiplier = multiplier}
	else
		return nil -- Not enough PT
	end
end
