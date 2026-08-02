--!nonstrict

-- © 2026 Sai — All original content reserved. Do not copy, paste, redistribute, or claim as your own.

local environment = (getgenv and getgenv()) or _G or (getfenv and getfenv()) or {}

local hooks = environment.pullFile("/blob/master/Modules/httphook.lua").fn()

local UIS = game:GetService("UserInputService")

local CONFIG = {
	Font = Enum.Font.BuilderSansBold,
	MonoFont = Enum.Font.BuilderSansBold,
	TextSize = 13,

	AutoAccept = false,
	AutoDeny = false,

	Patterns = {
		{ Pattern = "telemetry", Action = "deny" },
		{ Pattern = "roblox%.com", Action = "allow" },
	},
}

if not pcall(function()
	return CONFIG.Font.Name
end) then
	CONFIG.Font = Enum.Font.Gotham
end

local ICON = {
	settings = "rbxassetid://10734950309",
	copy = "rbxassetid://10709812159",
	check = "rbxassetid://10709790644",
	x = "rbxassetid://10747384394",
	trash = "rbxassetid://10747362241",
	globe = "rbxassetid://10723404337",
	minimize = "rbxassetid://10734896206",
	activity = "rbxassetid://10709752035",
}

local COL = {
	bg = Color3.fromRGB(18, 18, 20),
	bar = Color3.fromRGB(28, 28, 32),
	panel = Color3.fromRGB(24, 24, 27),
	line = Color3.fromRGB(45, 45, 52),
	row = Color3.fromRGB(32, 32, 37),
	text = Color3.fromRGB(240, 240, 246),
	dim = Color3.fromRGB(165, 165, 178),
	green = Color3.fromRGB(110, 210, 130),
	red = Color3.fromRGB(225, 100, 100),
	amber = Color3.fromRGB(240, 195, 110),
}

local HOVER = Color3.fromRGB(250, 250, 255)
local DARK = Color3.fromRGB(15, 15, 18)

local host = (gethui and gethui()) or game:GetService("CoreGui")
local old = host:FindFirstChild("ReqSpy")
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "ReqSpy"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = host

local function make(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do
		o[k] = v
	end
	o.Parent = parent
	return o
end

local function corner(p, r)
	make("UICorner", { CornerRadius = UDim.new(0, r or 6) }, p)
end

local function iconBtn(parent, image, size, pos)
	local b = make("ImageButton", {
		Size = UDim2.fromOffset(size, size),
		Position = pos,
		BackgroundTransparency = 1,
		Image = image,
		ImageColor3 = COL.dim,
		AutoButtonColor = false,
	}, parent)

	b.MouseEnter:Connect(function()
		b.ImageColor3 = HOVER
	end)
	b.MouseLeave:Connect(function()
		b.ImageColor3 = COL.dim
	end)
	return b
end

local function toggleRow(parent, label, y, initial, onChange)
	make("TextLabel", {
		Size = UDim2.new(1, -60, 0, 24),
		Position = UDim2.fromOffset(0, y),
		BackgroundTransparency = 1,
		Font = CONFIG.Font,
		Text = label,
		TextColor3 = COL.text,
		TextSize = CONFIG.TextSize,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, parent)

	local state = initial

	local sw = make("TextButton", {
		Size = UDim2.fromOffset(42, 20),
		Position = UDim2.new(1, -42, 0, y + 2),
		BackgroundColor3 = state and COL.green or COL.line,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	}, parent)
	corner(sw, 10)

	local knob = make("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.fromOffset(state and 24 or 2, 2),
		BackgroundColor3 = Color3.fromRGB(240, 240, 245),
		BorderSizePixel = 0,
	}, sw)
	corner(knob, 8)

	local api = {}

	function api.Set(v)
		state = v
		sw.BackgroundColor3 = state and COL.green or COL.line
		knob.Position = UDim2.fromOffset(state and 24 or 2, 2)
	end

	sw.MouseButton1Click:Connect(function()
		api.Set(not state)
		onChange(state)
	end)

	return api
end

local root = make("Frame", {
	Size = UDim2.fromOffset(700, 440),
	Position = UDim2.new(0.5, -350, 0.5, -220),
	BackgroundColor3 = COL.bg,
	BorderSizePixel = 0,
}, gui)
corner(root, 8)
make("UIStroke", { Color = COL.line, Thickness = 1 }, root)

local bar = make("Frame", {
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundColor3 = COL.bar,
	BorderSizePixel = 0,
}, root)
corner(bar, 8)
make("Frame", {
	Size = UDim2.new(1, 0, 0, 10),
	Position = UDim2.new(0, 0, 1, -10),
	BackgroundColor3 = COL.bar,
	BorderSizePixel = 0,
}, bar)

make("ImageLabel", {
	Size = UDim2.fromOffset(16, 16),
	Position = UDim2.fromOffset(12, 10),
	BackgroundTransparency = 1,
	Image = ICON.globe,
	ImageColor3 = COL.dim,
}, bar)

make("TextLabel", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Font = CONFIG.Font,
	Text = "Request Monitor",
	TextColor3 = COL.text,
	TextSize = 15,
}, bar)

