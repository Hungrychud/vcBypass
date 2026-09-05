-- Speed GUI
-- LocalScript: place in StarterPlayer > StarterPlayerScripts (or run via executor)
-- Lets you set your character's WalkSpeed with a draggable on-screen panel.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local DEFAULT_SPEED = 16
local currentSpeed = DEFAULT_SPEED
local enabled = false

--// Apply speed to current character's humanoid
local function getHumanoid()
	local char = player.Character or player.CharacterAdded:Wait()
	return char:FindFirstChildOfClass("Humanoid")
end

local function applySpeed()
	local hum = getHumanoid()
	if hum then
		hum.WalkSpeed = enabled and currentSpeed or DEFAULT_SPEED
	end
end

-- Reapply on respawn so speed persists across deaths
player.CharacterAdded:Connect(function()
	task.wait(0.2)
	applySpeed()
end)

--// Build GUI
local gui = Instance.new("ScreenGui")
gui.Name = "SpeedGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(220, 120)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
title.BorderSizePixel = 0
title.Text = "Speed GUI"
title.TextColor3 = Color3.fromRGB(235, 235, 240)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = frame

local titleCorner = corner:Clone()
titleCorner.Parent = title

-- Speed input box
local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -20, 0, 32)
box.Position = UDim2.fromOffset(10, 40)
box.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
box.BorderSizePixel = 0
box.Text = tostring(currentSpeed)
box.PlaceholderText = "Speed…"
box.TextColor3 = Color3.fromRGB(235, 235, 240)
box.Font = Enum.Font.Gotham
box.TextSize = 14
box.ClearTextOnFocus = false
box.Parent = frame

local boxCorner = corner:Clone()
boxCorner.Parent = box

-- Toggle button
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, -20, 0, 32)
toggle.Position = UDim2.fromOffset(10, 78)
toggle.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
toggle.BorderSizePixel = 0
toggle.Text = "OFF"
toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 14
toggle.Parent = frame

local toggleCorner = corner:Clone()
toggleCorner.Parent = toggle

--// Logic
local function refreshToggleVisual()
	toggle.Text = enabled and "ON" or "OFF"
	toggle.BackgroundColor3 = enabled and Color3.fromRGB(60, 170, 90) or Color3.fromRGB(180, 60, 60)
end

toggle.MouseButton1Click:Connect(function()
	enabled = not enabled
	refreshToggleVisual()
	applySpeed()
end)

box.FocusLost:Connect(function()
	local n = tonumber(box.Text)
	if n and n > 0 then
		currentSpeed = n
		if enabled then applySpeed() end
	end
	box.Text = tostring(currentSpeed)
end)

--// Drag (title bar)
local dragging, dragStart, startPos
title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)
