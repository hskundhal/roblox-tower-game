-- FixNewAlien.lua
-- COPY AND PASTE THIS INTO THE ROBLOX STUDIO COMMAND BAR AND PRESS ENTER
-- This script will fix or create a "NewAlien" in ReplicatedStorage.Enemies

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local enemyFolder = ReplicatedStorage:FindFirstChild("Enemies")

if not enemyFolder then
    enemyFolder = Instance.new("Folder")
    enemyFolder.Name = "Enemies"
    enemyFolder.Parent = ReplicatedStorage
end

-- 1. Get the basic Alien as a template
local basicAlien = enemyFolder:FindFirstChild("Alien")
if not basicAlien then
    warn("Basic 'Alien' model not found in ReplicatedStorage.Enemies. Please ensure it exists first!")
    return
end

-- 2. Create or find NewAlien
local template = enemyFolder:FindFirstChild("NewAlien")
if template then
    template:Destroy() -- We will recreate it to be sure it's correct
end

local newAlien = basicAlien:Clone()
newAlien.Name = "NewAlien"

-- 3. Modify its appearance (so you can tell it's the new one)
local head = newAlien:FindFirstChild("Head")
if head then
    head.Color = Color3.fromRGB(255, 0, 0) -- Red head for the New Alien
end

-- 4. Ensure it has a Humanoid (Critical for health and targeting)
local humanoid = newAlien:FindFirstChild("Humanoid")
if not humanoid then
    humanoid = Instance.new("Humanoid")
    humanoid.Parent = newAlien
end

-- 5. Ensure it has the EnemyMovement script
local movementScript = newAlien:FindFirstChild("EnemyMovement")
if not movementScript then
    -- Try to find it in the basic Alien
    local basicMovement = basicAlien:FindFirstChild("EnemyMovement")
    if basicMovement then
        movementScript = basicMovement:Clone()
        movementScript.Parent = newAlien
        print("Copied EnemyMovement script from Alien to NewAlien.")
    else
        warn("EnemyMovement script not found in basic Alien! NewAlien won't move.")
    end
end

-- 6. Set Parent
newAlien.Parent = enemyFolder

print("✅ NewAlien has been FIXED / CREATED in ReplicatedStorage.Enemies!")
print("   - Red Head: Yes")
print("   - Humanoid: " .. (newAlien:FindFirstChild("Humanoid") and "Yes" or "NO"))
print("   - Movement Script: " .. (newAlien:FindFirstChild("EnemyMovement") and "Yes" or "NO"))
