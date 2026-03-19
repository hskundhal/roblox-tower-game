-- AttackRoutine (Supporter Noob)
-- Place this inside SUPPORTER NOOB
local tower = script.Parent
local torso = tower:WaitForChild("Torso")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local gameSpeed = ReplicatedStorage:WaitForChild("GameSpeed")

-- Stats
local range = 18 
local attackSpeed = 2.0 

while true do
    local towersFolder = workspace:FindFirstChild("Towers")
    if towersFolder then
        for _, otherTower in ipairs(towersFolder:GetChildren()) do
            if otherTower ~= tower then
                local otherTorso = otherTower:FindFirstChild("Torso")
                if otherTorso then
                    local dist = (torso.Position - otherTorso.Position).Magnitude
                    if dist <= range then
                        otherTower:SetAttribute("BonusDamage", 10)
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
    
    task.wait(attackSpeed / gameSpeed.Value)
end
