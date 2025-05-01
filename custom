local api = ...
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")

local framework = {
    connections = {},
    antiSitActive = false,
    spinActive = false,
    multiToolActive = false,
    equippedTools = {},
    isHoldingKey = false
}

local extrasTab = api:AddTab("extras")

local antiSitGroup = extrasTab:AddLeftGroupbox("Anti-Sit")
local antiSitToggle = antiSitGroup:AddToggle("anti_sit", {
    Text = "Anti-Sit",
    Default = true,
})

antiSitToggle:OnChanged(function()
    framework.antiSitActive = antiSitToggle.Value
end)

table.insert(framework.connections, RunService.Heartbeat:Connect(function()
    if not framework.antiSitActive then return end

    local char = LocalPlayer.Character
    if not char then return end

    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end

    if humanoid:GetState() == Enum.HumanoidStateType.Seated then
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    end
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
end))

table.insert(framework.connections, RunService.Heartbeat:Connect(function()
    if not framework.antiSitActive then
        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid then return end
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    end
end))

do
    local group = extrasTab:AddLeftGroupbox("Voice Chat")

    group:AddButton("Reconnect VC", function()
        local success, err = pcall(function()
            game:GetService("VoiceChatService"):joinVoice()
        end)
        api:Notify(success and "Reconnected to VC" or ("VC Failed: " .. tostring(err)), 2)
    end)

    group:AddButton("Rejoin Server", function()
        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
        api:Notify(success and "Rejoining server..." or ("Failed: " .. tostring(err)), 2)
    end)
end

do
    local group = extrasTab:AddLeftGroupbox("God Block")
    
    local silentBlockToggle = group:AddToggle("god_block", {
        Text = "God block",
        Default = true,
    })

    table.insert(framework.connections, RunService.Heartbeat:Connect(function()
        if silentBlockToggle.Value then
            local char = LocalPlayer.Character
            if not char then return end

            game.ReplicatedStorage.MainEvent:FireServer("Block", true)

            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                for _, anim in ipairs(hum:GetPlayingAnimationTracks()) do
                    if anim.Animation.AnimationId:match("2788354405") then 
                        anim:Stop()
                    end
                end
            end

            local effects = char:FindFirstChild("BodyEffects")
            if effects and effects:FindFirstChild("Block") then
                effects.Block:Destroy()
            end
        end
    end))

end

do
    local group = extrasTab:AddLeftGroupbox("Force Reset")

    group:AddButton("Force Reset", function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
        api:Notify("Character reset", 2)
    end)
end

do
    local group = extrasTab:AddLeftGroupbox("Activity Logs")
    local joinConn, leaveConn = nil, nil

    group:AddToggle("logs_toggle", {
        Text = "Enable Logs",
        Default = false,
        Callback = function(enabled)
            if enabled then
                group:AddInput("notify_text", {
                    Text = "Notification Text",
                    Default = "{NAME} has {ACTIVITY} the game.",
                    Placeholder = "ex: {NAME}, {ACTIVITY}",
                    Finished = true
                })
                group:AddSlider("notify_duration", {
                    Text = "Notify Duration",
                    Default = 3,
                    Min = 0.5,
                    Max = 10,
                    Rounding = 1, 
                    Suffix = "s"
                })
                joinConn = Players.PlayerAdded:Connect(function(p)
                    api:Notify(Options.notify_text.Value:gsub("{NAME}", p.Name):gsub("{ACTIVITY}", "joined"), Options.notify_duration.Value)
                end)
                leaveConn = Players.PlayerRemoving:Connect(function(p)
                    api:Notify(Options.notify_text.Value:gsub("{NAME}", p.Name):gsub("{ACTIVITY}", "left"), Options.notify_duration.Value)
                end)
                table.insert(framework.connections, joinConn)
                table.insert(framework.connections, leaveConn)
            else
                if joinConn then joinConn:Disconnect() end
                if leaveConn then leaveConn:Disconnect() end
            end
        end
    })
end

local antiFlingGroup = extrasTab:AddLeftGroupbox("Misc")
antiFlingGroup:AddToggle("anti_fling", {
    Text = "Anti-Fling",
    Default = false,
})

local originalCollisions = {}

