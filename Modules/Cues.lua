-- WoW Essentials Cues Module
-- Provides visual and audio cues for important cooldowns, procs, and resources

local WE = WoWEssentials
local CuesModule = WE:NewModule("Cues", true)
local _G = _G

-- Local variables
local trackedSpells = {}
local trackedCooldowns = {}
local activeCues = {}
local cueFrames = {}
local playerClass, playerSpec

-- Initialize module
function CuesModule:Initialize()
    -- Create container frame
    self.container = CreateFrame("Frame", "WoWEssentialsCuesContainer", UIParent)
    self.container:SetPoint("CENTER", 0, -150)
    self.container:SetSize(400, 100)
    
    -- Get player class
    local _, class = UnitClass("player")
    playerClass = class
    
    -- Initialize tracked abilities based on class
    self:InitTrackedAbilities()
    
    -- Register slash command
    _G["SLASH_WECUES1"] = "/wecues"
    SlashCmdList["WECUES"] = function(msg)
        self:HandleCommands(msg)
    end
end

-- Handle module-specific slash commands
function CuesModule:HandleCommands(msg)
    local args = {}
    for arg in string.gmatch(msg, "%S+") do
        table.insert(args, string.lower(arg))
    end
    
    local command = args[1]
    
    if command == "test" then
        self:TestCue()
        WE:Print("Showing test cue")
    elseif command == "cooldowns" and args[2] then
        local enabled = args[2] == "on" or args[2] == "true" or args[2] == "1"
        WE:SetConfig("modules.Cues.cooldowns", enabled)
        WE:Print("Cooldown tracking " .. (enabled and "enabled" or "disabled"))
    elseif command == "procs" and args[2] then
        local enabled = args[2] == "on" or args[2] == "true" or args[2] == "1"
        WE:SetConfig("modules.Cues.procs", enabled)
        WE:Print("Proc tracking " .. (enabled and "enabled" or "disabled"))
    elseif command == "resources" and args[2] then
        local enabled = args[2] == "on" or args[2] == "true" or args[2] == "1"
        WE:SetConfig("modules.Cues.resources", enabled)
        WE:Print("Resource tracking " .. (enabled and "enabled" or "disabled"))
    elseif command == "add" and args[2] then
        self:AddCustomSpell(args[2])
    elseif command == "remove" and args[2] then
        self:RemoveCustomSpell(args[2])
    elseif command == "list" then
        self:ListTrackedSpells()
    else
        WE:Print("Cues module commands:")
        WE:Print("/wecues test - Show a test cue")
        WE:Print("/wecues cooldowns on|off - Toggle cooldown tracking")
        WE:Print("/wecues procs on|off - Toggle proc tracking")
        WE:Print("/wecues resources on|off - Toggle resource tracking")
        WE:Print("/wecues add [spellId] - Add custom spell to track")
        WE:Print("/wecues remove [spellId] - Remove custom spell")
        WE:Print("/wecues list - List all tracked spells")
    end
end

