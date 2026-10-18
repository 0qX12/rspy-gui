local Library = {}
Library.__index = Library

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local COLORS = {
	Background = Color3.fromRGB(10, 10, 13),
	Panel = Color3.fromRGB(17, 17, 21),
	PanelRaised = Color3.fromRGB(23, 23, 28),
	Control = Color3.fromRGB(25, 25, 30),
	Line = Color3.fromRGB(43, 43, 51),
	LineBright = Color3.fromRGB(78, 78, 88),
	Text = Color3.fromRGB(235, 235, 239),
	Muted = Color3.fromRGB(125, 125, 135),
	Accent = Color3.fromRGB(235, 235, 240),
}

local FONTS = {
	Regular = Enum.Font.Gotham,
	Medium = Enum.Font.GothamMedium,
	Semibold = Enum.Font.GothamSemibold,
	Bold = Enum.Font.GothamBold,
	Black = Enum.Font.GothamBlack,
}

local ICONS = {
	activity = "◎",
	eye = "◉",
	settings = "☷",
	save = "◫",
	monitor = "◎",
	visuals = "◉",
	misc = "☷",
	config = "⌘",
}

local function getGuiParent()
	local ok, holder = pcall(function()
		if type(gethui) == "function" then
			return gethui()
		end
		return nil
	end)

	if ok and holder then
		return holder
	end

	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer and localPlayer:FindFirstChildOfClass("PlayerGui")
	if playerGui then
		return playerGui
	end

	return game:GetService("CoreGui")
end

local function create(className, properties, parent)
	local object = Instance.new(className)

	for property, value in pairs(properties or {}) do
		object[property] = value
	end

	object.Parent = parent
	return object
end

local function addCorner(parent, radius)
	return create("UICorner", {CornerRadius = UDim.new(0, radius or 6)}, parent)
end

local function addStroke(parent, color, transparency)
	return create("UIStroke", {
		Color = color or COLORS.Line,
		Transparency = transparency or 0,
		Thickness = 1,
	}, parent)
end

local function addText(parent, value, size, color, properties)
	local textProperties = {
		BackgroundTransparency = 1,
		Text = tostring(value or ""),
		TextColor3 = color or COLORS.Text,
		TextSize = size or 11,
		Font = FONTS.Medium,
		TextXAlignment = Enum.TextXAlignment.Left,
	}

	for property, propertyValue in pairs(properties or {}) do
		textProperties[property] = propertyValue
	end

	return create("TextLabel", textProperties, parent)
end

local function iconLine(parent, position, size, rotation)
	local line = create("Frame", {
		Position = position,
		Size = size,
		BackgroundColor3 = COLORS.Muted,
		BorderSizePixel = 0,
		Rotation = rotation or 0,
		ZIndex = 6,
	}, parent)
	addCorner(line, 1)
	return line
end

local function createIcon(parent, value)
	local key = string.lower(tostring(value or ""))
	local holder = create("Frame", {
		Size = UDim2.fromOffset(19, 19),
		BackgroundTransparency = 1,
		ZIndex = 6,
	}, parent)

	if key == "activity" or key == "monitor" then
		local ring = create("Frame", {
			Position = UDim2.fromOffset(4, 4),
			Size = UDim2.fromOffset(11, 11),
			BackgroundTransparency = 1,
			ZIndex = 6,
		}, holder)
		addCorner(ring, 8)
		addStroke(ring, COLORS.Muted)
		local center = create("Frame", {
			Position = UDim2.fromOffset(7, 7),
			Size = UDim2.fromOffset(5, 5),
			BackgroundTransparency = 1,
			ZIndex = 7,
		}, holder)
		addCorner(center, 4)
		addStroke(center, COLORS.Muted)
		iconLine(holder, UDim2.fromOffset(9, 1), UDim2.fromOffset(1, 4))
		iconLine(holder, UDim2.fromOffset(9, 14), UDim2.fromOffset(1, 4))
		iconLine(holder, UDim2.fromOffset(1, 9), UDim2.fromOffset(4, 1))
		iconLine(holder, UDim2.fromOffset(14, 9), UDim2.fromOffset(4, 1))
	elseif key == "eye" or key == "visuals" then
		iconLine(holder, UDim2.fromOffset(2, 9), UDim2.fromOffset(8, 1), -28)
		iconLine(holder, UDim2.fromOffset(9, 5), UDim2.fromOffset(8, 1), 28)
		iconLine(holder, UDim2.fromOffset(2, 9), UDim2.fromOffset(8, 1), 28)
		iconLine(holder, UDim2.fromOffset(9, 13), UDim2.fromOffset(8, 1), -28)
		local pupil = create("Frame", {
			Position = UDim2.fromOffset(7, 7),
			Size = UDim2.fromOffset(5, 5),
			BackgroundColor3 = COLORS.Muted,
			ZIndex = 7,
		}, holder)
		addCorner(pupil, 4)
	elseif key == "save" or key == "config" then
		for index, x in ipairs({4, 9, 14}) do
			iconLine(holder, UDim2.fromOffset(x, 3), UDim2.fromOffset(1, 14))
			local knob = create("Frame", {
				Position = UDim2.fromOffset(x - 2, index == 1 and 5 or index == 2 and 11 or 7),
				Size = UDim2.fromOffset(5, 5),
				BackgroundColor3 = COLORS.Background,
				ZIndex = 7,
			}, holder)
			addCorner(knob, 4)
			addStroke(knob, COLORS.Muted)
		end
	elseif key == "settings" or key == "misc" then
		for index, y in ipairs({4, 9, 14}) do
			iconLine(holder, UDim2.fromOffset(2, y), UDim2.fromOffset(15, 1))
			local knob = create("Frame", {
				Position = UDim2.fromOffset(index == 1 and 6 or index == 2 and 11 or 4, y - 2),
				Size = UDim2.fromOffset(5, 5),
				BackgroundColor3 = COLORS.Background,
				ZIndex = 7,
			}, holder)
			addCorner(knob, 4)
			addStroke(knob, COLORS.Muted)
		end
	else
		iconLine(holder, UDim2.fromOffset(5, 4), UDim2.fromOffset(1, 12), 0)
		iconLine(holder, UDim2.fromOffset(13, 4), UDim2.fromOffset(1, 12), 0)
		iconLine(holder, UDim2.fromOffset(5, 9), UDim2.fromOffset(9, 1), 0)
	end

	return holder
end

local function setIconColor(holder, color)
	for _, descendant in ipairs(holder:GetDescendants()) do
		if descendant:IsA("UIStroke") then
			descendant.Color = color
		elseif descendant:IsA("Frame") and descendant.BackgroundTransparency < 1 then
			descendant.BackgroundColor3 = color
		end
	end
end

local function copyOptions(source)
	local result = {}

	for key, value in pairs(source or {}) do
		result[key] = value
	end

	return result
end

local function parseOptions(value, callback)
	if type(value) == "table" then
		return copyOptions(value)
	end

	return {Name = value, Callback = callback}
end

local function resolveTabData(value, icon)
	if type(value) == "table" then
		return copyOptions(value)
	end

	return {Name = value, Icon = icon}
end

