-- AttackRoutine (Fire Noob)
-- Place this inside FIRE NOOB
local tower = script.Parent
local torso = tower:WaitForChild("Torso")
local rightArm = tower:WaitForChild("Right Arm")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local gameSpeed = ReplicatedStorage:WaitForChild("GameSpeed")

-- Stats
local baseDamage = 50 
local range = 18
local attackSpeed = 0.8 
local currentDamage = baseDamage
local comboStep = 1

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
    p.Size = Vector3.new(2,2,2)
    p.Transparency = 0.4
    p.Color = Color3.fromRGB(255, 85, 0) -- Fire Orange
    p.Material = Enum.Material.Neon
    p.Anchored = true
    p.CanCollide = false
    p.Position = pos
    p.Parent = workspace
    task.delay(0.1, function() p:Destroy() end)
end

local rightArmDefaultCFrame = rightArm.CFrame

while true do
    if comboStep == 1 then
        -- AoE Step
        local enemies = workspace:FindFirstChild("Enemies") or workspace
        local targets = {}
        for _, enemy in ipairs(enemies:GetChildren()) do
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
    task.wait(attackSpeed / gameSpeed.Value)
end
