--[[
    WoW Essentials: API Documentation
    
    This file provides documentation for commonly used WoW API functions based on analysis
    of popular addons like WeakAuras, ElvUI, and Deadly Boss Mods.
    
    This documentation serves as a reference for addon development and helps understand
    the capabilities of the WoW API.
]]--

------------------------------------------
-- FRAMES AND UI
------------------------------------------

--[[
    CreateFrame(frameType, frameName, parent, template, id)
    Creates a new UI frame with the specified parameters.
    
    Parameters:
    - frameType: String - The type of frame to create (Frame, Button, CheckButton, etc.)
    - frameName: String - Global name to assign to the frame (can be nil)
    - parent: Frame - Parent frame (often UIParent for top-level frames)
    - template: String - Template to inherit from (can be nil)
    - id: Number - ID for the frame (can be nil)
    
    Returns: Frame - The newly created frame
    
    Example:
    local myFrame = CreateFrame("Frame", "MyAddonFrame", UIParent)
]]--

--[[
    Frame positioning methods:
    
    Frame:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
    Sets the anchor point for the frame.
    
    Parameters:
    - point: String - Anchor point on this frame (CENTER, TOPLEFT, etc.)
    - relativeTo: Frame - Frame to anchor to (can be nil for screen)
    - relativePoint: String - Anchor point on the relativeTo frame
    - xOffset: Number - Horizontal offset
    - yOffset: Number - Vertical offset
    
    Example:
    myFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    Other positioning methods:
    - Frame:SetSize(width, height)
    - Frame:SetWidth(width)
    - Frame:SetHeight(height)
    - Frame:ClearAllPoints()
]]--

--[[
    Frame:SetScript(scriptType, handler)
    Sets a script handler for the frame.
    
    Parameters:
    - scriptType: String - The script event to hook ("OnLoad", "OnEvent", "OnUpdate", etc.)
    - handler: Function - The function to call when the event fires
    
    Example:
    myFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            -- Do something
        end
    end)
]]--

------------------------------------------
-- EVENTS
------------------------------------------

--[[
    Frame:RegisterEvent(event)
    Registers the frame to receive a specific event.
    
    Parameters:
    - event: String - The event to register for
    
    Common events:
    - ADDON_LOADED - Fired when an addon is loaded
    - PLAYER_LOGIN - Fired when the player logs in
    - PLAYER_ENTERING_WORLD - Fired when the player enters the world
    - UNIT_HEALTH - Fired when a unit's health changes
    - COMBAT_LOG_EVENT_UNFILTERED - Fired for combat log events
    
    Example:
    myFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
]]--

--[[
    C_EventUtils.IsEventValid(eventName)
    Checks if an event is valid.
    
    Parameters:
    - eventName: String - The event name to check
    
    Returns: Boolean - True if the event is valid
]]--

------------------------------------------
-- UNITS AND TARGETING
------------------------------------------

--[[
    UnitHealth(unit)
    Returns the current health of the specified unit.
    
    Parameters:
    - unit: String - Unit ID (player, target, pet, party1, etc.)
    
    Returns: Number - Current health
    
    Example:
    local health = UnitHealth("player")
]]--

--[[
    UnitHealthMax(unit)
    Returns the maximum health of the specified unit.
    
    Parameters:
    - unit: String - Unit ID
    
    Returns: Number - Maximum health
]]--

--[[
    UnitPower(unit, powerType)
    Returns the current power (mana, rage, energy, etc.) of the specified unit.
    
    Parameters:
    - unit: String - Unit ID
    - powerType: Number - Type of power to query (optional)
    
    Returns: Number - Current power
    
    Power Types:
    - Enum.PowerType.Mana = 0
    - Enum.PowerType.Rage = 1
    - Enum.PowerType.Focus = 2
    - Enum.PowerType.Energy = 3
    - Enum.PowerType.ComboPoints = 4
    - Enum.PowerType.Runes = 5
    - Enum.PowerType.RunicPower = 6
    - Enum.PowerType.SoulShards = 7
    - Enum.PowerType.LunarPower = 8
    - Enum.PowerType.HolyPower = 9
    - Enum.PowerType.Alternate = 10
    - Enum.PowerType.Maelstrom = 11
    - Enum.PowerType.Chi = 12
    - Enum.PowerType.Insanity = 13
    - Enum.PowerType.Obsolete = 14
    - Enum.PowerType.Obsolete2 = 15
    - Enum.PowerType.ArcaneCharges = 16
    - Enum.PowerType.Fury = 17
    - Enum.PowerType.Pain = 18
    - Enum.PowerType.Essence = 19
]]--

--[[
    UnitExists(unit)
    Checks if a unit exists.
    
    Parameters:
    - unit: String - Unit ID
    
    Returns: Boolean - True if the unit exists
]]--

--[[
    UnitIsPlayer(unit)
    Checks if a unit is a player character.
    
    Parameters:
    - unit: String - Unit ID
    
    Returns: Boolean - True if the unit is a player
]]--