table.insert(framework.connections, RunService.Heartbeat:Connect(function()
    local toggle = Toggles.anti_fling
    if not toggle or not toggle.Value then
        for player, parts in pairs(originalCollisions) do
            if player and player.Character then
                for part, properties in pairs(parts) do
                    if part and part:IsA("BasePart") then
                        part.CanCollide = properties.CanCollide
                        if part.Name == "Torso" then
                            part.Massless = properties.Massless
                        end
                    end
                end
            end
        end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end

        pcall(function()
            local parts = {}
            for _, part in ipairs(player.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    parts[part] = { CanCollide = part.CanCollide, Massless = part.Name == "Torso" and part.Massless or false }
                    part.CanCollide = false
                    if part.Name == "Torso" then
                        part.Massless = true
                    end
                    if toggle.Value then
                        part.Velocity = Vector3.zero
                        part.RotVelocity = Vector3.zero
                    end
                end
            end
            originalCollisions[player] = parts
        end)
    end
end))

do
    local group = extrasTab:AddLeftGroupbox("Troll")
    local jerkTool = nil
    local respawnConnection = nil

    local function createTool()
        local plr = game:GetService("Players").LocalPlayer
        local pack = plr:WaitForChild("Backpack")

        local existing = workspace:FindFirstChild("aaa")
        if existing then existing:Destroy() end

        local animation = Instance.new("Animation")
        animation.Name = "aaa"
        animation.Parent = workspace
        animation.AnimationId = (plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R15)
            and "rbxassetid://698251653" or "rbxassetid://72042024"

        jerkTool = Instance.new("Tool")
        jerkTool.Name = "Jerk"
        jerkTool.RequiresHandle = false
        jerkTool.Parent = pack

        local doing, animTrack = false, nil

        jerkTool.Equipped:Connect(function()
            doing = true
            while doing do
                if not animTrack then
                    local hum = plr.Character and plr.Character:FindFirstChild("Humanoid")
                    local animator = hum and (hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator"))
                    if not animator then break end
                    animTrack = animator:LoadAnimation(animation)
                end
                animTrack:Play()
                animTrack:AdjustSpeed(0.7)
                animTrack.TimePosition = 0.6
                task.wait(0.1)
                while doing and animTrack and animTrack.TimePosition < 0.7 do task.wait(0.05) end
                if animTrack then animTrack:Stop(); animTrack:Destroy(); animTrack = nil end
            end
        end)

        local function stopAnim()
            doing = false
            if animTrack then animTrack:Stop(); animTrack:Destroy(); animTrack = nil end
        end

        jerkTool.Unequipped:Connect(stopAnim)
        local hum = plr.Character and plr.Character:FindFirstChild("Humanoid")
        if hum then hum.Died:Connect(stopAnim) end

        respawnConnection = plr.CharacterAdded:Connect(function(char)
            local ff = char:FindFirstChildOfClass("ForceField")
            if ff then ff.AncestryChanged:Wait() end
            createTool()
        end)
    end

    local function removeTool()
        if jerkTool then jerkTool:Destroy() jerkTool = nil end
        local existing = workspace:FindFirstChild("aaa")
        if existing then existing:Destroy() end
        if respawnConnection then respawnConnection:Disconnect() respawnConnection = nil end
    end

    group:AddToggle("jerk_toggle", {
        Text = "Jerk Tool",
        Default = false,
        Callback = function(state)
            if state then createTool() else removeTool() end
        end
    })
end

do
    local group = extrasTab:AddRightGroupbox("Inventory Sorter")

    group:AddToggle("sort_toggle", { Text = "Enable Sorter", Default = false })

    group:AddLabel("Press to sort")
        :AddKeyPicker("sort_keybind", {
            Default = "I",
            Mode = "Hold",
            Text = "Sort Inventory Key",
            NoUI = false
        })

    local weaponOptions = {
        "(Empty)",
        
        "[Double-Barrel SG]", "[TacticalShotgun]", "[Drum-Shotgun]", "[Shotgun]",
        "[Glock]", "[Revolver]", "[Flintlock]", "[Silencer]", "[Pistol]",
        "[DrumGun]", "[SMG]", "[P90]",
        "[Rifle]", "[AUG]", "[SilencerAR]", "[AR]", "[AK-47]",
        "[LMG]", "[Flamethrower]", "[GrenadeLauncher]", "[RPG]",
        "[Knife]", "[Food]", "[Grenade]", "[Flashbang]", "[Whip]"
    }

    for i = 1, 10 do
        group:AddDropdown("gun_sort_slot_" .. i, {
            Values = weaponOptions,
            Default = 1,
            Multi = false,
            Text = "Slot " .. i
        })
    end

    local inputConnection
    local function isFood(name)
        name = string.lower(name)
        return name:find("hamburger") or name:find("pizza") or name:find("chicken") or name:find("popcorn")
            or name:find("milk") or name:find("meat") or name:find("taco") or name:find("donut")
            or name:find("hotdog") or name:find("cranberry")
    end

    local function preciseSort()
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if not backpack then return end

        local tools = {}
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then table.insert(tools, item) end
        end

        local temp = Instance.new("Folder")
        temp.Name = "TempInventory"
        temp.Parent = workspace
        for _, tool in ipairs(tools) do tool.Parent = temp end
        task.wait(0.2)

        local used, slotList = {}, {}
        for i = 1, 10 do
            local v = Options["gun_sort_slot_" .. i] and Options["gun_sort_slot_" .. i].Value
            slotList[i] = v and v ~= "(Empty)" and string.lower(v) or nil
        end

        for _, name in ipairs(slotList) do
            for _, tool in ipairs(tools) do
                if tool.Parent == temp and not used[tool] then
                    local lname = string.lower(tool.Name)
                    local match = name == "[food]" and isFood(lname) or lname == name
                    if match then
                        tool.Parent = backpack
                        used[tool] = true
                        break
                    end
                end
            end
        end

        for _, tool in ipairs(tools) do
            if tool.Parent == temp then
                tool.Parent = backpack
            end
        end

        temp:Destroy()
    end

    Toggles.sort_toggle:OnChanged(function(state)
        if inputConnection then inputConnection:Disconnect() inputConnection = nil end
        if state then
            inputConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
                if processed then return end
                local key = Options.sort_keybind
                if key and key:GetState() then
                    preciseSort()
                end
            end)
            table.insert(framework.connections, inputConnection)
        end
    end)
end

local spinGroup = extrasTab:AddLeftGroupbox("Character Spin")
spinGroup:AddToggle("char_spin", { Text = "Character Spin", Default = true })

spinGroup:AddSlider("spin_speed", {
    Text = "Spin Speed",
    Default = 50,
    Min = 1,
    Max = 50,
    Rounding = 0
})

spinGroup:AddLabel("Toggle Key"):AddKeyPicker("char_spin_keybind", {
    Default = "LeftAlt",
    Mode = "Toggle",
    Text = "Character Spin",
    NoUI = false,
    Callback = function()
        local mode = Options.char_spin_keybind.Mode
        if mode == "Toggle" and Toggles.char_spin.Value then
            framework.spinActive = not framework.spinActive
        end
    end
})

table.insert(framework.connections, RunService.Heartbeat:Connect(function()
    if not Toggles.char_spin.Value then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.AutoRotate = true
        end
        return
    end

    local keybindOption = Options.char_spin_keybind
    local isActive = false

    if keybindOption.Mode == "Always" then
        isActive = true
    elseif keybindOption.Mode == "Hold" then
        isActive = keybindOption:GetState()
    elseif keybindOption.Mode == "Toggle" then
        isActive = framework.spinActive
    end

    if not isActive then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.AutoRotate = true
        end
        return
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    LocalPlayer.Character.Humanoid.AutoRotate = false
    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Options.spin_speed.Value), 0)
end))

