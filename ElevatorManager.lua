-- ElevatorManager.lua (SINGLE-PLACE VOTING EDITION)
-- Place this inside ServerScriptService
-- No separate places needed! Everything runs in one game.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- CONFIGURATION
local MAX_PLAYERS  = 3
local COUNTDOWN_TIME = 15   -- Seconds to vote before game starts
local ELEVATORS_FOLDER_NAME = "Elevators"
local SCAN_RATE = 0.5       -- Seconds between presence scans

-- ── RemoteEvents ─────────────────────────────────────────────────────────────
local function getOrCreate(name, class)
	local obj = ReplicatedStorage:FindFirstChild(name)
	if not obj then
		obj = Instance.new(class)
		obj.Name = name
		obj.Parent = ReplicatedStorage
	end
	return obj
end

local onElevatorEvent  = getOrCreate("OnElevatorEvent",  "RemoteEvent")  -- Server→Client: which elevator player is on
local castVoteEvent    = getOrCreate("CastVoteEvent",    "RemoteEvent")  -- Client→Server: player's difficulty vote
local voteUpdateEvent  = getOrCreate("VoteUpdateEvent",  "RemoteEvent")  -- Server→Client: live tally broadcast
local startGameEvent   = getOrCreate("StartGameEvent",   "RemoteEvent")  -- Already used by GameManager

-- ── Elevator Folder ──────────────────────────────────────────────────────────
local elevatorsFolder = workspace:FindFirstChild(ELEVATORS_FOLDER_NAME)
if not elevatorsFolder then
	warn("'Elevators' folder not found in Workspace! Please create it.")
	return
end

-- ── State ─────────────────────────────────────────────────────────────────────
-- queues[elevatorName] = { players, votes, timer, isActive, graceCount }
local queues = {}
for _, elevator in ipairs(elevatorsFolder:GetChildren()) do
	if elevator:IsA("BasePart") then
		queues[elevator.Name] = {
			players    = {},
			votes      = {},  -- { [Player] = difficultyNumber }
			timer      = COUNTDOWN_TIME,
			isActive   = false,
			graceCount = 0,
		}
	end
end

-- Track which elevator each player is currently standing on
local playerElevator = {}   -- { [Player] = elevatorName }

-- ── Helpers ──────────────────────────────────────────────────────────────────
local function getWinningDifficulty(votes)
	local tally = {}
	for _, diff in pairs(votes) do
		tally[diff] = (tally[diff] or 0) + 1
	end
	local bestDiff, bestCount = 1, 0
	for diff, count in pairs(tally) do
		if count > bestCount then
			bestDiff  = diff
			bestCount = count
		end
	end
	return bestDiff
end

local function buildTally(votes)
	local tally = {}
	for d = 1, 5 do tally[d] = 0 end
	for _, diff in pairs(votes) do
		tally[diff] = (tally[diff] or 0) + 1
	end
	return tally
end

local function broadcastVotes(elevatorName)
	local q = queues[elevatorName]
	local tally = buildTally(q.votes)
	for _, player in ipairs(q.players) do
		voteUpdateEvent:FireClient(player, tally, math.ceil(q.timer))
	end
end

local function updateDisplay(elevator)
	local surfaceGui = elevator:FindFirstChild("Display")
	if not surfaceGui then return end
	local textLabel = surfaceGui:FindFirstChild("TextLabel")
	if not textLabel then return end

	local q = queues[elevator.Name]
	local tally = buildTally(q.votes)
	local voteStr = ""
	for d = 1, 5 do
		if tally[d] > 0 then voteStr = voteStr .. "Lv" .. d .. ":" .. tally[d] .. " " end
	end

	if q.isActive then
		textLabel.Text = elevator.Name
			.. "\n" .. #q.players .. "/" .. MAX_PLAYERS
			.. "\n⏱ " .. math.ceil(q.timer) .. "s"
			.. (voteStr ~= "" and ("\n" .. voteStr) or "")
	else
		textLabel.Text = elevator.Name
			.. "\n" .. #q.players .. "/" .. MAX_PLAYERS
			.. "\nStep on to start!"
	end
end