-- Initialize class-specific tracked abilities
function CuesModule:InitTrackedAbilities()
    trackedSpells = {}
    
    -- Add common abilities for all classes
    trackedSpells["COMMON"] = {
        -- Trinket procs
        {id = 2825, name = "Bloodlust", type = "buff", important = true, sound = true},
        {id = 32182, name = "Heroism", type = "buff", important = true, sound = true},
        {id = 80353, name = "Time Warp", type = "buff", important = true, sound = true},
        {id = 264667, name = "Primal Rage", type = "buff", important = true, sound = true},
    }
    
    -- Class-specific abilities
    if playerClass == "WARRIOR" then
        trackedSpells["CLASS"] = {
            -- Arms
            {id = 167105, name = "Colossus Smash", type = "debuff", spec = 1, important = true},
            {id = 262228, name = "Deadly Calm", type = "buff", spec = 1, important = true},
            -- Fury
            {id = 1719, name = "Recklessness", type = "buff", spec = 2, important = true, sound = true},
            {id = 85739, name = "Meat Cleaver", type = "buff", spec = 2},
            -- Protection
            {id = 871, name = "Shield Wall", type = "buff", spec = 3, important = true},
            {id = 23920, name = "Spell Reflection", type = "buff", spec = 3},
            {id = 12975, name = "Last Stand", type = "buff", spec = 3, important = true},
        }
    elseif playerClass == "PALADIN" then
        trackedSpells["CLASS"] = {
            -- Holy
            {id = 31842, name = "Avenging Wrath", type = "buff", spec = 1, important = true, sound = true},
            {id = 216331, name = "Avenging Crusader", type = "buff", spec = 1, important = true},
            -- Protection
            {id = 31850, name = "Ardent Defender", type = "buff", spec = 2, important = true},
            {id = 86659, name = "Guardian of Ancient Kings", type = "buff", spec = 2, important = true},
            -- Retribution
            {id = 31884, name = "Avenging Wrath", type = "buff", spec = 3, important = true, sound = true},
            {id = 84963, name = "Inquisition", type = "buff", spec = 3},
        }
    elseif playerClass == "HUNTER" then
        trackedSpells["CLASS"] = {
            -- Beast Mastery
            {id = 19574, name = "Bestial Wrath", type = "buff", spec = 1, important = true},
            {id = 193530, name = "Aspect of the Wild", type = "buff", spec = 1, important = true},
            -- Marksmanship
            {id = 288613, name = "Trueshot", type = "buff", spec = 2, important = true, sound = true},
            {id = 194594, name = "Lock and Load", type = "buff", spec = 2},
            -- Survival
            {id = 266779, name = "Coordinated Assault", type = "buff", spec = 3, important = true},
            {id = 259388, name = "Mongoose Fury", type = "buff", spec = 3, important = true},
        }
    elseif playerClass == "ROGUE" then
        trackedSpells["CLASS"] = {
            -- Assassination
            {id = 79140, name = "Vendetta", type = "buff", spec = 1, important = true},
            {id = 121153, name = "Blindside", type = "buff", spec = 1},
            -- Outlaw
            {id = 13750, name = "Adrenaline Rush", type = "buff", spec = 2, important = true, sound = true},
            {id = 199600, name = "Buried Treasure", type = "buff", spec = 2},
            -- Subtlety
            {id = 121471, name = "Shadow Blades", type = "buff", spec = 3, important = true},
            {id = 185422, name = "Shadow Dance", type = "buff", spec = 3, important = true},
        }
    elseif playerClass == "PRIEST" then
        trackedSpells["CLASS"] = {
            -- Discipline
            {id = 47536, name = "Rapture", type = "buff", spec = 1, important = true, sound = true},
            {id = 33206, name = "Pain Suppression", type = "buff", spec = 1, important = true},
            -- Holy
            {id = 64843, name = "Divine Hymn", type = "buff", spec = 2, important = true},
            {id = 64901, name = "Symbol of Hope", type = "buff", spec = 2, important = true},
            -- Shadow
            {id = 194249, name = "Voidform", type = "buff", spec = 3, important = true, sound = true},
            {id = 263165, name = "Void Torrent", type = "buff", spec = 3},
        }
    elseif playerClass == "SHAMAN" then
        trackedSpells["CLASS"] = {
            -- Elemental
            {id = 198067, name = "Fire Elemental", type = "buff", spec = 1, important = true},
            {id = 191634, name = "Stormkeeper", type = "buff", spec = 1, important = true},
            -- Enhancement
            {id = 201845, name = "Stormbringer", type = "buff", spec = 2},
            {id = 204945, name = "Doom Winds", type = "buff", spec = 2, important = true, sound = true},
            -- Restoration
            {id = 98008, name = "Spirit Link Totem", type = "buff", spec = 3, important = true},
            {id = 114052, name = "Ascendance", type = "buff", spec = 3, important = true, sound = true},
        }
    elseif playerClass == "MAGE" then
        trackedSpells["CLASS"] = {
            -- Arcane
            {id = 12042, name = "Arcane Power", type = "buff", spec = 1, important = true, sound = true},
            {id = 263725, name = "Clearcasting", type = "buff", spec = 1},
            -- Fire
            {id = 190319, name = "Combustion", type = "buff", spec = 2, important = true, sound = true},
            {id = 48107, name = "Heating Up", type = "buff", spec = 2},
            -- Frost
            {id = 12472, name = "Icy Veins", type = "buff", spec = 3, important = true},
            {id = 44544, name = "Fingers of Frost", type = "buff", spec = 3},
        }
    elseif playerClass == "WARLOCK" then
        trackedSpells["CLASS"] = {
            -- Affliction
            {id = 205180, name = "Summon Darkglare", type = "buff", spec = 1, important = true},
            {id = 259395, name = "Deathbolt", type = "buff", spec = 1},
            -- Demonology
            {id = 265187, name = "Summon Demonic Tyrant", type = "buff", spec = 2, important = true, sound = true},
            {id = 264173, name = "Demonic Core", type = "buff", spec = 2},
            -- Destruction
            {id = 1122, name = "Summon Infernal", type = "buff", spec = 3, important = true, sound = true},
            {id = 266030, name = "Reverse Entropy", type = "buff", spec = 3},
        }
    elseif playerClass == "MONK" then
        trackedSpells["CLASS"] = {
            -- Brewmaster
            {id = 115203, name = "Fortifying Brew", type = "buff", spec = 1, important = true},
            {id = 214326, name = "Exploding Keg", type = "buff", spec = 1},
            -- Mistweaver
            {id = 116680, name = "Thunder Focus Tea", type = "buff", spec = 2, important = true},
            {id = 197908, name = "Mana Tea", type = "buff", spec = 2, important = true},
            -- Windwalker
            {id = 137639, name = "Storm, Earth, and Fire", type = "buff", spec = 3, important = true},
            {id = 152173, name = "Serenity", type = "buff", spec = 3, important = true, sound = true},
        }
    elseif playerClass == "DRUID" then
        trackedSpells["CLASS"] = {
            -- Balance
            {id = 194223, name = "Celestial Alignment", type = "buff", spec = 1, important = true, sound = true},
            {id = 202425, name = "Warrior of Elune", type = "buff", spec = 1},
            -- Feral
            {id = 106951, name = "Berserk", type = "buff", spec = 2, important = true},
            {id = 135700, name = "Clearcasting", type = "buff", spec = 2},
            -- Guardian
            {id = 61336, name = "Survival Instincts", type = "buff", spec = 3, important = true},
            {id = 22842, name = "Frenzied Regeneration", type = "buff", spec = 3},
            -- Restoration
            {id = 33891, name = "Incarnation: Tree of Life", type = "buff", spec = 4, important = true, sound = true},
            {id = 29166, name = "Innervate", type = "buff", spec = 4, important = true},
        }
    elseif playerClass == "DEATHKNIGHT" then
        trackedSpells["CLASS"] = {
            -- Blood
            {id = 55233, name = "Vampiric Blood", type = "buff", spec = 1, important = true},
            {id = 81256, name = "Dancing Rune Weapon", type = "buff", spec = 1, important = true},
            -- Frost
            {id = 47568, name = "Empower Rune Weapon", type = "buff", spec = 2, important = true},
            {id = 51271, name = "Pillar of Frost", type = "buff", spec = 2, important = true, sound = true},
            -- Unholy
            {id = 42650, name = "Army of the Dead", type = "buff", spec = 3, important = true},
            {id = 63560, name = "Dark Transformation", type = "buff", spec = 3, important = true},
        }
    elseif playerClass == "DEMONHUNTER" then
        trackedSpells["CLASS"] = {
            -- Havoc
            {id = 162264, name = "Metamorphosis", type = "buff", spec = 1, important = true, sound = true},
            {id = 206416, name = "First Blood", type = "buff", spec = 1},
            -- Vengeance
            {id = 187827, name = "Metamorphosis", type = "buff", spec = 2, important = true},
            {id = 203720, name = "Demon Spikes", type = "buff", spec = 2},
        }
    end
    
    -- Add custom spells from saved settings
    local customSpells = WE:GetConfig("modules.Cues.customSpells", {})
    for spellId, data in pairs(customSpells) do
        trackedSpells["CUSTOM"] = trackedSpells["CUSTOM"] or {}
        table.insert(trackedSpells["CUSTOM"], {
            id = tonumber(spellId),
            name = data.name,
            type = data.type,
            important = data.important,
            sound = data.sound
        })
    end
