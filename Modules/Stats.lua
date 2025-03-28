-- WoW Essentials Stats Module
-- Provides combat statistics tracking and display

local WE = WoWEssentials
local StatsModule = WE:NewModule("Stats", true)
local _G = _G

-- Local variables
local combatData = {}
local currentCombat = nil
local statsFrame
local isInCombat = false
local updateTimer

-- Initialize module
function StatsModule:Initialize()
    -- Create container frame
    self.container = CreateFrame("Frame", "WoWEssentialsStatsContainer", UIParent)
    self.container:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -20, 180)
    self.container:SetSize(200, 100)
    
    -- Register slash command
    _G["SLASH_WESTATS1"] = "/westats"
    SlashCmdList["WESTATS"] = function(msg)
        self:HandleCommands(msg)
    end
end

-- Handle module-specific slash commands
function StatsModule:HandleCommands(msg)
    local args = {}
    for arg in string.gmatch(msg, "%S+") do
        table.insert(args, string.lower(arg))
    end
    
    local command = args[1]
    
    if command == "show" then
        self:ShowStats()
        WE:Print("Showing stats window")
    elseif command == "hide" then
        self:HideStats()
        WE:Print("Hiding stats window")
    elseif command == "reset" then
        self:ResetStats()
        WE:Print("Stats reset")
    elseif command == "dps" and args[2] then
        local enabled = args[2] == "on" or args[2] == "true" or args[2] == "1"
        WE:SetConfig("modules.Stats.showDps", enabled)
        WE:Print("DPS display " .. (enabled and "enabled" or "disabled"))
        self:UpdateStatsDisplay()
    elseif command == "hps" and args[2] then
        local enabled = args[2] == "on" or args[2] == "true" or args[2] == "1"
        WE:SetConfig("modules.Stats.showHps", enabled)
        WE:Print("HPS display " .. (enabled and "enabled" or "disabled"))
        self:UpdateStatsDisplay()
    elseif command == "combatonly" and args[2] then
        local enabled = args[2] == "on" or args[2] == "true" or args[2] == "1"
        WE:SetConfig("modules.Stats.combatOnly", enabled)
        WE:Print("Combat-only mode " .. (enabled and "enabled" or "disabled"))
        -- Update display visibility
        if not isInCombat and enabled and statsFrame and statsFrame:IsShown() then
            statsFrame:Hide()
        elseif not enabled and statsFrame and not statsFrame:IsShown() then
            statsFrame:Show()
        end
    elseif command == "window" and args[2] then
        local window = tonumber(args[2])
        if window and window >= 5 and window <= 300 then
            WE:SetConfig("modules.Stats.window", window)
            WE:Print("Stats window set to " .. window .. " seconds")
        else
            WE:Print("Window must be between 5 and 300 seconds")
        end
    elseif command == "threshold" and args[2] then
        local threshold = tonumber(args[2])
        if threshold and threshold >= 0 then
            WE:SetConfig("modules.Stats.threshold", threshold)
            WE:Print("Display threshold set to " .. threshold)
            self:UpdateStatsDisplay()
        else
            WE:Print("Threshold must be a non-negative number")
        end
    else
        WE:Print("Stats module commands:")
        WE:Print("/westats show - Show stats window")
        WE:Print("/westats hide - Hide stats window")
        WE:Print("/westats reset - Reset all stats")
        WE:Print("/westats dps on|off - Toggle DPS display")
        WE:Print("/westats hps on|off - Toggle HPS display")
        WE:Print("/westats combatonly on|off - Toggle combat-only mode")
        WE:Print("/westats window [seconds] - Set time window (5-300)")
        WE:Print("/westats threshold [value] - Set minimum threshold to display")
    end
end

