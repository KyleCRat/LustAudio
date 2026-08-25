local LSM = LibStub("LibSharedMedia-3.0")

local LUST_AUDIO = "lustaudio"
local MEDIA_PATH = "Interface\\AddOns\\LustAudio\\Media\\Audio\\"

local LUST_DURATION = 40
local LOCKOUT_DURATION = 600
local AURA_SCAN_DELAY = 0.05
local RECONCILE_INTERVAL = 1
local WORLD_SETTLE_DELAY = 1

local function RegisterSound(name, file)
    local path = MEDIA_PATH .. file
    LSM:Register(LUST_AUDIO, name, path)
end

RegisterSound("PedroLust", "PedroLust.mp3")

-- These are buff aura IDs, not the spellcast IDs. Older drums remain here
-- because they can still be used in level-scaled content.
local BLOODLUST_BUFFS = {
    2825,    -- Bloodlust
    32182,   -- Heroism
    80353,   -- Time Warp
    90355,   -- Ancient Hysteria
    160452,  -- Netherwinds
    264667,  -- Primal Rage
    390386,  -- Fury of the Aspects
    466904,  -- Harrier's Cry
    146555,  -- Drums of Rage
    178207,  -- Drums of Fury
    204276,  -- Drums of Battle
    230935,  -- Drums of the Mountain
    256740,  -- Drums of the Maelstrom
    272678,  -- Drums of Battle
    275200,  -- Drums of Battle
    292686,  -- Drums of the Maelstrom
    309658,  -- Drums of Deathly Ferocity
    381301,  -- Feral Hide Drums
    441076,  -- Timeless Drums
    444257,  -- Thunderous Drums
    1243972, -- Void-touched Drums
}

-- WoW 12.1 can hide the actual haste buff during restricted encounters. The
-- corresponding lockout remains readable and is used only as evidence that
-- the player gained a lust effect; it is never itself a playback trigger on
-- login, reload, or a world transition.
local BLOODLUST_LOCKOUTS = {
    57723,  -- Exhaustion
    57724,  -- Sated
    80354,  -- Temporal Displacement
    95809,  -- Insanity
    160455, -- Fatigued
    264689, -- Fatigued
    390435, -- Exhaustion
}

local function GetLustSounds()
    local list = {}
    for name in pairs(LSM:HashTable(LUST_AUDIO)) do
        list[name] = name
    end

    return list
end

local SOUND_CHANNELS = {
    ["Master"] = "Master (always plays)",
    ["SFX"] = "Sound Effects",
    ["Music"] = "Music",
    ["Ambience"] = "Ambience",
    ["Dialog"] = "Dialog",
}

local CHANNEL_ORDER = {
    "Master", "SFX", "Music", "Ambience", "Dialog",
}

local addon = LibStub("AceAddon-3.0"):NewAddon(
    "LustAudio",
    "AceConsole-3.0"
)

local defaults = {
    profile = {
        sound = "PedroLust",
        channel = "Music",
    },
}

local function FindReadablePlayerAura(spellIDs)
    for _, spellID in ipairs(spellIDs) do
        if not C_Secrets.ShouldSpellAuraBeSecret(spellID) then
            local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
            if aura then
                return aura
            end
        end
    end
end

local function ResolveAuraState(aura, previousExpiration, now, fallbackDuration)
    if aura then
        local expiration = aura.expirationTime
        if not issecretvalue(expiration) and expiration and expiration > now then
            return true, expiration, true
        end

        return true, now + fallbackDuration, false
    end

    if previousExpiration and now < previousExpiration then
        return true, previousExpiration, false
    end

    return false, nil, false
end

local options = {
    name = "LustAudio",
    type = "group",
    args = {
        sound = {
            order = 1,
            type = "select",
            width = "double",
            name = "Sound",
            desc = "Sound to play when your character gains a Bloodlust buff.",
            values = GetLustSounds,
            get = function()
                return addon.db.profile.sound
            end,
            set = function(_, value)
                addon.db.profile.sound = value
            end,
        },
        preview = {
            order = 2,
            type = "execute",
            width = "half",
            name = "Preview",
            desc = "Play the selected sound on the selected audio channel.",
            func = function()
                addon:PlaySelectedSound()
            end,
        },
        channel = {
            order = 3,
            type = "select",
            width = "double",
            name = "Sound Channel",
            desc = "Audio channel for playback.",
            values = SOUND_CHANNELS,
            sorting = CHANNEL_ORDER,
            get = function()
                return addon.db.profile.channel
            end,
            set = function(_, value)
                addon.db.profile.channel = value
            end,
        },
        soundHelp = {
            order = 4,
            type = "description",
            name =
                "\n" ..
                "Add custom sounds by registering them as " ..
                "`lustaudio` with SharedMedia. `lustaudio` is " ..
                "a custom type so the dropdown here only shows " ..
                "media meant to be used during lust.\n\n" ..
                "For more detailed instructions read the " ..
                "LustAudio/README.md and the SharedMedia " ..
                "MyMedia instructions.",
            fontSize = "medium",
        },
    },
}

local eventFrame = CreateFrame("Frame")