end

-- Called when the module is enabled
function CuesModule:OnEnable()
    -- Create cue frames
    self:CreateCueFrames()
    
    -- Register events
    WE:RegisterEvent("UNIT_AURA", function(unit) self:CheckAuras(unit) end)
    WE:RegisterEvent("SPELL_UPDATE_COOLDOWN", function() self:CheckCooldowns() end)
    WE:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function() self:UpdatePlayerSpec() end)
    
    -- Get current specialization
    self:UpdatePlayerSpec()
    
    -- Initial cooldown check
    self:CheckCooldowns()
end

-- Called when the module is disabled
function CuesModule:OnDisable()
    -- Hide all cue frames
    for id, frame in pairs(cueFrames) do
        frame:Hide()
    end
    
    -- Unregister events
    WE:UnregisterEvent("UNIT_AURA")
    WE:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
    WE:UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED")
end

-- Create frames for cues
function CuesModule:CreateCueFrames()
    -- Create container for cues
    local cueContainer = CreateFrame("Frame", "WoWEssentialsCuesDisplay", self.container)
    cueContainer:SetPoint("CENTER")
    cueContainer:SetSize(400, 100)
    
    -- Max cues to display at once
    local maxCues = 8
    
    for i = 1, maxCues do
        local frame = CreateFrame("Frame", "WoWEssentialsCue" .. i, cueContainer)
        frame:SetSize(50, 50)
        
        -- Position frames in a horizontal row
        if i == 1 then
            frame:SetPoint("LEFT", cueContainer, "LEFT", 10, 0)
        else
            frame:SetPoint("LEFT", cueFrames[i-1], "RIGHT", 5, 0)
        end
        
        -- Icon texture
        local icon = frame:CreateTexture(nil, "BACKGROUND")
        icon:SetAllPoints()
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Trim the borders
        
        -- Border texture
        local border = frame:CreateTexture(nil, "BORDER")
        border:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
        border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
        border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
        
        -- Cooldown swipe
        local cooldown = CreateFrame("Cooldown", frame:GetName() .. "Cooldown", frame, "CooldownFrameTemplate")
        cooldown:SetAllPoints()
        cooldown:SetDrawEdge(false)
        cooldown:SetDrawSwipe(true)
        cooldown:SetSwipeColor(0, 0, 0, 0.8)
        
        -- Count text
        local count = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        count:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
        count:SetText("")
        
        -- Time text
        local time = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        time:SetPoint("TOP", frame, "BOTTOM", 0, -1)
        time:SetText("")
        
        -- Name text
        local name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        name:SetPoint("BOTTOM", time, "BOTTOM", 0, -12)
        name:SetText("")
        name:SetWidth(60)
        name:SetWordWrap(false)
        name:SetJustifyH("CENTER")
        
        -- Store references
        frame.icon = icon
        frame.border = border
        frame.cooldown = cooldown
        frame.count = count
        frame.time = time
        frame.name = name
        
        -- Hide initially
        frame:Hide()
        
        -- Add to cue frames table
        cueFrames[i] = frame
    end
    
    -- Store container reference
    self.cueContainer = cueContainer
