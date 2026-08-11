local LSM = LibStub("LibSharedMedia-3.0")

local LUST_AUDIO = "lustaudio"

local MEDIA_PATH = "Interface\\AddOns\\LustAudio\\Media\\Audio\\"

local function RegisterSound(name, file)
    local path = MEDIA_PATH .. file
    LSM:Register(LUST_AUDIO, name, path)
end

RegisterSound("PedroLust", "PedroLust.mp3")

-- Track the short-lived haste buffs themselves, not the long-lived
-- exhaustion effects. This prevents zoning with an existing lockout from
-- being treated as a new Bloodlust application.
local BLOODLUST_BUFFS = {
    2825,   -- Bloodlust
    32182,  -- Heroism
    80353,  -- Time Warp
    90355,  -- Ancient Hysteria
    160452, -- Netherwinds
    264667, -- Primal Rage
    390386, -- Fury of the Aspects
}

local AURA_SOUND_RETRY_EVENTS = {
    "PLAYER_REGEN_ENABLED",
    "ENCOUNTER_END",
    "PLAYER_ENTERING_WORLD",
    "ZONE_CHANGED_NEW_AREA",
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
    "AceConsole-3.0",
    "AceEvent-3.0"
)

local defaults = {
    profile = {
        sound = "PedroLust",
        channel = "Music",
    },
}

local function CanChangeAuraSoundRegistrations()
    return not InCombatLockdown()
        and not C_Secrets.ShouldAurasBeSecret()
end

local function RemoveAuraSoundRegistrations(registrationIDs)
    if not registrationIDs then
        return
    end

    for _, registrationID in ipairs(registrationIDs) do
        C_UnitAuras.RemoveAuraSound(registrationID)
    end
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
            desc = "Sound to play when a Bloodlust buff is applied.",
            values = GetLustSounds,
            get = function()
                return addon.db.profile.sound
            end,
            set = function(_, value)
                addon.db.profile.sound = value
                addon:RefreshAuraSounds()
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
                addon:RefreshAuraSounds()
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

function addon:PlaySelectedSound()
    local path = LSM:Fetch(LUST_AUDIO, self.db.profile.sound)
    if not path then
        return
    end

    PlaySoundFile(path, self.db.profile.channel)
end

function addon:RegisterAuraSoundRetryEvents()
    for _, event in ipairs(AURA_SOUND_RETRY_EVENTS) do
        self:RegisterEvent(event, "RetryAuraSoundRefresh")
    end
end

function addon:UnregisterAuraSoundRetryEvents()
    for _, event in ipairs(AURA_SOUND_RETRY_EVENTS) do
        self:UnregisterEvent(event)
    end
end

function addon:ClearAuraSounds()
    local registrationIDs = self.auraSoundRegistrationIDs
    self.auraSoundRegistrationIDs = nil
    RemoveAuraSoundRegistrations(registrationIDs)
end

function addon:TryRegisterAuraSounds()
    local path = LSM:Fetch(LUST_AUDIO, self.db.profile.sound)
    if not path then
        self:ClearAuraSounds()
        return true
    end

    local registrationIDs = {}
    for _, spellID in ipairs(BLOODLUST_BUFFS) do
        local registrationID = C_UnitAuras.AddAuraSound(
            Enum.UnitAuraSoundTrigger.Added,
            {
                unitToken = "player",
                spellID = spellID,
                soundFileName = path,
                outputChannel = self.db.profile.channel,
            }
        )

        if not registrationID then
            RemoveAuraSoundRegistrations(registrationIDs)
            return false
        end

        registrationIDs[#registrationIDs + 1] = registrationID
    end

    local previousRegistrationIDs = self.auraSoundRegistrationIDs
    self.auraSoundRegistrationIDs = registrationIDs
    RemoveAuraSoundRegistrations(previousRegistrationIDs)
    return true
end

function addon:RefreshAuraSounds()
    if not CanChangeAuraSoundRegistrations() then
        self:RegisterAuraSoundRetryEvents()
        return false
    end

    if not self:TryRegisterAuraSounds() then
        self:RegisterAuraSoundRetryEvents()
        return false
    end

    self:UnregisterAuraSoundRetryEvents()
    return true
end

function addon:RetryAuraSoundRefresh()
    self:RefreshAuraSounds()
end

function addon:OnEnable()
    self:RefreshAuraSounds()
end

function addon:OnDisable()
    self:UnregisterAllEvents()
    self:ClearAuraSounds()
end
