-- MM2 Coin Farmer - PROPER COIN DETECTION
local SPEED = 16
local MAX_COINS_PER_ROUND = 40

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Root = Character:WaitForChild("HumanoidRootPart")

local function RefreshCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    Humanoid = Character:WaitForChild("Humanoid")
    Root = Character:WaitForChild("HumanoidRootPart")
end
LocalPlayer.CharacterAdded:Connect(RefreshCharacter)

-- ========== PROPER COIN TRACKING ==========
local CoinList = {}  -- Dynamic coin list

-- Initial scan for coins
local function ScanCoins()
    CoinList = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Coin_Server" then
            table.insert(CoinList, obj)
        end
    end
end

-- Listen for new coins spawning
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("BasePart") and obj.Name == "Coin_Server" then
        table.insert(CoinList, obj)
    end
end)

-- Listen for coins being removed
workspace.DescendantRemoving:Connect(function(obj)
    if obj:IsA("BasePart") and obj.Name == "Coin_Server" then
        for i, coin in ipairs(CoinList) do
            if coin == obj then
                table.remove(CoinList, i)
                break
            end
        end
    end
end)

-- Initial scan
ScanCoins()

-- ========== GUI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoinFarmerGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") or game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 230)
frame.Position = UDim2.new(0.8, -300, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 3
frame.BorderColor3 = Color3.fromRGB(255, 100, 0)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "COIN FARMER"
title.TextColor3 = Color3.fromRGB(255, 200, 50)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.85, 0, 0, 45)
toggleBtn.Position = UDim2.new(0.075, 0, 0.25, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
toggleBtn.Text = "▶ START FARMING"
toggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = frame

local clipBtn = Instance.new("TextButton")
clipBtn.Size = UDim2.new(0.4, 0, 0, 35)
clipBtn.Position = UDim2.new(0.075, 0, 0.53, 0)
clipBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
clipBtn.Text = "CLIP OFF"
clipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clipBtn.TextScaled = true
clipBtn.Font = Enum.Font.Gotham
clipBtn.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(0.5, 0, 0, 25)
status.Position = UDim2.new(0.55, 0, 0.55, 0)
status.BackgroundTransparency = 1
status.Text = "IDLE"
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.TextScaled = true
status.Font = Enum.Font.Gotham
status.Parent = frame

local totalCoinLabel = Instance.new("TextLabel")
totalCoinLabel.Size = UDim2.new(0.4, 0, 0, 20)
totalCoinLabel.Position = UDim2.new(0.075, 0, 0.75, 0)
totalCoinLabel.BackgroundTransparency = 1
totalCoinLabel.Text = "Total: 0"
totalCoinLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
totalCoinLabel.TextScaled = true
totalCoinLabel.Font = Enum.Font.Gotham
totalCoinLabel.Parent = frame

local roundCoinLabel = Instance.new("TextLabel")
roundCoinLabel.Size = UDim2.new(0.4, 0, 0, 20)
roundCoinLabel.Position = UDim2.new(0.55, 0, 0.75, 0)
roundCoinLabel.BackgroundTransparency = 1
roundCoinLabel.Text = "Round: 0/40"
roundCoinLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
roundCoinLabel.TextScaled = true
roundCoinLabel.Font = Enum.Font.Gotham
roundCoinLabel.Parent = frame

local capMsg = Instance.new("TextLabel")
capMsg.Size = UDim2.new(0.85, 0, 0, 20)
capMsg.Position = UDim2.new(0.075, 0, 0.88, 0)
capMsg.BackgroundTransparency = 1
capMsg.Text = ""
capMsg.TextColor3 = Color3.fromRGB(255, 0, 0)
capMsg.TextScaled = true
capMsg.Font = Enum.Font.GothamBold
capMsg.Parent = frame

-- ========== CORE LOGIC ==========
local isFarming = false
local isClipping = false
local farmThread = nil
local totalCoins = 0
local roundCoins = 0
local maxCoins = MAX_COINS_PER_ROUND

local originalCollisions = {}

local function SetClip(enable)
    isClipping = enable
    clipBtn.Text = enable and "CLIP ON" or "CLIP OFF"
    clipBtn.BackgroundColor3 = enable and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(80, 80, 80)
    if Character then
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                if enable then
                    if originalCollisions[part] == nil then
                        originalCollisions[part] = part.CanCollide
                    end
                    part.CanCollide = false
                else
                    if originalCollisions[part] ~= nil then
                        part.CanCollide = originalCollisions[part]
                    end
                end
            end
        end
    end
end

-- Reset round counter on respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    Root = newChar:WaitForChild("HumanoidRootPart")
    originalCollisions = {}
    roundCoins = 0
    roundCoinLabel.Text = "Round: 0/" .. maxCoins
    capMsg.Text = ""
    if isClipping then SetClip(true) end
end)

