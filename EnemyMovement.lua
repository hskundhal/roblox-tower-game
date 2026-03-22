-- EnemyMovement.lua
-- Place this script INSIDE your enemy model (e.g., a basic Dummy or Zombie rig)

-- Get the Humanoid component, which is the brain that moves Roblox characters
local enemy = script.Parent
local humanoid = enemy:WaitForChild("Humanoid")

-- Find the folder containing all our waypoints in the Workspace
local waypointsFolder = workspace:WaitForChild("Waypoints")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local gameSpeed = ReplicatedStorage:WaitForChild("GameSpeed")

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

-- Disable collisions between enemies to prevent piling up
for _, part in ipairs(enemy:GetDescendants()) do
    if part:IsA("BasePart") then
        part.CanCollide = false
    end
end

-- Function to make the enemy walk through each waypoint sequentially
local function moveAlongPath()
    print("Enemy is starting to move!")
    
    for i = 1, #waypoints do
        local targetWaypoint = waypoints[i]
        if targetWaypoint then
            local retryTimer = 0
            humanoid:MoveTo(targetWaypoint.Position)
            
            while true do
                local root = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Torso")
                if not root then break end
                
                local dist = (root.Position - targetWaypoint.Position).Magnitude
                if dist < 4 then break end 
                
                -- Handle Stuns
                if enemy:GetAttribute("Stunned") then
                    humanoid.WalkSpeed = 0
                    while enemy:GetAttribute("Stunned") do task.wait(0.5) end
                    updateSpeed() 
                    humanoid:MoveTo(targetWaypoint.Position)
                    retryTimer = 0
                end
                
                -- Robustness: Re-issue MoveTo every 2 seconds if stuck
                retryTimer = retryTimer + 0.2
                if retryTimer >= 2 then
                    humanoid:MoveTo(targetWaypoint.Position)
                    retryTimer = 0
                end
                
                task.wait(0.2)
            end
        end
    end
    
    -- When the loop finishes, the enemy has reached the final waypoint!
    -- Damage the player's Base health using the global function from GameManager
    if _G.OnEnemyReachedEnd then
        _G.OnEnemyReachedEnd(enemy)
    elseif _G.DamageBase then
        _G.DamageBase(10) -- Fallback for old system
    else
        warn("GameManager is not running! Cannot damage base.")
    end
    
    enemy:Destroy() -- Remove the enemy from the game
end

-- Update WalkSpeed based on game speed and stun status
local function updateSpeed()
    if enemy:GetAttribute("Stunned") then
        humanoid.WalkSpeed = 0
    else
        humanoid.WalkSpeed = 16 * gameSpeed.Value
    end
end

gameSpeed.Changed:Connect(updateSpeed)
enemy:GetAttributeChangedSignal("Stunned"):Connect(updateSpeed)
updateSpeed() -- Initial set

-- Wait 2 seconds to make sure the game has loaded before starting
task.wait(2)
moveAlongPath()
