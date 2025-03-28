-- WoW Essentials UI Module
-- Handles UI customization and frame management

local WE = WoWEssentials
local UIModule = WE:NewModule("UI", true)
local _G = _G

-- Local variables
local frames = {}
local playerFrame, targetFrame, partyFrames
local originalFramePositions = {}

-- Initialize module
function UIModule:Initialize()
    -- Create main UI container frame
    self.container = CreateFrame("Frame", "WoWEssentialsUIContainer", UIParent)
    self.container:SetPoint("CENTER")
    self.container:SetSize(1, 1) -- Initially invisible size
    
    -- Store this module in the frames table for easy reference
    frames.container = self.container
    
    -- Register slash command specific to UI module
    _G["SLASH_WEUI1"] = "/weui"
    SlashCmdList["WEUI"] = function(msg)
        self:HandleCommands(msg)
    end
end

-- Handle UI specific slash commands
function UIModule:HandleCommands(msg)
    local args = {}
    for arg in string.gmatch(msg, "%S+") do
        table.insert(args, string.lower(arg))
    end
    
    local command = args[1]
    
    if command == "reset" then
        self:ResetPositions()
        WE:Print("UI positions have been reset")
    elseif command == "lock" then
        self:LockFrames()
        WE:Print("UI frames are now locked")
    elseif command == "unlock" then
        self:UnlockFrames()
        WE:Print("UI frames are now unlocked and can be moved")
    elseif command == "scale" and args[2] then
        local scale = tonumber(args[2])
        if scale and scale > 0.5 and scale <= 2.0 then
            self:SetScale(scale)
            WE:Print("UI scale set to " .. scale)
        else
            WE:Print("Scale must be between 0.5 and 2.0")
        end
    else
        WE:Print("UI module commands:")
        WE:Print("/weui reset - Reset all frame positions")
        WE:Print("/weui lock - Lock all frames")
        WE:Print("/weui unlock - Unlock frames for movement")
        WE:Print("/weui scale [0.5-2.0] - Set UI scale")
    end
end

-- Called when the module is enabled
function UIModule:OnEnable()
    -- Save original frame positions
    self:SaveOriginalPositions()
    
    -- Create or update custom frames
    self:CreatePlayerFrame()
    self:CreateTargetFrame()
    self:CreatePartyFrames()
    
    -- Apply initial settings
    self:ApplySettings()
    
    -- Register for necessary events
    WE:RegisterEvent("PLAYER_TARGET_CHANGED", function() self:UpdateTargetFrame() end)
    WE:RegisterEvent("UNIT_HEALTH", function(unit) self:UpdateHealthBars(unit) end)
    WE:RegisterEvent("UNIT_POWER_UPDATE", function(unit, powerType) self:UpdatePowerBars(unit, powerType) end)
    WE:RegisterEvent("GROUP_ROSTER_UPDATE", function() self:UpdatePartyFrames() end)
    
    -- Apply font changes
    self:ApplyFontChanges()
    
    -- Hook functions if needed
    self:HookBlizzardFunctions()
end

-- Called when the module is disabled
function UIModule:OnDisable()
    -- Hide custom frames
    if frames.player then frames.player:Hide() end
    if frames.target then frames.target:Hide() end
    if frames.party then
        for i = 1, 4 do
            if frames.party[i] then frames.party[i]:Hide() end
        end
    end
    
    -- Restore original positions
    self:RestoreOriginalPositions()
    
    -- Unregister events
    WE:UnregisterEvent("PLAYER_TARGET_CHANGED", self.UpdateTargetFrame)
    WE:UnregisterEvent("UNIT_HEALTH", self.UpdateHealthBars)
    WE:UnregisterEvent("UNIT_POWER_UPDATE", self.UpdatePowerBars)
    WE:UnregisterEvent("GROUP_ROSTER_UPDATE", self.UpdatePartyFrames)
    
    -- Unhook functions
    self:UnhookBlizzardFunctions()
end

-- Save original frame positions
function UIModule:SaveOriginalPositions()
    originalFramePositions.player = {PlayerFrame:GetPoint()}
    originalFramePositions.target = {TargetFrame:GetPoint()}
    
    -- Party frames
    originalFramePositions.party = {}
    for i = 1, 4 do
        local frame = _G["PartyMemberFrame" .. i]
        if frame then
            originalFramePositions.party[i] = {frame:GetPoint()}
        end
    end
end

