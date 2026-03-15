-- TowerPlacementClient.lua
-- Place this inside StarterPlayer -> StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local placementEvent = ReplicatedStorage:WaitForChild("PlaceTowerEvent")
local selectEvent = ReplicatedStorage:WaitForChild("SelectTowerEvent")

-- Tower State
local selectedTowerName = nil
local towerFolder = ReplicatedStorage:WaitForChild("Towers")
local previewModel = nil
local rangePreview = nil
local TOWER_RANGE = 25 -- Default range

-- 1. Function to clear current preview
local function clearPreview()
    if previewModel then previewModel:Destroy() end
    if rangePreview then rangePreview:Destroy() end
    previewModel = nil
    rangePreview = nil
    selectedTowerName = nil
end

-- 2. Function to create the Previews (Ghost & Range Ring)
local function createPreview(towerName)
    clearPreview() -- Clear any existing one
    
    selectedTowerName = towerName
    local towerModel = towerFolder:FindFirstChild(towerName)
    if not towerModel then return end
    
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
    
    -- Create the range ring preview (RESTORED functionality)
    rangePreview = Instance.new("Part")
    rangePreview.Name = "RangePreview"
    rangePreview.Shape = Enum.PartType.Cylinder
    rangePreview.Size = Vector3.new(0.2, TOWER_RANGE * 2, TOWER_RANGE * 2)
    rangePreview.Transparency = 0.7
    rangePreview.Color = Color3.fromRGB(0, 170, 255)
    rangePreview.Material = Enum.Material.Neon
    rangePreview.Anchored = true
    rangePreview.CanCollide = false
    rangePreview.Parent = workspace
end

-- 3. Listen for UI Selection
selectEvent.Event:Connect(function(towerName)
    if selectedTowerName == towerName then
        clearPreview() -- Toggle off if clicked again
    else
        createPreview(towerName)
    end
end)

-- 4. Cancel on ESC
UserInputService.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.Escape then
        clearPreview()
    end
end)

-- 5. Update the Previews to follow the mouse
RunService.RenderStepped:Connect(function()
    if previewModel and rangePreview then
        local ray = workspace.CurrentCamera:ScreenPointToRay(mouse.X, mouse.Y)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {player.Character, previewModel, rangePreview, workspace:FindFirstChild("Towers")}
        
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
        
        if result then
            local hitPos = result.Position
            -- For a NOOB character, the Torso (PrimaryPart) is 3 studs above ground
            local adjustedPos = hitPos + Vector3.new(0, 3, 0)
            
            previewModel:PivotTo(CFrame.new(adjustedPos))
            rangePreview.CFrame = CFrame.new(hitPos) * CFrame.Angles(0, 0, math.rad(90))
            
            previewModel.Parent = workspace
            rangePreview.Transparency = 0.7
        else
            rangePreview.Transparency = 1
            previewModel.Parent = nil
        end
    end
end)

-- 6. Actually place the tower on click
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if previewModel and previewModel.Parent == workspace and selectedTowerName then
            -- Tell server the GROUND position
            local finalPos = previewModel.PrimaryPart.Position - Vector3.new(0, 3, 0)
            placementEvent:FireServer(selectedTowerName, finalPos)
            
            -- Keep the ghost active for multi-placement? 
            -- We'll clear it for now to follow standard TD patterns
            clearPreview()
        end
    end
end)
