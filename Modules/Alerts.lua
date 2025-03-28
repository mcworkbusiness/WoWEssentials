-- WoW Essentials Alerts Module
-- Handles boss alerts and special ability notifications

local WE = WoWEssentials
local AlertsModule = WE:NewModule("Alerts", true)
local _G = _G

-- Local variables
local alertFrame
local currentAlerts = {}
local activeTimers = {}
local knownBosses = {}
local knownMechanics = {}

-- Initialize module
function AlertsModule:Initialize()
    -- Create main alerts container frame
    self.container = CreateFrame("Frame", "WoWEssentialsAlertsContainer", UIParent)
    self.container:SetPoint("CENTER", 0, 200)
    self.container:SetSize(400, 100)
    
    -- Initialize known boss mechanics database
    self:InitBossDatabase()
    
    -- Register slash command specific to Alerts module
    _G["SLASH_WEALERTS1"] = "/wealerts"
    SlashCmdList["WEALERTS"] = function(msg)
        self:HandleCommands(msg)
    end
end

-- Handle Alerts specific slash commands
function AlertsModule:HandleCommands(msg)
    local args = {}
    for arg in string.gmatch(msg, "%S+") do
        table.insert(args, string.lower(arg))
    end
    
    local command = args[1]
    
    if command == "test" then
        self:TestAlert("Test Alert", "This is a test alert message", 3)
        WE:Print("Showing test alert")
    elseif command == "sound" and args[2] then
        local enabled = args[2] == "on" or args[2] == "true" or args[2] == "1"
        WE:SetConfig("modules.Alerts.sound", enabled)
        WE:Print("Alert sounds " .. (enabled and "enabled" : "disabled"))
    elseif command == "visual" and args[2] then
        local enabled = args[2] == "on" or args[2] == "true" or args[2] == "1"
        WE:SetConfig("modules.Alerts.visual", enabled)
        WE:Print("Visual alerts " .. (enabled and "enabled" : "disabled"))
    elseif command == "text" and args[2] then
        local enabled = args[2] == "on" or args[2] == "true" or args[2] == "1"
        WE:SetConfig("modules.Alerts.text", enabled)
        WE:Print("Text alerts " .. (enabled and "enabled" : "disabled"))
    elseif command == "bossonly" and args[2] then
        local enabled = args[2] == "on" or args[2] == "true" or args[2] == "1"
        WE:SetConfig("modules.Alerts.bossOnly", enabled)
        WE:Print("Boss-only mode " .. (enabled and "enabled" : "disabled"))
    elseif command == "threshold" and args[2] then
        local value = tonumber(args[2])
        if value and value >= 0 and value <= 100 then
            WE:SetConfig("modules.Alerts.threshold", value)
            WE:Print("Health threshold set to " .. value .. "%")
        else
            WE:Print("Threshold must be between 0 and 100")
        end
    else
        WE:Print("Alerts module commands:")
        WE:Print("/wealerts test - Show a test alert")
        WE:Print("/wealerts sound on|off - Toggle sound alerts")
        WE:Print("/wealerts visual on|off - Toggle visual alerts")
        WE:Print("/wealerts text on|off - Toggle text alerts")
        WE:Print("/wealerts bossonly on|off - Toggle boss-only mode")
        WE:Print("/wealerts threshold [0-100] - Set health percentage threshold for alerts")
    end
end

-- Called when the module is enabled
function AlertsModule:OnEnable()
    -- Create or update alerts frame
    self:CreateAlertsFrame()
    
    -- Register for necessary events
    WE:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function() self:ProcessCombatLog() end)
    WE:RegisterEvent("UNIT_HEALTH", function(unit) self:MonitorHealth(unit) end)
    WE:RegisterEvent("PLAYER_TARGET_CHANGED", function() self:CheckTargetForMechanics() end)
    WE:RegisterEvent("ENCOUNTER_START", function(encounterId, encounterName) self:BossEncounterStarted(encounterId, encounterName) end)
    WE:RegisterEvent("ENCOUNTER_END", function() self:BossEncounterEnded() end)
end