end

-- Update player specialization info
function CuesModule:UpdatePlayerSpec()
    -- Get current spec
    playerSpec = GetSpecialization()
    
    -- Clear current cues as spec has changed
    for id, _ in pairs(activeCues) do
        self:RemoveCue(id)
    end
    
    -- Reinitialize tracked abilities based on new spec
    self:InitTrackedAbilities()
    
    -- Check current auras
    self:CheckAuras("player")
    
    WE:Debug("Player spec updated to: " .. (playerSpec or "none"))
end

-- Check for auras that need cues
function CuesModule:CheckAuras(unit)
    if unit ~= "player" and unit ~= "target" then return end
    
    -- Check player buffs
    if unit == "player" then
        -- Check for tracked auras
        for category, spells in pairs(trackedSpells) do
            for _, spell in ipairs(spells) do
                -- Skip if not for current spec (if spell has a spec)
                if spell.spec and spell.spec ~= playerSpec then
                    -- Remove any existing cues for this spell
                    if activeCues[spell.id] then
                        self:RemoveCue(spell.id)
                    end
                    goto continue
                end
                
                -- Skip buffs if procs disabled
                if spell.type == "buff" and not WE:GetConfig("modules.Cues.procs", true) then
                    goto continue
                end
                
                -- Check for the aura
                local name, icon, count, _, duration, expirationTime = self:FindAura(unit, spell.id, spell.type)
                
                if name then
                    -- Aura is active, show or update cue
                    self:ShowCue(spell.id, name, icon, count, duration, expirationTime, spell.important, spell.sound)
                else
                    -- Aura not active, remove cue if it exists
                    if activeCues[spell.id] then
                        self:RemoveCue(spell.id)
                    end
                end
                
                ::continue::
            end
        end
    end
    
    -- Check target debuffs (if needed in the future)
    -- Currently not implemented
