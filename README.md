## How It Works

LustAudio plays a sound when a bloodlust effect is activated. It detects lust
only on the player and treats all supported Bloodlust-class buffs as one state.
This includes Bloodlust, Heroism, Time Warp, Hunter and Evoker variants, and
drums. Simultaneous lust casts therefore start only one audio track.

When WoW exposes the actual buff, LustAudio detects it directly. During
restricted encounters where WoW hides that buff from addons, LustAudio uses the
new lockout on the player as evidence that the same lust effect was gained. An
existing Sated, Exhaustion, or equivalent lockout never triggers playback by
itself. Current state is initialized silently after login, reload, and zone
transitions, and an active LustAudio track stops when a loading screen begins.

Configure the sound and audio channel via `/la` or the addon settings panel.

## Adding Custom Audio

LustAudio uses a custom SharedMedia type called `lustaudio` so the sound picker
only shows sounds meant for lust, rather than every sound registered with
SharedMedia.

You can add your own audio files by creating a small addon called
`SharedMedia_MyMedia`. More detailed instructions can be found within the
SharedMedia addon.

### Setup

1. Follow the instructions within the SharedMedia addon to create your
   `SharedMedia_MyMedia` addon.

2. Place your audio files (`.mp3` or `.ogg`) anywhere inside the
   `SharedMedia_MyMedia/lustaudio` subfolder:

   ```
   SharedMedia_MyMedia\lustaudio\MySound.mp3
   ```

3. Add a register line to `MyMedia.lua` for each audio file. You
   must register to the `lustaudio` type (not `sound`):

   ```lua
   LSM:Register("lustaudio", "My Sound Name",
       [[Interface\AddOns\SharedMedia_MyMedia\lustaudio\MySound.mp3]])
   ```

4. Restart the game (or reload the UI with `/reload`). Your new
   sounds will appear in the LustAudio sound picker.

### MyMedia.lua Examples

```lua
LSM:Register("lustaudio", "Air Horn",
    [[Interface\AddOns\SharedMedia_MyMedia\lustaudio\AirHorn.mp3]])

LSM:Register("lustaudio", "Hype Music",
    [[Interface\AddOns\SharedMedia_MyMedia\lustaudio\HypeMusic.ogg]])
```

### Notes

- The first argument must be `"lustaudio"`, not `"sound"`. The
  `sound` type contains hundreds of entries and is not used by this
  addon.
- The second argument is the display name shown in the picker.
- The path uses backslashes and must be wrapped in `[[ ]]`.
- Supported formats are `.mp3` and `.ogg`.
