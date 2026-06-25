-- MM2 Coin Farmer - CLIP MODE EDITION (you asked for it)
local SPEED = 25  -- adjust as needed, but higher = more kicks
local CLIP_ENABLED = false  -- default off; toggle via GUI

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Root = Character:WaitForChild("HumanoidRootPart")

-- Refresh on respawn
local function RefreshCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    Humanoid = Character:WaitForChild("Humanoid")
    Root = Character:WaitForChild("HumanoidRootPart")
end
LocalPlayer.CharacterAdded:Connect(RefreshCharacter)

-- ===== GUI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoinFarmerGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") or game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 190)  -- taller for clip toggle
frame.Position = UDim2.new(0.8, -240, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "COIN FARMER (F TOGGLE)"
title.TextColor3 = Color3.fromRGB(255, 200, 100)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.8, 0, 0, 35)
toggleBtn.Position = UDim2.new(0.1, 0, 0.25, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
toggleBtn.Text = "START FARMING"
toggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = frame

-- Clip toggle (checkbox style)
local clipBtn = Instance.new("TextButton")
clipBtn.Size = UDim2.new(0.4, 0, 0, 25)
clipBtn.Position = UDim2.new(0.1, 0, 0.55, 0)
clipBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
clipBtn.Text = "CLIP OFF"
clipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clipBtn.TextScaled = true
clipBtn.Font = Enum.Font.Gotham
clipBtn.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(0.8, 0, 0, 20)
status.Position = UDim2.new(0.1, 0, 0.7, 0)
status.BackgroundTransparency = 1
status.Text = "Status: IDLE"
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.TextScaled = true
status.Font = Enum.Font.Gotham
status.Parent = frame

local coinCounter = Instance.new("TextLabel")
coinCounter.Size = UDim2.new(0.8, 0, 0, 20)
coinCounter.Position = UDim2.new(0.1, 0, 0.82, 0)
coinCounter.BackgroundTransparency = 1
coinCounter.Text = "Coins: 0"
coinCounter.TextColor3 = Color3.fromRGB(100, 255, 100)
coinCounter.TextScaled = true
coinCounter.Font = Enum.Font.Gotham
coinCounter.Parent = frame

-- ===== CORE LOGIC =====
local isFarming = false
local isClipping = false
local farmThread = nil
local currentCoins = 0

-- Store original collision states to restore
local originalCollisions = {}

-- Function to toggle clipping on/off
local function SetClip(enable)
    isClipping = enable
    clipBtn.Text = enable and "CLIP ON" or "CLIP OFF"
    clipBtn.BackgroundColor3 = enable and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(60, 60, 60)
    -- Set CanCollide on all character parts
    if Character then
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                if enable then
                    -- Store original only once
                    if originalCollisions[part] == nil then
                        originalCollisions[part] = part.CanCollide
                    end
                    part.CanCollide = false
                else
                    -- Restore original if stored
                    if originalCollisions[part] ~= nil then
                        part.CanCollide = originalCollisions[part]
                    end
                end
            end
        end
    end
end

-- On character respawn, reapply clip state if enabled
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    Root = newChar:WaitForChild("HumanoidRootPart")
    originalCollisions = {}
    if isClipping then
        SetClip(true)
    end
end)