-- Called when the module is disabled
function AlertsModule:OnDisable()
    -- Hide alerts frame
    if self.container then
        self.container:Hide()
    end
    
    -- Cancel any active timers
    for _, timer in pairs(activeTimers) do
        if timer then
            timer:Cancel()
        end
    end
    
    -- Unregister events
    WE:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    WE:UnregisterEvent("UNIT_HEALTH")
    WE:UnregisterEvent("PLAYER_TARGET_CHANGED")
    WE:UnregisterEvent("ENCOUNTER_START")
    WE:UnregisterEvent("ENCOUNTER_END")
end

-- Create the alerts display frame
function AlertsModule:CreateAlertsFrame()
    if self.alertsFrame then
        return self.alertsFrame
    end
    
    local frame = CreateFrame("Frame", "WoWEssentialsAlertsFrame", self.container)
    frame:SetSize(400, 100)
    frame:SetPoint("CENTER", self.container, "CENTER")
    
    -- Create background texture
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.7)
    
    -- Create border
    frame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropBorderColor(1, 0, 0, 0.8)
    
    -- Create title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetTextColor(1, 0.3, 0.3)
    
    -- Create description text
    local description = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    description:SetPoint("TOP", title, "BOTTOM", 0, -5)
    description:SetPoint("LEFT", frame, "LEFT", 20, 0)
    description:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
    description:SetTextColor(1, 1, 1)
    
    -- Create timer text
    local timer = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    timer:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    timer:SetTextColor(1, 1, 0)
    
    -- Store references
    frame.title = title
    frame.description = description
    frame.timer = timer
    
    -- Hide initially
    frame:Hide()
    
    self.alertsFrame = frame
    return frame
end

-- Initialize boss mechanics database
function AlertsModule:InitBossDatabase()
    -- This would be expanded with actual boss mechanics data
    -- For now, just a small sample for testing purposes
    knownBosses = {
        [2482] = { -- Example boss ID (Chronormu from Trial of Infinity)
            name = "Chronormu",
            mechanics = {
                {
                    spellId = 400641, -- Time Spiral
                    alertText = "Time Spiral - MOVE AWAY",
                    description = "Move away from other players",
                    sound = "Interface\\AddOns\\WoWEssentials\\Sounds\\alarm.mp3",
                    color = {r = 0.7, g = 0.4, b = 1.0}
                },
                {
                    spellId = 401029, -- Borrowed Time
                    alertText = "Borrowed Time - SPREAD",
                    description = "Spread out to avoid chain damage",
                    sound = "Interface\\AddOns\\WoWEssentials\\Sounds\\alarm.mp3",
                    color = {r = 1.0, g = 0.4, b = 0.4}
                }
            }
        }
    }
    
    -- Build lookup table for quick spell checking
    for _, boss in pairs(knownBosses) do
        for _, mechanic in ipairs(boss.mechanics) do
            knownMechanics[mechanic.spellId] = mechanic
        end
    end
end

-- Process combat log events for alerts
function AlertsModule:ProcessCombatLog()
    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName = CombatLogGetCurrentEventInfo()
    
    -- Check if we care about this event type
    if event == "SPELL_CAST_START" or event == "SPELL_AURA_APPLIED" then
        -- Check if this is a known mechanic
        if knownMechanics[spellId] then
            local mechanic = knownMechanics[spellId]
            self:ShowAlert(mechanic.alertText, mechanic.description, 3, mechanic.sound, mechanic.color)
        end
    end
end

-- Monitor unit health for low health alerts
function AlertsModule:MonitorHealth(unit)
    if not unit then return end
    
    local threshold = WE:GetConfig("modules.Alerts.threshold", 75)
    local bossOnly = WE:GetConfig("modules.Alerts.bossOnly", false)
    
    -- Only alert for player, target, focus, boss units
    if unit ~= "player" and unit ~= "target" and unit ~= "focus" and not string.match(unit, "^boss%d$") then
        return
    end
    
    -- Skip if boss only mode and this isn't a boss
    if bossOnly and not UnitClassification(unit) == "worldboss" and not string.match(unit, "^boss%d$") then
        return
    end
    
    local healthPercent = (UnitHealth(unit) / UnitHealthMax(unit)) * 100
    
    if healthPercent <= threshold then
        -- Avoid spam by checking if we've recently alerted for this unit
        local unitName = UnitName(unit)
        if not currentAlerts[unitName] then
            currentAlerts[unitName] = true
            
            -- Show low health alert
            local alertText = string.format("%s Low Health!", unitName)
            local description = string.format("%s is at %d%% health", unitName, floor(healthPercent))
            self:ShowAlert(alertText, description, 2, nil, {r = 1.0, g = 0.0, b = 0.0})
            
            -- Clear this alert after 5 seconds to avoid spam
            C_Timer.After(5, function()
                currentAlerts[unitName] = nil
            end)
        end
    end
