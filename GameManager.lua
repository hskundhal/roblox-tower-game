-- GameManager.lua
-- Place this script inside ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Game Settings
local BASE_HEALTH_MAX = 100
local STARTING_CASH = 500
local TIME_BETWEEN_WAVES = 10

-- Game Configuration
local IS_LOBBY_PLACE = false -- CHANGE TO FALSE FOR YOUR COMBAT MAPS!
local FINAL_WAVE = 20 -- The boss arrives here!
local BOSS_NAME = "AlienBoss"

-- Wave Sync
local waveEvent = ReplicatedStorage:FindFirstChild("UpdateWave")
if not waveEvent then
	waveEvent = Instance.new("RemoteEvent")
	waveEvent.Name = "UpdateWave"
	waveEvent.Parent = ReplicatedStorage
end

-- Phase Sync (Server to Client)
local gamePhaseValue = ReplicatedStorage:FindFirstChild("GamePhase")
if not gamePhaseValue then
	gamePhaseValue = Instance.new("StringValue")
	gamePhaseValue.Name = "GamePhase"
	gamePhaseValue.Value = "Lobby"
	gamePhaseValue.Parent = ReplicatedStorage
end

-- Game Speed Sync (1x or 2x)
local gameSpeed = ReplicatedStorage:FindFirstChild("GameSpeed")
if not gameSpeed then
	gameSpeed = Instance.new("NumberValue")
	gameSpeed.Name = "GameSpeed"
	gameSpeed.Value = 1
	gameSpeed.Parent = ReplicatedStorage
end

local toggleSpeedEvent = ReplicatedStorage:FindFirstChild("ToggleSpeedEvent")
if not toggleSpeedEvent then
	toggleSpeedEvent = Instance.new("RemoteEvent")
	toggleSpeedEvent.Name = "ToggleSpeedEvent"
	toggleSpeedEvent.Parent = ReplicatedStorage
end

toggleSpeedEvent.OnServerEvent:Connect(function(player)
	if gameSpeed.Value >= 5 then
		gameSpeed.Value = 1
	else
		gameSpeed.Value = gameSpeed.Value + 1
	end
	print("Game Speed Toggled to: " .. gameSpeed.Value .. "x")
end)

-- Teleport player to Lobby on join
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local lobbySpawn = workspace:FindFirstChild("LobbySpawn")
		if lobbySpawn then
			task.wait(0.1) -- Wait for character to fully load
			character:PivotTo(lobbySpawn.CFrame + Vector3.new(0, 5, 0))
		end
	end)
end)

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
local function onEnemyReachedEnd(enemy)
	local isBoss = (enemy.Name == BOSS_NAME)
	local damage = isBoss and 50 or 10 -- Boss deals 50 damage!
	
	baseHealth = math.max(0, baseHealth - damage)
	print("An " .. enemy.Name .. " reached the base! Base Health: " .. baseHealth .. " / " .. BASE_HEALTH_MAX)
	
	-- Tell everyone on the server that the health just went down!
	healthEvent:FireAllClients(baseHealth, BASE_HEALTH_MAX)
	
	if baseHealth <= 0 then
		print("GAME OVER! The base was destroyed.")
		gameInProgress = false
	end
end
-- We make this global so the Enemy script can talk to it
_G.OnEnemyReachedEnd = onEnemyReachedEnd


