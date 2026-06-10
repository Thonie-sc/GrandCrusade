Crusader's Path :: Custom Sounds
================================

The "area purged" notification plays a cathedral bell toll (a built-in Classic
sound) followed, a beat later, by a CUSTOM fanfare that ships with the addon.

To supply that fanfare, place your audio file here as:

    Sounds\PurgeFanfare.ogg

Requirements (WoW Classic / 1.15.x):
  - Format:  Ogg Vorbis (.ogg) is preferred. MP3 (.mp3) also works.
             WAV is NOT supported by PlaySoundFile in modern clients.
  - Name:    PurgeFanfare.ogg  (exact, case-insensitive on Windows)
  - Length:  keep it short - roughly 1 to 3 seconds works best.
  - Channels/rate: mono or stereo, 44100 Hz is safe.

If you prefer a different filename or .mp3, change PURGE_SOUND near the top of
    Modules\Notify.lua
to match, e.g.:
    local PURGE_SOUND = "Interface\\AddOns\\CrusadersPath\\Sounds\\YourFile.mp3"

Notes:
  - The path is relative to the WoW AddOns folder and is case-insensitive on
    Windows, but keep the literal "Interface\AddOns\CrusadersPath\Sounds\" prefix.
  - If the file is missing, the game simply skips it (no error) and you still
    hear the bell toll.
  - After adding or changing the file, fully restart the client (a /reload does
    not always re-scan newly added media files). Then preview with:
        /crusade purge