-- ── Start Game (within this same place) ─────────────────────────────────────
local function startGame(elevatorName)
	local q = queues[elevatorName]
	local winningDiff = getWinningDifficulty(q.votes)
	print("Elevator " .. elevatorName .. " → Winning difficulty: " .. winningDiff)

	-- Teleport players to MapSpawn in this same place
	local mapSpawn = workspace:FindFirstChild("MapSpawn")
	for _, player in ipairs(q.players) do
		if player and player.Parent then
			if player.Character and mapSpawn then
				player.Character:PivotTo(mapSpawn.CFrame + Vector3.new(0, 5, 0))
			end
			-- Notify client: off the elevator
			playerElevator[player] = nil
			onElevatorEvent:FireClient(player, nil)
		end
	end

	-- Fire the StartGameEvent so GameManager starts the wave loop
	-- We fire it from the server using FireAllClients trick — but GameManager
	-- listens to OnServerEvent, so we directly call it via a BindableEvent
	-- The cleanest approach: set _G values and fire a BindableEvent
	_G.Difficulty = winningDiff

	local startBind = ReplicatedStorage:FindFirstChild("StartGameBind")
	if not startBind then
		startBind = Instance.new("BindableEvent")
		startBind.Name = "StartGameBind"
		startBind.Parent = ReplicatedStorage
	end
	startBind:Fire(winningDiff)

	-- Reset queue
	q.players    = {}
	q.votes      = {}
	q.timer      = COUNTDOWN_TIME
	q.isActive   = false
	q.graceCount = 0
end

-- ── Vote Handler (Client → Server) ───────────────────────────────────────────
castVoteEvent.OnServerEvent:Connect(function(player, difficulty)
	difficulty = tonumber(difficulty)
	if not difficulty or difficulty < 1 or difficulty > 5 then return end

	local elevName = playerElevator[player]
	if not elevName then return end   -- player isn't on any elevator

	queues[elevName].votes[player] = difficulty
	print(player.Name .. " voted Lv" .. difficulty .. " on " .. elevName)

	broadcastVotes(elevName)
	local elevator = elevatorsFolder:FindFirstChild(elevName)
	if elevator then updateDisplay(elevator) end
end)

-- ── Cleanup on leave ─────────────────────────────────────────────────────────
Players.PlayerRemoving:Connect(function(player)
	local elevName = playerElevator[player]
	if elevName and queues[elevName] then
		queues[elevName].votes[player] = nil
	end
	playerElevator[player] = nil
end)

-- ── Main Stable Scan Loop ────────────────────────────────────────────────────
task.spawn(function()
	while true do
		task.wait(SCAN_RATE)

		for _, elevator in ipairs(elevatorsFolder:GetChildren()) do
			if not elevator:IsA("BasePart") then continue end
			local q = queues[elevator.Name]

			-- 1. Detect who is on this elevator pad (10-stud tall box)
			local playersOnPad = {}
			local scanCFrame = elevator.CFrame * CFrame.new(0, 5, 0)
			local scanSize   = Vector3.new(elevator.Size.X, 10, elevator.Size.Z)
			for _, part in ipairs(workspace:GetPartBoundsInBox(scanCFrame, scanSize)) do
				local model    = part:FindFirstAncestorOfClass("Model")
				local humanoid = model and model:FindFirstChild("Humanoid")
				local player   = humanoid and Players:GetPlayerFromCharacter(model)
				if player and not table.find(playersOnPad, player) then
					table.insert(playersOnPad, player)
				end
			end

			-- 2. Arrivals / departures
			for _, player in ipairs(playersOnPad) do
				if not table.find(q.players, player) then
					playerElevator[player] = elevator.Name
					onElevatorEvent:FireClient(player, elevator.Name)
				end
			end
			for _, player in ipairs(q.players) do
				if not table.find(playersOnPad, player) then
					playerElevator[player] = nil
					q.votes[player] = nil
					onElevatorEvent:FireClient(player, nil)
				end
			end

			q.players = playersOnPad

			-- 3. Countdown
			if #q.players > 0 then
				q.graceCount = 0
				if not q.isActive then
					q.isActive = true
					q.timer    = COUNTDOWN_TIME
				end
				q.timer = q.timer - SCAN_RATE
				broadcastVotes(elevator.Name)

				if q.timer <= 0 or #q.players >= MAX_PLAYERS then
					startGame(elevator.Name)
				end
			else
				q.graceCount = q.graceCount + 1
				if q.graceCount >= 4 then
					q.isActive   = false
					q.timer      = COUNTDOWN_TIME
					q.votes      = {}
					q.graceCount = 0
				end
			end

			-- 4. Update the physical display on the elevator
			updateDisplay(elevator)
		end
	end
end)