local tpGroup = extrasTab:AddLeftGroupbox("Teleport to player")

local function getPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    return list
end

local selectedPlayer, originalPosition

tpGroup:AddDropdown("MyDropdown", {
    Values = getPlayers(),
    Default = 1,
    Multi = false,
    Text = "Select Player",
    Tooltip = "Select a player to teleport to",
    Callback = function(v) selectedPlayer = v end
})

tpGroup:AddButton("Teleport", function()
    local target = Players:FindFirstChild(selectedPlayer)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        originalPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
        LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
    end
end)

tpGroup:AddButton("Teleport Back", function()
    if originalPosition then
        LocalPlayer.Character.HumanoidRootPart.CFrame = originalPosition
    end
end)

local multiToolGroup = extrasTab:AddRightGroupbox("Multi tool")

if Toggles.gun_auto_ammo then
    Toggles.gun_auto_ammo.Value = false
end

local allowedTools = {
    ["[Rifle]"] = true,
    ["[Double-Barrel SG]"] = true,
    ["[AUG]"] = true
}

framework.ragebotActive = false
framework.multiToolActive = false
framework.toolsUnequippedForRagebot = false
framework.equippedTools = {}
framework.connections = {}

local function isRagebotActive()
    return getgenv().ragebotActive or false
end

multiToolGroup:AddToggle("multi_tool_toggle", {
    Text = "Multi Tool",
    Default = true,
    Tooltip = "Enable/disable multi tool globally.",
    Callback = function()
        local toggle = Toggles.multi_tool_toggle
        if not toggle then return end

        if not (framework.ragebotActive or isRagebotActive()) then
            framework.multiToolActive = toggle.Value
        else
            toggle.Value = false
            framework.multiToolActive = false
        end
    end
})

