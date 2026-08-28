--[[
    Voice Chat Bypass
    ==================================================================
    CREDITS / ATTRIBUTION
      - Concept & original protected script: marbeg
        (Luarmor loader, script_id 74c74f95fd0-marbeg). Idea only --
        no code was copied or de-obfuscated from that script.
      - Roblox internal API names verified against the public
        client mirror: MaximumADHD/Roblox-Client-Tracker
        (scripts/CoreScripts/Modules/VoiceChat/VoiceChatServiceManager.lua)
      - Eligibility-check API cross-checked from community references.

    This is an ORIGINAL from-scratch implementation. Extend / twist it.
    ==================================================================
    HOW IT WORKS
      Roblox's client decides voice eligibility in CoreVoiceManager,
      which is populated from VoiceChatService:IsVoiceEnabledForUserIdAsync.
      The CoreGui module returns a class with a singleton at `.default`,
      and `.default.coreVoiceManager` is the real decision object; the
      facade just delegates (UserVoiceEnabled -> coreVoiceManager, etc).

      Those manager methods are plain Lua functions on a required table,
      so we can OVERWRITE them to report "eligible" with NO hook
      primitive at all. The only C-side call (IsVoiceEnabledForUserIdAsync)
      is patched via hookfunction/hookmetamethod when available.
      Then we asyncInit + JoinVoice so the mic UI spawns and connects.

    REQUIREMENTS
      Full-featured executor with the standard Instance API + require of
      CoreGui modules. Hook primitives are OPTIONAL (improve reliability).
      Does NOT run on Matcha (no require of core modules, no hooks,
      voice methods unbound).

    UNTESTED: written from verified API, not run on a live client here.
      Flag names / method presence drift between client versions -- the
      pcall guards below degrade gracefully; confirm on your executor.
]]

local Players          = game:GetService("Players")
local VoiceChatService = game:GetService("VoiceChatService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local function log(...) warn("[vcBypass]", ...) end

-- ------------------------------------------------------------------
-- 1. Optional: patch the C-side eligibility call to always say "yes".
--    Uses whatever hook primitive the executor exposes; skipped if none.
-- ------------------------------------------------------------------
local ENV      = getfenv()
local hookfn   = rawget(ENV, "hookfunction")   or rawget(ENV, "replaceclosure")
local hookmeta = rawget(ENV, "hookmetamethod")
local getnc    = rawget(ENV, "getnamecallmethod")

local ELIGIBILITY_CALLS = {
    IsVoiceEnabledForUserIdAsync         = true,
    IsVoiceEnabledForUserIdAndPlaceAsync = true,
    IsVoiceEnabledForPlaceAsync          = true,
}

if hookmeta and getnc then
    local ok, err = pcall(function()
        local original
        original = hookmeta(game, "__namecall", function(self, ...)
            local method = getnc()
            if method and ELIGIBILITY_CALLS[method] then
                return true
            end
            return original(self, ...)
        end)
    end)
    if ok then log("namecall eligibility hook installed") end
elseif hookfn then
    for name in pairs(ELIGIBILITY_CALLS) do
        local fn = VoiceChatService[name]
        if typeof(fn) == "function" then
            pcall(hookfn, fn, function() return true end)
        end
    end
    log("hookfunction eligibility patch attempted")
else
    log("no hook primitive -- relying on manager method overwrites only")
end

-- ------------------------------------------------------------------
-- 2. Require the CoreGui voice manager singleton.
-- ------------------------------------------------------------------
local mgr
do
    local ok, modOrErr = pcall(function()
        local module = CoreGui:WaitForChild("RobloxGui")
            :WaitForChild("Modules")
            :WaitForChild("VoiceChat")
            :WaitForChild("VoiceChatServiceManager")
        return require(module)
    end)
    if not ok then
        log("cannot require VoiceChatServiceManager:", modOrErr)
        return
    end
    -- module returns the class; the live instance is `.default`
    mgr = (type(modOrErr) == "table" and modOrErr.default) or modOrErr
end

if not mgr then
    log("no manager instance resolved")
    return
end

local core = rawget(mgr, "coreVoiceManager") or mgr.coreVoiceManager

-- ------------------------------------------------------------------
-- 3. Overwrite the Lua eligibility methods on both the facade and the
--    core manager so every gate reports the user as voice-eligible.
--    No hook primitive required -- these are writable table fields.
-- ------------------------------------------------------------------
local TRUE_METHODS = {
    "UserVoiceEnabled",
    "UserOnlyEligibleForVoice",
    "UserOnlyEligibleForVoiceViaOverlay",
    "ShouldShowJoinVoice",
    "canUseService",
    "userAndPlaceCanUseVoice",
    "verifyUniverseAndPlaceCanUseVoice",
    "VoiceChatAvailable",
}

local function forceTrue(tbl, label)
    if type(tbl) ~= "table" then return end
    for _, name in ipairs(TRUE_METHODS) do
        if type(rawget(tbl, name)) == "function" or type(tbl[name]) == "function" then
            pcall(function() tbl[name] = function() return true end end)
        end
    end
    log("eligibility methods forced on", label)
end

forceTrue(mgr, "facade")
forceTrue(core, "coreVoiceManager")

-- ------------------------------------------------------------------
-- 4. Kick off init + join. Guarded because names/flags vary by version.
-- ------------------------------------------------------------------
task.spawn(function()
    -- asyncInit returns a Promise (:andThen/:catch). Support both promise
    -- and plain-return executors.
    local ok, result = pcall(function() return mgr:asyncInit() end)
    if ok and type(result) == "table" and type(result.andThen) == "function" then
        result:andThen(function()
            pcall(function() mgr:EnableVoice() end)
            pcall(function() mgr:JoinVoice() end)
        end):catch(function(e)
            log("asyncInit rejected:", e)
        end)
    else
        pcall(function() mgr:EnableVoice() end)
        pcall(function() mgr:JoinVoice() end)
    end
    pcall(function() mgr:ShowVoiceUI() end)
    log("init + join dispatched -- mic button should appear")
end)
