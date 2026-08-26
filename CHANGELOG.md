# Changelog

## [12.1.0-11] - 2026-08-26
- Re-armed lust detection when a loading screen finishes so entering a dungeon
  or changing zones cannot leave detection paused
- Preserved silent post-load initialization so existing lust lockouts never
  trigger playback during a world transition

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