multiToolGroup:AddLabel("Toggle Key"):AddKeyPicker("char_multi_tool_keybind", {
    Default = "L",
    Mode = "Toggle",
    Text = "Multi Tool",
    NoUI = false,
    Callback = function()
        local keybind = Options.char_multi_tool_keybind
        if not keybind then return end

        if framework.ragebotActive or isRagebotActive() then
            framework.multiToolActive = false
            local toggle = Toggles.multi_tool_toggle
            if toggle then toggle.Value = false end

            for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
                if tool:IsA("Tool") then
                    tool.Parent = LocalPlayer.Backpack
                end
            end
        else
            if keybind.Mode == "Toggle" then
                framework.multiToolActive = not framework.multiToolActive
                local toggle = Toggles.multi_tool_toggle
                if toggle then toggle.Value = framework.multiToolActive end
            end
        end
    end
})

local function equipAndTrackTools()
    local char = LocalPlayer.Character
    if not char then return end

    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and allowedTools[tool.Name] and tool.Parent ~= char then
            tool.Parent = char
        end
    end

    table.clear(framework.equippedTools)
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and allowedTools[tool.Name] then
            table.insert(framework.equippedTools, tool)
        end
    end
end

local lastFiredTimes = {}
local TOOL_FIRE_DELAY = {
    ["[Rifle]"] = 0.3,
    ["[Double-Barrel SG]"] = 0.3,
    ["[AUG]"] = 0
}

local function simulateShooting(tool)
    if tool:IsA("Tool") then
        local clickDetector = tool:FindFirstChildOfClass("ClickDetector")
        if clickDetector then
            pcall(function()
                clickDetector.MouseClick:Fire()
            end)
        else
            pcall(function()
                if tool.Activate then
                    tool:Activate()
                end
            end)
        end
    end
end

local lastEquipTime = tick()

task.spawn(function()
    while true do
        local rageEnabled = Toggles.ragebot_enabled
        local rageKeybind = Options.ragebot_keybind
        local rageActive = (rageEnabled and rageEnabled.Value and rageKeybind and rageKeybind:GetState())

        if rageActive and not framework.ragebotActive then
            framework.ragebotActive = true
            framework.multiToolActive = false
            if Toggles.multi_tool_toggle then
                Toggles.multi_tool_toggle.Value = false
            end

            if not framework.toolsUnequippedForRagebot then
                framework.toolsUnequippedForRagebot = true
                for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
                    if tool:IsA("Tool") then
                        tool.Parent = LocalPlayer.Backpack
                    end
                end
            end
        elseif not rageActive and framework.ragebotActive then
            framework.ragebotActive = false
            framework.toolsUnequippedForRagebot = false

            if Toggles.multi_tool_toggle and Toggles.multi_tool_toggle.Value then
                framework.multiToolActive = true
            end
        end

        task.wait(0.1)
    end
end)

table.insert(framework.connections, RunService.RenderStepped:Connect(function()
    if framework.ragebotActive or isRagebotActive() then return end

    local keybind = Options.char_multi_tool_keybind
    local toggle = Toggles.multi_tool_toggle
    if not keybind or not toggle or not toggle.Value then return end

    local active = false
    if keybind.Mode == "Always" then
        active = true
    elseif keybind.Mode == "Hold" then
        active = keybind:GetState()
    elseif keybind.Mode == "Toggle" then
        active = framework.multiToolActive
    end

    if not active then return end

    equipAndTrackTools()
    local now = tick()

    if now - lastEquipTime >= 0.5 then
        for _, tool in ipairs(framework.equippedTools) do
            if tool and tool.Parent == LocalPlayer.Character then
                tool.Parent = LocalPlayer.Backpack
            end
        end
        equipAndTrackTools()
        lastEquipTime = now
    end

    for _, tool in ipairs(framework.equippedTools) do
        if tool and tool.Parent == LocalPlayer.Character then
            local delay = TOOL_FIRE_DELAY[tool.Name] or 0.2
            if now - (lastFiredTimes[tool] or 0) >= delay then
                lastFiredTimes[tool] = now
                simulateShooting(tool)
            end
        end
    end
end))

local equippedToolsBackup = {}

for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
    if tool:IsA("Tool") then
        table.insert(equippedToolsBackup, tool)
    end
end

function api:Unload()
    for _, connection in pairs(framework.connections) do
        pcall(function() connection:Disconnect() end)
    end

    for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Parent = LocalPlayer.Backpack
        end
    end

    table.clear(framework.equippedTools)

    framework.multiToolActive = false
    framework.ragebotActive = false
    framework.toolsUnequippedForRagebot = false
    framework.spinActive = false
    framework.antiSitActive = false
    framework.antiFlingActive = false

    if Toggles.multi_tool_toggle then
        Toggles.multi_tool_toggle.Value = false
    end
end
-- created by hvhgui and envert. special thanks to ender for helping out with toggle variables (ragebot and auto ammo)