local closeWinBtn = iconBtn(bar, ICON.x, 18, UDim2.new(1, -30, 0, 9))
local minBtn = iconBtn(bar, ICON.minimize, 18, UDim2.new(1, -58, 0, 9))
local gearBtn = iconBtn(bar, ICON.settings, 18, UDim2.new(1, -86, 0, 9))
local clearBtn = iconBtn(bar, ICON.trash, 18, UDim2.new(1, -114, 0, 9))

local left = make("ScrollingFrame", {
	Size = UDim2.new(0, 250, 1, -44),
	Position = UDim2.fromOffset(8, 40),
	BackgroundColor3 = COL.panel,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = COL.line,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, root)
corner(left, 6)
make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, left)
make("UIPadding", {
	PaddingTop = UDim.new(0, 4),
	PaddingLeft = UDim.new(0, 4),
	PaddingRight = UDim.new(0, 4),
	PaddingBottom = UDim.new(0, 4),
}, left)

local right = make("Frame", {
	Size = UDim2.new(1, -274, 1, -44),
	Position = UDim2.fromOffset(266, 40),
	BackgroundColor3 = COL.panel,
	BorderSizePixel = 0,
}, root)
corner(right, 6)

local urlBar = make("Frame", {
	Size = UDim2.new(1, -16, 0, 26),
	Position = UDim2.fromOffset(8, 8),
	BackgroundColor3 = COL.row,
	BorderSizePixel = 0,
}, right)
corner(urlBar, 4)

local urlLabel = make("TextLabel", {
	Size = UDim2.new(1, -34, 1, 0),
	Position = UDim2.fromOffset(8, 0),
	BackgroundTransparency = 1,
	Font = CONFIG.MonoFont,
	Text = "—",
	TextColor3 = COL.dim,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, urlBar)

local copyBtn = iconBtn(urlBar, ICON.copy, 14, UDim2.new(1, -22, 0, 6))

local detail = make("ScrollingFrame", {
	Size = UDim2.new(1, -16, 1, -84),
	Position = UDim2.fromOffset(8, 40),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = COL.line,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, right)

local detailText = make("TextLabel", {
	Size = UDim2.new(1, -6, 0, 0),
	BackgroundTransparency = 1,
	Font = CONFIG.MonoFont,
	Text = "Select a call.",
	TextColor3 = COL.dim,
	TextSize = 12,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	AutomaticSize = Enum.AutomaticSize.Y,
}, detail)

local actions = make("Frame", {
	Size = UDim2.new(1, -16, 0, 30),
	Position = UDim2.new(0, 8, 1, -38),
	BackgroundTransparency = 1,
	Visible = false,
}, right)

local function actionBtn(text, icon, color, pos)
	local b = make("TextButton", {
		Size = UDim2.new(0.5, -4, 1, 0),
		Position = pos,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Font = CONFIG.Font,
		Text = "   " .. text,
		TextColor3 = DARK,
		TextSize = 14,
	}, actions)
	corner(b, 4)

	make("ImageLabel", {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.fromOffset(12, 8),
		BackgroundTransparency = 1,
		Image = icon,
		ImageColor3 = DARK,
	}, b)

	return b
end

local allowBtn = actionBtn("Allow", ICON.check, COL.green, UDim2.new(0, 0, 0, 0))
local denyBtn = actionBtn("Deny", ICON.x, COL.red, UDim2.new(0.5, 4, 0, 0))

local overlay = make("TextButton", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.45,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
}, root)
corner(overlay, 8)

local settings = make("Frame", {
	Size = UDim2.fromOffset(340, 340),
	Position = UDim2.new(0.5, -170, 0.5, -170),
	BackgroundColor3 = COL.bar,
	BorderSizePixel = 0,
}, overlay)
corner(settings, 8)
make("UIStroke", { Color = COL.line, Thickness = 1 }, settings)

local sHead = make("Frame", {
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundTransparency = 1,
}, settings)

make("ImageLabel", {
	Size = UDim2.fromOffset(16, 16),
	Position = UDim2.fromOffset(14, 12),
	BackgroundTransparency = 1,
	Image = ICON.settings,
	ImageColor3 = COL.dim,
}, sHead)

make("TextLabel", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Font = CONFIG.Font,
	Text = "Settings",
	TextColor3 = COL.text,
	TextSize = 15,
}, sHead)