--[[
    UnitClass(unit)
    Returns the class of the specified unit.
    
    Parameters:
    - unit: String - Unit ID
    
    Returns: String, String - Localized class name, English class name
]]--

--[[
    UnitAura(unit, index or "name" [, filter])
    Returns information about a buff or debuff on the unit.
    
    Parameters:
    - unit: String - Unit ID
    - index: Number - Index of the aura to query, or name of the aura
    - filter: String - Optional filter (HELPFUL, HARMFUL, PLAYER, etc.)
    
    Returns: Multiple values - name, icon, count, debuffType, duration, expirationTime, etc.
    
    Example:
    local name, _, _, _, duration, expirationTime = UnitAura("player", "Arcane Intellect", "HELPFUL")
]]--

------------------------------------------
-- SPELLS AND ABILITIES
------------------------------------------

--[[
    GetSpellInfo(spellID)
    Returns information about a spell by ID.
    
    Parameters:
    - spellID: Number - The ID of the spell
    
    Returns: String, String, String, Number, Number, Number, Number - name, rank, icon, castTime, minRange, maxRange, spellID
    
    Example:
    local spellName, _, spellIcon = GetSpellInfo(1459) -- Arcane Intellect
]]--

--[[
    IsSpellKnown(spellID)
    Checks if the player knows a spell.
    
    Parameters:
    - spellID: Number - The ID of the spell
    
    Returns: Boolean - True if the spell is known
]]--

--[[
    GetSpellCooldown(spellID or "spellName")
    Returns cooldown information for a spell.
    
    Parameters:
    - spellID: Number - The ID of the spell, or the spell name
    
    Returns: Number, Number, Number - start, duration, enabled
    
    Example:
    local start, duration, _ = GetSpellCooldown(12345)
    local cooldownRemaining = start + duration - GetTime()
]]--

------------------------------------------
-- COMBAT LOG
------------------------------------------

--[[
    COMBAT_LOG_EVENT_UNFILTERED event
    Provides detailed information about combat events.
    
    Parameters passed to the event handler:
    timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
    destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, etc.
    
    Common subevents:
    - SPELL_CAST_START - A spell cast has started
    - SPELL_CAST_SUCCESS - A spell was cast successfully
    - SPELL_AURA_APPLIED - A buff or debuff was applied
    - SPELL_AURA_REMOVED - A buff or debuff was removed
    - SPELL_DAMAGE - Spell damage was dealt
    - SWING_DAMAGE - Melee damage was dealt
    
    Example:
    myFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    myFrame:SetScript("OnEvent", function(self, event)
        local timestamp, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName = CombatLogGetCurrentEventInfo()
        
        if subevent == "SPELL_DAMAGE" and destGUID == UnitGUID("player") then
            -- Player took spell damage
        end
    end)
]]--

--[[
    CombatLogGetCurrentEventInfo()
    Returns information about the current combat log event.
    
    Returns: Multiple values - combat log event data
]]--

------------------------------------------
-- COMMUNICATION
------------------------------------------

--[[
    SendChatMessage(msg, chatType, language, channel)
    Sends a chat message.
    
    Parameters:
    - msg: String - The message to send
    - chatType: String - Type of chat (SAY, PARTY, RAID, WHISPER, etc.)
    - language: Number or String - Language ID or nil for default
    - channel: String - Target channel name or player name for whispers
    
    Example:
    SendChatMessage("Hello!", "PARTY")
]]--

--[[
    C_ChatInfo.SendAddonMessage(prefix, text, chatType, target)
    Sends a message that can be received by other addons.
    
    Parameters:
    - prefix: String - Addon message prefix (must be registered)
    - text: String - Message content
    - chatType: String - Type of chat (PARTY, RAID, GUILD, etc.)
    - target: String - Target player for whispers
    
    Example:
    C_ChatInfo.RegisterAddonMessagePrefix("MyAddon")
    C_ChatInfo.SendAddonMessage("MyAddon", "Hello!", "PARTY")
]]--

------------------------------------------
-- SLASH COMMANDS
------------------------------------------

--[[
    SLASH_COMMANDNAME1, SLASH_COMMANDNAME2 = '/command1', '/command2'
    SlashCmdList["COMMANDNAME"] = function(msg)
        -- Handle the slash command
    end
    
    Registers a slash command for the addon.
    
    Example:
    SLASH_MYADDON1, SLASH_MYADDON2 = '/myaddon', '/ma'
    SlashCmdList["MYADDON"] = function(msg)
        print("My addon slash command: " .. msg)
    end
]]--

------------------------------------------
-- CONFIGURATION
------------------------------------------

--[[
    SavedVariables
    
    Variables saved between game sessions must be declared in the TOC file:
    ## SavedVariables: MyAddonDB
    ## SavedVariablesPerCharacter: MyAddonCharDB
    
    Example usage:
    MyAddonDB = MyAddonDB or {}
    
    -- After settings are changed
    MyAddonDB.settings = newSettings
]]--

------------------------------------------
-- C_TIMER API
------------------------------------------

