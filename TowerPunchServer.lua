-- TowerPunchServer.lua
-- Place this script INSIDE your NEW "Noob" BasicTower model in ReplicatedStorage

local tower = script.Parent
local torso = tower:WaitForChild("Torso")
local rightArm = tower:WaitForChild("Right Arm")
local head = tower:WaitForChild("Head")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local gameSpeed = ReplicatedStorage:WaitForChild("GameSpeed")

-- Tower Stats
local baseDamage = 25 
local currentDamage = baseDamage
local range = 18 -- REDUCED RANGE (Previously 25)
local attackSpeed = 0.8 

-- Update damage when level changes
tower:GetAttributeChangedSignal("Level"):Connect(function()
    local level = tower:GetAttribute("Level") or 1
    local multiplier = tower:GetAttribute("DamageMultiplier") or 1
    currentDamage = (baseDamage + (level - 1) * 5) * multiplier
    print("UPGRADED: " .. tower.Name .. " Level " .. level .. " | Mult: x" .. multiplier .. " (Damage: " .. currentDamage .. ")")
end)

-- Initial damage set
local initialLevel = tower:GetAttribute("Level") or 1
local initialMult = tower:GetAttribute("DamageMultiplier") or 1
currentDamage = (baseDamage + (initialLevel - 1) * 5) * initialMult
-- 1. Create/Find the RangeRing (sitting at the feet)
local rangeRing = tower:FindFirstChild("RangeRing")
if not rangeRing then
    rangeRing = Instance.new("Part")
    rangeRing.Name = "RangeRing"
    rangeRing.Shape = Enum.PartType.Cylinder
    rangeRing.Size = Vector3.new(0.2, range * 2, range * 2)
    rangeRing.Transparency = 0.8
    rangeRing.Color = Color3.fromRGB(0, 170, 255) 
    rangeRing.Material = Enum.Material.Neon
    rangeRing.Anchored = true
    rangeRing.CanCollide = false
    rangeRing.Parent = tower
end

-- Position the range ring at the ground level
local function updateVisuals()
	local groundLevel = torso.Position - Vector3.new(0, 3, 0) -- R6 torso is roughly 3 studs above ground
	rangeRing.CFrame = CFrame.new(groundLevel + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90))
end

-- Function to find the closest zombie
local function findClosestEnemy()
    local closestEnemy = nil
    local shortestDistance = range

    local function checkContainer(container)
        for _, obj in ipairs(container:GetChildren()) do
            if obj:IsA("Model") and obj ~= tower then
                local humanoid = obj:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local isPlayer = game:GetService("Players"):GetPlayerFromCharacter(obj)
                    if not isPlayer then
                        local rootPart = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso")
                        if rootPart then
                            local distance = (torso.Position - rootPart.Position).Magnitude
                            if distance < shortestDistance then
                                shortestDistance = distance
                                closestEnemy = obj
                            end
                        end
                    end
                end
            end
        end
    end

    checkContainer(workspace)
    local enemyFolder = workspace:FindFirstChild("Enemies")
    if enemyFolder then checkContainer(enemyFolder) end

    return closestEnemy
end

-- Create a small effect at the hit location
local function createHitEffect(position)
    local effect = Instance.new("Part")
    effect.Size = Vector3.new(2, 2, 2)
    effect.Transparency = 0.4
    effect.Color = Color3.fromRGB(255, 255, 255) 
    effect.Material = Enum.Material.Neon
    effect.Anchored = true
    effect.CanCollide = false
    effect.Position = position
    effect.Parent = workspace
    task.delay(0.1, function() effect:Destroy() end)
end

-- Initial arm positions
local rightArmDefaultCFrame = rightArm.CFrame

-- The main loop
while true do
    updateVisuals()
    
    local target = findClosestEnemy()
    
    if target then
        local targetRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso") or target:FindFirstChild("UpperTorso")
        local humanoid = target:FindFirstChild("Humanoid")
        
        if targetRoot and humanoid then
            -- Face the target
            local lookAtCFrame = CFrame.lookAt(torso.Position, Vector3.new(targetRoot.Position.X, torso.Position.Y, targetRoot.Position.Z))
            tower:PivotTo(lookAtCFrame)
            
            -- PUNCH animation (Move Right Arm forward)
            local originalArmCFrame = rightArm.CFrame
            local punchCFrame = rightArm.CFrame * CFrame.new(0, 0, -2) -- Move forward 2 studs
            
            rightArm.CFrame = punchCFrame
            
            -- Damage and Effect
            humanoid:TakeDamage(currentDamage)
            createHitEffect(targetRoot.Position)
            print("NOOB PUNCH: " .. target.Name)
            
            task.wait(0.15 / gameSpeed.Value)
            rightArm.CFrame = originalArmCFrame
        end
    end
    
    task.wait(attackSpeed / gameSpeed.Value)
end