-- Called when the module is enabled
function StatsModule:OnEnable()
    -- Create the stats frame if it doesn't exist
    if not statsFrame then
        self:CreateStatsFrame()
    end
    
    -- Register for events
    WE:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function() self:ProcessCombatLog() end)
    WE:RegisterEvent("PLAYER_REGEN_DISABLED", function() self:EnterCombat() end)
    WE:RegisterEvent("PLAYER_REGEN_ENABLED", function() self:LeaveCombat() end)
    
    -- Start with a clean slate
    self:ResetStats()
    
    -- Show frame if not in combat-only mode
    if not WE:GetConfig("modules.Stats.combatOnly", true) then
        statsFrame:Show()
    else
        statsFrame:Hide()
    end
    
    -- Set up update timer
    if not updateTimer then
        updateTimer = C_Timer.NewTicker(1, function() self:UpdateStatsDisplay() end)
    end
end

-- Called when the module is disabled
function StatsModule:OnDisable()
    -- Hide stats frame
    if statsFrame then
        statsFrame:Hide()
    end
    
    -- Cancel update timer
    if updateTimer then
        updateTimer:Cancel()
        updateTimer = nil
    end
    
    -- Unregister events
    WE:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    WE:UnregisterEvent("PLAYER_REGEN_DISABLED")
    WE:UnregisterEvent("PLAYER_REGEN_ENABLED")
end

-- Create the stats display frame
function StatsModule:CreateStatsFrame()
    local frame = CreateFrame("Frame", "WoWEssentialsStatsFrame", self.container)
    frame:SetSize(200, 100)
    frame:SetPoint("CENTER", self.container, "CENTER")
    
    -- Background
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.7)
    
    -- Border
    frame:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -8)
    title:SetText("WoW Essentials Stats")
    
    -- DPS Text
    local dpsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dpsLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
    dpsLabel:SetText("DPS:")
    
    local dpsValue = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    dpsValue:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -30)
    dpsValue:SetJustifyH("RIGHT")
    dpsValue:SetText("0")
    
    -- HPS Text
    local hpsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hpsLabel:SetPoint("TOPLEFT", dpsLabel, "BOTTOMLEFT", 0, -10)
    hpsLabel:SetText("HPS:")
    
    local hpsValue = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    hpsValue:SetPoint("TOPRIGHT", dpsValue, "BOTTOMRIGHT", 0, -10)
    hpsValue:SetJustifyH("RIGHT")
    hpsValue:SetText("0")
    
    -- Combat Timer Text
    local timerLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timerLabel:SetPoint("TOPLEFT", hpsLabel, "BOTTOMLEFT", 0, -10)
    timerLabel:SetText("Time:")
    
    local timerValue = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timerValue:SetPoint("TOPRIGHT", hpsValue, "BOTTOMRIGHT", 0, -10)
    timerValue:SetJustifyH("RIGHT")
    timerValue:SetText("00:00")
    
    -- Status Text (In Combat/Out of Combat)
    local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 8)
    statusText:SetText("Out of Combat")
    
    -- Make frame movable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    -- Right-click menu
    frame:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            self:StopMovingOrSizing()
            StatsModule:ShowContextMenu()
        end
    end)
    
    -- Store references
    frame.title = title
    frame.dpsLabel = dpsLabel
    frame.dpsValue = dpsValue
    frame.hpsLabel = hpsLabel
    frame.hpsValue = hpsValue
    frame.timerLabel = timerLabel
    frame.timerValue = timerValue
    frame.statusText = statusText
    
    -- Store the frame
    statsFrame = frame
    
    return frame
end

-- Create context menu for right-click
function StatsModule:ShowContextMenu()
    -- Check if menu exists
    if not self.contextMenu then
        self.contextMenu = CreateFrame("Frame", "WoWEssentialsStatsContextMenu", UIParent, "UIDropDownMenuTemplate")
    end
    
    -- Build menu
    local menu = {
        {text = "WoW Essentials Stats", isTitle = true},
        {text = "Reset Stats", func = function() self:ResetStats() end},
        {text = "Show DPS", checked = WE:GetConfig("modules.Stats.showDps", true),
         func = function() 
             local current = WE:GetConfig("modules.Stats.showDps", true)
             WE:SetConfig("modules.Stats.showDps", not current)
             self:UpdateStatsDisplay()
         end},
        {text = "Show HPS", checked = WE:GetConfig("modules.Stats.showHps", true),
         func = function() 
             local current = WE:GetConfig("modules.Stats.showHps", true)
             WE:SetConfig("modules.Stats.showHps", not current)
             self:UpdateStatsDisplay()
         end},
        {text = "Combat Only", checked = WE:GetConfig("modules.Stats.combatOnly", true),
         func = function() 
             local current = WE:GetConfig("modules.Stats.combatOnly", true)
             WE:SetConfig("modules.Stats.combatOnly", not current)
             if not isInCombat and not current and statsFrame and not statsFrame:IsShown() then
                 statsFrame:Show()
             elseif not isInCombat and current and statsFrame and statsFrame:IsShown() then
                 statsFrame:Hide()
             end
         end},
        {text = "Close Menu", func = function() CloseDropDownMenus() end}
    }
    
    -- Display the menu
    EasyMenu(menu, self.contextMenu, "cursor", 0, 0, "MENU")
