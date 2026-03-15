-- TowerPunchServer.lua
-- Place this script INSIDE your BasicTower model in ReplicatedStorage

local tower = script.Parent
local primaryPart = tower.PrimaryPart

-- Tower Stats
local damage = 25 
local range = 25 
local attackSpeed = 0.8 

-- 1. Create the "Range Ring" (Visible area)
local rangeRing = Instance.new("Part")
rangeRing.Name = "RangeRing"
rangeRing.Shape = Enum.PartType.Cylinder
rangeRing.Size = Vector3.new(0.2, range * 2, range * 2) -- X is the thickness
rangeRing.Transparency = 0.8
rangeRing.Color = Color3.fromRGB(0, 170, 255) 
rangeRing.Material = Enum.Material.Neon
rangeRing.Anchored = true
rangeRing.CanCollide = false
rangeRing.Parent = tower

-- 2. Create the "Fist" part for punching
local fist = Instance.new("Part")
fist.Size = Vector3.new(2.5, 2.5, 2.5) 
fist.Color = Color3.fromRGB(255, 0, 0) 
fist.Material = Enum.Material.Neon
fist.Anchored = true
fist.CanCollide = false
fist.Parent = tower

-- Reset fist to inside the tower
fist.CFrame = primaryPart.CFrame

-- Function to find the closest zombie
local function findClosestEnemy()
    local closestEnemy = nil
    local shortestDistance = range

    for _, obj in ipairs(workspace:GetChildren()) do
        -- Only check enemies (ignore towers and folders)
        if obj:IsA("Model") and obj ~= tower then
            local humanoid = obj:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local isPlayer = game:GetService("Players"):GetPlayerFromCharacter(obj)
                if not isPlayer then
                    local rootPart = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso")
                    if rootPart then
                        local distance = (primaryPart.Position - rootPart.Position).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestEnemy = obj
                        end
                    end
                end
            end
        end
    end
    
    -- Also check the dedicated Enemies folder if it exists!
    local enemyFolder = workspace:FindFirstChild("Enemies")
    if enemyFolder then
        for _, obj in ipairs(enemyFolder:GetChildren()) do
            local humanoid = obj:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local rootPart = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso")
                if rootPart then
                    local distance = (primaryPart.Position - rootPart.Position).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestEnemy = obj
                    end
                end
            end
        end
    end

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

-- The main loop
while true do
    -- Position and flatten the ring
    -- Rotating on Z (0, 0, 90) makes the X-axis (the cylinder height) point UP.
    local ringPos = primaryPart.Position - Vector3.new(0, primaryPart.Size.Y/2 - 0.05, 0)
    rangeRing.CFrame = CFrame.new(ringPos) * CFrame.Angles(0, 0, math.rad(90))

    local target = findClosestEnemy()
    
    if target then
        local targetRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso") or target:FindFirstChild("UpperTorso")
        local humanoid = target:FindFirstChild("Humanoid")
        
        if targetRoot and humanoid then
            -- Face the target
            local lookAtCFrame = CFrame.lookAt(primaryPart.Position, Vector3.new(targetRoot.Position.X, primaryPart.Position.Y, targetRoot.Position.Z))
            tower:PivotTo(lookAtCFrame)
            
            -- Punch!
            local punchPosition = lookAtCFrame * CFrame.new(0, 0, -8) 
            fist.CFrame = punchPosition
            
            -- Damage and Effect
            humanoid:TakeDamage(damage)
            createHitEffect(targetRoot.Position)
            print("PUNCHED: " .. target.Name)
            
            task.wait(0.15)
        end
    end
    
    -- Reset fist and wait
    fist.CFrame = primaryPart.CFrame
    task.wait(attackSpeed)
end
