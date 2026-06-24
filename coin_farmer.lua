-- MM2 Coin Farmer with Toggle GUI - Crude as fuck
-- Drop this in a LocalScript under StarterGui or just run it directly

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Root = Character:WaitForChild("HumanoidRootPart")

-- ===== GUI CREATION =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoinFarmerGUI"
screenGui.ResetOnSpawn = false  -- stays between deaths, because we're persistent bastards
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") or game:GetService("CoreGui")

-- Main frame (draggable, resizable, ugly)
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 140)
frame.Position = UDim2.new(0.8, -240, 0.3, 0) -- top-right corner
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
frame.Active = true
frame.Draggable = true  -- drag it by the title bar
frame.Parent = screenGui

-- Title label (edgy)
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "COIN FARMER (TOGGLE)"
title.TextColor3 = Color3.fromRGB(255, 200, 100)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = frame

-- Toggle button (the main event)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
toggleBtn.Position = UDim2.new(0.1, 0, 0.35, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
toggleBtn.Text = "START FARMING"
toggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = frame

-- Status label
local status = Instance.new("TextLabel")
status.Size = UDim2.new(0.8, 0, 0, 25)
status.Position = UDim2.new(0.1, 0, 0.7, 0)
status.BackgroundTransparency = 1
status.Text = "Status: IDLE"
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.TextScaled = true
status.Font = Enum.Font.Gotham
status.Parent = frame

-- Coin counter label (just for show, because numbers make your dick hard)
local coinCounter = Instance.new("TextLabel")
coinCounter.Size = UDim2.new(0.8, 0, 0, 20)
coinCounter.Position = UDim2.new(0.1, 0, 0.85, 0)
coinCounter.BackgroundTransparency = 1
coinCounter.Text = "Coins: 0"
coinCounter.TextColor3 = Color3.fromRGB(100, 255, 100)
coinCounter.TextScaled = true
coinCounter.Font = Enum.Font.Gotham
coinCounter.Parent = frame

-- ===== CORE LOGIC =====
local isFarming = false
local farmThread = nil
local currentCoins = 0  -- fake counter, update manually if you want

-- Function to find coins (same as before)
local function GetCoins()
    local coins = {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name:lower():find("coin") or v:FindFirstChild("CoinTag") or v:FindFirstChild("Collectible")) then
            if v:FindFirstChild("TouchInterest") or v:FindFirstChild("ClickDetector") then
                table.insert(coins, v)
            end
        end
    end
    return coins
end

-- Tween movement with speed randomization
local function MoveToCoin(targetPos)
    if not Root or not Root.Parent then return end
    local currentPos = Root.Position
    local distance = (targetPos - currentPos).Magnitude
    if distance < 1 then return end -- already there
    local speed = math.random(10, 16) -- human-like variation
    local duration = math.clamp(distance / speed, 0.05, 4)
    local tweenInfo = TweenInfo.new(
        duration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )
    local goal = {CFrame = CFrame.new(targetPos + Vector3.new(0, 2, 0))}
    local tween = TweenService:Create(Root, tweenInfo, goal)
    tween:Play()
    tween.Completed:Wait()
    -- Small random delay to look organic
    task.wait(math.random(30, 150) / 1000)
end

-- The main farming loop (runs in a separate thread)
local function FarmLoop()
    while isFarming do
        local coins = GetCoins()
        if #coins == 0 then
            task.wait(0.3)
            continue
        end
        -- Find closest
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
            -- Update fake counter (optional)
            currentCoins = currentCoins + 1
            coinCounter.Text = "Coins: " .. currentCoins
        end
        task.wait(0.1) -- small breather
    end
end

-- Toggle function
local function ToggleFarming()
    isFarming = not isFarming
    if isFarming then
        toggleBtn.Text = "STOP FARMING"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        status.Text = "Status: COLLECTING"
        status.TextColor3 = Color3.fromRGB(0, 255, 0)
        -- Start the loop in a new coroutine so it doesn't block the GUI
        if farmThread then coroutine.close(farmThread) end
        farmThread = coroutine.create(FarmLoop)
        coroutine.resume(farmThread)
    else
        toggleBtn.Text = "START FARMING"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        status.Text = "Status: IDLE"
        status.TextColor3 = Color3.fromRGB(200, 200, 200)
        -- The loop will exit on its own because isFarming is false
        -- But we also need to wait for the coroutine to finish
        if farmThread then
            -- Let it die naturally; we won't force close to avoid errors
            farmThread = nil
        end
    end
end

-- Bind the button
toggleBtn.MouseButton1Click:Connect(ToggleFarming)

-- Optional: hotkey 'F' to toggle (because clicking is for casuals)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        ToggleFarming()
    end
end)

-- Cleanup when GUI is removed (not needed but nice)
screenGui.AncestryChanged:Connect(function()
    if not screenGui.Parent then
        isFarming = false
        if farmThread then coroutine.close(farmThread) end
    end
end)