end

-- Check abilities on cooldown
function CuesModule:CheckCooldowns()
    -- Skip if cooldown tracking disabled
    if not WE:GetConfig("modules.Cues.cooldowns", true) then
        return
    end
    
    -- Scan action bars for cooldowns
    for i = 1, 120 do -- Check all action buttons
        local actionType, id = GetActionInfo(i)
        
        if actionType == "spell" then
            local start, duration, enable = GetSpellCooldown(id)
            
            if start > 0 and duration > 1.5 then -- Skip GCD
                local name, _, icon = GetSpellInfo(id)
                
                if name and icon then
                    -- Check if this is an important cooldown we want to track
                    local isTracked = false
                    local isImportant = false
                    local useSound = false
                    
                    -- Check against our list of important spells
                    for category, spells in pairs(trackedSpells) do
                        for _, spell in ipairs(spells) do
                            if spell.id == id then
                                isTracked = true
                                isImportant = spell.important
                                useSound = spell.sound
                                break
                            end
                        end
                        if isTracked then break end
                    end
                    
                    if isTracked then
                        local remaining = start + duration - GetTime()
                        self:ShowCooldownCue(id, name, icon, remaining, duration, isImportant, useSound)
                    end
                end
            elseif activeCues[id] and activeCues[id].isCooldown then
                -- Cooldown finished, remove the cue
                self:RemoveCue(id)
            end
        end
    end
end

-- Find an aura by spell ID
function CuesModule:FindAura(unit, spellId, auraType)
    local filter = (auraType == "buff") and "HELPFUL" or "HARMFUL"
    
    for i = 1, 40 do
        local name, icon, count, _, duration, expirationTime, _, _, _, id = UnitAura(unit, i, filter)
        if not name then break end
        
        if id == spellId then
            return name, icon, count, duration, expirationTime
        end
    end
    
    return nil
end

-- Show a cue for an active aura
function CuesModule:ShowCue(spellId, name, icon, count, duration, expirationTime, isImportant, playSound)
    -- Check if cue already exists
    if activeCues[spellId] then
        -- Update existing cue
        local cueIndex = activeCues[spellId].index
        local frame = cueFrames[cueIndex]
        
        if frame then
            -- Update count if changed
            if count and count > 0 then
                frame.count:SetText(count)
            else
                frame.count:SetText("")
            end
            
            -- Update cooldown if duration exists
            if duration and duration > 0 and expirationTime then
                local startTime = expirationTime - duration
                frame.cooldown:SetCooldown(startTime, duration)
            end
        end
    else
        -- Find an available cue slot
        local availableIndex = nil
        for i = 1, #cueFrames do
            if not cueFrames[i].inUse then
                availableIndex = i
                break
            end
        end
        
        -- If no slots available, consider replacing a less important cue
        if not availableIndex and isImportant then
            for id, cue in pairs(activeCues) do
                if not cue.important then
                    self:RemoveCue(id)
                    availableIndex = cue.index
                    break
                end
            end
        end
        
        -- If still no slots, just don't show this cue
        if not availableIndex then return end
        
        -- Create new cue
        local frame = cueFrames[availableIndex]
        frame.icon:SetTexture(icon)
        frame.name:SetText(name)
        
        if count and count > 0 then
            frame.count:SetText(count)
        else
            frame.count:SetText("")
        end
        
        if duration and duration > 0 and expirationTime then
            local startTime = expirationTime - duration
            frame.cooldown:SetCooldown(startTime, duration)
        end
        
        -- Show and highlight important cues
        if isImportant then
            frame.border:SetVertexColor(1, 0.3, 0.3, 1)
            -- Add glow animation if desired
            -- self:AddGlowAnimation(frame)
        else
            frame.border:SetVertexColor(1, 1, 1, 1)
        end
        
        frame.inUse = true
        frame:Show()
        
        -- Store in active cues
        activeCues[spellId] = {
            index = availableIndex,
            important = isImportant,
            isCooldown = false,
            expires = expirationTime
        }
        
        -- Play sound if enabled
        if playSound and isImportant then
            PlaySound(SOUNDKIT.RAID_WARNING, "Master")
        end
    end
end

