-- AttackRoutine (Sumo Noob)
-- Place this inside SUMO NOOB
local tower = script.Parent
local torso = tower:WaitForChild("Torso")
local rightArm = tower:WaitForChild("Right Arm")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local gameSpeed = ReplicatedStorage:WaitForChild("GameSpeed")

-- Stats
local baseDamage = 100 
local range = 18
local attackSpeed = 2.0 
local currentDamage = baseDamage

-- Update damage for buffs/upgrades
local function recalculateDamage()
    local level = tower:GetAttribute("Level") or 1
    local multiplier = tower:GetAttribute("DamageMultiplier") or 1
    local bonus = tower:GetAttribute("BonusDamage") or 0
    currentDamage = (baseDamage + (level - 1) * 5 + bonus) * multiplier
end
tower:GetAttributeChangedSignal("Level"):Connect(recalculateDamage)
tower:GetAttributeChangedSignal("DamageMultiplier"):Connect(recalculateDamage)
tower:GetAttributeChangedSignal("BonusDamage"):Connect(recalculateDamage)
recalculateDamage()

local function findClosestEnemy()
    local closestEnemy = nil
    local shortestDistance = range
    local enemies = workspace:FindFirstChild("Enemies") or workspace
    for _, obj in ipairs(enemies:GetChildren()) do
        local hum = obj:FindFirstChild("Humanoid")
        local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
        if hum and hum.Health > 0 and root then
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
    p.Size = Vector3.new(3,3,3) -- Large impact
    p.Transparency = 0.4
    p.Color = Color3.fromRGB(150, 75, 0) -- Sumo Brown
    p.Material = Enum.Material.Neon
    p.Anchored = true
    p.CanCollide = false
    p.Position = pos
    p.Parent = workspace
    task.delay(0.1, function() p:Destroy() end)
end

local rightArmDefaultCFrame = rightArm.CFrame

while true do
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
    task.wait(attackSpeed / gameSpeed.Value)
end