--[[
    C_Timer.After(seconds, callback)
    Executes a function after the specified number of seconds.
    
    Parameters:
    - seconds: Number - Delay in seconds
    - callback: Function - Function to call after the delay
    
    Example:
    C_Timer.After(5, function()
        print("5 seconds have passed")
    end)
]]--

--[[
    C_Timer.NewTicker(seconds, callback, iterations)
    Creates a repeating timer that calls a function at the specified interval.
    
    Parameters:
    - seconds: Number - Interval in seconds
    - callback: Function - Function to call at each interval
    - iterations: Number - Number of times to repeat (optional, nil for indefinite)
    
    Returns: Ticker - Timer object with Cancel() method
    
    Example:
    local ticker = C_Timer.NewTicker(1, function()
        print("Tick")
    end, 5) -- Runs 5 times
    
    -- Cancel early
    ticker:Cancel()
]]--

------------------------------------------
-- GAME OBJECT FUNCTIONS
------------------------------------------

--[[
    Item API
    
    Functions to work with items:
    
    GetItemInfo(itemID or "itemName" or "itemLink")
    Returns information about an item.
    
    Parameters:
    - itemID: Number - The ID of the item, or item name, or item link
    
    Returns: String, String, Number, Number, Number, String, String, Number, String, Number, Number, Number, Number, String, Boolean, String, Boolean - name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice, etc.
    
    Example:
    local itemName, itemLink, itemQuality = GetItemInfo(6948) -- Hearthstone
]]--

--[[
    Container API (Bags)
    
    Functions to work with containers (bags):
    
    GetContainerNumSlots(bagID)
    Returns the number of slots in a bag.
    
    Parameters:
    - bagID: Number - Bag ID (0 for backpack, 1-4 for bags)
    
    Returns: Number - Number of slots
    
    GetContainerItemInfo(bagID, slot)
    Returns information about an item in a bag slot.
    
    Parameters:
    - bagID: Number - Bag ID
    - slot: Number - Slot index
    
    Returns: Multiple values - texture, itemCount, locked, quality, readable, lootable, itemLink, etc.
]]--

------------------------------------------
-- CLASS-SPECIFIC API
------------------------------------------

--[[
    Class-specific API functions:
    
    -- Death Knight
    GetRuneCooldown(runeIndex)
    
    -- Paladin
    GetHolyPower()
    
    -- Mage
    GetArcaneCharges()
    
    -- Warlock
    GetSoulShards()
    
    -- Monk
    GetChi()
    
    -- Priest
    GetInsanity()
    
    -- Druid
    GetComboPoints("player", "target")
    
    -- Rogue
    GetComboPoints("player", "target")
    
    -- Warrior
    UnitPower("player", Enum.PowerType.Rage)
    
    -- Hunter
    UnitPower("player", Enum.PowerType.Focus)
    
    -- Demon Hunter
    UnitPower("player", Enum.PowerType.Fury)
    UnitPower("player", Enum.PowerType.Pain)
    
    -- Shaman
    UnitPower("player", Enum.PowerType.Maelstrom)
    
    -- Evoker
    UnitPower("player", Enum.PowerType.Essence)
]]--

------------------------------------------
-- MAJOR FUNCTIONS ADDED IN DRAGONFLIGHT
------------------------------------------

--[[
    C_MajorFactions.GetMajorFactionData(majorFactionID)
    Returns data about a major faction in Dragonflight.
    
    Parameters:
    - majorFactionID: Number - ID of the major faction
    
    Returns: Table - Data about the faction
]]--

--[[
    C_MajorFactions.GetCurrentRenownLevel(majorFactionID)
    Returns the current renown level for a major faction.
    
    Parameters:
    - majorFactionID: Number - ID of the major faction
    
    Returns: Number - Current renown level
]]--

--[[
    C_MajorFactions.GetRenownRewardsForLevel(majorFactionID, renownLevel)
    Returns the rewards for a specific renown level with a major faction.
    
    Parameters:
    - majorFactionID: Number - ID of the major faction
    - renownLevel: Number - The renown level to query
    
    Returns: Table - Reward information
]]--

------------------------------------------
-- COMMON ADDON LIBRARIES AND THEIR USES
------------------------------------------

--[[
    Common third-party libraries used by popular addons:
    
    LibStub - Addon library management
    Usage: local AceAddon = LibStub("AceAddon-3.0")
    
    AceAddon-3.0 - Addon framework
    AceConfig-3.0 - Configuration UI
    AceDB-3.0 - Database management
    AceEvent-3.0 - Event handling
    AceTimer-3.0 - Timer management
    AceHook-3.0 - Function hooking
    AceGUI-3.0 - UI widgets
    AceConsole-3.0 - Console/slash commands
    
    LibSharedMedia-3.0 - Media resource sharing
    LibDataBroker-1.1 - Data broker
    LibDBIcon-1.0 - Minimap icons
    
    These are commonly used in addons like WeakAuras, ElvUI, and others
    to provide standardized functionality and avoid code duplication.
]]-- 