# Changelog

All notable changes to Lust Audio will be documented in this file.

## [12.0.1-4] - 2026-03-06

### Changed
- Audio no longer stops when combat ends — it plays to completion
- Audio stops on player death instead of combat end

## [12.0.1-3] - 2026-03-06

### Changed
- Detect bloodlust via sated/exhaustion debuffs instead of cast spell IDs
- Audio triggers on the not-sated to sated transition, so it works regardless of who cast lust
- Assumes sated on login/reload to prevent false triggers from an existing debuff
