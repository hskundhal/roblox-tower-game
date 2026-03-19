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
if tower.Name == "TRIPLE PUNCH NOOB" then
	baseDamage = 30
elseif tower.Name == "ALL OUT NOOB" then
	baseDamage = 15
elseif tower.Name == "SUPPORTER NOOB" then
    baseDamage = 0 -- Doesn't deal direct damage
elseif tower.Name == "FIRE NOOB" then
    baseDamage = 50
elseif tower.Name == "WATER NOOB" then
    baseDamage = 50
elseif tower.Name == "SUMO NOOB" then
    baseDamage = 100
end
local currentDamage = baseDamage
local range = 18 -- REDUCED RANGE (Previously 25)
local attackSpeed = 0.8 

-- Special states
local comboStep = 1 -- For Fire Noob

-- Update damage when level or buffs change
local function recalculateDamage()
    local level = tower:GetAttribute("Level") or 1
    local multiplier = tower:GetAttribute("DamageMultiplier") or 1
    local bonus = tower:GetAttribute("BonusDamage") or 0
    currentDamage = (baseDamage + (level - 1) * 5 + bonus) * multiplier
    print("STATS UPDATED: " .. tower.Name .. " (Damage: " .. currentDamage .. ")")
end

tower:GetAttributeChangedSignal("Level"):Connect(recalculateDamage)
tower:GetAttributeChangedSignal("DamageMultiplier"):Connect(recalculateDamage)
tower:GetAttributeChangedSignal("BonusDamage"):Connect(recalculateDamage)

