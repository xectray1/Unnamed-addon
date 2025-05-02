local api = getfenv().api or {}
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChatService = game:GetService("Chat")
local UserInputService = game:GetService("UserInputService")
local Heartbeat = RunService.Heartbeat

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

local miscGroup = extrasTab:AddLeftGroupbox("Misc")

local silentBlockToggle = miscGroup:AddToggle("god_block", {
    Text = "God Block",
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

do
    local group = miscGroup 

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

miscGroup:AddToggle("anti_fling", {
    Text = "Anti-Fling",
    Default = false,
})

miscGroup:AddButton("Force Reset", function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end
    api:Notify("Character reset", 2)
end)

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
                    parts[part] = {
                        CanCollide = part.CanCollide,
                        Massless = part.Name == "Torso" and part.Massless or false
                    }
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

        if jerkTool and jerkTool.Parent == pack then
            return 
        end

        if jerkTool then
            jerkTool:Destroy()
        end

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
            removeTool()
            createTool()
        end)
    end

    local function removeTool()
        if jerkTool then
            jerkTool:Destroy()
            jerkTool = nil
        end
        local existing = workspace:FindFirstChild("aaa")
        if existing then existing:Destroy() end
        if respawnConnection then
            respawnConnection:Disconnect()
            respawnConnection = nil
        end
    end

    group:AddToggle("jerk_toggle", {
        Text = "Jerk Tool",
        Default = false,
        Callback = function(state)
            if state then createTool() else removeTool() end
        end
    })

    local words = {
        "where are you aiming at?",
        "sonned",
        "bad",
        "even my grandma has faster reactions",
        ":clown:",
        "gg = get good",
        "im just better",
        "my gaming chair is just better",
        "clip me",
        "skill",
        ":Skull:",
        "go play adopt me",
        "go play brookhaven",
        "omg you are so good :screm:",
        "awesome",
        "fridge",
        "do not bully pliisss :sobv:",
        "it was your lag ofc",
        "fly high",
        "*cough* *cough*",
        "son",
        "already mad?",
        "please don't report :sobv:",
        "sob harder",
        "UE on top",
        "alt + f4 for better aim",
        "Get sonned",
        "Where are you aiming? 💀",
        "You just got outplayed...",
        "Omg you're so good... said no one ever",
        "You built like Gru, but with zero braincells 💀",
        "Fly high but your aim is still low 😹",
        "Bet you've never heard of UE",
        "UE is best, sorry but its facts",
        "UE > your skills 😭",
        "UE always wins",
        "UE doesn't miss, unlike you 💀",
        "UE made me get ekittens"
    }

    local enabled = false

    group:AddToggle("autotrash_e", { Text = "Trash Talk", Default = false }):OnChanged(function(v)
        enabled = v
    end)

    table.insert(framework.connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or not enabled then return end
        if input.KeyCode == Enum.KeyCode.E then
            local msg = words[math.random(1, #words)]
            local legacy = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")

            if legacy then
                local event = legacy:FindFirstChild("SayMessageRequest")
                if event then event:FireServer(msg, "All") end
            else
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
                    ChatService:Chat(LocalPlayer.Character.Head, msg, Enum.ChatColor.Red)
                end
            end

            api:Notify("Trash: " .. msg, 1.5)
        end
    end))

   group:AddToggle("anti_rpg", {
        Text = "Anti RPG",
        Default = true,
    }):OnChanged(function(v)
        framework.antiRpgActive = v
    end)

    local function find_first_child(obj, name)
        return obj and obj:FindFirstChild(name)
    end

    local function GetLauncher()
        return find_first_child(workspace, "Ignored")
           and find_first_child(workspace.Ignored, "Model")
           and find_first_child(workspace.Ignored.Model, "Launcher")
    end

    local function IsLauncherNear()
        local HRP = LocalPlayer.Character and find_first_child(LocalPlayer.Character, "HumanoidRootPart")
        local Launcher = GetLauncher()

        if not HRP or not Launcher then return false end
        return (Launcher.Position - HRP.Position).Magnitude < 16
    end

    local function GetLauncherImpactPosition()
        local Launcher = GetLauncher()
        if not Launcher then return end
        return Launcher.Position + (Launcher.CFrame.LookVector * 10)
    end

    local function TeleportBehindImpact(impactPosition)
        local HRP = LocalPlayer.Character and find_first_child(LocalPlayer.Character, "HumanoidRootPart")
        if not HRP then return end

        local direction = (impactPosition - HRP.Position).Unit
        local targetPosition = HRP.Position + (direction * 20)
        HRP.CFrame = CFrame.new(targetPosition)
    end

    table.insert(framework.connections, RunService.Heartbeat:Connect(function()
        if not framework.antiRpgActive then return end

        if IsLauncherNear() then
            local impactPosition = GetLauncherImpactPosition()
            if impactPosition then
                TeleportBehindImpact(impactPosition)
            end
        end
    end))
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
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    return list
end

local selectedPlayer, originalPosition
local searchResultLabel

local playerDropdown = tpGroup:AddDropdown("PlayerDropdown", {
    Values = getPlayers(),
    Default = 1,
    Multi = false,
    Text = "Select Player",
    Tooltip = "Select a player to teleport to",
    Callback = function(v)
        selectedPlayer = v
        if searchResultLabel then
            searchResultLabel:SetText("Selected: " .. selectedPlayer)
        end
    end
})

searchResultLabel = tpGroup:AddLabel("Selected: None")

tpGroup:AddInput("PlayerSearchBox", {
    Default = "",
    Numeric = false,
    Finished = true,
    Text = "Search Player",
    Tooltip = "Type the name or display name of a player and press Enter to select them",
    Placeholder = "Enter name or display name",
    Callback = function(value)
        local trimmed = value:lower():gsub("^%s*(.-)%s*$", "%1")
        local match = nil

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local displayName = p.DisplayName:lower()
                local username = p.Name:lower()

                if displayName:sub(1, #trimmed) == trimmed or username:sub(1, #trimmed) == trimmed then
                    match = p.Name 
                    break
                end
            end
        end

        if match then
            selectedPlayer = match
            searchResultLabel:SetText("Selected: " .. selectedPlayer)
        else
            selectedPlayer = nil
            searchResultLabel:SetText("Selected: No match")
        end
    end
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

local function refreshPlayerList()
    local playerList = getPlayers()
    if playerDropdown then
        playerDropdown.Values = playerList
        playerDropdown:SetValues(playerList)
    end
end

Players.PlayerAdded:Connect(function()
    task.wait(0.1)
    refreshPlayerList()
end)

Players.PlayerRemoving:Connect(function()
    task.wait(0.1)
    refreshPlayerList()
end)

local group = extrasTab:AddRightGroupbox("Character")

group:AddToggle("no_jump_cd", {
    Text = "No Jump Cooldown",
    Default = false
})

table.insert(framework.connections, RunService.Heartbeat:Connect(function()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        if Toggles.no_jump_cd and Toggles.no_jump_cd.Value then
            if hum.UseJumpPower ~= false then
                hum.UseJumpPower = false 
            end
        else
            if hum.UseJumpPower ~= true then
                hum.UseJumpPower = true 
            end
        end
    end
end))

local lastDeathPosition = nil

local function trackCharacter(char)
    local hum = char:WaitForChild("Humanoid")
    local hrp = char:WaitForChild("HumanoidRootPart")

    hum.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Dead and hrp then
            lastDeathPosition = hrp.Position
        end
    end)
end

if LocalPlayer.Character then
    trackCharacter(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    trackCharacter(char)
end)

group:AddButton("Flashback", function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and lastDeathPosition then
        hrp.CFrame = CFrame.new(lastDeathPosition + Vector3.new(0, 5, 0))
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
-- created by hvhgui/createremotethread, envert and unnamed toggle variables provided by ender
