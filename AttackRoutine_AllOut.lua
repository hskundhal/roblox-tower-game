-- AttackRoutine (ALL OUT NOOB)
-- Place this inside ALL OUT NOOB
local tower = script.Parent
local torso = tower:WaitForChild("Torso")
local rightArm = tower:WaitForChild("Right Arm")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local gameSpeed = ReplicatedStorage:WaitForChild("GameSpeed")

-- Stats (AoE Specialist)
local damagePerTick = 15
local range = 18
local attackSpeed = 1.0 

local function createHitEffect(pos)
    local p = Instance.new("Part")
    p.Size = Vector3.new(2,2,2)
    p.Transparency = 0.5
    p.Color = Color3.new(1,0,0) -- RED for AoE
    p.Anchored = true
    p.CanCollide = false
    p.Position = pos
    p.Parent = workspace
    task.delay(0.1, function() p:Destroy() end)
end

while true do
    local workspaceEnemies = workspace:FindFirstChild("Enemies") or workspace
    local targetsInRange = {}
    
    for _, enemy in ipairs(workspaceEnemies:GetChildren()) do
        local root = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Torso")
        local hum = enemy:FindFirstChild("Humanoid")
        if root and hum and hum.Health > 0 then
            if (root.Position - torso.Position).Magnitude <= range then
                table.insert(targetsInRange, {root = root, hum = hum})
            end
        end
    end

    if #targetsInRange > 0 then
        local oldCFrame = rightArm.CFrame
        rightArm.CFrame = rightArm.CFrame * CFrame.new(0, 0, -2)
        
        for _, data in ipairs(targetsInRange) do
            data.hum:TakeDamage(damagePerTick)
            createHitEffect(data.root.Position)
        end
        print("AOE: ALL OUT hit " .. #targetsInRange .. " targets!")
        
        task.wait(0.2 / gameSpeed.Value)
        rightArm.CFrame = oldCFrame
    end
    
    task.wait(attackSpeed / gameSpeed.Value)
end
