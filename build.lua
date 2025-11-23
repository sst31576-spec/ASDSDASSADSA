local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/accountsdaasa/uilibraryforkinggen/refs/heads/main/baseui.lua"))() 
if not Library then return end

local Window = Library:Window({
    ConfigName = "buildtoboat.json"
})

local MainTab = Window:Tab("Main")
local MiscTab = Window:Tab("Misc")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local farming = false
local teleportCoroutine = nil
local flyCoroutine = nil
local webhookUrl = ""
local totalGoldEarned = 0
local lastGold = 0

local places = {
    Vector3.new(-39.51, 43.44, 1372.73),
    Vector3.new(-46.16, 43.69, 2145.83),
    Vector3.new(-48.89, 23.43, 2908.94),
    Vector3.new(-63.15, 23.06, 3679.83),
    Vector3.new(-81.72, 33.69, 4449.42),
    Vector3.new(-71.63, 34.77, 5221.51),
    Vector3.new(-41.69, 18.96, 5990.66),
    Vector3.new(-56.49, 18.98, 6761.81),
    Vector3.new(-46.62, 21.75, 7525.17),
    Vector3.new(-53.54, 25.00, 8297.80),
    Vector3.new(-52.77, -362.19, 9490.53)
}

local function enableFlying()
    if not LocalPlayer.Character then return end
    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end
    humanoid.PlatformStand = true
    local bg = Instance.new("BodyGyro")
    bg.P = 1000
    bg.D = 50
    bg.MaxTorque = Vector3.new(4000,4000,4000)
    bg.CFrame = rootPart.CFrame
    bg.Parent = rootPart
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0,0,0)
    bv.MaxForce = Vector3.new(4000,4000,4000)
    bv.Parent = rootPart
    flyCoroutine = coroutine.create(function()
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not farming or not LocalPlayer.Character or not rootPart then
                if connection then connection:Disconnect() end
                return
            end
            if bg and bv then
                bg.CFrame = rootPart.CFrame
                bv.Velocity = Vector3.new(0,0,0)
            end
        end)
    end)
    coroutine.resume(flyCoroutine)
end

local function disableFlying()
    if not LocalPlayer.Character then return end
    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if humanoid then humanoid.PlatformStand = false end
    if rootPart then
        for _, obj in pairs(rootPart:GetChildren()) do
            if obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") then
                obj:Destroy()
            end
        end
    end
    if flyCoroutine then coroutine.close(flyCoroutine) end
end

local function teleportTo(position)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        enableFlying()
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(position)
        local rootPart = LocalPlayer.Character.HumanoidRootPart
        local currentPos = rootPart.Position
        rootPart.CFrame = CFrame.new(currentPos.X, position.Y, currentPos.Z)
    end
end

local function sendWebhook(goldEarned)
    if webhookUrl == "" then return end
    local data = {
        ["embeds"] = {{
            ["title"] = "Always more gold!",
            ["description"] = "You have earned **" .. tostring(goldEarned) .. "** ", 
            ["color"] = 65280,
            ["fields"] = {
                { ["name"]="Gold Earned", ["value"]="**"..tostring(goldEarned).."**", ["inline"]=true },
                { ["name"]="Total Gold Earned", ["value"]="**"..tostring(totalGoldEarned).."**", ["inline"]=true }
            },
            ["footer"] = { ["text"]="KingGen Hub - BABFT | https://discord.gg/zwWtufuznX "..os.date("%d/%m/%Y %H:%M:%S") }
        }}
    }
    local success, jsonData = pcall(function() return HttpService:JSONEncode(data) end)
    if not success then return end
    local requestFunc = syn and syn.request or http and http.request or http_request or request
    if not requestFunc then return end
    pcall(function()
        requestFunc({Url=webhookUrl, Method="POST", Headers={["Content-Type"]="application/json"}, Body=jsonData})
    end)
end

local function checkForGold()
    local currentGold = LocalPlayer.Data.Gold.Value
    local goldDifference = currentGold - lastGold
    if goldDifference > 0 then
        totalGoldEarned = totalGoldEarned + goldDifference
        sendWebhook(goldDifference)
        lastGold = currentGold
    end
end

local function claimGoldOnce()
    pcall(function() Workspace:WaitForChild("ClaimRiverResultsGold"):FireServer() end)
end

local function startTeleportLoop()
    teleportCoroutine = coroutine.create(function()
        while farming do
            for i, place in ipairs(places) do
                if not farming then break end
                teleportTo(place)
                task.wait(2)
                if i == 11 then
                    local initialPosition = LocalPlayer.Character.HumanoidRootPart.Position
                    disableFlying()
                    repeat task.wait(0.5) until not farming or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer.Character.HumanoidRootPart.Position - initialPosition).Magnitude > 100)
                    claimGoldOnce()
                    task.wait(1)
                    checkForGold()
                    lastGold = LocalPlayer.Data.Gold.Value
                    task.wait(5)
                end
            end
        end
    end)
    coroutine.resume(teleportCoroutine)
end

local function startFarming()
    if farming then return end
    farming = true
    lastGold = LocalPlayer.Data.Gold.Value
    if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
    startTeleportLoop()
end

local function stopFarming()
    farming = false
    disableFlying()
    if teleportCoroutine then coroutine.close(teleportCoroutine) end
end

MainTab:Toggle({
    Name = "Enable Auto Farm",
    Flag = "AutoFarm",
    Default = false,
    Callback = function(Value)
        if Value then
            startFarming()
            Library:Notify({Title="Auto Farm Started", Content="Auto farming enabled.", Duration=3})
        else
            stopFarming()
            Library:Notify({Title="Auto Farm Stopped", Content="Auto farming disabled.", Duration=3})
        end
    end
})

coroutine.wrap(function()
    while true do
        task.wait(1)
        MainTab:Label({Text="Total Gold: "..tostring(totalGoldEarned).." 🪙"})
    end
end)()

MiscTab:TextBox({
    Name = "Webhook URL",
    Flag = "Webhook",
    Default = "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(Value)
        webhookUrl = Value
    end
})

MiscTab:Button({
    Name = "Test Webhook",
    Callback = function()
        if webhookUrl ~= "" then
            sendWebhook(999)
            Library:Notify({Title="Webhook Test", Content="Webhook Check", Duration=3})
        else
            Library:Notify({Title="Error", Content="Set a webhook first", Duration=5})
        end
    end
})

Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then stopFarming() end
end)

Window:Init()
