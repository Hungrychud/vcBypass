-- Matcha Speed (velocity override)
-- Matcha has no Instance.new / WalkSpeed / CharacterAdded, so no GUI and no
-- WalkSpeed writes. Instead we override HumanoidRootPart.Velocity each frame.
--
-- Usage: hold LEFT SHIFT to move at SPEED in your current move direction.
-- Release to return to normal. Edit SPEED below.

local SPEED = 64          -- studs/sec while boosting (normal walk is 16)
local BOOST_KEY = 304     -- LeftShift keycode value (Enum.KeyCode.LeftShift.Value)
local MOVE_THRESHOLD = 2  -- only override when actually moving

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local MASK = Vector3.xAxis + Vector3.zAxis  -- (1,0,1): zeroes vertical component

-- Kill a previous run if the script is executed again
if _G.__matchaSpeedConn then
	_G.__matchaSpeedConn:Disconnect()
	_G.__matchaSpeedConn = nil
end

local conn = RunService.Heartbeat:Connect(function()
	if not UserInputService:IsKeyDown(BOOST_KEY) then return end

	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local cur = hrp.Velocity
	local horiz = cur * MASK               -- current horizontal velocity
	if horiz.Magnitude < MOVE_THRESHOLD then return end  -- standing still: don't force

	-- keep moving in the same direction, but at SPEED; preserve vertical (gravity/jump)
	hrp.Velocity = horiz.Unit * SPEED + Vector3.yAxis * cur.Y
end)

_G.__matchaSpeedConn = conn
print("[MatchaSpeed] active. Hold LeftShift to move at " .. SPEED .. " studs/sec.")
