-- MM2 Coin Farmer - COMPLETE WITH GUI AND SPEED CONTROL
local SPEED = 35  -- CHANGE THIS TO GO FASTER (60) OR SLOWER (20)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Root = Character:WaitForChild("HumanoidRootPart")

-- Refresh character on respawn
local function RefreshCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    Humanoid = Character:WaitForChild("Humanoid")
    Root = Character:WaitForChild("HumanoidRootPart")
end
LocalPlayer.CharacterAdded:Connect(RefreshCharacter)

-- ====== GUI CREATION ======
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoinFarmerGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") or game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 160)  -- made a bit taller for speed label
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
title.Text = "COIN FARMER (TOGGLE F)"
title.TextColor3 = Color3.fromRGB(255, 200, 100)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.8, 0, 0, 35)
toggleBtn.Position = UDim2.new(0.1, 0, 0.3, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
toggleBtn.Text = "START FARMING"
toggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(0.8, 0, 0, 20)
status.Position = UDim2.new(0.1, 0, 0.6, 0)
status.BackgroundTransparency = 1
status.Text = "Status: IDLE"
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.TextScaled = true
status.Font = Enum.Font.Gotham
status.Parent = frame

local coinCounter = Instance.new("TextLabel")
coinCounter.Size = UDim2.new(0.8, 0, 0, 20)
coinCounter.Position = UDim2.new(0.1, 0, 0.75, 0)
coinCounter.BackgroundTransparency = 1
coinCounter.Text = "Coins: 0"
coinCounter.TextColor3 = Color3.fromRGB(100, 255, 100)
coinCounter.TextScaled = true
coinCounter.Font = Enum.Font.Gotham
coinCounter.Parent = frame

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.8, 0, 0, 18)
speedLabel.Position = UDim2.new(0.1, 0, 0.9, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: " .. SPEED .. " studs/s"
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
speedLabel.TextScaled = true
speedLabel.Font = Enum.Font.Gotham
speedLabel.Parent = frame

-- ====== COIN DETECTION ======
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

-- ====== MOVEMENT ======
local function MoveToCoin(targetPos)
    if not Root or not Root.Parent then RefreshCharacter() end
    if not Root then return end
    local currentPos = Root.Position
    local distance = (targetPos - currentPos).Magnitude
    if distance < 1 then return end
    
    local duration = math.max(0.05, distance / SPEED)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local goal = {CFrame = CFrame.new(targetPos + Vector3.new(0, 2, 0))}
    local tween = TweenService:Create(Root, tweenInfo, goal)
    local success, err = pcall(function() tween:Play() end)
    if not success then
        Root.CFrame = CFrame.new(targetPos + Vector3.new(0, 2, 0))
    else
        tween.Completed:Wait()
    end
    task.wait(0.02)
end

-- ====== FARM LOOP ======
local isFarming = false
local farmThread = nil
local currentCoins = 0

local function FarmLoop()
    while isFarming do
        local coins = GetCoins()
        if #coins == 0 then
            task.wait(0.3)
        else
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
        end
        task.wait(0.1)
    end
end

-- ====== TOGGLE ======
local function ToggleFarming()
    isFarming = not isFarming
    if isFarming then
        toggleBtn.Text = "STOP FARMING"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        status.Text = "Status: COLLECTING"
        status.TextColor3 = Color3.fromRGB(0, 255, 0)
        if farmThread then coroutine.close(farmThread) end
        farmThread = coroutine.create(FarmLoop)
        coroutine.resume(farmThread)
    else
        toggleBtn.Text = "START FARMING"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        status.Text = "Status: IDLE"
        status.TextColor3 = Color3.fromRGB(200, 200, 200)
        farmThread = nil
    end
end

-- ====== EVENTS ======
toggleBtn.MouseButton1Click:Connect(ToggleFarming)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then ToggleFarming() end
end)

screenGui.AncestryChanged:Connect(function()
    if not screenGui.Parent then
        isFarming = false
        if farmThread then coroutine.close(farmThread) end
    end
end)