function addon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New(
        "LustAudioDB", defaults, true
    )

    LibStub("AceConfig-3.0"):RegisterOptionsTable(
        "LustAudio", options
    )

    local _, categoryID =
        LibStub("AceConfigDialog-3.0"):AddToBlizOptions(
            "LustAudio", "LustAudio"
        )
    self.categoryID = categoryID

    self:RegisterChatCommand("la", "SlashCommand")
end

function addon:SlashCommand()
    Settings.OpenToCategory(self.categoryID)
end

function addon:StopSelectedSound()
    if not self.soundHandle then
        return
    end

    StopSound(self.soundHandle)
    self.soundHandle = nil
end

function addon:PlaySelectedSound()
    local path = LSM:Fetch(LUST_AUDIO, self.db.profile.sound)
    if not path then
        return
    end

    self:StopSelectedSound()

    local didPlay, soundHandle = PlaySoundFile(
        path, self.db.profile.channel
    )
    if didPlay then
        self.soundHandle = soundHandle
    end
end

function addon:UpdateLustState(suppressPlayback)
    local now = GetTime()
    local previousLustActive = self.lustActive == true
    local previousLockoutActive = self.lockoutActive == true
    local previousLockoutExpiration = self.lockoutExpiration

    local lustAura = FindReadablePlayerAura(BLOODLUST_BUFFS)
    local lustActive, lustExpiration = ResolveAuraState(
        lustAura, self.lustExpiration, now, LUST_DURATION
    )

    local lockoutAura = FindReadablePlayerAura(BLOODLUST_LOCKOUTS)
    local lockoutActive, lockoutExpiration, observedLockoutExpiration =
        ResolveAuraState(
            lockoutAura,
            previousLockoutExpiration,
            now,
            LOCKOUT_DURATION
        )

    local lockoutReapplied = observedLockoutExpiration
        and previousLockoutExpiration
        and lockoutExpiration > previousLockoutExpiration + 1
    local gainedLust = lustActive and not previousLustActive
    local gainedLockout = lockoutActive and not previousLockoutActive

    self.lustActive = lustActive
    self.lustExpiration = lustExpiration
    self.lockoutActive = lockoutActive
    self.lockoutExpiration = lockoutExpiration

    if suppressPlayback then
        self.playedForCurrentLockout = lustActive or lockoutActive
        return
    end

    if not lustActive and not lockoutActive then
        self.playedForCurrentLockout = false
        return
    end

    if lockoutReapplied then
        self.playedForCurrentLockout = false
    end

    local gainedLustCycle = gainedLust or gainedLockout or lockoutReapplied
    if gainedLustCycle and not self.playedForCurrentLockout then
        self.playedForCurrentLockout = true

        if not UnitIsDeadOrGhost("player") then
            self:PlaySelectedSound()
        end
    end
end

function addon:CancelAuraScan()
    if self.auraScanTimer then
        self.auraScanTimer:Cancel()
        self.auraScanTimer = nil
    end
end

function addon:QueueAuraScan()
    if not self.isWorldReady or self.auraScanTimer then
        return
    end

    self.auraScanTimer = C_Timer.NewTimer(AURA_SCAN_DELAY, function()
        self.auraScanTimer = nil

        if self.isWorldReady then
            self:UpdateLustState(false)
        end
    end)
end

function addon:CancelWorldReadyTimer()
    if self.worldReadyTimer then
        self.worldReadyTimer:Cancel()
        self.worldReadyTimer = nil
    end
end

function addon:ScheduleWorldReady()
    self:CancelWorldReadyTimer()
    self.worldReadyTimer = C_Timer.NewTimer(WORLD_SETTLE_DELAY, function()
        self.worldReadyTimer = nil
        self:UpdateLustState(true)
        self.isWorldReady = true
    end)
end

function addon:OnDetectionEvent(event)
    if event == "LOADING_SCREEN_ENABLED" then
        self.isWorldReady = false
        self:CancelAuraScan()
        self:CancelWorldReadyTimer()
        self:StopSelectedSound()
    elseif event == "PLAYER_ENTERING_WORLD" then
        self.isWorldReady = false
        self:CancelAuraScan()
        self:StopSelectedSound()
        self:ScheduleWorldReady()
    elseif event == "UNIT_AURA" then
        self:QueueAuraScan()
    end
end

function addon:OnEnable()
    self.lustActive = false
    self.lustExpiration = nil
    self.lockoutActive = false
    self.lockoutExpiration = nil
    self.playedForCurrentLockout = false
    self.isWorldReady = false

    eventFrame:RegisterEvent("LOADING_SCREEN_ENABLED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterUnitEvent("UNIT_AURA", "player")

    self.reconcileTicker = C_Timer.NewTicker(RECONCILE_INTERVAL, function()
        if self.isWorldReady then
            self:UpdateLustState(false)
        end
    end)

    self:ScheduleWorldReady()
end

function addon:OnDisable()
    eventFrame:UnregisterAllEvents()
    self:CancelAuraScan()
    self:CancelWorldReadyTimer()

    if self.reconcileTicker then
        self.reconcileTicker:Cancel()
        self.reconcileTicker = nil
    end

    self:StopSelectedSound()
    self.isWorldReady = false
end

eventFrame:SetScript("OnEvent", function(_, event)
    addon:OnDetectionEvent(event)
end)
