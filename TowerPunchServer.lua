-- TowerPunchServer.lua
-- Place this script INSIDE your NEW "Tall Pole" BasicTower model in ReplicatedStorage

local tower = script.Parent
local pillar = tower.PrimaryPart -- We assume the tall tall pillar is the PrimaryPart

-- Tower Stats
local damage = 25 
local range = 35 -- Increased slightly since it's a TALL tower
local attackSpeed = 0.8 

-- 1. Reference the existing RangeRing and Fist (Created by the construction script)
local rangeRing = tower:WaitForChild("RangeRing")
local fist = tower:WaitForChild("Fist")

-- Position the range ring at the ground level (pillar's bottom)
local function updateVisuals()
	local groundLevel = pillar.Position - Vector3.new(0, pillar.Size.Y/2, 0)
	rangeRing.CFrame = CFrame.new(groundLevel + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90))
end

-- Function to find the closest zombie
local function findClosestEnemy()
    local closestEnemy = nil
    local shortestDistance = range

    -- Helper to check objects in a container
    local function checkContainer(container)
        for _, obj in ipairs(container:GetChildren()) do
            if obj:IsA("Model") and obj ~= tower then
                local humanoid = obj:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local isPlayer = game:GetService("Players"):GetPlayerFromCharacter(obj)
                    if not isPlayer then
                        local rootPart = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso")
                        if rootPart then
                            local distance = (pillar.Position - rootPart.Position).Magnitude
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
    effect.Size = Vector3.new(3, 3, 3)
    effect.Transparency = 0.4
    effect.Color = Color3.fromRGB(255, 255, 255) 
    effect.Material = Enum.Material.Neon
    effect.Anchored = true
    effect.CanCollide = false
    effect.Position = position
    effect.Parent = workspace
    task.delay(0.1, function() effect:Destroy() end)
end

-- Initial setup
updateVisuals()
fist.CFrame = pillar.CFrame * CFrame.new(0, pillar.Size.Y/2 - 1, 0) -- Hidden near the top

-- The main loop
while true do
    updateVisuals()
    
    local target = findClosestEnemy()
    
    if target then
        local targetRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso") or target:FindFirstChild("UpperTorso")
        local humanoid = target:FindFirstChild("Humanoid")
        
        if targetRoot and humanoid then
            -- Face the target (Rotate the whole tower)
            local lookAtCFrame = CFrame.lookAt(pillar.Position, Vector3.new(targetRoot.Position.X, pillar.Position.Y, targetRoot.Position.Z))
            tower:PivotTo(lookAtCFrame * CFrame.Angles(0, 0, math.rad(90)))
            
            -- Punch from the TOP of the pole!
            -- Calculate the start point (top of the pillar)
            local topPosition = pillar.CFrame * CFrame.new(0, pillar.Size.Y/2 - 1, 0)
            local punchPosition = topPosition * CFrame.new(0, 0, -range/2) -- Punches out half its range
            
            fist.CFrame = punchPosition
            
            -- Damage and Effect
            humanoid:TakeDamage(damage)
            createHitEffect(targetRoot.Position)
            print("TALL PUNCH: " .. target.Name)
            
            task.wait(0.2)
        end
    end
    
    -- Reset fist to top of pole
    fist.CFrame = pillar.CFrame * CFrame.new(0, pillar.Size.Y/2 - 1, 0)
    task.wait(attackSpeed)
end
