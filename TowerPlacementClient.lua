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
local rangePreview = nil
local TOWER_RANGE = 25 -- Match the range in our Punch script!

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
    
    -- Create the range ring preview
    rangePreview = Instance.new("Part")
    rangePreview.Shape = Enum.PartType.Cylinder
    rangePreview.Size = Vector3.new(0.2, TOWER_RANGE * 2, TOWER_RANGE * 2)
    rangePreview.Transparency = 0.7
    rangePreview.Color = Color3.fromRGB(0, 170, 255)
    rangePreview.Material = Enum.Material.Neon
    rangePreview.Anchored = true
    rangePreview.CanCollide = false
    rangePreview.Parent = workspace
end

createPreview()

-- 2. Update the Previews to follow the mouse
RunService.RenderStepped:Connect(function()
    if previewModel and rangePreview then
        local ray = workspace.CurrentCamera:ScreenPointToRay(mouse.X, mouse.Y)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {player.Character, previewModel, rangePreview, workspace:FindFirstChild("Towers")}
        
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
        
        if result then
            local hitPos = result.Position
            -- Adjust height so it sits on top of whatever we hit
            local adjustedPos = hitPos + Vector3.new(0, previewModel.PrimaryPart.Size.Y / 2, 0)
            
            previewModel:PivotTo(CFrame.new(adjustedPos))
            rangePreview.CFrame = CFrame.new(hitPos) * CFrame.Angles(0, 0, math.rad(90))
            
            previewModel.Parent = workspace
            rangePreview.Transparency = 0.7
        else
            -- Hide if pointing at sky
            rangePreview.Transparency = 1
            previewModel.Parent = nil
        end
    end
end)

-- 3. Actually place the tower on click
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if previewModel and previewModel.Parent == workspace then
            -- Use the actual hit position from the preview model
            local finalPos = previewModel.PrimaryPart.Position - Vector3.new(0, previewModel.PrimaryPart.Size.Y / 2, 0)
            placementEvent:FireServer(selectedTowerName, finalPos)
        end
    end
end)