local closeSettings = iconBtn(sHead, ICON.x, 16, UDim2.new(1, -30, 0, 12))

make("Frame", {
	Size = UDim2.new(1, -24, 0, 1),
	Position = UDim2.fromOffset(12, 40),
	BackgroundColor3 = COL.line,
	BorderSizePixel = 0,
}, settings)

local body = make("Frame", {
	Size = UDim2.new(1, -32, 1, -56),
	Position = UDim2.fromOffset(16, 50),
	BackgroundTransparency = 1,
}, settings)

local acceptSwitch, denySwitch

acceptSwitch = toggleRow(body, "Auto Accept", 4, CONFIG.AutoAccept, function(v)
	CONFIG.AutoAccept = v
	if v and CONFIG.AutoDeny then
		CONFIG.AutoDeny = false
		denySwitch.Set(false)
	end
end)

denySwitch = toggleRow(body, "Auto Deny", 34, CONFIG.AutoDeny, function(v)
	CONFIG.AutoDeny = v
	if v and CONFIG.AutoAccept then
		CONFIG.AutoAccept = false
		acceptSwitch.Set(false)
	end
end)

make("TextLabel", {
	Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.fromOffset(0, 70),
	BackgroundTransparency = 1,
	Font = CONFIG.Font,
	Text = "URL Patterns",
	TextColor3 = COL.dim,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
}, body)

local patternList = make("ScrollingFrame", {
	Size = UDim2.new(1, 0, 0, 130),
	Position = UDim2.fromOffset(0, 90),
	BackgroundColor3 = COL.panel,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = COL.line,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, body)
corner(patternList, 4)
make("UIListLayout", { Padding = UDim.new(0, 2) }, patternList)
make("UIPadding", {
	PaddingTop = UDim.new(0, 4),
	PaddingLeft = UDim.new(0, 4),
	PaddingRight = UDim.new(0, 4),
	PaddingBottom = UDim.new(0, 4),
}, patternList)

local function refreshPatterns()
	for _, c in patternList:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end

	for i, rule in CONFIG.Patterns do
		local tint = rule.Action == "allow" and COL.green or COL.red

		local rowF = make("Frame", {
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundColor3 = COL.row,
			BorderSizePixel = 0,
			LayoutOrder = i,
		}, patternList)
		corner(rowF, 3)

		make("Frame", {
			Size = UDim2.fromOffset(3, 14),
			Position = UDim2.fromOffset(6, 5),
			BackgroundColor3 = tint,
			BorderSizePixel = 0,
		}, rowF)

		make("TextLabel", {
			Size = UDim2.new(1, -52, 1, 0),
			Position = UDim2.fromOffset(16, 0),
			BackgroundTransparency = 1,
			Font = CONFIG.MonoFont,
			Text = rule.Pattern,
			TextColor3 = tint,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, rowF)

		local del = iconBtn(rowF, ICON.x, 12, UDim2.new(1, -20, 0, 6))
		del.MouseButton1Click:Connect(function()
			table.remove(CONFIG.Patterns, i)
			refreshPatterns()
		end)
	end
end

refreshPatterns()

local inputRow = make("Frame", {
	Size = UDim2.new(1, 0, 0, 26),
	Position = UDim2.new(0, 0, 1, -26),
	BackgroundTransparency = 1,
}, body)

local box = make("TextBox", {
	Size = UDim2.new(1, -104, 1, 0),
	BackgroundColor3 = COL.panel,
	BorderSizePixel = 0,
	Font = CONFIG.MonoFont,
	PlaceholderText = "url pattern...",
	PlaceholderColor3 = COL.dim,
	Text = "",
	TextColor3 = COL.text,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	ClearTextOnFocus = false,
}, inputRow)
corner(box, 4)
make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 6) }, box)