end

-- Enter combat
function StatsModule:EnterCombat()
    isInCombat = true
    
    -- Show the stats frame if hidden and in combat-only mode
    if WE:GetConfig("modules.Stats.combatOnly", true) and statsFrame and not statsFrame:IsShown() then
        statsFrame:Show()
    end
    
    -- Update status text
    if statsFrame then
        statsFrame.statusText:SetText("In Combat")
        statsFrame.statusText:SetTextColor(1, 0.3, 0.3)
    end
    
    -- Start a new combat session if none is active
    if not currentCombat then
        currentCombat = {
            startTime = GetTime(),
            endTime = nil,
            totalDamage = 0,
            totalHealing = 0,
            damageEvents = {},
            healingEvents = {}
        }
    end
end

-- Leave combat
function StatsModule:LeaveCombat()
    isInCombat = false
    
    -- Hide the stats frame if in combat-only mode
    if WE:GetConfig("modules.Stats.combatOnly", true) and statsFrame and statsFrame:IsShown() then
        statsFrame:Hide()
    end
    
    -- Update status text
    if statsFrame then
        statsFrame.statusText:SetText("Out of Combat")
        statsFrame.statusText:SetTextColor(0.5, 0.5, 0.5)
    end
    
    -- End the current combat session
    if currentCombat then
        currentCombat.endTime = GetTime()
        
        -- Store this combat in history
        table.insert(combatData, currentCombat)
        
        -- Keep only the last 10 combats to avoid memory bloat
        if #combatData > 10 then
            table.remove(combatData, 1)
        end
        
        -- Don't reset current combat yet to display final stats
    end
end

-- Process combat log events
function StatsModule:ProcessCombatLog()
    -- Get combat log event info
    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
          destGUID, destName, destFlags, destRaidFlags, param1, param2, param3 = CombatLogGetCurrentEventInfo()
    
    -- Skip if not in combat or not the player's actions
    if not currentCombat or sourceGUID ~= UnitGUID("player") then
        return
    end
    
    -- Process damage events
    if event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" or 
       event == "RANGE_DAMAGE" or event == "SWING_DAMAGE" then
        local amount = param1
        if event == "SWING_DAMAGE" then
            amount = param1
        else
            amount = param4
        end
        
        -- Record damage event
        table.insert(currentCombat.damageEvents, {
            timestamp = timestamp,
            amount = amount
        })
        
        -- Update total damage
        currentCombat.totalDamage = currentCombat.totalDamage + amount
    end
    
    -- Process healing events
    if event == "SPELL_HEAL" or event == "SPELL_PERIODIC_HEAL" then
        local amount = param4
        local overhealing = param5
        local absorbed = param6
        
        -- Subtract overhealing
        local effectiveHealing = amount - (overhealing or 0)
        
        -- Record healing event
        table.insert(currentCombat.healingEvents, {
            timestamp = timestamp,
            amount = effectiveHealing
        })
        
        -- Update total healing
        currentCombat.totalHealing = currentCombat.totalHealing + effectiveHealing
    end
end

