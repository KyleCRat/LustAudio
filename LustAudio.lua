local LSM = LibStub("LibSharedMedia-3.0")

local LUST_AUDIO = "lustaudio"

local MEDIA_PATH = "Interface\\AddOns\\LustAudio\\Media\\Audio\\"

local function RegisterSound(name, file)
    local path = MEDIA_PATH .. file
    LSM:Register(LUST_AUDIO, name, path)
end

RegisterSound("PedroLust", "PedroLust.mp3")

local BLOODLUST_SPELLS = {
    [2825] = true,   -- Bloodlust (Shaman)
    [32182] = true,  -- Heroism (Shaman)
    [80353] = true,  -- Time Warp (Mage)
    [264667] = true, -- Primal Rage (Hunter Pet)
    [390386] = true, -- Fury of the Aspects (Evoker)
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

function addon:OnEnable()
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

function addon:UNIT_SPELLCAST_SUCCEEDED(_, unit, _, spellID)
    if unit ~= "player" then
        return
    end

    if not BLOODLUST_SPELLS[spellID] then
        return
    end

    local path = LSM:Fetch(LUST_AUDIO, self.db.profile.sound)
    if not path then
        return
    end

    PlaySoundFile(path, self.db.profile.channel)
end
