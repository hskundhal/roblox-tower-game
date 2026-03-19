-- AttackRoutine (Triple Punch Noob)
-- Place this inside TRIPLE PUNCH NOOB
local tower = script.Parent
local torso = tower:WaitForChild("Torso")
local rightArm = tower:WaitForChild("Right Arm")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local gameSpeed = ReplicatedStorage:WaitForChild("GameSpeed")

-- Stats
local baseDamage = 30 
local range = 18
local attackSpeed = 0.8 
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

local function findClosestEnemies()
    local targets = {}
    local enemies = workspace:FindFirstChild("Enemies") or workspace
    for _, enemy in ipairs(enemies:GetChildren()) do
        local root = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Torso")
        local hum = enemy:FindFirstChild("Humanoid")
        if root and hum and hum.Health > 0 then
            local dist = (root.Position - torso.Position).Magnitude
            if dist <= range then
                table.insert(targets, {root = root, hum = hum, dist = dist})
            end
        end
    end
    table.sort(targets, function(a, b) return a.dist < b.dist end)
    return targets
end

local function createHitEffect(pos)
    local p = Instance.new("Part")
    p.Size = Vector3.new(2,2,2)
    p.Transparency = 0.4
    p.Color = Color3.fromRGB(200, 0, 255)
    p.Material = Enum.Material.Neon
    p.Anchored = true
    p.CanCollide = false
    p.Position = pos
    p.Parent = workspace
    task.delay(0.1, function() p:Destroy() end)
end

local rightArmDefaultCFrame = rightArm.CFrame

while true do
    local targets = findClosestEnemies()
    if #targets > 0 then
        local numToHit = math.min(#targets, 3)
        local firstTarget = targets[1]
        tower:PivotTo(CFrame.lookAt(torso.Position, Vector3.new(firstTarget.root.Position.X, torso.Position.Y, firstTarget.root.Position.Z)))
        
        rightArm.CFrame = rightArm.CFrame * CFrame.new(0, 0, -2)
        for i = 1, numToHit do
            local t = targets[i]
            t.hum:TakeDamage(currentDamage)
            createHitEffect(t.root.Position)
        end
        task.wait(0.15 / gameSpeed.Value)
        rightArm.CFrame = rightArmDefaultCFrame
    end
    task.wait(attackSpeed / gameSpeed.Value)
end
