pcall(function()
    if hookmetamethod then
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", function(t, k)
            if not checkcaller() and k == "Size" and typeof(t) == "Instance" then
                if t.Name == "HumanoidRootPart" then
                    return Vector3.new(2, 2, 1)
                end
            end
            return oldIndex(t, k)
        end)
    end
end)

local TARGET_PART = "HumanoidRootPart" 
local CONFIG_HITBOX_SIZE = 4           
local CONFIG_HITBOX_TRANSPARENCY = 0.7 

local AIMBOT_KEY = Enum.UserInputType.MouseButton2 
local AIMBOT_SMOOTHNESS = 0.25                     
local AIMBOT_FOV_RADIUS = 150                      
local TARGET_USER_ID = 1

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local HighlightEnabled = false
local HitboxEnabled = false
local TeamCheckEnabled = false
local AimbotEnabled = false
local AimbotHolding = false

local CharacterConnections = {}
local PlayerAddedConnection
local HitboxConnection

local OrionLib = loadstring(game:HttpGet("https://sandbox.orioncloud.tech/api/source", true))()
local Window = OrionLib:MakeWindow({Name = "Akbar Hub", HidePremium = true, SaveConfig = false, IntroText = "Loading Akbar Hub..."})

local FovCircle = Drawing.new("Circle")
FovCircle.Visible = false
FovCircle.Thickness = 1
FovCircle.NumSides = 60
FovCircle.Radius = AIMBOT_FOV_RADIUS
FovCircle.Color = Color3.fromRGB(255, 255, 255)
FovCircle.Filled = false

local function createHighlight(character)
    if character:FindFirstChild("AdminHighlight") then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "AdminHighlight"
    highlight.FillTransparency = 1                
    highlight.OutlineColor = Color3.fromRGB(160, 32, 240) 
    highlight.OutlineTransparency = 0             
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
end

local function watchPlayer(player)
    if player == LocalPlayer then return end
    if player.Character then createHighlight(player.Character) end
    CharacterConnections[player] = player.CharacterAdded:Connect(function(character)
        if HighlightEnabled then createHighlight(character) end
    end)
end

local function setHighlights(enabled)
    HighlightEnabled = enabled
    if enabled then
        for _, player in ipairs(Players:GetPlayers()) do watchPlayer(player) end
        if not PlayerAddedConnection then PlayerAddedConnection = Players.PlayerAdded:Connect(watchPlayer) end
    else
        if PlayerAddedConnection then PlayerAddedConnection:Disconnect() PlayerAddedConnection = nil end
        for _, connection in pairs(CharacterConnections) do connection:Disconnect() end
        table.clear(CharacterConnections)
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("AdminHighlight") then
                player.Character.AdminHighlight:Destroy()
            end
        end
    end
end

local function resetHitbox(player)
    pcall(function()
        if player.Character and player.Character:FindFirstChild(TARGET_PART) then
            local part = player.Character[TARGET_PART]
            part.Size = Vector3.new(2, 2, 1) 
            part.Transparency = 1           
            part.CanCollide = false
        end
    end)
end

local function updateHitboxes()
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LocalPlayer then
            pcall(function()
                if v.Character and v.Character:FindFirstChild(TARGET_PART) then
                    local part = v.Character[TARGET_PART]
                    if HitboxEnabled then
                        local isEnemy = true
                        if TeamCheckEnabled and LocalPlayer.Team ~= nil and v.Team == LocalPlayer.Team then
                            isEnemy = false
                        end
                        if isEnemy then
                            part.Size = Vector3.new(CONFIG_HITBOX_SIZE, CONFIG_HITBOX_SIZE, CONFIG_HITBOX_SIZE)
                            part.Transparency = CONFIG_HITBOX_TRANSPARENCY
                            part.BrickColor = BrickColor.new("Really black")
                            part.Material = Enum.Material.Neon
                            part.CanCollide = false
                        else
                            if part.Size.X ~= 2 then resetHitbox(v) end
                        end
                    else
                        if part.Size.X ~= 2 then resetHitbox(v) end
                    end
                end
            end)
        end
    end
end

local function getClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 and player.Character:FindFirstChild(TARGET_PART) then
            if TeamCheckEnabled and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then continue end
            
            local pos, onScreen = Camera:WorldToViewportPoint(player.Character[TARGET_PART].Position)
            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                local distance = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if distance < shortestDistance and distance < AIMBOT_FOV_RADIUS then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end
    return closestPlayer
end

local function handleAimbot()
    FovCircle.Position = UserInputService:GetMouseLocation()
    if AimbotEnabled and AimbotHolding then
        local targetPlayer = getClosestPlayerToCursor()
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild(TARGET_PART) then
            pcall(function()
                local targetPos = targetPlayer.Character[TARGET_PART].Position
                local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, AIMBOT_SMOOTHNESS)
            end)
        end
    end
end

local function spoofAvatar()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    pcall(function()
        local desc = Players:GetHumanoidDescriptionFromUserId(TARGET_USER_ID)
        if desc then
            hum:ApplyDescription(desc)
            OrionLib:MakeNotification({Name = "Wardrobe", Content = "Avatar successfully changed!", Time = 3})
        end
    end)
end

HitboxConnection = RunService.RenderStepped:Connect(function()
    updateHitboxes()
    handleAimbot()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == AIMBOT_KEY then AimbotHolding = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == AIMBOT_KEY then AimbotHolding = false end
end)

local CombatTab = Window:MakeTab({Name = "Combat", Icon = "rbxassetid://4483345998", PremiumOnly = false})

CombatTab:AddToggle({
    Name = "Enable Aimbot",
    Default = false,
    Callback = function(Value)
        AimbotEnabled = Value
        FovCircle.Visible = Value
    end    
})

CombatTab:AddToggle({
    Name = "Hitbox Expander",
    Default = false,
    Callback = function(Value)
        HitboxEnabled = Value
    end    
})

CombatTab:AddToggle({
    Name = "Team Check",
    Default = false,
    Callback = function(Value)
        TeamCheckEnabled = Value
    end    
})

local VisualsTab = Window:MakeTab({Name = "Visuals", Icon = "rbxassetid://4483345998", PremiumOnly = false})

VisualsTab:AddToggle({
    Name = "Purple Highlight (ESP)",
    Default = false,
    Callback = function(Value)
        setHighlights(Value)
    end    
})

local WardrobeTab = Window:MakeTab({Name = "Wardrobe", Icon = "rbxassetid://4483345998", PremiumOnly = false})

WardrobeTab:AddTextbox({
    Name = "Target UserID",
    Default = "1",
    TextDisappear = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then TARGET_USER_ID = num end
    end
})

WardrobeTab:AddButton({
    Name = "Apply Avatar (Local)",
    Callback = function()
        spoofAvatar()
    end
})

OrionLib:Init()