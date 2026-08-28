# vcBypass

Voice Chat eligibility bypass for Roblox. Forces the client to treat the
local user as voice-eligible, then initialises and joins voice so the mic
UI appears.

## Loader

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Hungrychud/vcBypass/main/vcBypass.lua"))()
```

## Requirements

- Full-featured executor with the standard Instance API and `require` of
  CoreGui modules.
- Hook primitives (`hookfunction` / `hookmetamethod`) are **optional** —
  they patch the C-side eligibility call for extra reliability, but the
  core bypass works without them by overwriting the manager's Lua
  eligibility methods.
- **Does not run on Matcha** — no `require` of core modules, no hook
  primitives, voice methods unbound.

## How it works

Roblox decides voice eligibility in `CoreVoiceManager`, populated from
`VoiceChatService:IsVoiceEnabledForUserIdAsync`. The CoreGui module
`VoiceChatServiceManager` returns a class whose singleton lives at
`.default`, and `.default.coreVoiceManager` is the real decision object.
The script:

1. (Optional) hooks the C-side `IsVoiceEnabledForUserIdAsync` to return `true`.
2. Requires the manager singleton.
3. Overwrites the Lua eligibility methods (`UserVoiceEnabled`,
   `UserOnlyEligibleForVoice`, `ShouldShowJoinVoice`, `canUseService`, ...)
   to report the user as eligible — no hook needed.
4. Calls `asyncInit` + `EnableVoice` + `JoinVoice` + `ShowVoiceUI`.

## Status

Untested on a live client. Built from the verified public client source,
not run here. Method names / FFlags drift between client versions; the
`pcall` guards degrade gracefully. Confirm on your executor and tweak.

## Credits

- **Concept & original protected script:** marbeg (Luarmor loader,
  script_id `74c74f95fd0-marbeg`). Idea only — no code was copied or
  de-obfuscated from that script.
- **Roblox internal API names:** verified against
  [MaximumADHD/Roblox-Client-Tracker](https://github.com/MaximumADHD/Roblox-Client-Tracker)
  (`scripts/CoreScripts/Modules/VoiceChat/VoiceChatServiceManager.lua`).

This repository is an original, from-scratch reimplementation. Extend and
modify freely.