local function addRuleBtn(text, color, xFromRight, action)
	local b = make("TextButton", {
		Size = UDim2.fromOffset(46, 26),
		Position = UDim2.new(1, xFromRight, 0, 0),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Font = CONFIG.Font,
		Text = text,
		TextColor3 = DARK,
		TextSize = 12,
	}, inputRow)
	corner(b, 4)

	b.MouseButton1Click:Connect(function()
		if box.Text ~= "" then
			table.insert(CONFIG.Patterns, { Pattern = box.Text, Action = action })
			box.Text = ""
			refreshPatterns()
		end
	end)
end

addRuleBtn("Allow", COL.green, -98, "allow")
addRuleBtn("Deny", COL.red, -46, "deny")

gearBtn.MouseButton1Click:Connect(function()
	overlay.Visible = not overlay.Visible
end)

closeSettings.MouseButton1Click:Connect(function()
	overlay.Visible = false
end)

overlay.MouseButton1Click:Connect(function()
	overlay.Visible = false
end)

do
	local dragging, startPos, startInput

	bar.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging, startPos, startInput = true, root.Position, input.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if
			input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local d = input.Position - startInput
		root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end)
end

local pill = make("TextButton", {
	Size = UDim2.fromOffset(38, 38),
	Position = UDim2.fromOffset(40, 120),
	BackgroundColor3 = COL.bar,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
}, gui)
corner(pill, 8)
make("UIStroke", { Color = COL.line, Thickness = 1 }, pill)

local pillIcon = make("ImageLabel", {
	Size = UDim2.fromOffset(18, 18),
	Position = UDim2.fromOffset(10, 10),
	BackgroundTransparency = 1,
	Image = ICON.activity,
	ImageColor3 = COL.dim,
}, pill)

local badge = make("TextLabel", {
	Size = UDim2.fromOffset(16, 16),
	Position = UDim2.fromOffset(26, -4),
	BackgroundColor3 = COL.amber,
	BorderSizePixel = 0,
	Font = CONFIG.Font,
	Text = "0",
	TextColor3 = DARK,
	TextSize = 10,
	Visible = false,
}, pill)
corner(badge, 8)

pill.MouseEnter:Connect(function()
	pillIcon.ImageColor3 = HOVER
end)
pill.MouseLeave:Connect(function()
	pillIcon.ImageColor3 = COL.dim
end)

local function restore()
	pill.Visible = false
	root.Visible = true
	badge.Visible = false
	badge.Text = "0"
end

do
	local dragging, moved, startPos, startInput

	pill.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging, moved = true, false
			startPos, startInput = pill.Position, input.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if not moved then
						restore()
					end
				end
			end)
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if
			input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local d = input.Position - startInput
		if math.abs(d.X) > 3 or math.abs(d.Y) > 3 then
			moved = true
		end

		pill.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end)
end

minBtn.MouseButton1Click:Connect(function()
	overlay.Visible = false
	root.Visible = false
	pill.Visible = true
end)

local entries = {}
local selected = nil
local order = 0

local function dump(t, indent, out, seen)
	for k, v in t do
		if type(v) == "table" and not seen[v] then
			seen[v] = true
			table.insert(out, indent .. tostring(k) .. ":")
			dump(v, indent .. "   ", out, seen)
		else
			table.insert(out, indent .. tostring(k) .. " = " .. tostring(v))
		end
	end
end

local function matchPattern(url)
	for _, rule in CONFIG.Patterns do
		local ok, found = pcall(string.find, url, rule.Pattern)
		if ok and found then
			return rule.Action
		end
	end
	return nil
