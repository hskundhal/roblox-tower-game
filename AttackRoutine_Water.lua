-- AttackRoutine (Water Noob)
-- Place this inside WATER NOOB
local tower = script.Parent
local torso = tower:WaitForChild("Torso")
local rightArm = tower:WaitForChild("Right Arm")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local gameSpeed = ReplicatedStorage:WaitForChild("GameSpeed")

-- Stats
local baseDamage = 50 
local range = 18
local attackSpeed = 1.2 
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

local function createHitEffect(pos)
    local p = Instance.new("Part")
    p.Size = Vector3.new(2,2,2)
    p.Transparency = 0.4
    p.Color = Color3.fromRGB(0, 170, 255) -- Water Blue
    p.Material = Enum.Material.Neon
    p.Anchored = true
    p.CanCollide = false
    p.Position = pos
    p.Parent = workspace
    task.delay(0.1, function() p:Destroy() end)
end

local rightArmDefaultCFrame = rightArm.CFrame

while true do
    local enemies = workspace:FindFirstChild("Enemies") or workspace
    local targets = {}
    for _, enemy in ipairs(enemies:GetChildren()) do
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
    task.wait(attackSpeed / gameSpeed.Value)
end