-- Restore original frame positions
function UIModule:RestoreOriginalPositions()
    if originalFramePositions.player then
        PlayerFrame:ClearAllPoints()
        PlayerFrame:SetPoint(unpack(originalFramePositions.player))
    end
    
    if originalFramePositions.target then
        TargetFrame:ClearAllPoints()
        TargetFrame:SetPoint(unpack(originalFramePositions.target))
    end
    
    for i = 1, 4 do
        local frame = _G["PartyMemberFrame" .. i]
        if frame and originalFramePositions.party and originalFramePositions.party[i] then
            frame:ClearAllPoints()
            frame:SetPoint(unpack(originalFramePositions.party[i]))
        end
    end
end

-- Create custom player frame
function UIModule:CreatePlayerFrame()
    if frames.player then return frames.player end
    
    local frame = CreateFrame("Frame", "WoWEssentialsPlayerFrame", UIParent)
    frame:SetSize(200, 60)
    frame:SetPoint("BOTTOM", UIParent, "BOTTOM", -200, 140)
    
    -- Health bar
    local healthBar = CreateFrame("StatusBar", nil, frame)
    healthBar:SetPoint("TOP", frame, "TOP", 0, 0)
    healthBar:SetSize(200, 30)
    healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    healthBar:SetStatusBarColor(0.1, 0.9, 0.1)
    
    -- Health text
    local healthText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    healthText:SetPoint("CENTER", healthBar, "CENTER", 0, 0)
    
    -- Power bar
    local powerBar = CreateFrame("StatusBar", nil, frame)
    powerBar:SetPoint("TOP", healthBar, "BOTTOM", 0, -2)
    powerBar:SetSize(200, 15)
    powerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    
    -- Power text
    local powerText = powerBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    powerText:SetPoint("CENTER", powerBar, "CENTER", 0, 0)
    
    -- Class/name text
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("BOTTOM", healthBar, "TOP", 0, 4)
    
    -- Store references
    frame.healthBar = healthBar
    frame.healthText = healthText
    frame.powerBar = powerBar
    frame.powerText = powerText
    frame.nameText = nameText
    
    -- Make frame movable
    frame:SetMovable(true)
    frame:EnableMouse(false)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if self:IsMovable() then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    -- Store in frames table
    frames.player = frame
    
    -- Initial update
    self:UpdatePlayerFrame()
    
    return frame
end

-- Create custom target frame
function UIModule:CreateTargetFrame()
    if frames.target then return frames.target end
    
    local frame = CreateFrame("Frame", "WoWEssentialsTargetFrame", UIParent)
    frame:SetSize(200, 60)
    frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 200, 140)
    
    -- Health bar
    local healthBar = CreateFrame("StatusBar", nil, frame)
    healthBar:SetPoint("TOP", frame, "TOP", 0, 0)
    healthBar:SetSize(200, 30)
    healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    healthBar:SetStatusBarColor(0.9, 0.1, 0.1)
    
    -- Health text
    local healthText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    healthText:SetPoint("CENTER", healthBar, "CENTER", 0, 0)
    
    -- Power bar
    local powerBar = CreateFrame("StatusBar", nil, frame)
    powerBar:SetPoint("TOP", healthBar, "BOTTOM", 0, -2)
    powerBar:SetSize(200, 15)
    powerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    
    -- Power text
    local powerText = powerBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    powerText:SetPoint("CENTER", powerBar, "CENTER", 0, 0)
    
    -- Name text
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("BOTTOM", healthBar, "TOP", 0, 4)
    
    -- Store references
    frame.healthBar = healthBar
    frame.healthText = healthText
    frame.powerBar = powerBar
    frame.powerText = powerText
    frame.nameText = nameText
    
    -- Make frame movable
    frame:SetMovable(true)
    frame:EnableMouse(false)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if self:IsMovable() then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    -- Store in frames table
    frames.target = frame
    
    return frame
end

-- Create party frames
function UIModule:CreatePartyFrames()
    if frames.party then return frames.party end
    
    frames.party = {}
    
    for i = 1, 4 do
        local frame = CreateFrame("Frame", "WoWEssentialsPartyFrame" .. i, UIParent)
        frame:SetSize(150, 40)
        frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -100 - (i-1) * 45)
        
        -- Health bar
        local healthBar = CreateFrame("StatusBar", nil, frame)
        healthBar:SetPoint("TOP", frame, "TOP", 0, 0)
        healthBar:SetSize(150, 20)
        healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        healthBar:SetStatusBarColor(0.1, 0.9, 0.1)
        
        -- Health text
        local healthText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        healthText:SetPoint("CENTER", healthBar, "CENTER", 0, 0)
        
        -- Power bar
        local powerBar = CreateFrame("StatusBar", nil, frame)
        powerBar:SetPoint("TOP", healthBar, "BOTTOM", 0, -2)
        powerBar:SetSize(150, 10)
        powerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        
        -- Name text
        local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("BOTTOMLEFT", healthBar, "TOPLEFT", 0, 2)
        
        -- Store references
        frame.healthBar = healthBar
        frame.healthText = healthText
        frame.powerBar = powerBar
        frame.nameText = nameText
        
        -- Make frame movable
        frame:SetMovable(true)
        frame:EnableMouse(false)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function(self) if self:IsMovable() then self:StartMoving() end end)
        frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        
        frames.party[i] = frame
    end
    
    -- Initial update
    self:UpdatePartyFrames()
    
    return frames.party