-- Coin detection (same aggressive)
local function GetCoins()
    local coins = {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v:FindFirstChild("TouchInterest") then
            local name = v.Name:lower()
            if name:find("coin") or name:find("money") or name:find("collect") or
               (v.Parent and v.Parent.Name:lower():find("coin")) then
                table.insert(coins, v)
            elseif v:FindFirstChild("CoinTag") or v:FindFirstChild("Collectible") then
                table.insert(coins, v)
            end
        end
    end
    return coins
end

-- Movement with optional clipping (no raycast if clipping)
local function MoveToCoin(targetPos)
    if not Root or not Root.Parent then RefreshCharacter() end
    if not Root then return end

    -- If clipping, we don't care about walls; if not, we skip coins behind walls
    if not isClipping then
        -- Simple raycast to check if a wall is in the way
        local direction = (targetPos - Root.Position).Unit
        local ray = Ray.new(Root.Position, direction * 10)
        local hit = workspace:FindPartOnRay(ray, Character)
        if hit and hit:IsA("BasePart") and hit.CanCollide then
            return  -- skip this coin
        end
    end

    -- Random offset to look human (still applies)
    local offsetX = (math.random() - 0.5) * 1.5 * 2
    local offsetZ = (math.random() - 0.5) * 1.5 * 2
    local offsetTarget = targetPos + Vector3.new(offsetX, 0, offsetZ)

    local currentPos = Root.Position
    local distance = (offsetTarget - currentPos).Magnitude
    if distance < 1 then
        Humanoid:MoveTo(targetPos)
        task.wait(0.2)
        return
    end

    local duration = math.max(0.05, distance / SPEED)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local goal = {CFrame = CFrame.new(offsetTarget + Vector3.new(0, 2, 0))}
    local tween = TweenService:Create(Root, tweenInfo, goal)
    local success, err = pcall(function() tween:Play() end)
    if not success then
        Humanoid:MoveTo(targetPos)
        task.wait(0.3)
    else
        tween.Completed:Wait()
        Humanoid:MoveTo(targetPos)
        task.wait(0.1)
    end
    task.wait(0.02)
end

-- Farm loop
local function FarmLoop()
    while isFarming do
        if not Root or not Root.Parent then
            RefreshCharacter()
            task.wait(0.5)
            continue
        end

        local coins = GetCoins()
        if #coins == 0 then
            task.wait(0.3)
            continue
        end

        local closestCoin = nil
        local closestDist = math.huge
        for _, coin in ipairs(coins) do
            local dist = (Root.Position - coin.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closestCoin = coin
            end
        end
        if closestCoin then
            MoveToCoin(closestCoin.Position)
            currentCoins = currentCoins + 1
            coinCounter.Text = "Coins: " .. currentCoins
        end
        task.wait(0.1)
    end
end

-- Toggle farming
local function ToggleFarming()
    isFarming = not isFarming
    if isFarming then
        toggleBtn.Text = "STOP FARMING"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        status.Text = "Status: COLLECTING"
        status.TextColor3 = Color3.fromRGB(0, 255, 0)
        -- If clip is on, apply it now
        if isClipping then SetClip(true) end
        if farmThread then coroutine.close(farmThread) end
        farmThread = coroutine.create(FarmLoop)
        coroutine.resume(farmThread)
    else
        toggleBtn.Text = "START FARMING"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        status.Text = "Status: IDLE"
        status.TextColor3 = Color3.fromRGB(200, 200, 200)
        -- Restore collisions when stopping
        if isClipping then SetClip(false) end
        farmThread = nil
    end
end

-- Toggle clip mode (does not start/stop farming)
local function ToggleClip()
    -- Only change if not farming, or allow toggling on the fly (risky)
    SetClip(not isClipping)
    -- If currently farming, we need to update state immediately
    if isFarming and isClipping then
        -- Ensure all parts are noclipped
        SetClip(true)
    elseif isFarming and not isClipping then
        -- Restore collisions while still farming
        SetClip(false)
    end
end

-- Button events
toggleBtn.MouseButton1Click:Connect(ToggleFarming)
clipBtn.MouseButton1Click:Connect(ToggleClip)

-- Hotkey: F for farming, C for clip toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then ToggleFarming() end
    if input.KeyCode == Enum.KeyCode.C then ToggleClip() end
end)

-- Cleanup
screenGui.AncestryChanged:Connect(function()
    if not screenGui.Parent then
        isFarming = false
        if farmThread then coroutine.close(farmThread) end
        if isClipping then SetClip(false) end
    end
end)