-- Show a cue for an ability on cooldown
function CuesModule:ShowCooldownCue(spellId, name, icon, remaining, duration, isImportant, playSound)
    -- Only add/update if not already tracked as an active buff
    if activeCues[spellId] and not activeCues[spellId].isCooldown then
        return
    end
    
    -- Only track long cooldowns
    if duration < 10 then return end
    
    -- If already tracking this cooldown, just update it
    if activeCues[spellId] and activeCues[spellId].isCooldown then
        local cueIndex = activeCues[spellId].index
        local frame = cueFrames[cueIndex]
        
        if frame then
            local startTime = GetTime() - (duration - remaining)
            frame.cooldown:SetCooldown(startTime, duration)
            
            -- Update time text
            if remaining > 60 then
                frame.time:SetText(math.floor(remaining / 60) .. "m")
            else
                frame.time:SetText(math.floor(remaining) .. "s")
            end
        end
        return
    end
    
    -- Find an available cue slot
    local availableIndex = nil
    for i = 1, #cueFrames do
        if not cueFrames[i].inUse then
            availableIndex = i
            break
        end
    end
    
    -- If no slots available, don't show this cooldown
    if not availableIndex then return end
    
    -- Create new cooldown cue
    local frame = cueFrames[availableIndex]
    frame.icon:SetTexture(icon)
    frame.name:SetText(name)
    frame.count:SetText("")
    
    -- Set cooldown swipe (reversed for CDs)
    local startTime = GetTime() - (duration - remaining)
    frame.cooldown:SetCooldown(startTime, duration)
    frame.cooldown:SetDrawSwipe(true)
    frame.cooldown:SetReverse(false)
    
    -- Display remaining time
    if remaining > 60 then
        frame.time:SetText(math.floor(remaining / 60) .. "m")
    else
        frame.time:SetText(math.floor(remaining) .. "s")
    end
    
    -- Gray out icon for cooldowns
    frame.icon:SetDesaturated(true)
    frame.border:SetVertexColor(0.7, 0.7, 0.7, 1)
    
    frame.inUse = true
    frame:Show()
    
    -- Store in active cues
    activeCues[spellId] = {
        index = availableIndex,
        important = isImportant,
        isCooldown = true,
        expires = GetTime() + remaining
    }
    
    -- Set up timer to update the text
    C_Timer.After(1, function() self:UpdateCooldownCue(spellId) end)
end

-- Update cooldown cue time text
function CuesModule:UpdateCooldownCue(spellId)
    -- Check if cue still exists
    if not activeCues[spellId] or not activeCues[spellId].isCooldown then
        return
    end
    
    local cueData = activeCues[spellId]
    local remaining = cueData.expires - GetTime()
    
    -- If expired, remove the cue
    if remaining <= 0 then
        self:RemoveCue(spellId)
        return
    end
    
    -- Update text
    local frame = cueFrames[cueData.index]
    if frame then
        if remaining > 60 then
            frame.time:SetText(math.floor(remaining / 60) .. "m")
        else
            frame.time:SetText(math.floor(remaining) .. "s")
        end
    end
    
    -- Continue updating
    C_Timer.After(1, function() self:UpdateCooldownCue(spellId) end)
end

-- Remove a cue
function CuesModule:RemoveCue(spellId)
    if not activeCues[spellId] then
        return
    end
    
    local cueIndex = activeCues[spellId].index
    local frame = cueFrames[cueIndex]
    
    if frame then
        frame.inUse = false
        frame:Hide()
    end
    
    activeCues[spellId] = nil
    
    -- Reposition remaining cues (optional - can cause flickering if done too often)
    -- self:RepositionCues()
end

-- Reposition cues to avoid gaps
function CuesModule:RepositionCues()
    local visibleCues = {}
    
    -- First gather all visible cues
    for id, cueData in pairs(activeCues) do
        table.insert(visibleCues, {id = id, index = cueData.index})
    end
    
    -- Sort by current index to maintain order
    table.sort(visibleCues, function(a, b) return a.index < b.index end)
    
    -- Reassign cue indices
    for newIndex, cue in ipairs(visibleCues) do
        local oldIndex = activeCues[cue.id].index
        
        if newIndex ~= oldIndex then
            -- Move to new position
            local frame = cueFrames[oldIndex]
            
            -- Update visuals
            cueFrames[newIndex].icon:SetTexture(frame.icon:GetTexture())
            cueFrames[newIndex].count:SetText(frame.count:GetText())
            cueFrames[newIndex].time:SetText(frame.time:GetText())
            cueFrames[newIndex].name:SetText(frame.name:GetText())
            cueFrames[newIndex].border:SetVertexColor(frame.border:GetVertexColor())
            cueFrames[newIndex].icon:SetDesaturated(frame.icon:IsDesaturated())
            
            -- Handle cooldown
            local startTime, duration = frame.cooldown:GetCooldownTimes()
            if duration > 0 then
                cueFrames[newIndex].cooldown:SetCooldown(startTime/1000, duration/1000)
            end
            
            -- Show the frame at new position
            cueFrames[newIndex].inUse = true
            cueFrames[newIndex]:Show()
            
            -- Hide old position
            frame.inUse = false
            frame:Hide()
            
            -- Update index in storage
            activeCues[cue.id].index = newIndex
        end
    end
