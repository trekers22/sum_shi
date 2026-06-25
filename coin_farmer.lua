-- MM2 Coin Farmer - FIXED & AGGRESSIVE
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Root = Character:WaitForChild("HumanoidRootPart")

-- SPEED ADJUST HERE – set to 30 if 60 is too fast
local SPEED = 30  -- default, change to whatever

-- Refreshes character references on respawn
local function RefreshCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    Humanoid = Character:WaitForChild("Humanoid")
    Root = Character:WaitForChild("HumanoidRootPart")
end
LocalPlayer.CharacterAdded:Connect(RefreshCharacter)

-- AGGRESSIVE COIN DETECTION – no more bullshit
local function GetCoins()
    local coins = {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v:FindFirstChild("TouchInterest") then
            -- Check if it's a coin – look for name, parent, or any tag
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

-- MOVEMENT – with fallback to teleport if tween fails
local function MoveToCoin(targetPos)
    if not Root or not Root.Parent then RefreshCharacter() end
    if not Root then return end
    local currentPos = Root.Position
    local distance = (targetPos - currentPos).Magnitude
    if distance < 1 then return end
    
    -- If speed is too high, you get banned – but you wanted fast, so here it is
    local duration = math.max(0.05, distance / SPEED) -- min 0.05 sec
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local goal = {CFrame = CFrame.new(targetPos + Vector3.new(0, 2, 0))}
    local tween = TweenService:Create(Root, tweenInfo, goal)
    local success, err = pcall(function() tween:Play() end)
    if not success then
        -- Tween failed – fallback to raw teleport (you asked for speed, here's the cheat)
        Root.CFrame = CFrame.new(targetPos + Vector3.new(0, 2, 0))
    else
        tween.Completed:Wait()
    end
    task.wait(0.02) -- minimal delay
end

-- REST OF GUI – same as before, but with a speed label to show current value
-- I'll keep it brief, only include the core changes

-- ... (GUI creation code unchanged, just copy from previous working version)
-- But you need to add a way to change speed on the fly – I'll add a small TextBox later if you want, but for now just edit the SPEED variable.

-- The main loop is the same, but with error handling
local function FarmLoop()
    while isFarming do
        local coins = GetCoins()
        if #coins == 0 then
            task.wait(0.3) -- if no coins, wait a bit longer
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