end

-- Apply settings to frames
function UIModule:ApplySettings()
    local scale = WE:GetConfig("modules.UI.scale", 1.0)
    self:SetScale(scale)
    
    -- Apply other settings as needed
    self:UpdateHealthBarColors()
    self:UpdatePowerBarColors()
end

-- Update UI when config changes
function UIModule:OnConfigChanged()
    self:ApplySettings()
end

-- Update player frame with current data
function UIModule:UpdatePlayerFrame()
    if not frames.player then return end
    
    local frame = frames.player
    local unit = "player"
    
    -- Update health
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    frame.healthBar:SetMinMaxValues(0, maxHealth)
    frame.healthBar:SetValue(health)
    frame.healthText:SetText(health .. " / " .. maxHealth)
    
    -- Update power
    local powerType, powerToken = UnitPowerType(unit)
    local power = UnitPower(unit, powerType)
    local maxPower = UnitPowerMax(unit, powerType)
    frame.powerBar:SetMinMaxValues(0, maxPower)
    frame.powerBar:SetValue(power)
    frame.powerText:SetText(power .. " / " .. maxPower)
    
    -- Color power bar based on power type
    local color = PowerBarColor[powerToken]
    if color then
        frame.powerBar:SetStatusBarColor(color.r, color.g, color.b)
    end
    
    -- Update name and class
    local name = UnitName(unit)
    local _, class = UnitClass(unit)
    local classColor = RAID_CLASS_COLORS[class]
    
    if classColor then
        frame.nameText:SetText(name)
        frame.nameText:SetTextColor(classColor.r, classColor.g, classColor.b)
    else
        frame.nameText:SetText(name)
    end
end

-- Update target frame with current target data
function UIModule:UpdateTargetFrame()
    if not frames.target then return end
    
    local frame = frames.target
    local unit = "target"
    
    if UnitExists(unit) then
        -- Update health
        local health = UnitHealth(unit)
        local maxHealth = UnitHealthMax(unit)
        frame.healthBar:SetMinMaxValues(0, maxHealth)
        frame.healthBar:SetValue(health)
        frame.healthText:SetText(health .. " / " .. maxHealth)
        
        -- Update power
        local powerType, powerToken = UnitPowerType(unit)
        local power = UnitPower(unit, powerType)
        local maxPower = UnitPowerMax(unit, powerType)
        frame.powerBar:SetMinMaxValues(0, maxPower)
        frame.powerBar:SetValue(power)
        frame.powerText:SetText(power .. " / " .. maxPower)
        
        -- Color power bar based on power type
        local color = PowerBarColor[powerToken]
        if color then
            frame.powerBar:SetStatusBarColor(color.r, color.g, color.b)
        end
        
        -- Update name
        local name = UnitName(unit)
        frame.nameText:SetText(name)
        
        -- Color name based on reaction
        if UnitIsPlayer(unit) then
            local _, class = UnitClass(unit)
            local classColor = RAID_CLASS_COLORS[class]
            if classColor then
                frame.nameText:SetTextColor(classColor.r, classColor.g, classColor.b)
            end
        else
            local reaction = UnitReaction(unit, "player")
            if reaction then
                local color = GetQuestDifficultyColor(reaction)
                frame.nameText:SetTextColor(color.r, color.g, color.b)
            else
                frame.nameText:SetTextColor(1, 1, 1)
            end
        end
        
        frame:Show()
    else
        frame:Hide()
    end
end