local function resolveSize(config)
	if typeof(config.Size) == "UDim2" then
		return config.Size, config.Size.X.Offset, config.Size.Y.Offset
	end

	if typeof(config.Size) == "Vector2" then
		return UDim2.fromOffset(config.Size.X, config.Size.Y), config.Size.X, config.Size.Y
	end

	local width = tonumber(config.Width) or 860
	local height = tonumber(config.Height) or 560
	return UDim2.fromOffset(width, height), width, height
end

local function keyCodeFrom(value)
	if typeof(value) == "EnumItem" then
		return value
	end

	if type(value) == "string" then
		return Enum.KeyCode[value] or Enum.KeyCode.Unknown
	end

	return Enum.KeyCode.Unknown
end

local function keyName(value)
	local key = keyCodeFrom(value)
	return key == Enum.KeyCode.Unknown and "None" or key.Name
end

local function controlName(options, fallback)
	local name = options.Name or fallback
	local bind = options.Keybind or options.Hotkey or options.Key
	if bind then
		return tostring(name) .. "  [" .. keyName(bind) .. "]"
	end
	return name
end

local function safeCallback(callback, value, control)
	if type(callback) ~= "function" then
		return
	end

	task.spawn(function()
		pcall(callback, value, control)
	end)
end

local function formatNumber(value)
	if math.floor(value) == value then
		return tostring(value)
	end

	return string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", "")
end

