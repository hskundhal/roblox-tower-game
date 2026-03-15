-- GameManager.lua
-- Place this script inside ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Game Settings
local BASE_HEALTH_MAX = 100
local STARTING_CASH = 500
local TIME_BETWEEN_WAVES = 10

-- Game Difficulty (1-5)
_G.Difficulty = 1 
_G.GamePhase = "Lobby"


-- Game State Variables
local baseHealth = BASE_HEALTH_MAX
local currentWave = 0
local gameInProgress = false

local enemyFolder = ReplicatedStorage:WaitForChild("Enemies")
local basicZombie = enemyFolder:WaitForChild("Alien")

-- Find the spawn point
local waypointsFolder = workspace:WaitForChild("Waypoints")
local spawnPoint = waypointsFolder:WaitForChild("1")

-- Folders for cleanup
local workspaceEnemies = workspace:FindFirstChild("Enemies")
if not workspaceEnemies then
	workspaceEnemies = Instance.new("Folder")
	workspaceEnemies.Name = "Enemies"
	workspaceEnemies.Parent = workspace
end

local workspaceTowers = workspace:FindFirstChild("Towers")
 -- (This will be created by either script, but we'll check here too)
if not workspaceTowers then
	workspaceTowers = Instance.new("Folder")
	workspaceTowers.Name = "Towers"
	workspaceTowers.Parent = workspace
end

-- Reuse the events if they already exist, otherwise create them
local healthEvent = ReplicatedStorage:FindFirstChild("UpdateBaseHealth")
if not healthEvent then
	healthEvent = Instance.new("RemoteEvent")
	healthEvent.Name = "UpdateBaseHealth"
	healthEvent.Parent = ReplicatedStorage
end

local getHealthFunction = ReplicatedStorage:FindFirstChild("GetInitialHealth")
if not getHealthFunction then
	getHealthFunction = Instance.new("RemoteFunction")
	getHealthFunction.Name = "GetInitialHealth"
	getHealthFunction.Parent = ReplicatedStorage
end

getHealthFunction.OnServerInvoke = function(player)
	return baseHealth, BASE_HEALTH_MAX
end

-- Set up the player's leaderboard when they join
Players.PlayerAdded:Connect(function(player)
	-- Create a folder called 'leaderstats' inside the player. 
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = STARTING_CASH
	cash.Parent = leaderstats
	
	local pt = Instance.new("IntValue")
	pt.Name = "PT"
	pt.Value = 0
	pt.Parent = leaderstats
end)

-- Function to handle when an enemy reaches the end
-- You will need to call this from your EnemyMovement script!
local function damageBase(damageAmount)
	baseHealth = baseHealth - damageAmount
	print("Base Health: " .. baseHealth .. " / " .. BASE_HEALTH_MAX)
	
	-- Tell everyone on the server that the health just went down!
	healthEvent:FireAllClients(baseHealth, BASE_HEALTH_MAX)
	
	if baseHealth <= 0 then
		print("GAME OVER! The base was destroyed.")
		gameInProgress = false
	end
end
-- We make this global so the Enemy script can talk to it
_G.DamageBase = damageBase


-- Function to spawn a specific number of enemies
local function spawnWave(waveNumber)
	print("--- Wave " .. waveNumber .. " Starting! ---")
	
	-- A simple formula formula: Wave 1 spawns 5, Wave 2 spawns 10, etc.
	local enemiesToSpawn = waveNumber * 5 
	
	for i = 1, enemiesToSpawn do
		-- Only spawn if the game hasn't ended
		if not gameInProgress then break end
		
		local newZombie = basicZombie:Clone()
		
		-- Teleport it to the start of the path and face the next waypoint!
		local waypoint2 = waypointsFolder:FindFirstChild("2")
		if waypoint2 then
			local lookAtCFrame = CFrame.lookAt(spawnPoint.Position, waypoint2.Position)
			newZombie:PivotTo(lookAtCFrame)
		else
			newZombie:PivotTo(spawnPoint.CFrame)
		end
		
		newZombie.Parent = workspaceEnemies -- Put it in the folder for easy cleanup!
		
		-- Hook up a function to give all players cash and PT when the zombie dies
		local humanoid = newZombie:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			for _, player in ipairs(Players:GetPlayers()) do
				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats then
					local cash = leaderstats:FindFirstChild("Cash")
					local pt = leaderstats:FindFirstChild("PT")
					if cash then cash.Value = cash.Value + 10 end
					if pt then pt.Value = pt.Value + 1 end
				end
			end
			-- Wait 2 seconds for the body to disappear
			task.wait(2)
			newZombie:Destroy()
		end)
		
		-- Apply difficulty scaling to health
		humanoid.MaxHealth = humanoid.MaxHealth * _G.Difficulty
		humanoid.Health = humanoid.MaxHealth
		
		-- Wait a short time between each zombie spawning
		task.wait(1.5 / _G.Difficulty) -- Scale spawn speed too?
	end
end

local function clearZombiesAndTowers()
	-- Destroy everything inside the cleanup folders
	workspaceEnemies:ClearAllChildren()
	workspaceTowers:ClearAllChildren()
	print("Map cleared of all enemies and towers!")
end

-- RemoteEvent for starting the game
local startGameEvent = ReplicatedStorage:FindFirstChild("StartGameEvent")
if not startGameEvent then
	startGameEvent = Instance.new("RemoteEvent")
	startGameEvent.Name = "StartGameEvent"
	startGameEvent.Parent = ReplicatedStorage
end

local function runGame(difficulty)
	_G.Difficulty = difficulty
	_G.GamePhase = "Combat"
	print("--- NEW GAME STARTING AT DIFFICULTY " .. _G.Difficulty .. "! ---")
	
	-- Teleport players to Map
	local mapSpawn = workspace:FindFirstChild("MapSpawn")
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and mapSpawn then
			player.Character:PivotTo(mapSpawn.CFrame + Vector3.new(0, 5, 0))
		end
	end
	
	-- Reset the game variables
	baseHealth = BASE_HEALTH_MAX
	currentWave = 0
	gameInProgress = true
	
	-- Update the UI
	healthEvent:FireAllClients(baseHealth, BASE_HEALTH_MAX)
	
	-- Give everyone starting cash again
	for _, player in ipairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local cash = leaderstats:FindFirstChild("Cash")
			if cash then cash.Value = STARTING_CASH end
		end
	end
	
	task.wait(2) 

	-- The Wave Loop
	while gameInProgress do
		currentWave = currentWave + 1
		spawnWave(currentWave)
		
		if gameInProgress then
			print("Wave cleared! Waiting " .. TIME_BETWEEN_WAVES .. " seconds...")
			task.wait(TIME_BETWEEN_WAVES)
		end
	end
	
	-- If we broke out of the wave loop, the game is over!
	print("Game Over. Cleaning up...")
	clearZombiesAndTowers()
	
	_G.GamePhase = "Lobby"
	-- Teleport players back to Lobby
	local lobbySpawn = workspace:FindFirstChild("LobbySpawn")
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and lobbySpawn then
			player.Character:PivotTo(lobbySpawn.CFrame + Vector3.new(0, 5, 0))
		end
	end
	
	task.wait(3)
end

-- Wait for a player to pick a level
startGameEvent.OnServerEvent:Connect(function(player, selectedDifficulty)
	if gameInProgress then return end -- Don't start if already running
	runGame(selectedDifficulty or 1)
end)