-- Update party frames
function UIModule:UpdatePartyFrames()
    if not frames.party then return end
    
    for i = 1, 4 do
        local frame = frames.party[i]
        local unit = "party" .. i
        
        if UnitExists(unit) then
            -- Update health
            local health = UnitHealth(unit)
            local maxHealth = UnitHealthMax(unit)
            frame.healthBar:SetMinMaxValues(0, maxHealth)
            frame.healthBar:SetValue(health)
            frame.healthText:SetText(health .. " / " .. maxHealth)
            
            -- Update power
            local powerType, powerToken = UnitPowerType(unit)
            local power = UnitPower(unit, powerType)
            local maxPower = UnitPowerMax(unit, powerType)
            frame.powerBar:SetMinMaxValues(0, maxPower)
            frame.powerBar:SetValue(power)
            
            -- Color power bar based on power type
            local color = PowerBarColor[powerToken]
            if color then
                frame.powerBar:SetStatusBarColor(color.r, color.g, color.b)
            end
            
            -- Update name
            local name = UnitName(unit)
            local _, class = UnitClass(unit)
            local classColor = RAID_CLASS_COLORS[class]
            
            if classColor then
                frame.nameText:SetText(name)
                frame.nameText:SetTextColor(classColor.r, classColor.g, classColor.b)
            else
                frame.nameText:SetText(name)
            end
            
            frame:Show()
        else
            frame:Hide()
        end
    end
end

-- Update health bars for a specific unit
function UIModule:UpdateHealthBars(unit)
    if not unit then return end
    
    if unit == "player" and frames.player then
        self:UpdatePlayerFrame()
    elseif unit == "target" and frames.target then
        self:UpdateTargetFrame()
    elseif string.match(unit, "^party%d$") and frames.party then
        local index = tonumber(string.match(unit, "^party(%d)$"))
        if index and index <= 4 and frames.party[index] then
            self:UpdatePartyFrames()
        end
    end
end

-- Update power bars for a specific unit
function UIModule:UpdatePowerBars(unit, powerType)
    if not unit then return end
    
    if unit == "player" and frames.player then
        local frame = frames.player
        local power = UnitPower(unit, UnitPowerType(unit))
        local maxPower = UnitPowerMax(unit, UnitPowerType(unit))
        frame.powerBar:SetMinMaxValues(0, maxPower)
        frame.powerBar:SetValue(power)
        frame.powerText:SetText(power .. " / " .. maxPower)
    elseif unit == "target" and frames.target then
        local frame = frames.target
        local power = UnitPower(unit, UnitPowerType(unit))
        local maxPower = UnitPowerMax(unit, UnitPowerType(unit))
        frame.powerBar:SetMinMaxValues(0, maxPower)
        frame.powerBar:SetValue(power)
        frame.powerText:SetText(power .. " / " .. maxPower)
    elseif string.match(unit, "^party%d$") and frames.party then
        local index = tonumber(string.match(unit, "^party(%d)$"))
        if index and index <= 4 and frames.party[index] then
            local frame = frames.party[index]
            local power = UnitPower(unit, UnitPowerType(unit))
            local maxPower = UnitPowerMax(unit, UnitPowerType(unit))
            frame.powerBar:SetMinMaxValues(0, maxPower)
            frame.powerBar:SetValue(power)
        end
    end
end

-- Lock all frames to prevent movement
function UIModule:LockFrames()
    local movableFrames = {frames.player, frames.target}
    
    for i = 1, 4 do
        if frames.party and frames.party[i] then
            table.insert(movableFrames, frames.party[i])
        end
    end
    
    for _, frame in ipairs(movableFrames) do
        if frame then
            frame:EnableMouse(false)
        end
    end
end

-- Unlock all frames for movement
function UIModule:UnlockFrames()
    local movableFrames = {frames.player, frames.target}
    
    for i = 1, 4 do
        if frames.party and frames.party[i] then
            table.insert(movableFrames, frames.party[i])
        end
    end
    
    for _, frame in ipairs(movableFrames) do
        if frame then
            frame:EnableMouse(true)
        end
    end
    
    WE:Print("UI frames unlocked. You can drag them to reposition.")
end

-- Reset frames to default positions
function UIModule:ResetPositions()
    if frames.player then
        frames.player:ClearAllPoints()
        frames.player:SetPoint("BOTTOM", UIParent, "BOTTOM", -200, 140)
    end
    
    if frames.target then
        frames.target:ClearAllPoints()
        frames.target:SetPoint("BOTTOM", UIParent, "BOTTOM", 200, 140)
    end
    
    if frames.party then
        for i = 1, 4 do
            if frames.party[i] then
                frames.party[i]:ClearAllPoints()
                frames.party[i]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -100 - (i-1) * 45)
            end
        end
    end
end