end

-- Check target for known mechanics
function AlertsModule:CheckTargetForMechanics()
    if not UnitExists("target") then return end
    
    local targetName = UnitName("target")
    local targetGUID = UnitGUID("target")
    
    -- Check if this is a known boss
    for id, boss in pairs(knownBosses) do
        if targetName == boss.name then
            WE:Print(string.format("Target is a known boss: %s", targetName))
        end
    end
end

-- Handle boss encounter started
function AlertsModule:BossEncounterStarted(encounterId, encounterName)
    WE:Print(string.format("Boss encounter started: %s", encounterName))
    
    -- Check if we have data for this boss
    if knownBosses[encounterId] then
        local boss = knownBosses[encounterId]
        WE:Print(string.format("WoW Essentials has alerts for %s", boss.name))
        
        -- Could show initial encounter alert here
        self:ShowAlert("Boss Encounter", string.format("%s - Prepare for battle!", encounterName), 3)
    end
end

-- Handle boss encounter ended
function AlertsModule:BossEncounterEnded()
    -- Clear any active alerts
    if self.alertsFrame and self.alertsFrame:IsShown() then
        self.alertsFrame:Hide()
    end
    
    -- Cancel any active timers
    for timerId, timer in pairs(activeTimers) do
        if timer then
            timer:Cancel()
        end
        activeTimers[timerId] = nil
    end
end

-- Show an alert to the player
function AlertsModule:ShowAlert(title, description, duration, soundFile, color)
    -- Check if alerts are enabled
    local visualEnabled = WE:GetConfig("modules.Alerts.visual", true)
    local soundEnabled = WE:GetConfig("modules.Alerts.sound", true)
    local textEnabled = WE:GetConfig("modules.Alerts.text", true)
    
    -- Default duration
    duration = duration or 3
    
    -- Text alert
    if textEnabled then
        WE:Print(string.format("%s: %s", title, description))
    end
    
    -- Visual alert
    if visualEnabled then
        local frame = self.alertsFrame or self:CreateAlertsFrame()
        
        -- Set text
        frame.title:SetText(title)
        frame.description:SetText(description)
        frame.timer:SetText(duration .. "s")
        
        -- Set color if provided
        if color then
            frame:SetBackdropBorderColor(color.r, color.g, color.b, 0.8)
            frame.title:SetTextColor(color.r, color.g, color.b)
        else
            frame:SetBackdropBorderColor(1, 0, 0, 0.8)
            frame.title:SetTextColor(1, 0.3, 0.3)
        end
        
        -- Show the frame
        frame:Show()
        
        -- Start countdown timer
        local countdownTime = duration
        local timerId = tostring(time()) .. "-" .. tostring(math.random(1000))
        
        -- Cancel any existing timer
        if activeTimers.countdown then
            activeTimers.countdown:Cancel()
        end
        
        -- Create new timer
        activeTimers.countdown = C_Timer.NewTicker(1, function(self)
            countdownTime = countdownTime - 1
            frame.timer:SetText(countdownTime .. "s")
            
            if countdownTime <= 0 then
                frame:Hide()
                activeTimers.countdown = nil
            end
        end, duration)
    end
    
    -- Sound alert
    if soundEnabled then
        if soundFile then
            PlaySoundFile(soundFile, "Master")
        else
            -- Default alert sound
            PlaySound(SOUNDKIT.RAID_WARNING, "Master")
        end
    end
end

-- Test alert function
function AlertsModule:TestAlert(title, description, duration)
    self:ShowAlert(title or "Test Alert", 
                   description or "This is a test alert message", 
                   duration or 3,
                   nil,
                   {r = 0.0, g = 1.0, b = 0.5})
end

-- Handle configuration changes
function AlertsModule:OnConfigChanged()
    -- Nothing specific needed here for now
end

-- Return the module
WE.AlertsModule = AlertsModule 