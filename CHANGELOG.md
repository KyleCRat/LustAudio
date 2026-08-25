# Changelog

## [12.1.0-10] - 2026-08-25
- Replaced independent native sound registrations with one player-level lust
  state machine
- Prevented simultaneous lust effects from starting duplicate audio tracks
- Suppressed playback while aura state is initialized after login, reload, and
  zone transitions
- Stopped an active LustAudio track when a loading screen or world transition
  begins
- Added Harrier's Cry and current and legacy drum buff variants
- Coalesced rapid player-aura updates and retained known aura state across
  temporary loading gaps

## [12.1.0-9] - 2026-08-10
- Targeted WoW 12.1 and its native aura-sound API exclusively
- Changed playback triggers from sated/exhaustion debuffs to the actual
  Bloodlust-class haste buffs
- Prevented existing exhaustion effects from replaying audio after zone changes
- Deferred sound registration changes while combat or secret-aura restrictions
  are active