-- Initial damage set
recalculateDamage()
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
    
    local towerName = tower.Name
    local waitTime = attackSpeed / gameSpeed.Value
    
    if towerName == "ALL OUT NOOB" then
        -- AoE ATTACK (Doesn't necessarily need a single target to start)
        local attackDamage = 15
        local workspaceEnemies = workspace:FindFirstChild("Enemies") or workspace
        local targetsInRange = {}
        
        for _, enemy in ipairs(workspaceEnemies:GetChildren()) do
            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
            local enemyHumanoid = enemy:FindFirstChild("Humanoid")
            if enemyRoot and enemyHumanoid and enemyHumanoid.Health > 0 then
                if (enemyRoot.Position - torso.Position).Magnitude <= range then
                    table.insert(targetsInRange, {root = enemyRoot, hum = enemyHumanoid})
                end
            end
        end

        if #targetsInRange > 0 then
            -- Animate
            local originalArmCFrame = rightArm.CFrame
            rightArm.CFrame = rightArm.CFrame * CFrame.new(0, 0, -2)
            
            for _, targetData in ipairs(targetsInRange) do
                targetData.hum:TakeDamage(currentDamage)
                createHitEffect(targetData.root.Position)
            end
            print("ALL OUT NOOB hit " .. #targetsInRange .. " targets!")
            
            task.wait(0.2 / gameSpeed.Value)
            rightArm.CFrame = originalArmCFrame
        end
        waitTime = 1.0 / gameSpeed.Value
    elseif towerName == "SUPPORTER NOOB" then
        -- SUPPORTER NOOB (Damage Buff)
        local towersFolder = workspace:FindFirstChild("Towers")
        if towersFolder then
            for _, otherTower in ipairs(towersFolder:GetChildren()) do
                if otherTower ~= tower then
                    local otherTorso = otherTower:FindFirstChild("Torso")
                    if otherTorso then
                        local dist = (torso.Position - otherTorso.Position).Magnitude
                        if dist <= range then
                            otherTower:SetAttribute("BonusDamage", 10)
                            -- Visual feedback could go here
                        else
                            -- Clear if moved out of range (though towers usually don't move)
                            if otherTower:GetAttribute("BonusDamage") == 10 then
                                -- We don't want to clear if ANOTHER supporter is there, 
                                -- but for simplicity in this project, we'll just let it stay for a pulse
                            end
                        end
                    end
                end
            end
        end
        -- Pulsing effect
        local pulse = Instance.new("Part")
        pulse.Shape = Enum.PartType.Cylinder
        pulse.Size = Vector3.new(0.5, range*2, range*2)
        pulse.CFrame = torso.CFrame * CFrame.new(0, -3, 0) * CFrame.Angles(0,0,math.rad(90))
        pulse.Transparency = 0.7
        pulse.Color = Color3.fromRGB(255, 255, 0)
        pulse.Material = Enum.Material.Neon
        pulse.Anchored = true
        pulse.CanCollide = false
        pulse.Parent = workspace
        task.delay(0.2, function() pulse:Destroy() end)
        
        waitTime = 2.0 / gameSpeed.Value
    elseif towerName == "FIRE NOOB" then
        if comboStep == 1 then
            -- AoE Step
            local workspaceEnemies = workspace:FindFirstChild("Enemies") or workspace
            local targets = {}
            for _, enemy in ipairs(workspaceEnemies:GetChildren()) do
                local root = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Torso")
                local hum = enemy:FindFirstChild("Humanoid")
                if root and hum and hum.Health > 0 and (root.Position - torso.Position).Magnitude <= range then
                    table.insert(targets, {root = root, hum = hum})
                end
            end
            if #targets > 0 then
                rightArm.CFrame = rightArm.CFrame * CFrame.new(0, 0, -2)
                for _, t in ipairs(targets) do
                    t.hum:TakeDamage(currentDamage)
                    createHitEffect(t.root.Position)
                end
                task.wait(0.15 / gameSpeed.Value)
                rightArm.CFrame = rightArmDefaultCFrame
                comboStep = 2
            end
        else
            -- Single Target Step
            local target = findClosestEnemy()
            if target then
                local root = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
                local hum = target:FindFirstChild("Humanoid")
                if root and hum then
                    tower:PivotTo(CFrame.lookAt(torso.Position, Vector3.new(root.Position.X, torso.Position.Y, root.Position.Z)))
                    rightArm.CFrame = rightArm.CFrame * CFrame.new(0, 0, -2)
                    hum:TakeDamage(currentDamage)
                    createHitEffect(root.Position)
                    task.wait(0.15 / gameSpeed.Value)
                    rightArm.CFrame = rightArmDefaultCFrame
                    comboStep = 1
                end
            end
        end
        waitTime = attackSpeed / gameSpeed.Value
    elseif towerName == "WATER NOOB" then
        -- AoE + Stun
        local workspaceEnemies = workspace:FindFirstChild("Enemies") or workspace
        local targets = {}
        for _, enemy in ipairs(workspaceEnemies:GetChildren()) do
            local root = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Torso")
            local hum = enemy:FindFirstChild("Humanoid")
            if root and hum and hum.Health > 0 and (root.Position - torso.Position).Magnitude <= range then
                table.insert(targets, {enemy = enemy, root = root, hum = hum})
            end
        end
        if #targets > 0 then
            rightArm.CFrame = rightArm.CFrame * CFrame.new(0, 0, -2)
            for _, t in ipairs(targets) do
                t.hum:TakeDamage(currentDamage)
                createHitEffect(t.root.Position)
                
                -- Create Water Puddle
                local puddle = Instance.new("Part")
                puddle.Size = Vector3.new(6, 0.2, 6)
                puddle.Position = t.root.Position - Vector3.new(0, 3, 0)
                puddle.Color = Color3.fromRGB(0, 170, 255)
                puddle.Transparency = 0.5
                puddle.Material = Enum.Material.Plastic
                puddle.Anchored = true
                puddle.CanCollide = false
                puddle.Parent = workspace
                
                -- Stun logic on puddle
                puddle.Touched:Connect(function(hit)
                    local char = hit.Parent
                    if char:FindFirstChild("Humanoid") and not game.Players:GetPlayerFromCharacter(char) then
                        char:SetAttribute("Stunned", true)
                        task.delay(2, function() char:SetAttribute("Stunned", false) end)
                    end
                end)
                
                task.delay(5, function() puddle:Destroy() end)
            end
            task.wait(0.15 / gameSpeed.Value)
            rightArm.CFrame = rightArmDefaultCFrame
        end
        waitTime = 1.2 / gameSpeed.Value
    elseif towerName == "SUMO NOOB" then
        local target = findClosestEnemy()
        if target then
            local root = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
            local hum = target:FindFirstChild("Humanoid")
            if root and hum then
                tower:PivotTo(CFrame.lookAt(torso.Position, Vector3.new(root.Position.X, torso.Position.Y, root.Position.Z)))
                rightArm.CFrame = rightArm.CFrame * CFrame.new(0, 0, -2)
                hum:TakeDamage(currentDamage)
                createHitEffect(root.Position)
                task.wait(0.2 / gameSpeed.Value)
                rightArm.CFrame = rightArmDefaultCFrame
            end
        end
        waitTime = 2.0 / gameSpeed.Value
    elseif towerName == "TRIPLE PUNCH NOOB" then
        -- TRIPLE PUNCH ATTACK (Hits up to 3 enemies)
        local workspaceEnemies = workspace:FindFirstChild("Enemies") or workspace
        local targetsInRange = {}
        
        for _, enemy in ipairs(workspaceEnemies:GetChildren()) do
            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Torso")
            local enemyHumanoid = enemy:FindFirstChild("Humanoid")
            if enemyRoot and enemyHumanoid and enemyHumanoid.Health > 0 then
                if (enemyRoot.Position - torso.Position).Magnitude <= range then
                    table.insert(targetsInRange, {root = enemyRoot, hum = enemyHumanoid, dist = (enemyRoot.Position - torso.Position).Magnitude})
                end
            end
        end

        if #targetsInRange > 0 then
            -- Sort by distance to hit the closest 3
            table.sort(targetsInRange, function(a, b) return a.dist < b.dist end)
            
            -- Keep only the first 3
            local numToHit = math.min(#targetsInRange, 3)
            
            -- Face the first target
            local firstTarget = targetsInRange[1]
            local lookAtTarget = CFrame.lookAt(torso.Position, Vector3.new(firstTarget.root.Position.X, torso.Position.Y, firstTarget.root.Position.Z))
            tower:PivotTo(lookAtTarget)

            -- Animate
            local originalArmCFrame = rightArm.CFrame
            rightArm.CFrame = rightArm.CFrame * CFrame.new(0, 0, -2)
            
            for i = 1, numToHit do
                local targetData = targetsInRange[i]
                targetData.hum:TakeDamage(currentDamage)
                createHitEffect(targetData.root.Position)
            end
            print("TRIPLE PUNCH NOOB hit " .. numToHit .. " targets!")
            
            task.wait(0.15 / gameSpeed.Value)
            rightArm.CFrame = originalArmCFrame
        end
    else
        -- SINGLE TARGET ATTACK
        local target = findClosestEnemy()
        if target then
            local targetRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso") or target:FindFirstChild("UpperTorso")
            local humanoid = target:FindFirstChild("Humanoid")
            
            if targetRoot and humanoid then
                -- Face target
                local lookAtTarget = CFrame.lookAt(torso.Position, Vector3.new(targetRoot.Position.X, torso.Position.Y, targetRoot.Position.Z))
                tower:PivotTo(lookAtTarget)
                
                -- Animate
                local originalArmCFrame = rightArm.CFrame
                rightArm.CFrame = rightArm.CFrame * CFrame.new(0, 0, -2)
                
                humanoid:TakeDamage(currentDamage)
                createHitEffect(targetRoot.Position)
                print("NOOB PUNCH: " .. target.Name)
                
                task.wait(0.15 / gameSpeed.Value)
                rightArm.CFrame = originalArmCFrame
            end
        end
    end
    
    task.wait(waitTime)
end
