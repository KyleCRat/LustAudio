local LSM = LibStub("LibSharedMedia-3.0")

local LUST_AUDIO = "lustaudio"

local MEDIA_PATH = "Interface\\AddOns\\LustAudio\\Media\\Audio\\"

local function RegisterSound(name, file)
    local path = MEDIA_PATH .. file
    LSM:Register(LUST_AUDIO, name, path)
end

RegisterSound("PedroLust", "PedroLust.mp3")

local SATED_DEBUFFS = {
    [57723] = true,  -- Exhaustion
    [57724] = true,  -- Sated
    [80354] = true,  -- Temporal Displacement
    [95809] = true,  -- Insanity (Hunter Pet)
    [160455] = true, -- Fatigued (Hunter Pet)
    [264689] = true, -- Fatigued (Hunter Pet)
    [390435] = true, -- Exhaustion
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

local options = {
    name = "LustAudio",
    type = "group",
    args = {
        sound = {
            order = 1,
            type = "select",
            width = "double",
            name = "Sound",
            desc = "Sound to play when bloodlust is cast.",
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
                local sound = addon.db.profile.sound
                local path = LSM:Fetch(LUST_AUDIO, sound)
                if path then
                    PlaySoundFile(
                        path,
                        addon.db.profile.channel
                    )
                end
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

local function HasSatedDebuff()
    for spellID in pairs(SATED_DEBUFFS) do
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
        if aura then
            return true
        end
    end

    return false
end

function addon:OnEnable()
    self.isSated = true
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("PLAYER_DEAD")
end

function addon:UNIT_AURA(_, unit)
    if unit ~= "player" then
        return
    end

    local wasSated = self.isSated
    self.isSated = HasSatedDebuff()

    if wasSated or not self.isSated then
        return
    end

    local path = LSM:Fetch(LUST_AUDIO, self.db.profile.sound)
    if not path then
        return
    end

    local _, handle = PlaySoundFile(
        path, self.db.profile.channel
    )
    self.soundHandle = handle
end

function addon:PLAYER_DEAD()
    if not self.soundHandle then
        return
    end

    StopSound(self.soundHandle)
    self.soundHandle = nil
end