-- Function to spawn a specific number of enemies
local function spawnWave(waveNumber)
	print("--- Wave " .. waveNumber .. " Starting! ---")
	waveEvent:FireAllClients(waveNumber, FINAL_WAVE)
	
	-- 1. Determine enemy type
	local enemyName = "BasicAlien"
	local isBossWave = (waveNumber == FINAL_WAVE)
	
	-- 2. Spawn loop
	local enemyCount = 5 + (waveNumber * 2)
	if isBossWave then enemyCount = 1 end -- Just the boss? Or boss + minions? Let's do Boss.
	
	for i = 1, enemyCount do
		-- Only spawn if the game hasn't ended
		if not gameInProgress then break end
		
		local templateName = "Alien"
		if isBossWave then
			templateName = BOSS_NAME
		elseif waveNumber >= 10 then
			-- Mix normal and new aliens after wave 10
			if math.random() > 0.5 then
				templateName = "NewAlien"
			end
		end
		
		local template = enemyFolder:FindFirstChild(templateName)
		
		if not template then
			warn(templateName .. " not found in ReplicatedStorage.Enemies!")
			-- Fallback to basic Alien if NewAlien is missing
			template = enemyFolder:FindFirstChild("Alien")
			if not template then break end
		end
		
		local newZombie = template:Clone()
		
		-- Teleport it to the start of the path with a small random offset so they don't stack perfectly!
		local randomOffset = Vector3.new(math.random(-4, 4), 0, math.random(-4, 4))
		local waypoint2 = waypointsFolder:FindFirstChild("2")
		if waypoint2 then
			local lookAtCFrame = CFrame.lookAt(spawnPoint.Position + randomOffset, waypoint2.Position)
			newZombie:PivotTo(lookAtCFrame)
		else
			newZombie:PivotTo(spawnPoint.CFrame + CFrame.new(randomOffset))
		end
		
		newZombie.Parent = workspaceEnemies -- Put it in the folder for easy cleanup!
		
		-- Hook up a function to give all players cash and PT when the zombie dies
		local humanoid = newZombie:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				for _, player in ipairs(Players:GetPlayers()) do
					local leaderstats = player:FindFirstChild("leaderstats")
					if leaderstats then
						local cash = leaderstats:FindFirstChild("Cash")
						local pt = leaderstats:FindFirstChild("PT")
						
						-- Boss gives 500 cash and 50 PT!
						local rewardCash = isBossWave and 500 or 10
						local rewardPT = isBossWave and 50 or 1
						
						if cash then cash.Value = cash.Value + rewardCash end
						if pt then pt.Value = pt.Value + rewardPT end
					end
				end
				-- Wait 2 seconds for the body to disappear
				task.wait(2)
				newZombie:Destroy()
			end)
			
			-- Apply difficulty scaling to health
			local healthMult = 1
			if isBossWave then
				healthMult = 20
			elseif templateName == "NewAlien" then
				-- NewAlien defaults to 100 base health (Normal Alien is usually 10-20)
				humanoid.MaxHealth = 100
			end
			
			humanoid.MaxHealth = humanoid.MaxHealth * _G.Difficulty * healthMult
			humanoid.Health = humanoid.MaxHealth
		else
			warn(templateName .. " is missing a Humanoid! It won't have health or be targetable.")
		end
		
		if isBossWave then
			print("🚨 BOSS WARNING: " .. BOSS_NAME .. " HAS SPAWNED!")
		end
		
		-- Wait a time between each zombie spawning (ensure minimum separation of 1.5s scaled by speed)
		local spawnDelay = math.max(1.5, 3.0 / _G.Difficulty)
		task.wait(spawnDelay / gameSpeed.Value) 
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
	gamePhaseValue.Value = "Combat"
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
		
		-- NEW: Check if this was the final wave
		if currentWave >= FINAL_WAVE then
			print("--- FINAL WAVE CLEARED! VICTORY! ---")
			gameInProgress = false
			break
		end
		
		if gameInProgress then
			print("Wave cleared! Waiting " .. TIME_BETWEEN_WAVES .. " seconds...")
			task.wait(TIME_BETWEEN_WAVES / gameSpeed.Value)
		end
	end
	
	-- If we broke out of the wave loop, the game is over!
	print("Game Over. Cleaning up...")
	clearZombiesAndTowers()
	
	_G.GamePhase = "Lobby"
	gamePhaseValue.Value = "Lobby"
	-- Teleport players back to Lobby
	local lobbySpawn = workspace:FindFirstChild("LobbySpawn")
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and lobbySpawn then
			player.Character:PivotTo(lobbySpawn.CFrame + Vector3.new(0, 5, 0))
		end
	end
	
	task.wait(3)
end

-- Wait for a player to pick a level (backup - in case it's triggered directly)
startGameEvent.OnServerEvent:Connect(function(player, selectedDifficulty)
	if IS_LOBBY_PLACE then return end -- NO COMBAT IN LOBBY!
	if gameInProgress then return end -- Don't start if already running
	runGame(selectedDifficulty or 1)
end)

-- Listen for the Elevator Voting system to start the game
local startBind = ReplicatedStorage:FindFirstChild("StartGameBind")
if not startBind then
	startBind = Instance.new("BindableEvent")
	startBind.Name = "StartGameBind"
	startBind.Parent = ReplicatedStorage
end
startBind.Event:Connect(function(winningDifficulty)
	if gameInProgress then return end  -- Don't double-start
	print("ElevatorManager triggered game start at difficulty: " .. winningDifficulty)
	runGame(winningDifficulty or 1)
end)