-- ========== MOVEMENT ==========
local function MoveToCoin(coin)
    -- CRITICAL FIX: Check if the coin still exists before moving
    if not coin or not coin.Parent then
        return false  -- Coin is gone, tell the loop to skip it
    end
    
    if not Root or not Root.Parent then RefreshCharacter() end
    if not Root then return false end

    if roundCoins >= maxCoins then
        return false
    end

    local targetPos = coin.Position
    
    -- Wall check if not clipping
    if not isClipping then
        local direction = (targetPos - Root.Position).Unit
        local ray = Ray.new(Root.Position + Vector3.new(0, 1, 0), direction * 8)
        local hit = workspace:FindPartOnRay(ray, Character)
        if hit and hit:IsA("BasePart") and hit.CanCollide then
            return false  -- Wall in the way, skip this coin
        end
    end

    local offsetX = (math.random() - 0.5) * 0.8
    local offsetZ = (math.random() - 0.5) * 0.8
    local offsetTarget = targetPos + Vector3.new(offsetX, 0, offsetZ)

    local currentPos = Root.Position
    local distance = (offsetTarget - currentPos).Magnitude
    if distance < 1.5 then
        Humanoid:MoveTo(targetPos)
        task.wait(0.15)
        return true
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
    return true
end

-- ========== FARM LOOP ==========
local function FarmLoop()
    while isFarming do
        if not Root or not Root.Parent then
            RefreshCharacter()
            task.wait(0.5)
            continue
        end

        if roundCoins >= maxCoins then
            capMsg.Text = "ROUND CAP REACHED (" .. maxCoins .. ")"
            task.wait(0.5)
            continue
        else
            capMsg.Text = ""
        end

        -- Use the dynamic CoinList instead of scanning each time
        if #CoinList == 0 then
            task.wait(0.3)
            continue
        end

        -- Find closest VALID coin
        local closestCoin = nil
        local closestDist = math.huge
        for _, coin in ipairs(CoinList) do
            -- CRITICAL FIX: Skip coins that no longer exist
            if coin and coin.Parent and coin:IsA("BasePart") then
                local dist = (Root.Position - coin.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestCoin = coin
                end
            end
        end
        
        if closestCoin then
            local success = MoveToCoin(closestCoin)
            if success then
                totalCoins = totalCoins + 1
                roundCoins = roundCoins + 1
                totalCoinLabel.Text = "Total: " .. totalCoins
                roundCoinLabel.Text = "Round: " .. roundCoins .. "/" .. maxCoins
            end
        end
        task.wait(0.1)
    end
end

-- ========== TOGGLE FUNCTIONS ==========
local function ToggleFarming()
    isFarming = not isFarming
    if isFarming then
        toggleBtn.Text = "⏹ STOP FARMING"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        status.Text = "COLLECTING"
        status.TextColor3 = Color3.fromRGB(0, 255, 0)
        if isClipping then SetClip(true) end
        if farmThread then coroutine.close(farmThread) end
        farmThread = coroutine.create(FarmLoop)
        coroutine.resume(farmThread)
    else
        toggleBtn.Text = "▶ START FARMING"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        status.Text = "IDLE"
        status.TextColor3 = Color3.fromRGB(200, 200, 200)
        if isClipping then SetClip(false) end
        farmThread = nil
    end
end

local function ToggleClip()
    SetClip(not isClipping)
end

toggleBtn.MouseButton1Click:Connect(ToggleFarming)
clipBtn.MouseButton1Click:Connect(ToggleClip)

screenGui.AncestryChanged:Connect(function()
    if not screenGui.Parent then
        isFarming = false
        if farmThread then coroutine.close(farmThread) end
        if isClipping then SetClip(false) end
    end
end)
