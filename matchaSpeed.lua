-- Matcha Speed + Anti-Rubberband (keyboard controlled)
--
-- Matcha has NO Instance.new, so a real GUI is impossible. Controls are keys.
-- Matcha has no WalkSpeed either, so speed is done by overriding
-- HumanoidRootPart.Velocity every Heartbeat.
--
-- CONTROLS:
--   G  = toggle speed ON / OFF
--   ]  = speed up   (+8)
--   [  = speed down (-8)
--   \  = reset to default speed
--
-- ANTI-RUBBERBAND:
--   Server anti-cheat "teleports you back" when you move too fast. You cannot
--   truly override a server-authoritative reset from the client, but Roblox
--   character physics are client-owned, so the practical bypass is to ride
--   just under the detection threshold. This auto-tuner ramps your speed and,
--   the moment it detects a backward yank, drops the effective speed and slowly
--   recovers. Net effect: you glide at the fastest speed the game won't punish.

local TARGET_SPEED   = 64    -- your requested speed (studs/sec). Change with ] / [
local DEFAULT_SPEED  = 16
local SPEED_STEP     = 8
local MIN_SPEED       = 20
local MOVE_THRESHOLD = 2     -- only override when actually moving
local YANK_DIST      = 6     -- backward jump (studs, 1 frame) that counts as a rubberband
local BACKOFF        = 0.6   -- multiply safe speed by this on a yank
local RECOVER_RATE   = 12    -- studs/sec added back per second when not being yanked

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local MASK = Vector3.xAxis + Vector3.zAxis  -- (1,0,1): strips vertical component

-- key codes (numbers; Matcha IsKeyDown needs a number, not an EnumItem)
local K_TOGGLE = Enum.KeyCode.G.Value
local K_UP     = Enum.KeyCode.RightBracket.Value
local K_DOWN   = Enum.KeyCode.LeftBracket.Value
local K_RESET  = Enum.KeyCode.Backslash.Value

-- kill previous run
if _G.__matchaSpeedConn then
	_G.__matchaSpeedConn:Disconnect()
	_G.__matchaSpeedConn = nil
end

local enabled   = false
local userSpeed = TARGET_SPEED
local safeSpeed = TARGET_SPEED   -- auto-tuned cap
local lastPos   = nil
local prevDown  = {}             -- edge detection for key taps

local function tap(keycode)
	-- true only on the frame the key goes from up -> down
	local down = UserInputService:IsKeyDown(keycode)
	local was = prevDown[keycode]
	prevDown[keycode] = down
	return down and not was
end

local conn = RunService.Heartbeat:Connect(function(dt)
	dt = dt or (1/60)

	-- handle key taps (edge triggered)
	if tap(K_TOGGLE) then
		enabled = not enabled
		lastPos = nil
		print("[MatchaSpeed] " .. (enabled and "ON" or "OFF"))
	end
	if tap(K_UP) then
		userSpeed = userSpeed + SPEED_STEP
		safeSpeed = userSpeed
		print("[MatchaSpeed] speed = " .. userSpeed)
	end
	if tap(K_DOWN) then
		userSpeed = math.max(MIN_SPEED, userSpeed - SPEED_STEP)
		safeSpeed = math.min(safeSpeed, userSpeed)
		print("[MatchaSpeed] speed = " .. userSpeed)
	end
	if tap(K_RESET) then
		userSpeed = DEFAULT_SPEED
		safeSpeed = DEFAULT_SPEED
		print("[MatchaSpeed] speed reset = " .. userSpeed)
	end

	if not enabled then
		lastPos = nil
		return
	end

	local char = player.Character
	if not char then lastPos = nil; return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then lastPos = nil; return end

	local cur = hrp.Velocity
	local horiz = cur * MASK
	local pos = hrp.Position

	-- anti-rubberband: did we get yanked backward against our move direction?
	if lastPos and horiz.Magnitude > MOVE_THRESHOLD then
		local dir = horiz.Unit
		local disp = pos - lastPos
		local forward = disp:Dot(dir)            -- signed progress along move dir
		if forward < -YANK_DIST then
			-- server pulled us back -> drop under the threshold
			safeSpeed = math.max(MIN_SPEED, safeSpeed * BACKOFF)
			print("[MatchaSpeed] rubberband! safe speed -> " .. math.floor(safeSpeed))
		else
			-- no punishment: creep back toward the speed you asked for
			safeSpeed = math.min(userSpeed, safeSpeed + RECOVER_RATE * dt)
		end
	end
	lastPos = pos

	-- apply speed in the current move direction, keep vertical (gravity/jump)
	if horiz.Magnitude > MOVE_THRESHOLD then
		hrp.Velocity = horiz.Unit * safeSpeed + Vector3.yAxis * cur.Y
	end
end)

_G.__matchaSpeedConn = conn
print("[MatchaSpeed] loaded. G=toggle  ]=faster  [=slower  \\=reset. Start speed " .. userSpeed)