-- Set UI scale
function UIModule:SetScale(scale)
    if not scale or scale <= 0 then scale = 1.0 end
    
    local frames = {self.container, frames.player, frames.target}
    
    if frames.party then
        for i = 1, 4 do
            if frames.party[i] then
                table.insert(frames, frames.party[i])
            end
        end
    end
    
    for _, frame in ipairs(frames) do
        if frame then
            frame:SetScale(scale)
        end
    end
    
    WE:SetConfig("modules.UI.scale", scale)
end

-- Apply font changes to all frames
function UIModule:ApplyFontChanges()
    local useCustomFont = WE:GetConfig("modules.UI.customFont", false)
    if not useCustomFont then return end
    
    local fontFamily = WE:GetConfig("modules.UI.fontFamily", "Friz Quadrata TT")
    local fontSize = WE:GetConfig("modules.UI.fontSize", 12)
    
    local fontObjects = {
        frames.player and frames.player.nameText,
        frames.player and frames.player.healthText,
        frames.player and frames.player.powerText,
        frames.target and frames.target.nameText,
        frames.target and frames.target.healthText,
        frames.target and frames.target.powerText
    }
    
    if frames.party then
        for i = 1, 4 do
            if frames.party[i] then
                table.insert(fontObjects, frames.party[i].nameText)
                table.insert(fontObjects, frames.party[i].healthText)
            end
        end
    end
    
    for _, fontObject in ipairs(fontObjects) do
        if fontObject then
            fontObject:SetFont(fontFamily, fontSize, "OUTLINE")
        end
    end
end

-- Update health bar colors based on settings
function UIModule:UpdateHealthBarColors()
    local useCustomColors = WE:GetConfig("modules.UI.customColors", false)
    if not useCustomColors then return end
    
    local healthColor = WE:GetConfig("modules.UI.colors.health", {r = 0.1, g = 0.9, b = 0.1})
    
    if frames.player and frames.player.healthBar then
        frames.player.healthBar:SetStatusBarColor(healthColor.r, healthColor.g, healthColor.b)
    end
    
    if frames.party then
        for i = 1, 4 do
            if frames.party[i] and frames.party[i].healthBar then
                frames.party[i].healthBar:SetStatusBarColor(healthColor.r, healthColor.g, healthColor.b)
            end
        end
    end
end

-- Update power bar colors based on settings
function UIModule:UpdatePowerBarColors()
    local useCustomColors = WE:GetConfig("modules.UI.customColors", false)
    if not useCustomColors then return end
    
    local powerTypes = {
        ["MANA"] = WE:GetConfig("modules.UI.colors.mana", {r = 0.1, g = 0.1, b = 0.9}),
        ["RAGE"] = WE:GetConfig("modules.UI.colors.rage", {r = 0.9, g = 0.1, b = 0.1}),
        ["ENERGY"] = WE:GetConfig("modules.UI.colors.energy", {r = 0.9, g = 0.9, b = 0.1})
    }
    
    -- Player power
    if frames.player and frames.player.powerBar then
        local _, powerToken = UnitPowerType("player")
        local color = powerTypes[powerToken] or {r = 0.5, g = 0.5, b = 0.5}
        frames.player.powerBar:SetStatusBarColor(color.r, color.g, color.b)
    end
    
    -- Party power
    if frames.party then
        for i = 1, 4 do
            if frames.party[i] and frames.party[i].powerBar and UnitExists("party" .. i) then
                local _, powerToken = UnitPowerType("party" .. i)
                local color = powerTypes[powerToken] or {r = 0.5, g = 0.5, b = 0.5}
                frames.party[i].powerBar:SetStatusBarColor(color.r, color.g, color.b)
            end
        end
    end
end

-- Hook into Blizzard frame functions if needed
function UIModule:HookBlizzardFunctions()
    -- Example: hide default frames
    local hideBlizzardFrames = WE:GetConfig("modules.UI.hideBlizzardFrames", false)
    if hideBlizzardFrames then
        if PlayerFrame then PlayerFrame:Hide() end
        if TargetFrame then TargetFrame:Hide() end
        for i = 1, 4 do
            local frame = _G["PartyMemberFrame" .. i]
            if frame then frame:Hide() end
        end
    end
end

-- Unhook Blizzard functions if needed
function UIModule:UnhookBlizzardFunctions()
    -- Example: show default frames that were hidden
    if PlayerFrame then PlayerFrame:Show() end
    if TargetFrame then TargetFrame:Show() end
    for i = 1, 4 do
        local frame = _G["PartyMemberFrame" .. i]
        if frame then frame:Show() end
    end
end

-- Return the module
WE.UIModule = UIModule 