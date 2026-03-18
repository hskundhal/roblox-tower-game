-- AttackRoutine (Fast Noob)
-- Place this inside FastNoob
local tower = script.Parent
local torso = tower:WaitForChild("Torso")
local rightArm = tower:WaitForChild("Right Arm")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local gameSpeed = ReplicatedStorage:WaitForChild("GameSpeed")

-- Stats (Faster but less damage)
local baseDamage = 15 
local range = 18
local attackSpeed = 0.4 
local currentDamage = baseDamage

-- Update damage for upgrades
tower:GetAttributeChangedSignal("Level"):Connect(function()
    local level = tower:GetAttribute("Level") or 1
    local multiplier = tower:GetAttribute("DamageMultiplier") or 1
    currentDamage = (baseDamage + (level - 1) * 3) * multiplier
end)

local function findClosestEnemy()
    local closestEnemy = nil
    local shortestDistance = range
    local enemies = workspace:FindFirstChild("Enemies") or workspace
    for _, obj in ipairs(enemies:GetChildren()) do
        local humanoid = obj:FindFirstChild("Humanoid")
        local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
        if humanoid and humanoid.Health > 0 and root then
            local dist = (torso.Position - root.Position).Magnitude
            if dist < shortestDistance then
                shortestDistance = dist
                closestEnemy = obj
            end
        end
    end
    return closestEnemy
end

local function createHitEffect(pos)
    local p = Instance.new("Part")
    p.Size = Vector3.new(1,1,1)
    p.Transparency = 0.5
    p.Color = Color3.new(1,1,1)
    p.Anchored = true
    p.CanCollide = false
    p.Position = pos
    p.Parent = workspace
    task.delay(0.1, function() p:Destroy() end)
end

while true do
    local target = findClosestEnemy()
    if target then
        local targetRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
        local humanoid = target:FindFirstChild("Humanoid")
        if targetRoot and humanoid then
            tower:PivotTo(CFrame.lookAt(torso.Position, Vector3.new(targetRoot.Position.X, torso.Position.Y, targetRoot.Position.Z)))
            local oldCFrame = rightArm.CFrame
            rightArm.CFrame = rightArm.CFrame * CFrame.new(0, 0, -2)
            humanoid:TakeDamage(currentDamage)
            createHitEffect(targetRoot.Position)
            task.wait(0.1 / gameSpeed.Value)
            rightArm.CFrame = oldCFrame
        end
    end
    task.wait(attackSpeed / gameSpeed.Value)
end
