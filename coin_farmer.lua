-- MM2 Coin Farmer - MOBILE EDITION (safe, no kicks)
local SPEED = 16  -- NORMAL WALKING SPEED – DO NOT INCREASE UNLESS YOU WANT BANS
local CLIP_ENABLED = false  -- CLIPPING IS OFF BY DEFAULT – TURN ON ONLY FOR STUCK COINS

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Character references (updated on respawn)
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Root = Character:WaitForChild("HumanoidRootPart")

local function RefreshCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    Humanoid = Character:WaitForChild("Humanoid")
    Root = Character:WaitForChild("HumanoidRootPart")
end
LocalPlayer.CharacterAdded:Connect(RefreshCharacter)

-- ========== GUI (BIG BUTTONS FOR PHONES) ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoinFarmerGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") or game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 200)  -- wider for big buttons
frame.Position = UDim2.new(0.8, -280, 0.3, 0)
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

-- MAIN TOGGLE (START/STOP) – BIG GREEN/RED
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.85, 0, 0, 50)
toggleBtn.Position = UDim2.new(0.075, 0, 0.25, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
toggleBtn.Text = "▶ START FARMING"
toggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = frame

-- CLIP TOGGLE – BIG RED/GREY
local clipBtn = Instance.new("TextButton")
clipBtn.Size = UDim2.new(0.4, 0, 0, 40)
clipBtn.Position = UDim2.new(0.075, 0, 0.58, 0)
clipBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
clipBtn.Text = "CLIP OFF"
clipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clipBtn.TextScaled = true
clipBtn.Font = Enum.Font.Gotham
clipBtn.Parent = frame

-- STATUS
local status = Instance.new("TextLabel")
status.Size = UDim2.new(0.5, 0, 0, 25)
status.Position = UDim2.new(0.55, 0, 0.6, 0)
status.BackgroundTransparency = 1
status.Text = "IDLE"
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.TextScaled = true
status.Font = Enum.Font.Gotham
status.Parent = frame

-- COIN COUNTER
local coinCounter = Instance.new("TextLabel")
coinCounter.Size = UDim2.new(0.85, 0, 0, 25)
coinCounter.Position = UDim2.new(0.075, 0, 0.8, 0)
coinCounter.BackgroundTransparency = 1
coinCounter.Text = "🪙 0"
coinCounter.TextColor3 = Color3.fromRGB(100, 255, 100)
coinCounter.TextScaled = true
coinCounter.Font = Enum.Font.Gotham
coinCounter.Parent = frame

-- ========== CORE LOGIC ==========
local isFarming = false
local isClipping = false
local farmThread = nil
local currentCoins = 0

-- Store original CanCollide for restoring
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

-- Reapply clip on respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    Root = newChar:WaitForChild("HumanoidRootPart")
    originalCollisions = {}
    if isClipping then SetClip(true) end
end)

-- Coin detection (aggressive but safe)
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

-- Movement (no wall check if clipping is enabled)
local function MoveToCoin(targetPos)
    if not Root or not Root.Parent then RefreshCharacter() end
    if not Root then return end

    -- If not clipping, do a simple raycast to skip unreachable coins (prevents stuck attempts)
    if not isClipping then
        local direction = (targetPos - Root.Position).Unit
        local ray = Ray.new(Root.Position + Vector3.new(0, 1, 0), direction * 8)
        local hit = workspace:FindPartOnRay(ray, Character)
        if hit and hit:IsA("BasePart") and hit.CanCollide then
            return  -- skip this coin, wall in the way
        end
    end

    -- Small random offset to look human (but very small)
    local offsetX = (math.random() - 0.5) * 0.8
    local offsetZ = (math.random() - 0.5) * 0.8
    local offsetTarget = targetPos + Vector3.new(offsetX, 0, offsetZ)

    local currentPos = Root.Position
    local distance = (offsetTarget - currentPos).Magnitude
    if distance < 1.5 then
        -- Walk the last bit
        Humanoid:MoveTo(targetPos)
        task.wait(0.15)
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

-- Main farming loop
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

        -- Find closest coin
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
            coinCounter.Text = "🪙 " .. currentCoins
        end
        task.wait(0.1)
    end
end

-- Toggle farming
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

-- Toggle clip
local function ToggleClip()
    SetClip(not isClipping)
    -- If farming is active, apply change immediately
    if isFarming then
        -- No extra action needed, SetClip already updates parts
    end
end

-- Button connections
toggleBtn.MouseButton1Click:Connect(ToggleFarming)
clipBtn.MouseButton1Click:Connect(ToggleClip)

-- Cleanup
screenGui.AncestryChanged:Connect(function()
    if not screenGui.Parent then
        isFarming = false
        if farmThread then coroutine.close(farmThread) end
        if isClipping then SetClip(false) end
    end
end)