end

-- Test cue function
function CuesModule:TestCue()
    local testId = -1 -- Use negative ID to avoid conflicts
    local testName = "Test Cue"
    local testIcon = GetSpellTexture(61316) -- Prayer of Mending icon as a placeholder
    
    -- Remove existing test cue if any
    if activeCues[testId] then
        self:RemoveCue(testId)
    end
    
    -- Show test cue
    self:ShowCue(testId, testName, testIcon, 3, 10, GetTime() + 10, true, true)
    
    -- Auto-remove after 5 seconds
    C_Timer.After(5, function()
        if activeCues[testId] then
            self:RemoveCue(testId)
        end
    end)
end

-- Add a custom spell to track
function CuesModule:AddCustomSpell(spellIdStr)
    local spellId = tonumber(spellIdStr)
    if not spellId then
        WE:Print("Invalid spell ID: " .. spellIdStr)
        return
    end
    
    -- Check if spell exists
    local name, _, icon = GetSpellInfo(spellId)
    if not name then
        WE:Print("Spell with ID " .. spellId .. " not found.")
        return
    end
    
    -- Get custom spells table
    local customSpells = WE:GetConfig("modules.Cues.customSpells", {})
    
    -- Add to custom spells
    customSpells[tostring(spellId)] = {
        name = name,
        type = "buff", -- Assume buff by default
        important = true,
        sound = false
    }
    
    -- Save config
    WE:SetConfig("modules.Cues.customSpells", customSpells)
    
    -- Reinitialize tracked abilities
    self:InitTrackedAbilities()
    
    WE:Print("Added " .. name .. " (" .. spellId .. ") to tracked spells.")
end

-- Remove a custom spell from tracking
function CuesModule:RemoveCustomSpell(spellIdStr)
    local spellId = tonumber(spellIdStr)
    if not spellId then
        WE:Print("Invalid spell ID: " .. spellIdStr)
        return
    end
    
    -- Get custom spells table
    local customSpells = WE:GetConfig("modules.Cues.customSpells", {})
    
    -- Remove from custom spells
    if customSpells[tostring(spellId)] then
        local name = customSpells[tostring(spellId)].name
        customSpells[tostring(spellId)] = nil
        
        -- Save config
        WE:SetConfig("modules.Cues.customSpells", customSpells)
        
        -- Reinitialize tracked abilities
        self:InitTrackedAbilities()
        
        -- Remove any active cues for this spell
        if activeCues[spellId] then
            self:RemoveCue(spellId)
        end
        
        WE:Print("Removed " .. name .. " (" .. spellId .. ") from tracked spells.")
    else
        WE:Print("Spell with ID " .. spellId .. " is not in your custom spells.")
    end
end

-- List all tracked spells
function CuesModule:ListTrackedSpells()
    WE:Print("Tracked Spells:")
    
    for category, spells in pairs(trackedSpells) do
        if category == "CUSTOM" then
            WE:Print("Custom spells:")
        elseif category == "COMMON" then
            WE:Print("Common spells:")
        elseif category == "CLASS" then
            WE:Print(playerClass .. " spells:")
        end
        
        for _, spell in ipairs(spells) do
            local name = GetSpellInfo(spell.id) or spell.name
            local specText = ""
            if spell.spec then
                specText = " (Spec " .. spell.spec .. ")"
            end
            
            WE:Print(" - " .. name .. " (" .. spell.id .. ")" .. specText)
        end
    end
end

-- Handle configuration changes
function CuesModule:OnConfigChanged()
    -- Nothing specific needed here
end

-- Return the module
WE.CuesModule = CuesModule 