function Library.new(config)
	config = config or {}
	local singleView = config.SingleView == true

	local self = setmetatable({
		_connections = {},
		_dynamicConnections = {},
		_tabs = {},
		_notifications = {},
		_destroyed = false,
	}, Library)

	local host = getGuiParent()
	local guiName = config.Name or "MonochromeUI"
	local previous = host:FindFirstChild(guiName)

	if previous then
		previous:Destroy()
	end

	local windowSize, width, height = resolveSize(config)

	self.Gui = create("ScreenGui", {
		Name = guiName,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, host)

	self.Window = create("Frame", {
		Size = windowSize,
		Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2),
		BackgroundColor3 = COLORS.Panel,
		BorderSizePixel = 0,
		Active = true,
		ClipsDescendants = true,
		ZIndex = 2,
	}, self.Gui)
	local haloOuter = create("Frame", {
		Size = UDim2.fromOffset(width + 22, height + 22),
		Position = UDim2.new(0.5, -width / 2 - 11, 0.5, -height / 2 - 11),
		BackgroundTransparency = 1,
		ZIndex = 0,
	}, self.Gui)
	addCorner(haloOuter, 15)
	local haloOuterStroke = addStroke(haloOuter, COLORS.Text, 0.965)
	haloOuterStroke.Thickness = 11
	local haloInner = create("Frame", {
		Size = UDim2.fromOffset(width + 8, height + 8),
		Position = UDim2.new(0.5, -width / 2 - 4, 0.5, -height / 2 - 4),
		BackgroundTransparency = 1,
		ZIndex = 1,
	}, self.Gui)
	addCorner(haloInner, 11)
	local haloInnerStroke = addStroke(haloInner, COLORS.Text, 0.90)
	haloInnerStroke.Thickness = 4
	local function syncHalo()
		local position = self.Window.Position
		haloOuter.Position = UDim2.new(position.X.Scale, position.X.Offset - 11, position.Y.Scale, position.Y.Offset - 11)
		haloInner.Position = UDim2.new(position.X.Scale, position.X.Offset - 4, position.Y.Scale, position.Y.Offset - 4)
	end
	addCorner(self.Window, 9)
	addStroke(self.Window, COLORS.Line)
	create("UIGradient", {
		Color = ColorSequence.new(COLORS.Panel, COLORS.Background),
		Rotation = 90,
	}, self.Window)
	local accentLine = create("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = COLORS.Accent,
		BorderSizePixel = 0,
		ZIndex = 20,
	}, self.Window)
	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, COLORS.Text),
			ColorSequenceKeypoint.new(0.55, COLORS.Muted),
			ColorSequenceKeypoint.new(1, COLORS.Background),
		}),
	}, accentLine)

	local topBar = create("Frame", {
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Visible = false,
	}, self.Window)

	local closeButton = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = COLORS.PanelRaised,
		Text = "×",
		TextColor3 = COLORS.Muted,
		TextSize = 16,
		Font = Enum.Font.Gotham,
		AutoButtonColor = false,
		Visible = false,
	}, topBar)
	addCorner(closeButton, 5)

	local sidebar = create("Frame", {
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(0, 72, 1, 0),
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, self.Window)
	sidebar.Visible = not singleView
	local brand = addText(sidebar, config.Title or "f4_byte", 10, COLORS.Text, {
		Position = UDim2.fromOffset(11, 12),
		Size = UDim2.fromOffset(50, 20),
		Font = FONTS.Black,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Active = true,
		ZIndex = 6,
	})
	local tabs = create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 58),
		Size = UDim2.new(1, 0, 1, -70),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ZIndex = 3,
	}, sidebar)
	create("UIListLayout", {
		Padding = UDim.new(0, 4),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabs)
	create("Frame", {
		Position = UDim2.new(1, -1, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = COLORS.Line,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, sidebar)

	local content = create("Frame", {
		Position = singleView and UDim2.fromOffset(0, 0) or UDim2.fromOffset(72, 0),
		Size = singleView and UDim2.new(1, 0, 1, 0) or UDim2.new(1, -72, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		ZIndex = 1,
	}, self.Window)
	local pages = create("Folder", {}, content)
	self._content = content
	if singleView then
		local header = create("Frame", {
			Size = UDim2.new(1, 0, 0, 42),
			BackgroundTransparency = 1,
			ZIndex = 6,
		}, content)
		addText(header, config.Title or "RemoteSpy", 13, COLORS.Text, {
			Position = UDim2.fromOffset(18, 0),
			Size = UDim2.new(1, -36, 1, 0),
			TextYAlignment = Enum.TextYAlignment.Center,
			Font = FONTS.Bold,
			ZIndex = 7,
		})
		create("Frame", {
			Position = UDim2.fromOffset(18, 41),
			Size = UDim2.new(1, -36, 0, 1),
			BackgroundColor3 = COLORS.Line,
			BorderSizePixel = 0,
			ZIndex = 6,
		}, header)
		self._singleHeader = header
	end
	self._topBar = topBar
	self._tabsContainer = tabs
	self._pages = pages

	local function connect(signal, handler)
		local connection = signal:Connect(handler)
		table.insert(self._connections, connection)
		return connection
	end

	connect(closeButton.MouseEnter, function()
		TweenService:Create(closeButton, TweenInfo.new(0.12), {
			BackgroundColor3 = Color3.fromRGB(120, 46, 52),
			TextColor3 = COLORS.Text,
		}):Play()
	end)
	connect(closeButton.MouseLeave, function()
		TweenService:Create(closeButton, TweenInfo.new(0.12), {
			BackgroundColor3 = COLORS.PanelRaised,
			TextColor3 = COLORS.Muted,
		}):Play()
	end)
	connect(closeButton.MouseButton1Click, function()
		self:Destroy()
	end)

	local dragging = false
	local dragStart
	local windowStart

	connect(brand.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			windowStart = self.Window.Position
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			self.Window.Position = UDim2.new(
				windowStart.X.Scale,
				windowStart.X.Offset + delta.X,
				windowStart.Y.Scale,
				windowStart.Y.Offset + delta.Y
			)
			syncHalo()
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	function self:_connectDynamic(signal, handler)
		local connection = signal:Connect(handler)
		table.insert(self._dynamicConnections, connection)
		return connection
	end

	function self:_removeDynamic(connection)
		if not connection then
			return
		end

		pcall(function()
			connection:Disconnect()
		end)

		for index, item in ipairs(self._dynamicConnections) do
			if item == connection then
				table.remove(self._dynamicConnections, index)
				break
			end
		end
	end

	function self:SetVisible(visible)
		if self.Gui then
			self.Gui.Enabled = visible == true
		end
	end

	function self:ToggleVisible()
		if self.Gui then
			self.Gui.Enabled = not self.Gui.Enabled
		end
	end

	function self:_LegacyRemoteSpy(options)
		options = options or {}

		if self._spyRoot then
			self._spyRoot:Destroy()
		end
		if self._singleHeader then
			self._singleHeader.Visible = false
		end

		local view = {
			_logs = {},
			_selectedButton = nil,
			_library = self,
		}
		local root = create("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(11, 11, 14),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 4,
		}, self._content)
		self._spyRoot = root

		local topBar = create("Frame", {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundColor3 = Color3.fromRGB(11, 11, 14),
			BorderSizePixel = 0,
			ZIndex = 5,
		}, root)
		addText(topBar, options.Title or "RemoteSpy", 12, COLORS.Text, {
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -120, 1, 0),
			TextYAlignment = Enum.TextYAlignment.Center,
			Font = FONTS.Bold,
			ZIndex = 6,
		})
		addText(topBar, options.Status or "visual preview", 9, COLORS.Muted, {
			Position = UDim2.new(1, -104, 0, 0),
			Size = UDim2.fromOffset(78, 30),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Center,
			Font = FONTS.Medium,
			ZIndex = 6,
		})
		local close = create("TextButton", {
			Position = UDim2.new(1, -25, 0, 5),
			Size = UDim2.fromOffset(20, 20),
			BackgroundColor3 = Color3.fromRGB(38, 38, 43),
			Text = "×",
			TextColor3 = COLORS.Muted,
			TextSize = 14,
			Font = FONTS.Medium,
			AutoButtonColor = false,
			ZIndex = 7,
		}, topBar)
		addCorner(close, 4)
		create("Frame", {
			Position = UDim2.fromOffset(0, 29),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = Color3.fromRGB(29, 29, 35),
			BorderSizePixel = 0,
			ZIndex = 6,
		}, topBar)
		connect(close.MouseButton1Click, function()
			self:Destroy()
		end)

		local body = create("Frame", {
			Position = UDim2.fromOffset(0, 30),
			Size = UDim2.new(1, 0, 1, -30),
			BackgroundColor3 = Color3.fromRGB(11, 11, 14),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 4,
		}, root)
		local logPanel = create("Frame", {
			Size = UDim2.new(0, 165, 1, 0),
			BackgroundColor3 = Color3.fromRGB(11, 11, 14),
			BorderSizePixel = 0,
			ZIndex = 5,
		}, body)
		local logList = create("ScrollingFrame", {
			Position = UDim2.fromOffset(8, 8),
			Size = UDim2.new(1, -16, 1, -16),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = COLORS.LineBright,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 6,
		}, logPanel)
		create("Frame", {
			Position = UDim2.new(1, -1, 0, 0),
			Size = UDim2.new(0, 1, 1, 0),
			BackgroundColor3 = Color3.fromRGB(29, 29, 35),
			BorderSizePixel = 0,
			ZIndex = 7,
		}, logPanel)
		create("UIListLayout", {
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, logList)

		local detailPanel = create("Frame", {
			Position = UDim2.fromOffset(165, 0),
			Size = UDim2.new(1, -165, 1, 0),
			BackgroundColor3 = Color3.fromRGB(11, 11, 14),
			BorderSizePixel = 0,
			ZIndex = 5,
		}, body)
		local codeHeight = options.CodeHeight or 150
		local codePanel = create("Frame", {
			Size = UDim2.new(1, 0, 0, codeHeight),
			BackgroundColor3 = Color3.fromRGB(20, 20, 25),
			BorderSizePixel = 0,
			ZIndex = 6,
		}, detailPanel)
		addStroke(codePanel, Color3.fromRGB(36, 36, 43), 0.35)
		addText(codePanel, "generated request", 9, COLORS.Muted, {
			Position = UDim2.fromOffset(12, 8),
			Size = UDim2.new(1, -24, 0, 16),
			Font = FONTS.Bold,
			ZIndex = 7,
		})
		local codeLabel = addText(codePanel, options.Code or "-- no remote selected", 12, COLORS.Text, {
			Position = UDim2.fromOffset(12, 28),
			Size = UDim2.new(1, -24, 1, -36),
			Font = Enum.Font.Code,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = false,
			ZIndex = 7,
		})
		local actions = create("ScrollingFrame", {
			Position = UDim2.new(0, 0, 0, codeHeight),
			Size = UDim2.new(1, 0, 1, -codeHeight),
			BackgroundColor3 = Color3.fromRGB(11, 11, 14),
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = COLORS.LineBright,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ZIndex = 6,
		}, detailPanel)
		create("UIGridLayout", {
			CellSize = UDim2.new(0.333, -8, 0, 28),
			CellPadding = UDim2.fromOffset(8, 8),
			FillDirectionMaxCells = 3,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, actions)

		function view:SetCode(code)
			codeLabel.Text = tostring(code or "")
		end

		function view:AddLog(entry)
			local data = type(entry) == "table" and entry or {Name = tostring(entry)}
			local row = create("TextButton", {
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundColor3 = Color3.fromRGB(17, 17, 21),
				Text = "",
				AutoButtonColor = false,
				ZIndex = 7,
			}, logList)
			addCorner(row, 4)
			addStroke(row, Color3.fromRGB(36, 36, 43), 0.4)
			create("Frame", {
				Size = UDim2.new(0, 3, 1, 0),
				BackgroundColor3 = data.Color or (data.Type == "function" and Color3.fromRGB(100, 90, 240) or Color3.fromRGB(255, 224, 0)),
				BorderSizePixel = 0,
				ZIndex = 8,
			}, row)
			addText(row, data.Name or "Remote", 11, COLORS.Text, {
				Position = UDim2.fromOffset(12, 0),
				Size = UDim2.new(1, -16, 1, 0),
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Font = FONTS.Medium,
				ZIndex = 8,
			})
			connect(row.MouseEnter, function()
				row.BackgroundColor3 = Color3.fromRGB(27, 27, 32)
			end)
			connect(row.MouseLeave, function()
				if view._selectedButton ~= row then
					row.BackgroundColor3 = Color3.fromRGB(17, 17, 21)
				end
			end)
			connect(row.MouseButton1Click, function()
				if view._selectedButton then
					view._selectedButton.BackgroundColor3 = Color3.fromRGB(17, 17, 21)
				end
				view._selectedButton = row
				row.BackgroundColor3 = Color3.fromRGB(31, 31, 37)
				view:SetCode(data.Code or "-- no generated request")
				safeCallback(data.Callback, data, view)
			end)
			table.insert(view._logs, row)
			if #view._logs == 1 then
				view._selectedButton = row
				row.BackgroundColor3 = Color3.fromRGB(31, 31, 37)
				view:SetCode(data.Code or "-- no generated request")
			end
			return row
		end

		function view:AddAction(name, callback)
			local button = create("TextButton", {
				Size = UDim2.fromOffset(112, 28),
				BackgroundColor3 = COLORS.Control,
				Text = tostring(name),
				TextColor3 = COLORS.Text,
				TextSize = 10,
				Font = FONTS.Semibold,
				AutoButtonColor = false,
				ZIndex = 7,
			}, actions)
			addCorner(button, 5)
			addStroke(button, COLORS.Line, 0.1)
			connect(button.MouseEnter, function()
				button.BackgroundColor3 = Color3.fromRGB(31, 31, 37)
			end)
			connect(button.MouseLeave, function()
				button.BackgroundColor3 = COLORS.Control
			end)
			connect(button.MouseButton1Click, function()
				safeCallback(callback, button, view)
			end)
			return button
		end

		function view:Clear()
			for _, item in ipairs(view._logs) do
				item:Destroy()
			end
			table.clear(view._logs)
			view._selectedButton = nil
			view:SetCode("-- no remote selected")
		end

		return view
	end

	function self:Tab(nameOrOptions, icon)
		local data = resolveTabData(nameOrOptions, icon)
		local tab = {
			Name = data.Name or "Tab",
			Sections = {},
			_library = self,
		}

		tab._button = create("TextButton", {
			Size = UDim2.fromOffset(44, 40),
			BackgroundColor3 = COLORS.PanelRaised,
			BackgroundTransparency = 1,
			Text = "",
			TextColor3 = COLORS.Muted,
			TextSize = 19,
			Font = Enum.Font.GothamSemibold,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			AutoButtonColor = false,
			ZIndex = 4,
		}, tabs)
		tab._button.Visible = not singleView
		addCorner(tab._button, 6)
		tab._icon = createIcon(tab._button, data.Icon or tab.Name)
		tab._activeLine = create("Frame", {
			Position = UDim2.fromOffset(0, 9),
			Size = UDim2.fromOffset(2, 22),
			BackgroundColor3 = COLORS.Text,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 5,
		}, tab._button)

		tab._page = create("ScrollingFrame", {
			Position = singleView and UDim2.fromOffset(18, 54) or UDim2.fromOffset(18, 16),
			Size = singleView and UDim2.new(1, -36, 1, -70) or UDim2.new(1, -36, 1, -36),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = COLORS.Line,
			Visible = false,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ClipsDescendants = true,
			ZIndex = 2,
		}, pages)
		local pageContent = create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ClipsDescendants = false,
			ZIndex = 2,
		}, tab._page)
		local leftColumn = create("Frame", {
			Size = UDim2.new(0.5, -5, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ClipsDescendants = false,
			ZIndex = 3,
		}, pageContent)
		local rightColumn = create("Frame", {
			Position = UDim2.new(0.5, 5, 0, 0),
			Size = UDim2.new(0.5, -5, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ClipsDescendants = false,
			ZIndex = 3,
		}, pageContent)
		create("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, leftColumn)
		create("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, rightColumn)
		tab._pageContent = pageContent
		tab._leftColumn = leftColumn
		tab._rightColumn = rightColumn

		table.insert(self._tabs, tab)
		connect(tab._button.MouseEnter, function()
			if not tab._page.Visible then
				tab._button.BackgroundTransparency = 0.9
				tab._button.TextColor3 = COLORS.Text
				setIconColor(tab._icon, COLORS.Text)
			end
		end)
		connect(tab._button.MouseLeave, function()
			if not tab._page.Visible then
				tab._button.BackgroundTransparency = 1
				tab._button.TextColor3 = COLORS.Muted
				setIconColor(tab._icon, COLORS.Muted)
			end
		end)
		connect(tab._button.MouseButton1Click, function()
			self:SelectTab(tab)
		end)

		function tab:Section(nameOrOptions)
			local sectionData = type(nameOrOptions) == "table"
				and copyOptions(nameOrOptions)
				or {Name = nameOrOptions}
			local section = {
				Name = sectionData.Name or "Section",
				Column = sectionData.Column,
				Controls = {},
				_tab = tab,
				_library = self._library,
			}

			local column = sectionData.Column == 2 and tab._rightColumn or tab._leftColumn
			if sectionData.Column ~= 1 and sectionData.Column ~= 2 then
				column = (#tab.Sections % 2 == 0) and tab._leftColumn or tab._rightColumn
			end

			section._box = create("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = COLORS.Panel,
				BorderSizePixel = 0,
				ClipsDescendants = false,
				LayoutOrder = #tab.Sections + 1,
				ZIndex = 3,
			}, column)
			addCorner(section._box, 8)
			addStroke(section._box, COLORS.Line)
			addText(section._box, section.Name, 11, COLORS.Muted, {
				Position = UDim2.fromOffset(11, 0),
				Size = UDim2.new(1, -22, 0, 32),
				TextYAlignment = Enum.TextYAlignment.Center,
				Font = FONTS.Bold,
				ZIndex = 4,
			})
			section._list = create("Frame", {
				Position = UDim2.fromOffset(0, 32),
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				ClipsDescendants = false,
				ZIndex = 4,
			}, section._box)
			create("UIListLayout", {
				Padding = UDim.new(0, 1),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, section._list)
			table.insert(tab.Sections, section)

			function section:_row(name, rowHeight)
				local row = create("Frame", {
					Size = UDim2.new(1, 0, 0, rowHeight or 40),
					BackgroundColor3 = COLORS.Panel,
					BackgroundTransparency = 0,
					BorderSizePixel = 0,
					ClipsDescendants = false,
					ZIndex = 5,
				}, self._list)
				addText(row, name, 12, COLORS.Muted, {
					Position = UDim2.fromOffset(11, 0),
					Size = UDim2.new(1, -155, 1, 0),
					TextYAlignment = Enum.TextYAlignment.Center,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Font = FONTS.Medium,
					ZIndex = 6,
				})
				create("Frame", {
					Position = UDim2.new(0, 0, 1, -1),
					Size = UDim2.new(1, 0, 0, 1),
					BackgroundColor3 = Color3.fromRGB(28, 28, 34),
					BorderSizePixel = 0,
					ZIndex = 5,
				}, row)
				return row
			end

			function section:Label(valueOrOptions)
				local value = type(valueOrOptions) == "table"
					and (valueOrOptions.Text or valueOrOptions.Name)
					or valueOrOptions
				local row = self:_row(value)
				local textLabel = row:FindFirstChildOfClass("TextLabel")
				local control = {
					Set = function(_, nextValue)
						textLabel.Text = tostring(nextValue)
					end,
					Get = function()
						return textLabel.Text
					end,
				}
				table.insert(self.Controls, control)
				return control
			end

			function section:Code(options)
				options = type(options) == "table" and options or {Text = tostring(options or "")}
				local codeRow = create("Frame", {
					Size = UDim2.new(1, 0, 0, options.Height or 170),
					BackgroundColor3 = Color3.fromRGB(12, 12, 16),
					BorderSizePixel = 0,
					ClipsDescendants = true,
					ZIndex = 5,
				}, self._list)
				addCorner(codeRow, 5)
				addStroke(codeRow, COLORS.Line)
				addText(codeRow, options.Name or "generated request", 9, COLORS.Muted, {
					Position = UDim2.fromOffset(11, 8),
					Size = UDim2.new(1, -22, 0, 16),
					Font = FONTS.Bold,
					ZIndex = 6,
				})
				local codeLabel = addText(codeRow, options.Text or "", 10, COLORS.Text, {
					Position = UDim2.fromOffset(11, 31),
					Size = UDim2.new(1, -22, 1, -40),
					Font = FONTS.Medium,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextWrapped = false,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 6,
				})
				local control = {
					Set = function(_, value)
						codeLabel.Text = tostring(value or "")
					end,
					Get = function()
						return codeLabel.Text
					end,
				}
				table.insert(self.Controls, control)
				return control
			end

			function section:Button(nameOrOptions, callback)
				local data = parseOptions(nameOrOptions, callback)
				local row = self:_row(controlName(data, "Button"))
				local control

				local button = create("TextButton", {
					Position = UDim2.new(1, -105, 0.5, -13),
					Size = UDim2.fromOffset(94, 26),
					BackgroundColor3 = COLORS.Control,
					Text = data.Text or "execute",
					TextColor3 = COLORS.Text,
					TextSize = 10,
					Font = Enum.Font.GothamSemibold,
					AutoButtonColor = false,
					ZIndex = 7,
				}, row)
				addCorner(button, 5)
				addStroke(button, COLORS.Line)

				control = {
					Set = function() end,
					Get = function()
						return nil
					end,
				}

				connect(button.MouseEnter, function()
					button.BackgroundColor3 = COLORS.PanelRaised
				end)
				connect(button.MouseLeave, function()
					button.BackgroundColor3 = COLORS.Control
				end)
				connect(button.MouseButton1Click, function()
					safeCallback(data.Callback, nil, control)
				end)

				table.insert(self.Controls, control)
				return control
			end

			function section:Toggle(nameOrOptions, callback)
				local data = parseOptions(nameOrOptions, callback)
				local value = data.CurrentValue

				if value == nil then
					value = data.Default == true
				end

				local row = self:_row(controlName(data, "Toggle"))
				local button = create("TextButton", {
					Position = UDim2.new(1, -44, 0.5, -10),
					Size = UDim2.fromOffset(34, 19),
					BackgroundColor3 = Color3.fromRGB(27, 27, 32),
					Text = "",
					AutoButtonColor = false,
					ZIndex = 7,
				}, row)
				addCorner(button, 6)
				addStroke(button, COLORS.Line)

				local knob = create("Frame", {
					Size = UDim2.fromOffset(11, 11),
					BorderSizePixel = 0,
					ZIndex = 8,
				}, button)
				addCorner(knob, 4)

				local control
				local rowLabel = row:FindFirstChildOfClass("TextLabel")
				local rowIndicator = create("Frame", {
					Position = UDim2.fromOffset(0, 8),
					Size = UDim2.fromOffset(2, 22),
					BackgroundColor3 = COLORS.Text,
					BorderSizePixel = 0,
					Visible = false,
					ZIndex = 7,
				}, row)
				local function set(nextValue, fire)
					value = nextValue == true
					button.BackgroundColor3 = value and Color3.fromRGB(36, 36, 42) or Color3.fromRGB(27, 27, 32)
					knob.BackgroundColor3 = value and COLORS.Text or COLORS.Muted
					knob.Position = value
						and UDim2.new(1, -15, 0.5, -5)
						or UDim2.fromOffset(3, 4)
					rowIndicator.Visible = value
					row.BackgroundColor3 = value and COLORS.PanelRaised or COLORS.Panel
					rowLabel.TextColor3 = value and COLORS.Text or COLORS.Muted
					rowLabel.Font = value and FONTS.Bold or FONTS.Medium

					if fire then
						safeCallback(data.Callback, value, control)
					end
				end

				control = {
					Set = function(_, nextValue)
						set(nextValue, true)
					end,
					Get = function()
						return value
					end,
				}

				set(value, false)
				connect(button.MouseButton1Click, function()
					control:Set(not value)
				end)

				table.insert(self.Controls, control)
				return control
			end

			function section:Slider(nameOrOptions, callback)
				local data = parseOptions(nameOrOptions, callback)
				local range = data.Range or {data.Min or 0, data.Max or 100}
				local minimum = tonumber(range[1]) or 0
				local maximum = tonumber(range[2]) or 100
				local step = math.max(tonumber(data.Increment or data.Step) or 1, 0.0001)
				local initial = tonumber(data.CurrentValue or data.Default) or minimum

				if maximum < minimum then
					minimum, maximum = maximum, minimum
				end

				local row = self:_row(controlName(data, "Slider"))
				local valueLabel = addText(row, "", 10, COLORS.Muted, {
					Position = UDim2.new(1, -145, 0.5, -10),
					Size = UDim2.fromOffset(52, 20),
					TextXAlignment = Enum.TextXAlignment.Right,
					TextYAlignment = Enum.TextYAlignment.Center,
					ZIndex = 7,
				})
				local bar = create("Frame", {
					Position = UDim2.new(1, -88, 0.5, -12),
					Size = UDim2.fromOffset(86, 24),
					BackgroundColor3 = COLORS.Control,
					BorderSizePixel = 0,
					Active = true,
					ZIndex = 7,
				}, row)
				addCorner(bar, 5)
				addStroke(bar, COLORS.Line)
				create("Frame", {
					Position = UDim2.fromOffset(8, 11),
					Size = UDim2.new(1, -16, 0, 2),
					BackgroundColor3 = COLORS.Line,
					BorderSizePixel = 0,
					ZIndex = 8,
				}, bar)
				local thumb = create("Frame", {
					Position = UDim2.new(0, 7, 0.5, -8),
					Size = UDim2.fromOffset(2, 15),
					BackgroundColor3 = COLORS.Text,
					BorderSizePixel = 0,
					ZIndex = 9,
				}, bar)
				for index = 0, 6 do
					local tickHeight = (index == 0 or index == 6) and 10 or 8
					create("Frame", {
						Position = UDim2.new(index / 6, 0, 0.5, -4),
						Size = UDim2.fromOffset(2, tickHeight),
						BackgroundColor3 = COLORS.LineBright,
						BorderSizePixel = 0,
						ZIndex = 8,
					}, bar)
				end

				local value = initial
				local control
				local function set(nextValue, fire)
					nextValue = tonumber(nextValue) or minimum
					value = math.clamp(
						math.floor((nextValue - minimum) / step + 0.5) * step + minimum,
						minimum,
						maximum
					)
					local ratio = (value - minimum) / math.max(maximum - minimum, 0.0001)
					thumb.Position = UDim2.new(ratio, 7 - math.floor(ratio * 16), 0.5, -8)
					valueLabel.Text = "[" .. formatNumber(value) .. tostring(data.Unit or "") .. "]"

					if fire then
						safeCallback(data.Callback, value, control)
					end
				end

				control = {
					Set = function(_, nextValue)
						set(nextValue, true)
					end,
					Get = function()
						return value
					end,
				}
				set(value, false)

				local dragging = false
				local moveConnection
				local endConnection
				local function stopDragging()
					dragging = false
					self._library:_removeDynamic(moveConnection)
					self._library:_removeDynamic(endConnection)
					moveConnection = nil
					endConnection = nil
				end
				local function updateFromX(x)
					local width = math.max(bar.AbsoluteSize.X - 16, 1)
					local ratio = math.clamp((x - bar.AbsolutePosition.X - 8) / width, 0, 1)
					set(minimum + (maximum - minimum) * ratio, true)
				end
				connect(bar.InputBegan, function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseButton1
						and input.UserInputType ~= Enum.UserInputType.Touch then
						return
					end

					stopDragging()
					dragging = true
					updateFromX(input.Position.X)
					moveConnection = self._library:_connectDynamic(UserInputService.InputChanged, function(changed)
						if dragging and (changed.UserInputType == Enum.UserInputType.MouseMovement
							or changed.UserInputType == Enum.UserInputType.Touch) then
							updateFromX(changed.Position.X)
						end
					end)
					endConnection = self._library:_connectDynamic(UserInputService.InputEnded, function(ended)
						if ended.UserInputType == Enum.UserInputType.MouseButton1
							or ended.UserInputType == Enum.UserInputType.Touch then
							stopDragging()
						end
					end)
				end)

				table.insert(self.Controls, control)
				return control
			end

			function section:Dropdown(nameOrOptions, callback)
				local data = parseOptions(nameOrOptions, callback)
				local values = data.Options or data.Values or {}
				local value = data.CurrentOption or data.Default or values[1]
				local row = self:_row(controlName(data, "Dropdown"))
				local button = create("TextButton", {
					Position = UDim2.new(1, -136, 0.5, -15),
					Size = UDim2.fromOffset(124, 30),
					BackgroundColor3 = COLORS.Control,
					Text = "  " .. tostring(value or "Select"),
					TextColor3 = COLORS.Text,
					TextSize = 11,
					Font = Enum.Font.GothamSemibold,
					TextXAlignment = Enum.TextXAlignment.Left,
					AutoButtonColor = false,
					ZIndex = 8,
				}, row)
				addCorner(button, 5)
				addStroke(button, COLORS.Line)
				local arrowLeft = iconLine(button, UDim2.new(1, -18, 0.5, -1), UDim2.fromOffset(6, 1), 45)
				local arrowRight = iconLine(button, UDim2.new(1, -14, 0.5, -1), UDim2.fromOffset(6, 1), -45)
				arrowLeft.ZIndex = 9
				arrowRight.ZIndex = 9
				local menu = create("Frame", {
					Position = UDim2.new(0, 0, 1, 3),
					Size = UDim2.new(1, 0, 0, math.max(#values * 25 + 6, 30)),
					BackgroundColor3 = COLORS.PanelRaised,
					BorderSizePixel = 0,
					Visible = false,
					ZIndex = 30,
				}, button)
				addCorner(menu, 5)
				addStroke(menu, COLORS.Line)
				create("UIListLayout", {Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder}, menu)

				local control
				control = {
					Set = function(_, nextValue)
						for _, item in ipairs(values) do
							if item == nextValue then
								value = nextValue
								button.Text = "  " .. tostring(value)
								safeCallback(data.Callback, value, control)
								return
							end
						end
					end,
					Get = function()
						return value
					end,
				}

				connect(button.MouseButton1Click, function()
					if self._library._openDropdown and self._library._openDropdown ~= menu then
						self._library._openDropdown.Visible = false
					end
					menu.Visible = not menu.Visible
					self._library._openDropdown = menu.Visible and menu or nil
				end)

				for _, item in ipairs(values) do
					local option = create("TextButton", {
						Size = UDim2.new(1, 0, 0, 24),
						BackgroundTransparency = 1,
						Text = tostring(item),
						TextColor3 = COLORS.Text,
						TextSize = 10,
						Font = FONTS.Medium,
						AutoButtonColor = false,
						ZIndex = 31,
					}, menu)
					connect(option.MouseEnter, function()
						option.BackgroundTransparency = 0.82
						option.BackgroundColor3 = COLORS.Line
					end)
					connect(option.MouseLeave, function()
						option.BackgroundTransparency = 1
					end)
					connect(option.MouseButton1Click, function()
						control:Set(item)
						menu.Visible = false
						self._library._openDropdown = nil
					end)
				end

				table.insert(self.Controls, control)
				return control
			end

			function section:Keybind(nameOrOptions, callback)
				local data = parseOptions(nameOrOptions, callback)
				local key = keyCodeFrom(data.CurrentKeybind or data.Default)
				local listening = false
				local row = self:_row(controlName(data, "Keybind"))
				local button = create("TextButton", {
					Position = UDim2.new(1, -100, 0.5, -13),
					Size = UDim2.fromOffset(88, 26),
					BackgroundColor3 = COLORS.Control,
					Text = keyName(key),
					TextColor3 = COLORS.Text,
					TextSize = 10,
					Font = Enum.Font.GothamSemibold,
					AutoButtonColor = false,
					ZIndex = 7,
				}, row)
				addCorner(button, 5)
				addStroke(button, COLORS.Line)

				local control
				control = {
					Set = function(_, nextKey)
						key = keyCodeFrom(nextKey)
						button.Text = keyName(key)
						safeCallback(data.Callback, key, control)
					end,
					Get = function()
						return key
					end,
				}
				connect(button.MouseButton1Click, function()
					listening = true
					button.Text = "press key"
				end)
				connect(UserInputService.InputBegan, function(input, gameProcessed)
					if listening and input.UserInputType == Enum.UserInputType.Keyboard then
						listening = false
						control:Set(input.KeyCode)
						return
					end
					if not gameProcessed and key ~= Enum.KeyCode.Unknown
						and input.UserInputType == Enum.UserInputType.Keyboard
						and input.KeyCode == key then
						safeCallback(data.Callback, key, control)
					end
				end)

				table.insert(self.Controls, control)
				return control
			end

			return section
		end

		if #self._tabs == 1 then
			self:SelectTab(tab)
		end

		return tab
	end

	function self:RemoteSpy(options)
		options = options or {}

		if self._spyRoot then
			self._spyRoot:Destroy()
		end
		if self._singleHeader then
			self._singleHeader.Visible = false
		end

		local view = {
			_logs = {},
			_banned = {},
			_bannedRows = {},
			_selected = nil,
			_contextTarget = nil,
			_library = self,
		}
		local root = create("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(11, 11, 14),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 4,
		}, self._content)
		self._spyRoot = root

		local topBar = create("Frame", {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundColor3 = Color3.fromRGB(11, 11, 14),
			BorderSizePixel = 0,
			Active = true,
			ZIndex = 5,
		}, root)
		addText(topBar, options.Title or "RemoteSpy", 11, COLORS.Text, {
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -130, 1, 0),
			TextYAlignment = Enum.TextYAlignment.Center,
			Font = FONTS.Bold,
			ZIndex = 6,
		})
		addText(topBar, options.Status or "visual preview", 9, COLORS.Muted, {
			Position = UDim2.new(1, -108, 0, 0),
			Size = UDim2.fromOffset(82, 30),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Center,
			Font = FONTS.Medium,
			ZIndex = 6,
		})
		local closeButton = create("TextButton", {
			Position = UDim2.new(1, -25, 0, 5),
			Size = UDim2.fromOffset(20, 20),
			BackgroundColor3 = COLORS.Control,
			Text = "×",
			TextColor3 = COLORS.Muted,
			TextSize = 14,
			Font = FONTS.Medium,
			AutoButtonColor = false,
			ZIndex = 7,
		}, topBar)
		addCorner(closeButton, 5)
		addStroke(closeButton, COLORS.Line, 0.25)
		connect(closeButton.MouseButton1Click, function()
			self:Destroy()
		end)
		connect(topBar.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				windowStart = self.Window.Position
			end
		end)

		local body = create("Frame", {
			Position = UDim2.fromOffset(0, 30),
			Size = UDim2.new(1, 0, 1, -30),
			BackgroundColor3 = Color3.fromRGB(11, 11, 14),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 4,
		}, root)
		local leftPanel = create("Frame", {
			Size = UDim2.new(0, 178, 1, 0),
			BackgroundColor3 = Color3.fromRGB(11, 11, 14),
			BorderSizePixel = 0,
			ZIndex = 5,
		}, body)
		create("Frame", {
			Position = UDim2.new(1, -1, 0, 0),
			Size = UDim2.new(0, 1, 1, 0),
			BackgroundColor3 = Color3.fromRGB(29, 29, 35),
			BorderSizePixel = 0,
			ZIndex = 7,
		}, leftPanel)
		local logList = create("ScrollingFrame", {
			Position = UDim2.fromOffset(9, 8),
			Size = UDim2.new(1, -18, 1, -151),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = COLORS.LineBright,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 6,
		}, leftPanel)
		create("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, logList)

		local settingsPanel = create("Frame", {
			Position = UDim2.new(0, 0, 1, -143),
			Size = UDim2.new(1, -1, 0, 143),
			BackgroundColor3 = Color3.fromRGB(13, 13, 17),
			BorderSizePixel = 0,
			ZIndex = 6,
		}, leftPanel)
		create("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = Color3.fromRGB(29, 29, 35),
			BorderSizePixel = 0,
			ZIndex = 7,
		}, settingsPanel)
		addText(settingsPanel, "settings", 9, COLORS.Muted, {
			Position = UDim2.fromOffset(10, 8),
			Size = UDim2.new(1, -20, 0, 18),
			Font = FONTS.Bold,
			ZIndex = 7,
		})
		local settingsList = create("Frame", {
			Position = UDim2.fromOffset(8, 31),
			Size = UDim2.new(1, -16, 1, -37),
			BackgroundTransparency = 1,
			ZIndex = 7,
		}, settingsPanel)
		create("UIListLayout", {
			Padding = UDim.new(0, 5),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, settingsList)

		local detailPanel = create("Frame", {
			Position = UDim2.fromOffset(178, 0),
			Size = UDim2.new(1, -178, 1, 0),
			BackgroundColor3 = Color3.fromRGB(11, 11, 14),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 5,
		}, body)
		local codePanel = create("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(18, 18, 23),
			BorderSizePixel = 0,
			ZIndex = 6,
		}, detailPanel)
		addStroke(codePanel, Color3.fromRGB(36, 36, 43), 0.25)
		addText(codePanel, "generated request", 9, COLORS.Muted, {
			Position = UDim2.fromOffset(12, 9),
			Size = UDim2.new(1, -24, 0, 16),
			Font = FONTS.Bold,
			ZIndex = 7,
		})
		local codeLabel = addText(codePanel, options.Code or "-- no remote selected", 12, COLORS.Text, {
			Position = UDim2.fromOffset(12, 32),
			Size = UDim2.new(1, -24, 1, -44),
			Font = Enum.Font.Code,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = false,
			ZIndex = 7,
		})

		local contextMenu = create("Frame", {
			Size = UDim2.fromOffset(138, 118),
			BackgroundColor3 = Color3.fromRGB(17, 17, 21),
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 30,
		}, root)
		addCorner(contextMenu, 6)
		addStroke(contextMenu, COLORS.LineBright, 0.15)
		addText(contextMenu, "remote", 8, COLORS.Muted, {
			Position = UDim2.fromOffset(9, 5),
			Size = UDim2.new(1, -18, 0, 14),
			Font = FONTS.Bold,
			ZIndex = 31,
		})
		local contextList = create("Frame", {
			Position = UDim2.fromOffset(5, 23),
			Size = UDim2.new(1, -10, 1, -28),
			BackgroundTransparency = 1,
			ZIndex = 31,
		}, contextMenu)
		create("UIListLayout", {Padding = UDim.new(0, 3)}, contextList)

		local bannedPanel = create("Frame", {
			Position = UDim2.fromOffset(190, 52),
			Size = UDim2.fromOffset(300, 280),
			BackgroundColor3 = Color3.fromRGB(17, 17, 21),
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 25,
		}, root)
		addCorner(bannedPanel, 7)
		addStroke(bannedPanel, COLORS.LineBright, 0.1)
		addText(bannedPanel, "banned remotes", 10, COLORS.Text, {
			Position = UDim2.fromOffset(12, 8),
			Size = UDim2.new(1, -24, 0, 20),
			Font = FONTS.Bold,
			ZIndex = 26,
		})
		local bannedList = create("ScrollingFrame", {
			Position = UDim2.fromOffset(8, 34),
			Size = UDim2.new(1, -16, 1, -42),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 26,
		}, bannedPanel)
		create("UIListLayout", {Padding = UDim.new(0, 4)}, bannedList)

		function view:SetCode(code)
			codeLabel.Text = tostring(code or "")
		end

		function view:RefreshBanned()
			for _, item in ipairs(bannedList:GetChildren()) do
				if item:IsA("GuiObject") then
					item:Destroy()
				end
			end
			for name, row in pairs(view._bannedRows) do
				local item = create("TextButton", {
					Size = UDim2.new(1, 0, 0, 28),
					BackgroundColor3 = COLORS.Control,
					Text = "  " .. name .. "                         unban",
					TextColor3 = COLORS.Text,
					TextSize = 9,
					Font = FONTS.Medium,
					TextXAlignment = Enum.TextXAlignment.Left,
					AutoButtonColor = false,
					ZIndex = 27,
				}, bannedList)
				addCorner(item, 4)
				connect(item.MouseButton1Click, function()
					view._banned[name] = nil
					row.Visible = true
					view._bannedRows[name] = nil
					view:RefreshBanned()
				end)
			end
		end

		function view:Ban(data, row)
			if not data or not data.Name then
				return
			end
			view._banned[data.Name] = data
			view._bannedRows[data.Name] = row
			row.Visible = false
			contextMenu.Visible = false
			view:RefreshBanned()
		end

		function view:OpenBanned()
			view:RefreshBanned()
			bannedPanel.Visible = not bannedPanel.Visible
			contextMenu.Visible = false
		end

		local function closeContext()
			contextMenu.Visible = false
			view._contextTarget = nil
		end

		local function contextAction(name, callback)
			local button = create("TextButton", {
				Size = UDim2.new(1, 0, 0, 25),
				BackgroundColor3 = COLORS.Control,
				Text = "  " .. name,
				TextColor3 = COLORS.Text,
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = FONTS.Medium,
				AutoButtonColor = false,
				ZIndex = 32,
			}, contextList)
			addCorner(button, 4)
			connect(button.MouseEnter, function()
				button.BackgroundColor3 = Color3.fromRGB(31, 31, 37)
			end)
			connect(button.MouseLeave, function()
				button.BackgroundColor3 = COLORS.Control
			end)
			connect(button.MouseButton1Click, function()
				local target = view._contextTarget
				closeContext()
				if target then
					callback(target.data, target.row)
				end
			end)
			return button
		end

		contextAction("Run again", function(data)
			view:SetCode(data.Code or "-- run again preview")
		end)
		contextAction("Copy", function(data)
			view:SetCode("-- copy preview\n-- " .. tostring(data.Name or "Remote"))
		end)
		contextAction("Ban", function(data, row)
			view:Ban(data, row)
		end)

		function view:AddSetting(name, callback)
			local button = create("TextButton", {
				Size = UDim2.new(1, 0, 0, 27),
				BackgroundColor3 = COLORS.Control,
				Text = "  " .. tostring(name),
				TextColor3 = COLORS.Text,
				TextSize = 9,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = FONTS.Medium,
				AutoButtonColor = false,
				ZIndex = 8,
			}, settingsList)
			addCorner(button, 4)
			connect(button.MouseEnter, function()
				button.BackgroundColor3 = Color3.fromRGB(31, 31, 37)
			end)
			connect(button.MouseLeave, function()
				button.BackgroundColor3 = COLORS.Control
			end)
			connect(button.MouseButton1Click, function()
				if type(callback) == "function" then
					callback(view)
				end
			end)
			return button
		end

		function view:AddLog(entry)
			local data = type(entry) == "table" and entry or {Name = tostring(entry)}
			local row = create("TextButton", {
				Size = UDim2.new(1, 0, 0, 29),
				BackgroundColor3 = Color3.fromRGB(17, 17, 21),
				Text = "",
				AutoButtonColor = false,
				ZIndex = 8,
			}, logList)
			addCorner(row, 4)
			addStroke(row, Color3.fromRGB(36, 36, 43), 0.35)
			create("Frame", {
				Size = UDim2.new(0, 3, 1, 0),
				BackgroundColor3 = data.Color or (data.Type == "function" and Color3.fromRGB(115, 100, 240) or Color3.fromRGB(238, 220, 40)),
				BorderSizePixel = 0,
				ZIndex = 9,
			}, row)
			addText(row, data.Name or "Remote", 10, COLORS.Text, {
				Position = UDim2.fromOffset(11, 0),
				Size = UDim2.new(1, -16, 1, 0),
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Font = FONTS.Medium,
				ZIndex = 9,
			})
			local target = {data = data, row = row}
			connect(row.MouseEnter, function()
				if view._selected ~= target then
					row.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
				end
			end)
			connect(row.MouseLeave, function()
				if view._selected ~= target then
					row.BackgroundColor3 = Color3.fromRGB(17, 17, 21)
				end
			end)
			connect(row.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton2 then
					view._contextTarget = target
					local rootPosition = root.AbsolutePosition
					local x = math.clamp(input.Position.X - rootPosition.X + 4, 4, math.max(root.AbsoluteSize.X - 146, 4))
					local y = math.clamp(input.Position.Y - rootPosition.Y + 4, 34, math.max(root.AbsoluteSize.Y - 124, 34))
					contextMenu.Position = UDim2.fromOffset(x, y)
					contextMenu.Visible = true
				end
			end)
			connect(row.MouseButton1Click, function()
				if view._selected then
					view._selected.row.BackgroundColor3 = Color3.fromRGB(17, 17, 21)
				end
				view._selected = target
				row.BackgroundColor3 = Color3.fromRGB(31, 31, 37)
				view:SetCode(data.Code or "-- no generated request")
			end)
			row.Visible = view._banned[data.Name] == nil
			if not row.Visible then
				view._bannedRows[data.Name] = row
			end
			table.insert(view._logs, target)
			if not view._selected and row.Visible then
				view._selected = target
				row.BackgroundColor3 = Color3.fromRGB(31, 31, 37)
				view:SetCode(data.Code or "-- no generated request")
			end
			return row
		end

		function view:Clear()
			for _, target in ipairs(view._logs) do
				if target.row then
					target.row:Destroy()
				end
			end
			table.clear(view._logs)
			view._selected = nil
			view:SetCode("-- no remote selected")
		end

		return view
	end

	function self:SelectTab(activeTab)
		for _, tab in ipairs(self._tabs) do
			local active = tab == activeTab
			tab._page.Visible = active
			tab._activeLine.Visible = active
			tab._button.BackgroundTransparency = active and 0.88 or 1
			tab._button.TextColor3 = active and COLORS.Text or COLORS.Muted
			setIconColor(tab._icon, active and COLORS.Text or COLORS.Muted)
		end
	end

	function self:Notify(options)
		if self._destroyed then
			return nil
		end

		local data = type(options) == "table" and options or {Text = tostring(options)}

		if not self._notificationHolder then
			self._notificationHolder = create("Frame", {
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -18, 1, -18),
				Size = UDim2.fromOffset(270, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				ZIndex = 100,
			}, self.Gui)
			create("UIListLayout", {
				Padding = UDim.new(0, 8),
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
			}, self._notificationHolder)
		end

		local notification = create("Frame", {
			Size = UDim2.fromOffset(270, 64),
			BackgroundColor3 = COLORS.Panel,
			BackgroundTransparency = 0.04,
			BorderSizePixel = 0,
			ZIndex = 101,
		}, self._notificationHolder)
		addCorner(notification, 7)
		addStroke(notification, COLORS.LineBright)
		create("Frame", {
			Size = UDim2.new(0, 2, 1, -16),
			Position = UDim2.fromOffset(8, 8),
			BackgroundColor3 = COLORS.Accent,
			BorderSizePixel = 0,
			ZIndex = 102,
		}, notification)
		addText(notification, data.Title or "Notification", 11, COLORS.Text, {
			Position = UDim2.fromOffset(20, 9),
			Size = UDim2.new(1, -30, 0, 18),
			Font = Enum.Font.GothamBold,
			ZIndex = 102,
		})
		addText(notification, data.Text or data.Content or "", 10, COLORS.Muted, {
			Position = UDim2.fromOffset(20, 30),
			Size = UDim2.new(1, -30, 0, 24),
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 102,
		})

		table.insert(self._notifications, notification)
		while #self._notifications > 4 do
			local oldest = table.remove(self._notifications, 1)
			if oldest then
				oldest:Destroy()
			end
		end

		local duration = tonumber(data.Duration) or 3
		local fadeIn = TweenService:Create(notification, TweenInfo.new(0.18), {
			BackgroundTransparency = 0.04,
		})
		notification.BackgroundTransparency = 1
		fadeIn:Play()

		task.delay(duration, function()
			if not notification.Parent then
				return
			end

			local fadeOut = TweenService:Create(notification, TweenInfo.new(0.16), {
				BackgroundTransparency = 1,
			})
			fadeOut:Play()
			fadeOut.Completed:Wait()
			if notification.Parent then
				notification:Destroy()
			end
		end)

		return notification
	end

	function self:Destroy()
		if self._destroyed then
			return
		end

		self._destroyed = true

		for _, connection in ipairs(self._dynamicConnections) do
			pcall(function()
				connection:Disconnect()
			end)
		end
		for _, connection in ipairs(self._connections) do
			pcall(function()
				connection:Disconnect()
			end)
		end

		if self.Gui then
			self.Gui:Destroy()
		end
	end

	return self
end

return Library