end

local function selectEntry(entry)
	if selected then
		selected.row.BackgroundColor3 = COL.row
	end

	selected = entry
	entry.row.BackgroundColor3 = COL.line
	detailText.Text = entry.text
	detailText.TextColor3 = COL.text
	urlLabel.Text = entry.url
	urlLabel.TextColor3 = COL.text
	actions.Visible = entry.pending == true
end

copyBtn.MouseButton1Click:Connect(function()
	if not selected or not setclipboard then
		return
	end

	setclipboard(selected.url)
	copyBtn.Image = ICON.check
	copyBtn.ImageColor3 = COL.green

	task.delay(0.8, function()
		copyBtn.Image = ICON.copy
		copyBtn.ImageColor3 = COL.dim
	end)
end)

local function addEntry(id, options)
	order += 1

	local method = (type(options) == "table" and options.Method) or "GET"
	local url = (type(options) == "table" and options.Url) or tostring(options)

	local row = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = COL.row,
		BorderSizePixel = 0,
		LayoutOrder = order,
		Font = CONFIG.Font,
		Text = "  " .. method .. "  " .. url,
		TextColor3 = COL.text,
		TextSize = CONFIG.TextSize,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		AutoButtonColor = false,
	}, left)
	corner(row, 4)

	local lines = { "id: " .. id, "" }
	if type(options) == "table" then
		dump(options, "", lines, {})
	else
		table.insert(lines, tostring(options))
	end

	local entry = { row = row, url = url, text = table.concat(lines, "\n"), pending = false }
	entries[#entries + 1] = entry

	row.MouseButton1Click:Connect(function()
		selectEntry(entry)
	end)

	if not root.Visible then
		badge.Visible = true
		badge.Text = tostring((tonumber(badge.Text) or 0) + 1)
	end

	return entry
end

clearBtn.MouseButton1Click:Connect(function()
	local keep = {}

	for _, e in entries do
		if e.pending then
			keep[#keep + 1] = e
		else
			e.row:Destroy()
		end
	end

	entries = keep
	selected = nil
	detailText.Text = "Select a call."
	detailText.TextColor3 = COL.dim
	urlLabel.Text = "—"
	urlLabel.TextColor3 = COL.dim
	actions.Visible = false
end)

local DENIED = {
	Success = false,
	StatusCode = 403,
	StatusMessage = "Denied",
	Body = "",
	Headers = {},
}

local conn = hooks:sethook(function(id, original, options)
	local entry = addEntry(id, options)

	local ruled = matchPattern(entry.url)
	if ruled == "allow" then
		entry.row.TextColor3 = COL.green
		return original(options)
	elseif ruled == "deny" then
		entry.row.TextColor3 = COL.red
		return DENIED
	end

	if CONFIG.AutoAccept then
		entry.row.TextColor3 = COL.green
		return original(options)
	elseif CONFIG.AutoDeny then
		entry.row.TextColor3 = COL.red
		return DENIED
	end

	entry.pending = true
	entry.row.TextColor3 = COL.amber

	if not root.Visible then
		restore()
	end

	if not selected or not selected.pending then
		selectEntry(entry)
	end

	local decision = nil

	local c1 = allowBtn.MouseButton1Click:Connect(function()
		if selected == entry then
			decision = true
		end
	end)

	local c2 = denyBtn.MouseButton1Click:Connect(function()
		if selected == entry then
			decision = false
		end
	end)

	repeat
		task.wait()
	until decision ~= nil

	c1:Disconnect()
	c2:Disconnect()
	entry.pending = false

	if selected == entry then
		actions.Visible = false
	end

	if decision then
		entry.row.TextColor3 = COL.green
		return original(options)
	end

	entry.row.TextColor3 = COL.red
	return DENIED
end)

closeWinBtn.MouseButton1Click:Connect(function()
	conn:Disconnect()
	gui:Destroy()
end)

print("HttpSpy by Sai")
print("Discord: https://discord.gg/zUAwfBSk7Z")
print("Youtube: https://www.youtube.com/@its-skondo")

-- © 2026 Sai — All original content reserved. Do not copy, paste, redistribute, or claim as your own.
