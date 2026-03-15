-- EnemyMovement.lua
-- Place this script INSIDE your enemy model (e.g., a basic Dummy or Zombie rig)

-- Get the Humanoid component, which is the brain that moves Roblox characters
local enemy = script.Parent
local humanoid = enemy:WaitForChild("Humanoid")

-- Find the folder containing all our waypoints in the Workspace
local waypointsFolder = workspace:WaitForChild("Waypoints")

-- Create an empty table (list) to store waypoints in order (1, 2, 3...)
local waypoints = {}

-- Loop through the folder and gather all the waypoint parts
for _, waypoint in ipairs(waypointsFolder:GetChildren()) do
    if waypoint:IsA("BasePart") then
        local waypointNumber = tonumber(waypoint.Name)
        if waypointNumber then
            waypoints[waypointNumber] = waypoint
        else
            warn("A Waypoint name is not a number: " .. waypoint.Name)
        end
    end
end

-- Function to make the enemy walk through each waypoint sequentially
local function moveAlongPath()
    print("Enemy is starting to move!")
    
    -- Loop through our sorted waypoints list from 1 to the end
    for i = 1, #waypoints do
        local targetWaypoint = waypoints[i]
        
        if targetWaypoint then
            -- Tell the Humanoid to walk to the center position of the current waypoint
            humanoid:MoveTo(targetWaypoint.Position)
            
            -- Pause this script until the Humanoid actually reaches the destination
            -- (MoveToFinished fires automatically when it arrives)
            humanoid.MoveToFinished:Wait()
        end
    end
    
    -- When the loop finishes, the enemy has reached the final waypoint!
    -- Damage the player's Base health using the global function from GameManager
    if _G.DamageBase then
        _G.DamageBase(10) -- Zombies do 10 damage
    else
        warn("GameManager is not running! Cannot damage base.")
    end
    
    enemy:Destroy() -- Remove the enemy from the game
end

-- Wait 1 second to make sure the game has loaded before starting
task.wait(1)
moveAlongPath()
