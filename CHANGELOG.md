# Changelog

## [12.1.0-9] - 2026-08-10
- Targeted WoW 12.1 and its native aura-sound API exclusively
- Changed playback triggers from sated/exhaustion debuffs to the actual
  Bloodlust-class haste buffs
- Prevented existing exhaustion effects from replaying audio after zone changes
- Deferred sound registration changes while combat or secret-aura restrictions
  are active

## [12.1.0-8] - 2026-08-10
- Updated for WoW 12.1.0
- Added secret-value-safe handling for aura and unit event data