-- Update the stats display
function StatsModule:UpdateStatsDisplay()
    if not statsFrame then return end
    
    -- Get current time
    local currentTime = GetTime()
    
    -- Calculate display values
    local combatTime = 0
    local dps = 0
    local hps = 0
    
    -- If in combat, calculate from current combat
    if currentCombat then
        -- Calculate combat duration
        combatTime = currentTime - currentCombat.startTime
        
        -- Get time window for calculations
        local window = WE:GetConfig("modules.Stats.window", 60)
        local windowStartTime = currentTime - window
        
        -- Calculate damage within window
        local damageDuringWindow = 0
        for _, event in ipairs(currentCombat.damageEvents) do
            if event.timestamp >= windowStartTime then
                damageDuringWindow = damageDuringWindow + event.amount
            end
        end
        
        -- Calculate healing within window
        local healingDuringWindow = 0
        for _, event in ipairs(currentCombat.healingEvents) do
            if event.timestamp >= windowStartTime then
                healingDuringWindow = healingDuringWindow + event.amount
            end
        end
        
        -- Calculate actual window time (max of combat time or window)
        local actualWindowTime = math.min(combatTime, window)
        if actualWindowTime > 0 then
            dps = damageDuringWindow / actualWindowTime
            hps = healingDuringWindow / actualWindowTime
        end
    end
    
    -- Apply threshold filtering
    local threshold = WE:GetConfig("modules.Stats.threshold", 1000)
    if dps < threshold then dps = 0 end
    if hps < threshold then hps = 0 end
    
    -- Update display
    local showDps = WE:GetConfig("modules.Stats.showDps", true)
    local showHps = WE:GetConfig("modules.Stats.showHps", true)
    
    -- Format time as MM:SS
    local minutes = math.floor(combatTime / 60)
    local seconds = math.floor(combatTime % 60)
    local timeString = string.format("%02d:%02d", minutes, seconds)
    
    -- Update timer display
    statsFrame.timerValue:SetText(timeString)
    
    -- Update DPS display
    if showDps then
        statsFrame.dpsLabel:Show()
        statsFrame.dpsValue:Show()
        if dps >= 1000000 then
            statsFrame.dpsValue:SetText(string.format("%.2fM", dps / 1000000))
        elseif dps >= 1000 then
            statsFrame.dpsValue:SetText(string.format("%.1fK", dps / 1000))
        else
            statsFrame.dpsValue:SetText(string.format("%.0f", dps))
        end
    else
        statsFrame.dpsLabel:Hide()
        statsFrame.dpsValue:Hide()
    end
    
    -- Update HPS display
    if showHps then
        statsFrame.hpsLabel:Show()
        statsFrame.hpsValue:Show()
        if hps >= 1000000 then
            statsFrame.hpsValue:SetText(string.format("%.2fM", hps / 1000000))
        elseif hps >= 1000 then
            statsFrame.hpsValue:SetText(string.format("%.1fK", hps / 1000))
        else
            statsFrame.hpsValue:SetText(string.format("%.0f", hps))
        end
    else
        statsFrame.hpsLabel:Hide()
        statsFrame.hpsValue:Hide()
    end
    
    -- Adjust frame height based on shown elements
    local height = 60 -- Base height
    if not showDps then height = height - 15 end
    if not showHps then height = height - 15 end
    statsFrame:SetHeight(height)
end

-- Reset all stats data
function StatsModule:ResetStats()
    -- Clear all stored data
    combatData = {}
    
    -- Reset current combat if in combat
    if isInCombat then
        currentCombat = {
            startTime = GetTime(),
            endTime = nil,
            totalDamage = 0,
            totalHealing = 0,
            damageEvents = {},
            healingEvents = {}
        }
    else
        currentCombat = nil
    end
    
    -- Update display
    self:UpdateStatsDisplay()
end

-- Show the stats window
function StatsModule:ShowStats()
    if not statsFrame then
        self:CreateStatsFrame()
    end
    statsFrame:Show()
end

-- Hide the stats window
function StatsModule:HideStats()
    if statsFrame then
        statsFrame:Hide()
    end
end

-- Handle configuration changes
function StatsModule:OnConfigChanged()
    self:UpdateStatsDisplay()
end

-- Return the module
WE.StatsModule = StatsModule 