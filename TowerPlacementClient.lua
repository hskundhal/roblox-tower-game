-- TowerPlacementClient.lua
-- Place this inside StarterPlayer -> StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local placementEvent = ReplicatedStorage:WaitForChild("PlaceTowerEvent")

-- Tower to place
local selectedTowerName = "BasicTower"
local towerFolder = ReplicatedStorage:WaitForChild("Towers")
local towerModel = towerFolder:WaitForChild(selectedTowerName)

-- 1. Create the Previews (Ghost & Range Ring)
local previewModel = nil
local TOWER_RANGE = 35 -- MATCH the range in your new Punch script!

local function createPreview()
    -- Create the ghost model
    previewModel = towerModel:Clone()
    for _, part in ipairs(previewModel:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = 0.5
            part.CanCollide = false
            part.Color = Color3.fromRGB(0, 255, 0) -- Green ghost
        end
    end
    previewModel.Parent = workspace
    
    previewModel.Parent = workspace
end

createPreview()

-- 2. Update the Previews to follow the mouse
RunService.RenderStepped:Connect(function()
    if previewModel then
        local ray = workspace.CurrentCamera:ScreenPointToRay(mouse.X, mouse.Y)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {player.Character, previewModel, workspace:FindFirstChild("Towers")}
        
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
        
        if result then
            local hitPos = result.Position
            -- For a TALL POLE, we position the base on the ground
            -- We pivot the whole model so its center sits above the ground by half the Pillar's height
            local pillar = previewModel.PrimaryPart
            local adjustedPos = hitPos + Vector3.new(0, pillar.Size.Y / 2, 0)
            
            previewModel:PivotTo(CFrame.new(adjustedPos) * CFrame.Angles(0, 0, math.rad(90)))
            
            previewModel.Parent = workspace
        else
            previewModel.Parent = nil
        end
    end
end)

-- 3. Actually place the tower on click
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if previewModel and previewModel.Parent == workspace then
            -- Tell server the GROUND position
            local pillar = previewModel.PrimaryPart
            local finalPos = previewModel.PrimaryPart.Position - Vector3.new(0, pillar.Size.Y / 2, 0)
            placementEvent:FireServer(selectedTowerName, finalPos)
        end
    end
end)
