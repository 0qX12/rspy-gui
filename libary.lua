local Library = {}
Library.__index = Library

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local COLORS = {
	Background = Color3.fromRGB(9, 9, 12),
	Panel = Color3.fromRGB(17, 17, 22),
	PanelRaised = Color3.fromRGB(28, 28, 35),
	Control = Color3.fromRGB(31, 31, 39),
	Line = Color3.fromRGB(49, 49, 59),
	LineBright = Color3.fromRGB(98, 98, 111),
	Text = Color3.fromRGB(245, 245, 248),
	Muted = Color3.fromRGB(148, 148, 160),
	MutedDark = Color3.fromRGB(106, 106, 119),
	Accent = Color3.fromRGB(245, 245, 248),
	Event = Color3.fromRGB(238, 220, 40),
	Function = Color3.fromRGB(115, 100, 240),
}

local FONTS = {
	Regular = Enum.Font.Gotham,
	Medium = Enum.Font.GothamMedium,
	Semibold = Enum.Font.GothamSemibold,
	Bold = Enum.Font.GothamBold,
	Code = Enum.Font.Code,
}

local ICONS = {
	Settings = {16898613777, {48, 48}, {771, 257}},
	Close = {16898613869, {48, 48}, {869, 906}},
	Search = {16898613699, {48, 48}, {918, 857}},
	List = {16898613509, {48, 48}, {869, 808}},
	Minus = {16898613613, {48, 48}, {771, 196}},
}

local function iconProperties(icon, color, transparency)
	return {
		Image = "rbxassetid://" .. tostring(icon[1]),
		ImageRectSize = Vector2.new(icon[2][1], icon[2][2]),
		ImageRectOffset = Vector2.new(icon[3][1], icon[3][2]),
		ImageColor3 = color or COLORS.Muted,
		ImageTransparency = transparency or 0,
		ScaleType = Enum.ScaleType.Fit,
	}
end

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

local WARMUP_SIZES = {9, 10, 11, 12, 13, 14}
local WARMUP_TEXT = "abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789 -_.,:;()[]{}=\"'/"

local function warmupFonts(parent)
	local holder = create("Frame", {
		Name = "FontWarmup",
		Size = UDim2.fromOffset(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		ZIndex = 0,
	}, parent)

	for _, font in pairs(FONTS) do
		for _, size in ipairs(WARMUP_SIZES) do
			create("TextLabel", {
			Size = UDim2.fromOffset(1, 1),
			BackgroundTransparency = 1,
			TextTransparency = 0.99,
			Text = WARMUP_TEXT,
			TextSize = size,
			Font = font,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 0,
			}, holder)
		end
	end

	return holder
end

local function addCorner(parent, radius)
	return create("UICorner", {
		CornerRadius = UDim.new(0, radius or 6),
	}, parent)
end

local function addStroke(parent, color, transparency)
	return create("UIStroke", {
		Color = color or COLORS.Line,
		Transparency = transparency or 0,
		Thickness = 1,
	}, parent)
end

local function addGradient(parent, startColor, endColor, rotation)
	-- UIGradient multiplies its colors by the object's base color. Keep the
	-- base neutral so the requested surface colors remain visible at 1x scale.
	parent.BackgroundColor3 = Color3.new(1, 1, 1)
	return create("UIGradient", {
		Color = ColorSequence.new(startColor, endColor),
		Rotation = rotation or 90,
	}, parent)
end

local function addText(parent, value, size, color, properties)
	local textProperties = {
		BackgroundTransparency = 1,
		Text = tostring(value or ""),
		TextColor3 = color or COLORS.Text,
		TextSize = size or 11,
		Font = FONTS.Medium,
		TextStrokeTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
	}

	for property, propertyValue in pairs(properties or {}) do
		textProperties[property] = propertyValue
	end

	return create("TextLabel", textProperties, parent)
end

local function safeCallback(callback, ...)
	if type(callback) ~= "function" then
		return
	end

	local arguments = table.pack(...)
	task.spawn(function()
		pcall(function()
			callback(table.unpack(arguments, 1, arguments.n))
		end)
	end)
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

local function resolveKeyCode(value)
	if typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode then
		return value
	end

	if type(value) == "string" and value ~= "" then
		local ok, keyCode = pcall(function()
			return Enum.KeyCode[value]
		end)
		if ok and typeof(keyCode) == "EnumItem" then
			return keyCode
		end
	end

	return Enum.KeyCode.Home
end

local function typeColor(remoteType)
	return string.lower(tostring(remoteType or "event")) == "function"
		and COLORS.Function
		or COLORS.Event
end

local function displayName(value)
	return tostring(value or "Remote")
end

local SETTING_DESCRIPTIONS = {
	["Function info"] = "Show return values and argument details",
	["Autoblock"] = "Block matching remotes automatically",
	["Logcheckcaller"] = "Include calls from the local caller",
	["Advanced info"] = "Display extra call metadata",
	["Toggle key"] = "Change the key used to hide or restore RemoteSpy",
	["Banned remotes"] = "Review remotes hidden from capture",
	["Clear logs"] = "Remove every captured entry",
}

function Library.new(config)
	config = config or {}

	local self = setmetatable({
		_connections = {},
		_dynamicConnections = {},
		_destroyed = false,
		_hidden = false,
		_toggleKey = resolveKeyCode(config.ToggleKey),
		_onToggleKeyChanged = config.OnToggleKeyChanged,
		_keyCapture = false,
		_windowScale = nil,
		_visibilityVersion = 0,
		_view = nil,
	}, Library)

	local host = getGuiParent()
	local guiName = config.Name or "RemoteSpyGUI"
	local previous = host:FindFirstChild(guiName)
	if previous then
		previous:Destroy()
	end

	local windowSize, width, height = resolveSize(config)

	self.Gui = create("ScreenGui", {
		Name = guiName,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 1000,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, host)
	warmupFonts(self.Gui)

	local viewport = workspace.CurrentCamera.ViewportSize

	self.Window = create("Frame", {
		Size = windowSize,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(
			math.floor(viewport.X / 2),
			math.floor(viewport.Y / 2)
		),
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel = 0,
		Active = true,
		ClipsDescendants = true,
		ZIndex = 2,
	}, self.Gui)
	addCorner(self.Window, 9)
	addGradient(self.Window, Color3.fromRGB(20, 20, 26), COLORS.Background, 90)
	self._windowScale = create("UIScale", {
		Scale = 1,
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
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 5,
	}, self.Window)
	create("Frame", {
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = COLORS.Line,
		BorderSizePixel = 0,
		ZIndex = 7,
	}, topBar)
	addGradient(topBar, Color3.fromRGB(25, 25, 31), Color3.fromRGB(13, 13, 17), 90)
	addText(topBar, config.Title or "RemoteSpy", 12, COLORS.Text, {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -150, 1, 0),
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = FONTS.Bold,
		ZIndex = 6,
	})
	local closeButton = create("ImageButton", {
		Position = UDim2.new(1, -27, 0, 6),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = COLORS.Control,
		AutoButtonColor = false,
		ZIndex = 7,
	}, topBar)
	for property, value in pairs(iconProperties(ICONS.Close, COLORS.Muted, 0.08)) do
		closeButton[property] = value
	end
	addCorner(closeButton, 5)
	addStroke(closeButton, COLORS.Line, 0.2)
	local hideButton = create("ImageButton", {
		Position = UDim2.new(1, -51, 0, 6),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = COLORS.Control,
		AutoButtonColor = false,
		ZIndex = 7,
	}, topBar)
	for property, value in pairs(iconProperties(ICONS.Minus, COLORS.Muted, 0.08)) do
		hideButton[property] = value
	end
	addCorner(hideButton, 5)
	addStroke(hideButton, COLORS.Line, 0.2)

	local body = create("Frame", {
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(1, 0, 1, -34),
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 3,
	}, self.Window)
	addGradient(body, Color3.fromRGB(15, 15, 19), COLORS.Background, 90)

	self._body = body
	self._topBar = topBar

	local function connect(signal, handler)
		local connection = signal:Connect(handler)
		table.insert(self._connections, connection)
		return connection
	end

	connect(closeButton.MouseEnter, function()
		TweenService:Create(closeButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = Color3.fromRGB(120, 46, 52),
			ImageColor3 = COLORS.Text,
			ImageTransparency = 0,
		}):Play()
	end)
	connect(closeButton.MouseLeave, function()
		TweenService:Create(closeButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = COLORS.Control,
			ImageColor3 = COLORS.Muted,
			ImageTransparency = 0.08,
		}):Play()
	end)
	connect(closeButton.MouseButton1Click, function()
		self:Destroy()
	end)
	connect(hideButton.MouseEnter, function()
		TweenService:Create(hideButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = COLORS.PanelRaised,
			ImageColor3 = COLORS.Text,
			ImageTransparency = 0,
		}):Play()
	end)
	connect(hideButton.MouseLeave, function()
		TweenService:Create(hideButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = COLORS.Control,
			ImageColor3 = COLORS.Muted,
			ImageTransparency = 0.08,
		}):Play()
	end)
	connect(hideButton.MouseButton1Click, function()
		self:Hide()
	end)

	local dragging = false
	local dragStart
	local windowStart
	connect(topBar.InputBegan, function(input)
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
				windowStart.X.Offset + math.floor(delta.X + 0.5),
				windowStart.Y.Scale,
				windowStart.Y.Offset + math.floor(delta.Y + 0.5)
			)
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

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

	local function animateWindow(showing)
		self._visibilityVersion += 1
		local version = self._visibilityVersion
		local transitionDuration = showing and 0.3 or 0.24
		local hiddenScale = 0.92
		if showing then
			self.Window.Visible = true
			self._windowScale.Scale = hiddenScale
		end

		TweenService:Create(self._windowScale, TweenInfo.new(
			transitionDuration,
			Enum.EasingStyle.Quint,
			showing and Enum.EasingDirection.Out or Enum.EasingDirection.In
		), {
			Scale = showing and 1 or hiddenScale,
		}):Play()

		if not showing then
			task.delay(transitionDuration + 0.03, function()
				if self._visibilityVersion == version and self._hidden and self.Window.Parent then
					self.Window.Visible = false
				end
			end)
		end
	end

	function self:SetToggleKey(value)
		self._toggleKey = resolveKeyCode(value)
		if type(self._onToggleKeyChanged) == "function" then
			task.spawn(function()
				pcall(self._onToggleKeyChanged, self._toggleKey)
			end)
		end
		return self._toggleKey
	end

	function self:GetToggleKey()
		return self._toggleKey
	end

	function self:Hide()
		if self._destroyed or self._hidden then
			return
		end

		self._hidden = true
		animateWindow(false)
		self:Notify({
			Title = "RemoteSpy hidden",
			Text = "Press Home to restore",
			Duration = 5,
		})
	end

	function self:Show()
		if self._destroyed then
			return
		end

		self._hidden = false
		animateWindow(true)
	end

	function self:ToggleHidden()
		if self._hidden then
			self:Show()
		else
			self:Hide()
		end
	end

	connect(UserInputService.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.Keyboard
			and input.KeyCode == self._toggleKey
			and not self._keyCapture then
			self:ToggleHidden()
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

	function self:RemoteSpy(options)
		options = options or {}

		if self._view and self._view._root then
			self._view._root:Destroy()
		end

		local view = {
			_logs = {},
			_banned = {},
			_settings = {},
			_settingOrder = 0,
			_selected = nil,
			_contextTarget = nil,
			_library = self,
		}

		local root = create("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = COLORS.Background,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 4,
		}, self._body)
		view._root = root
		self._view = view
		local leftWidth = 242

		local leftPanel = create("Frame", {
			Size = UDim2.new(0, leftWidth, 1, 0),
			BackgroundColor3 = Color3.fromRGB(11, 11, 14),
			BorderSizePixel = 0,
			ZIndex = 5,
		}, root)
		addGradient(leftPanel, Color3.fromRGB(15, 15, 19), Color3.fromRGB(9, 9, 12), 90)
		addStroke(leftPanel, COLORS.Line, 0.58)
		local contextMenu
		create("Frame", {
			Position = UDim2.new(1, -1, 0, 0),
			Size = UDim2.new(0, 1, 1, 0),
			BackgroundColor3 = COLORS.Line,
			BorderSizePixel = 0,
			ZIndex = 8,
		}, leftPanel)

		local searchFrame = create("Frame", {
			Position = UDim2.fromOffset(9, 9),
			Size = UDim2.new(1, -18, 0, 30),
			BackgroundColor3 = Color3.fromRGB(24, 24, 30),
			BorderSizePixel = 0,
			ZIndex = 7,
		}, leftPanel)
		addCorner(searchFrame, 6)
		addStroke(searchFrame, COLORS.Line, 0.25)
		local searchIcon = create("ImageLabel", {
			Position = UDim2.fromOffset(9, 7),
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			ZIndex = 8,
		}, searchFrame)
		for property, value in pairs(iconProperties(ICONS.Search, COLORS.Muted, 0.08)) do
			searchIcon[property] = value
		end
		local searchInput = create("TextBox", {
			Position = UDim2.fromOffset(32, 0),
			Size = UDim2.new(1, -72, 1, 0),
			BackgroundTransparency = 1,
			ClearTextOnFocus = false,
			PlaceholderText = "Search remotes",
			PlaceholderColor3 = COLORS.MutedDark,
			Text = "",
			TextColor3 = COLORS.Text,
			TextSize = 10,
			Font = FONTS.Medium,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 8,
		}, searchFrame)
		local filterButton = create("ImageButton", {
			Position = UDim2.new(1, -32, 0, 3),
			Size = UDim2.fromOffset(24, 24),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			ZIndex = 9,
		}, searchFrame)
		for property, value in pairs(iconProperties(ICONS.List, COLORS.Muted, 0.08)) do
			filterButton[property] = value
		end

		local logList = create("ScrollingFrame", {
			Position = UDim2.fromOffset(9, 48),
			Size = UDim2.new(1, -18, 1, -91),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 0,
			ScrollBarImageColor3 = COLORS.LineBright,
			ScrollBarImageTransparency = 1,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 6,
		}, leftPanel)
		create("UIListLayout", {
			Padding = UDim.new(0, 7),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, logList)
		local searchQuery = ""
		local filterType = "all"
		local function matchesSearch(target)
			local matchesName = searchQuery == ""
				or string.find(string.lower(target.name), searchQuery, 1, true) ~= nil
			local targetType = string.lower(tostring(target.data.Type or "event"))
			local matchesType = filterType == "all" or targetType == filterType
			return matchesName and matchesType
		end
		local function applySearch()
			for _, target in ipairs(view._logs) do
				if target.row.Parent then
					target.row.Visible = view._banned[target.name] ~= true and matchesSearch(target)
				end
			end
			logList.CanvasPosition = Vector2.zero
		end
		connect(searchInput:GetPropertyChangedSignal("Text"), function()
			searchQuery = string.lower(searchInput.Text or "")
			applySearch()
		end)
		local filterPopup = create("Frame", {
			Position = UDim2.new(1, -174, 0, 44),
			Size = UDim2.fromOffset(165, 132),
			BackgroundColor3 = COLORS.PanelRaised,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Active = true,
			Visible = false,
			ZIndex = 50,
		}, leftPanel)
		addCorner(filterPopup, 7)
		addStroke(filterPopup, COLORS.LineBright, 0.25)
		addGradient(filterPopup, Color3.fromRGB(38, 38, 47), Color3.fromRGB(19, 19, 25), 90)
		addText(filterPopup, "filter by type", 10, COLORS.Muted, {
			Position = UDim2.fromOffset(12, 8),
			Size = UDim2.new(1, -24, 0, 18),
			Font = FONTS.Semibold,
			ZIndex = 51,
		})
		local filterList = create("Frame", {
			Position = UDim2.fromOffset(8, 31),
			Size = UDim2.new(1, -16, 1, -39),
			BackgroundTransparency = 1,
			ZIndex = 51,
		}, filterPopup)
		create("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, filterList)
		local filterOptions = {}
		local function updateFilterVisuals()
			for value, optionData in pairs(filterOptions) do
				local active = value == filterType
				optionData.Button.BackgroundColor3 = active and Color3.fromRGB(48, 48, 58) or Color3.fromRGB(27, 27, 34)
				optionData.Label.TextColor3 = active and COLORS.Text or COLORS.Muted
			end
			filterButton.ImageColor3 = filterType == "all" and COLORS.Muted or COLORS.Text
			filterButton.ImageTransparency = filterType == "all" and 0.08 or 0
		end
		local function addFilterOption(label, value, color)
			local option = create("TextButton", {
				Size = UDim2.new(1, 0, 0, 27),
				BackgroundColor3 = Color3.fromRGB(27, 27, 34),
				Text = "",
				AutoButtonColor = false,
				ZIndex = 52,
			}, filterList)
			addCorner(option, 5)
			addStroke(option, COLORS.Line, 0.62)
			create("Frame", {
				Position = UDim2.fromOffset(8, 7),
				Size = UDim2.fromOffset(2, 13),
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				ZIndex = 53,
			}, option)
			local optionLabel = addText(option, label, 10, COLORS.Muted, {
				Position = UDim2.fromOffset(19, 0),
				Size = UDim2.new(1, -27, 1, 0),
				TextYAlignment = Enum.TextYAlignment.Center,
				Font = FONTS.Medium,
				ZIndex = 53,
			})
			filterOptions[value] = {Button = option, Label = optionLabel}
			connect(option.MouseEnter, function()
				if filterType ~= value then
					TweenService:Create(option, TweenInfo.new(0.1), {
						BackgroundColor3 = Color3.fromRGB(42, 42, 50),
					}):Play()
				end
			end)
			connect(option.MouseLeave, function()
				updateFilterVisuals()
			end)
			connect(option.MouseButton1Click, function()
				filterType = value
				filterPopup.Visible = false
				updateFilterVisuals()
				applySearch()
			end)
		end
		addFilterOption("All types", "all", COLORS.Accent)
		addFilterOption("Events", "event", COLORS.Event)
		addFilterOption("Functions", "function", COLORS.Function)
		updateFilterVisuals()
		connect(filterButton.MouseEnter, function()
			TweenService:Create(filterButton, TweenInfo.new(0.1), {
				ImageColor3 = COLORS.Text,
				ImageTransparency = 0,
			}):Play()
		end)
		connect(filterButton.MouseLeave, function()
			updateFilterVisuals()
		end)
		connect(filterButton.MouseButton1Click, function()
			contextMenu.Visible = false
			view._contextTarget = nil
			filterPopup.Visible = not filterPopup.Visible
		end)

		local detailPanel = create("Frame", {
			Position = UDim2.fromOffset(leftWidth, 0),
			Size = UDim2.new(1, -leftWidth, 1, 0),
			BackgroundColor3 = COLORS.Background,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 5,
		}, root)
		addGradient(detailPanel, Color3.fromRGB(19, 19, 24), COLORS.Background, 90)

		local codePanel = create("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(18, 18, 23),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 6,
		}, detailPanel)
		addStroke(codePanel, COLORS.Line, 0.25)
		addGradient(codePanel, Color3.fromRGB(25, 25, 31), Color3.fromRGB(15, 15, 19), 90)
		create("Frame", {
			Position = UDim2.fromOffset(0, 34),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = COLORS.Line,
			BorderSizePixel = 0,
			ZIndex = 7,
		}, codePanel)
		local codeLabel = addText(codePanel, options.Code or "-- no remote selected", 13, Color3.fromRGB(230, 230, 235), {
			Position = UDim2.fromOffset(18, 48),
			Size = UDim2.new(1, -36, 1, -64),
			Font = FONTS.Code,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = false,
			ZIndex = 7,
		})

		local settingsButton = create("ImageButton", {
			Position = UDim2.new(0, 12, 1, -36),
			Size = UDim2.fromOffset(24, 24),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			ZIndex = 12,
		}, leftPanel)
		for property, value in pairs(iconProperties(ICONS.Settings, COLORS.Muted, 0.06)) do
			settingsButton[property] = value
		end

		local settingsPanel = create("Frame", {
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(15, 15, 19),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 8,
			Visible = false,
		}, root)
		addGradient(settingsPanel, Color3.fromRGB(24, 24, 30), Color3.fromRGB(12, 12, 16), 90)
		addText(settingsPanel, "settings", 14, COLORS.Text, {
			Position = UDim2.fromOffset(24, 12),
			Size = UDim2.new(1, -120, 0, 24),
			Font = FONTS.Bold,
			ZIndex = 9,
		})
		addText(settingsPanel, "RemoteSpy configuration", 10, COLORS.Muted, {
			Position = UDim2.fromOffset(24, 37),
			Size = UDim2.new(1, -150, 0, 18),
			Font = FONTS.Medium,
			ZIndex = 9,
		})
		create("Frame", {
			Position = UDim2.fromOffset(24, 67),
			Size = UDim2.new(1, -48, 0, 1),
			BackgroundColor3 = COLORS.Line,
			BorderSizePixel = 0,
			ZIndex = 9,
		}, settingsPanel)
		local settingsClose = create("ImageButton", {
			Position = UDim2.new(1, -54, 0, 14),
			Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = COLORS.Control,
			AutoButtonColor = false,
			ZIndex = 10,
		}, settingsPanel)
		for property, value in pairs(iconProperties(ICONS.Close, COLORS.Muted, 0.08)) do
			settingsClose[property] = value
		end
		addCorner(settingsClose, 6)
		addStroke(settingsClose, COLORS.Line, 0.25)
		connect(settingsClose.MouseEnter, function()
			TweenService:Create(settingsClose, TweenInfo.new(0.12), {
				BackgroundColor3 = COLORS.PanelRaised,
				ImageColor3 = COLORS.Text,
				ImageTransparency = 0,
			}):Play()
		end)
		connect(settingsClose.MouseLeave, function()
			TweenService:Create(settingsClose, TweenInfo.new(0.12), {
				BackgroundColor3 = COLORS.Control,
				ImageColor3 = COLORS.Muted,
				ImageTransparency = 0.08,
			}):Play()
		end)
		local settingsList = create("ScrollingFrame", {
			Position = UDim2.fromOffset(24, 82),
			Size = UDim2.new(1, -48, 1, -112),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 0,
			ScrollBarImageColor3 = COLORS.LineBright,
			ScrollBarImageTransparency = 1,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 9,
		}, settingsPanel)
		create("UIGridLayout", {
			CellSize = UDim2.new(0.5, -6, 0, 62),
			CellPadding = UDim2.fromOffset(12, 10),
			FillDirection = Enum.FillDirection.Horizontal,
			FillDirectionMaxCells = 2,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, settingsList)
		local settingsAppearance
		local function captureSettingsAppearance()
			if settingsAppearance then
				return
			end

			settingsAppearance = {}
			for _, object in ipairs(settingsPanel:GetDescendants()) do
				local state = {Object = object}
				local hasState = false
				if object:IsA("GuiObject") then
					state.BackgroundTransparency = object.BackgroundTransparency
					hasState = true
				end
				if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
					state.TextTransparency = object.TextTransparency
					hasState = true
				end
				if object:IsA("ImageLabel") or object:IsA("ImageButton") then
					state.ImageTransparency = object.ImageTransparency
					hasState = true
				end
				if object:IsA("UIStroke") then
					state.StrokeTransparency = object.Transparency
					hasState = true
				end
				if hasState then
					table.insert(settingsAppearance, state)
				end
			end
		end
		local function tweenSettingsAppearance(showing)
			captureSettingsAppearance()
			for index, state in ipairs(settingsAppearance) do
				local object = state.Object
				if object.Parent then
					local goal = {}
					if state.BackgroundTransparency ~= nil then
						if showing then
							object.BackgroundTransparency = 1
						end
						goal.BackgroundTransparency = showing and state.BackgroundTransparency or 1
					end
					if state.TextTransparency ~= nil then
						if showing then
							object.TextTransparency = 1
						end
						goal.TextTransparency = showing and state.TextTransparency or 1
					end
					if state.ImageTransparency ~= nil then
						if showing then
							object.ImageTransparency = 1
						end
						goal.ImageTransparency = showing and state.ImageTransparency or 1
					end
					if state.StrokeTransparency ~= nil then
						if showing then
							object.Transparency = 1
						end
						goal.Transparency = showing and state.StrokeTransparency or 1
					end
					TweenService:Create(object, TweenInfo.new(
						showing and 0.2 or 0.12,
						Enum.EasingStyle.Quint,
						showing and Enum.EasingDirection.Out or Enum.EasingDirection.In,
						0,
						false,
						showing and math.min(index * 0.004, 0.08) or 0
					), goal):Play()
				end
			end
		end
		local function showSettings()
			settingsPanel.Visible = true
			settingsButton.Visible = false
			filterPopup.Visible = false
			settingsPanel.BackgroundTransparency = 1
			tweenSettingsAppearance(true)
			TweenService:Create(settingsPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0,
			}):Play()
		end

		local function hideSettings()
			tweenSettingsAppearance(false)
			local fade = TweenService:Create(settingsPanel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 1,
			})
			fade.Completed:Connect(function()
				settingsPanel.Visible = false
				settingsButton.Visible = true
			end)
			fade:Play()
		end

		connect(settingsButton.MouseEnter, function()
			TweenService:Create(settingsButton, TweenInfo.new(0.12), {
				ImageColor3 = COLORS.Text,
				ImageTransparency = 0,
			}):Play()
		end)
		connect(settingsButton.MouseLeave, function()
			TweenService:Create(settingsButton, TweenInfo.new(0.12), {
				ImageColor3 = COLORS.Muted,
				ImageTransparency = 0.06,
			}):Play()
		end)
		connect(settingsButton.MouseButton1Click, showSettings)
		connect(settingsClose.MouseButton1Click, hideSettings)

		contextMenu = create("Frame", {
			Size = UDim2.fromOffset(188, 126),
			BackgroundColor3 = COLORS.PanelRaised,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Active = true,
			Visible = false,
			ZIndex = 40,
		}, root)
		addCorner(contextMenu, 8)
		addStroke(contextMenu, COLORS.LineBright, 0.28)
		addGradient(contextMenu, Color3.fromRGB(38, 38, 47), Color3.fromRGB(19, 19, 25), 90)
		local contextList = create("Frame", {
			Position = UDim2.fromOffset(7, 7),
			Size = UDim2.new(1, -14, 1, -14),
			BackgroundTransparency = 1,
			Active = true,
			ZIndex = 41,
		}, contextMenu)
		create("UIListLayout", {
			Padding = UDim.new(0, 5),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, contextList)

		local bannedPanel = create("Frame", {
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = COLORS.Panel,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Visible = false,
			ClipsDescendants = true,
			ZIndex = 30,
		}, root)
		addGradient(bannedPanel, Color3.fromRGB(24, 24, 30), Color3.fromRGB(11, 11, 14), 90)
		addText(bannedPanel, "banned remotes", 14, COLORS.Text, {
			Position = UDim2.fromOffset(24, 12),
			Size = UDim2.new(1, -190, 0, 24),
			Font = FONTS.Bold,
			ZIndex = 31,
		})
		addText(bannedPanel, "Remotes hidden from the capture list", 10, COLORS.Muted, {
			Position = UDim2.fromOffset(24, 37),
			Size = UDim2.new(1, -210, 0, 18),
			Font = FONTS.Medium,
			ZIndex = 31,
		})
		local bannedCountLabel = addText(bannedPanel, "0 blocked", 10, COLORS.Muted, {
			Position = UDim2.new(1, -190, 0, 38),
			Size = UDim2.fromOffset(120, 18),
			TextXAlignment = Enum.TextXAlignment.Right,
			Font = FONTS.Semibold,
			ZIndex = 31,
		})
		create("Frame", {
			Position = UDim2.fromOffset(24, 67),
			Size = UDim2.new(1, -48, 0, 1),
			BackgroundColor3 = COLORS.Line,
			BorderSizePixel = 0,
			ZIndex = 31,
		}, bannedPanel)
		local bannedClose = create("ImageButton", {
			Position = UDim2.new(1, -54, 0, 14),
			Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = COLORS.Control,
			AutoButtonColor = false,
			ZIndex = 32,
		}, bannedPanel)
		for property, value in pairs(iconProperties(ICONS.Close, COLORS.Muted, 0.08)) do
			bannedClose[property] = value
		end
		addCorner(bannedClose, 6)
		addStroke(bannedClose, COLORS.Line, 0.25)
		connect(bannedClose.MouseEnter, function()
			TweenService:Create(bannedClose, TweenInfo.new(0.12), {
				BackgroundColor3 = COLORS.PanelRaised,
				ImageColor3 = COLORS.Text,
				ImageTransparency = 0,
			}):Play()
		end)
		connect(bannedClose.MouseLeave, function()
			TweenService:Create(bannedClose, TweenInfo.new(0.12), {
				BackgroundColor3 = COLORS.Control,
				ImageColor3 = COLORS.Muted,
				ImageTransparency = 0.08,
			}):Play()
		end)
		local bannedList = create("ScrollingFrame", {
			Position = UDim2.fromOffset(24, 82),
			Size = UDim2.new(1, -48, 1, -112),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 0,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarImageColor3 = COLORS.LineBright,
			ScrollBarImageTransparency = 1,
			ZIndex = 31,
		}, bannedPanel)
		create("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, bannedList)
		local bannedEmpty = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 22),
			Size = UDim2.fromOffset(360, 82),
			BackgroundTransparency = 1,
			ZIndex = 33,
			Visible = false,
		}, bannedPanel)
		addText(bannedEmpty, "No banned remotes", 13, COLORS.Text, {
			Position = UDim2.fromOffset(0, 4),
			Size = UDim2.new(1, 0, 0, 24),
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = FONTS.Bold,
			ZIndex = 34,
		})
		addText(bannedEmpty, "Banned entries will appear here.", 10, COLORS.Muted, {
			Position = UDim2.fromOffset(0, 34),
			Size = UDim2.new(1, 0, 0, 20),
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = FONTS.Medium,
			ZIndex = 34,
		})
		local function showBanned()
			settingsPanel.Visible = false
			settingsButton.Visible = false
			filterPopup.Visible = false
			bannedPanel.Visible = true
			bannedPanel.BackgroundTransparency = 1
			TweenService:Create(bannedPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0,
			}):Play()
		end
		local function hideBanned()
			local fade = TweenService:Create(bannedPanel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 1,
			})
			fade.Completed:Connect(function()
				bannedPanel.Visible = false
				settingsButton.Visible = true
			end)
			fade:Play()
		end
		connect(bannedClose.MouseButton1Click, function()
			hideBanned()
		end)

		function view:SetCode(code)
			codeLabel.Text = tostring(code or "-- no remote selected")
		end

		local function selectTarget(target)
			if view._selected and view._selected.row.Parent then
				TweenService:Create(view._selected.row, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundColor3 = Color3.fromRGB(17, 17, 21),
				}):Play()
				TweenService:Create(view._selected.selectionStroke, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Transparency = 1,
				}):Play()
			end

			view._selected = target
			TweenService:Create(target.row, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				BackgroundColor3 = Color3.fromRGB(38, 38, 46),
			}):Play()
			TweenService:Create(target.selectionStroke, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Transparency = 0.2,
			}):Play()
			view:SetCode(target.data.Code or "-- no selected call")
			safeCallback(target.data.Callback, target.data, view)
		end

		function view:RefreshBanned()
			for _, item in ipairs(bannedList:GetChildren()) do
				if item:IsA("GuiObject") then
					item:Destroy()
				end
			end

			local bannedCount = 0
			for name in pairs(view._banned) do
				bannedCount += 1
				local item = create("Frame", {
					Size = UDim2.new(1, 0, 0, 62),
					BackgroundColor3 = COLORS.Panel,
					BorderSizePixel = 0,
					LayoutOrder = bannedCount,
					ZIndex = 37,
				}, bannedList)
				addCorner(item, 7)
				addStroke(item, COLORS.Line, 0.48)
				addGradient(item, Color3.fromRGB(25, 25, 31), Color3.fromRGB(17, 17, 22), 90)
				addText(item, tostring(name), 11, COLORS.Text, {
					Position = UDim2.fromOffset(14, 8),
					Size = UDim2.new(1, -126, 0, 20),
					TextTruncate = Enum.TextTruncate.AtEnd,
					Font = FONTS.Semibold,
					ZIndex = 38,
				})
				addText(item, "Hidden from capture list", 11, COLORS.Muted, {
					Position = UDim2.fromOffset(14, 32),
					Size = UDim2.new(1, -126, 0, 18),
					TextTruncate = Enum.TextTruncate.AtEnd,
					Font = FONTS.Medium,
					ZIndex = 38,
				})
				local unban = create("TextButton", {
					Position = UDim2.new(1, -92, 0.5, -13),
					Size = UDim2.fromOffset(78, 26),
					BackgroundColor3 = COLORS.Control,
					Text = "unban",
					TextColor3 = COLORS.Text,
					TextSize = 10,
					Font = FONTS.Semibold,
					AutoButtonColor = false,
					ZIndex = 39,
				}, item)
				addCorner(unban, 5)
				addStroke(unban, COLORS.Line, 0.2)
				connect(unban.MouseEnter, function()
					TweenService:Create(unban, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundColor3 = Color3.fromRGB(42, 42, 50),
					}):Play()
				end)
				connect(unban.MouseLeave, function()
					TweenService:Create(unban, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundColor3 = COLORS.Control,
					}):Play()
				end)
				connect(unban.MouseButton1Click, function()
					view._banned[name] = nil
					for _, target in ipairs(view._logs) do
						if target.name == name and target.row.Parent then
							target.row.Visible = matchesSearch(target)
						end
					end
					view:RefreshBanned()
				end)
			end
			bannedCountLabel.Text = tostring(bannedCount) .. " blocked"
			bannedList.Visible = bannedCount > 0
			bannedEmpty.Visible = bannedCount == 0
		end

		function view:Ban(data)
			if not data or not data.Name then
				return
			end

			local name = displayName(data.Name)
			view._banned[name] = true
			for _, target in ipairs(view._logs) do
				if target.name == name and target.row.Parent then
					target.row.Visible = false
				end
			end

			if view._selected and view._selected.name == name then
				view._selected = nil
				view:SetCode("-- remote is banned")
			end

			contextMenu.Visible = false
			view:RefreshBanned()
		end

		function view:OpenBanned()
			view:RefreshBanned()
			if bannedPanel.Visible then
				hideBanned()
			else
				showBanned()
			end
			contextMenu.Visible = false
		end

		local function closeContext()
			if not contextMenu.Visible then
				view._contextTarget = nil
				return
			end
			contextMenu.Visible = false
			view._contextTarget = nil
		end
		local function openContext(position)
			filterPopup.Visible = false
			for _, target in ipairs(view._logs) do
				if view._selected ~= target and target.row.Parent then
					TweenService:Create(target.row, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundColor3 = Color3.fromRGB(17, 17, 21),
					}):Play()
				end
			end
			contextMenu.Position = position
			contextMenu.Visible = true
		end
		connect(UserInputService.InputBegan, function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 or not contextMenu.Visible then
				return
			end

			local position = input.Position
			local topLeft = contextMenu.AbsolutePosition
			local bottomRight = topLeft + contextMenu.AbsoluteSize
			if position.X < topLeft.X or position.X > bottomRight.X
				or position.Y < topLeft.Y or position.Y > bottomRight.Y then
				closeContext()
			end
		end)
		connect(UserInputService.InputBegan, function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 or not filterPopup.Visible then
				return
			end

			local position = input.Position
			local popupTopLeft = filterPopup.AbsolutePosition
			local popupBottomRight = popupTopLeft + filterPopup.AbsoluteSize
			local buttonTopLeft = filterButton.AbsolutePosition
			local buttonBottomRight = buttonTopLeft + filterButton.AbsoluteSize
			local insidePopup = position.X >= popupTopLeft.X and position.X <= popupBottomRight.X
				and position.Y >= popupTopLeft.Y and position.Y <= popupBottomRight.Y
			local insideButton = position.X >= buttonTopLeft.X and position.X <= buttonBottomRight.X
				and position.Y >= buttonTopLeft.Y and position.Y <= buttonBottomRight.Y
			if not insidePopup and not insideButton then
				filterPopup.Visible = false
			end
		end)

		local function contextAction(name, callback, accentColor)
			local button = create("TextButton", {
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundColor3 = Color3.fromRGB(27, 27, 34),
				Text = "",
				AutoButtonColor = false,
				ZIndex = 42,
			}, contextList)
			addCorner(button, 6)
			addStroke(button, COLORS.Line, 0.62)
			create("Frame", {
				Position = UDim2.fromOffset(7, 9),
				Size = UDim2.fromOffset(2, 16),
				BackgroundColor3 = accentColor or COLORS.Accent,
				BorderSizePixel = 0,
				ZIndex = 43,
			}, button)
			addText(button, name, 10, COLORS.Text, {
				Position = UDim2.fromOffset(17, 0),
				Size = UDim2.new(1, -25, 1, 0),
				TextYAlignment = Enum.TextYAlignment.Center,
				Font = FONTS.Medium,
				ZIndex = 43,
			})
			connect(button.MouseEnter, function()
				TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundColor3 = Color3.fromRGB(48, 48, 58),
				}):Play()
			end)
			connect(button.MouseLeave, function()
				TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundColor3 = Color3.fromRGB(27, 27, 34),
				}):Play()
			end)
			connect(button.MouseButton1Click, function()
				local target = view._contextTarget
				closeContext()
				if target then
					callback(target.data, target.row)
				end
			end)
		end

		contextAction("Run preview", function(data)
			view:SetCode(data.Code or "-- no selected call")
		end, COLORS.Accent)
		contextAction("Copy code", function(data)
			if type(setclipboard) == "function" then
				pcall(setclipboard, tostring(data.Code or ""))
			end
			view:SetCode(data.Code or "-- no selected call")
		end, COLORS.Function)
		contextAction("Ban remote", function(data)
			view:Ban(data)
		end, Color3.fromRGB(225, 86, 92))

		function view:AddLog(entry)
			local data = type(entry) == "table" and entry or {Name = tostring(entry)}
			local remoteName = displayName(data.Name)
			local remoteType = string.lower(tostring(data.Type or "event"))
			local row = create("TextButton", {
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundColor3 = Color3.fromRGB(17, 17, 21),
				Text = "",
				AutoButtonColor = false,
				ZIndex = 7,
			}, logList)
			addCorner(row, 4)
			addStroke(row, COLORS.Line, 0.35)
			create("Frame", {
				Size = UDim2.new(0, 4, 1, 0),
				BackgroundColor3 = data.Color or typeColor(remoteType),
				BorderSizePixel = 0,
				ZIndex = 8,
			}, row)
			local selectionStroke = addStroke(row, data.Color or typeColor(remoteType), 1)
			selectionStroke.Thickness = 1.25
			addText(row, remoteName, 12, COLORS.Text, {
				Position = UDim2.fromOffset(14, 0),
				Size = UDim2.new(1, -72, 1, 0),
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Font = FONTS.Medium,
				ZIndex = 8,
			})
			local target = {data = data, name = remoteName, row = row, selectionStroke = selectionStroke}
			connect(row.MouseEnter, function()
				if not contextMenu.Visible and not filterPopup.Visible and view._selected ~= target then
					TweenService:Create(row, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundColor3 = Color3.fromRGB(28, 28, 35),
					}):Play()
				end
			end)
			connect(row.MouseLeave, function()
				if not contextMenu.Visible and not filterPopup.Visible and view._selected ~= target then
					TweenService:Create(row, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundColor3 = Color3.fromRGB(17, 17, 21),
					}):Play()
				end
			end)
			connect(row.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton2 then
					view._contextTarget = target
					local rootPosition = root.AbsolutePosition
					local x = math.clamp(input.Position.X - rootPosition.X + 4, 4, math.max(root.AbsoluteSize.X - 194, 4))
					local y = math.clamp(input.Position.Y - rootPosition.Y + 4, 36, math.max(root.AbsoluteSize.Y - 132, 36))
					openContext(UDim2.fromOffset(x, y))
				end
			end)
			connect(row.MouseButton1Click, function()
				filterPopup.Visible = false
				closeContext()
				selectTarget(target)
			end)

			row.Visible = view._banned[remoteName] ~= true and matchesSearch(target)
			table.insert(view._logs, target)
			if not view._selected and row.Visible then
				selectTarget(target)
			end
			return row
		end

		function view:AddSetting(name, callback, settingOptions)
			settingOptions = settingOptions or {}
			view._settingOrder += 1
			local description = settingOptions.Description
				or SETTING_DESCRIPTIONS[tostring(name)]
				or "Configure this RemoteSpy option"
			local row = create("Frame", {
				Size = UDim2.new(1, 0, 0, 62),
				BackgroundColor3 = COLORS.Panel,
				BorderSizePixel = 0,
				LayoutOrder = view._settingOrder,
				ZIndex = 10,
			}, settingsList)
			addCorner(row, 7)
			addStroke(row, COLORS.Line, 0.48)
			addGradient(row, Color3.fromRGB(25, 25, 31), Color3.fromRGB(17, 17, 22), 90)
			addText(row, name, 11, COLORS.Text, {
				Position = UDim2.fromOffset(14, 8),
				Size = UDim2.new(1, -126, 0, 20),
				TextYAlignment = Enum.TextYAlignment.Top,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Font = FONTS.Semibold,
				ZIndex = 11,
			})
			addText(row, description, 11, COLORS.Muted, {
				Position = UDim2.fromOffset(14, 31),
				Size = UDim2.new(1, -126, 0, 18),
				TextYAlignment = Enum.TextYAlignment.Top,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Font = FONTS.Medium,
				ZIndex = 11,
			})

			if settingOptions.Type == "toggle" then
				local state = settingOptions.Default == true
				local toggle = create("TextButton", {
					Position = UDim2.new(1, -52, 0.5, -10),
					Size = UDim2.fromOffset(38, 20),
					BackgroundColor3 = COLORS.Control,
					Text = "",
					AutoButtonColor = false,
					ZIndex = 12,
				}, row)
				addCorner(toggle, 8)
				addStroke(toggle, COLORS.Line)
				local knob = create("Frame", {
					Size = UDim2.fromOffset(12, 12),
					BorderSizePixel = 0,
					ZIndex = 13,
				}, toggle)
				addCorner(knob, 6)
				local control
				local function set(value, fire)
					state = value == true
					TweenService:Create(toggle, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundColor3 = state and Color3.fromRGB(42, 42, 50) or COLORS.Control,
					}):Play()
					TweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						BackgroundColor3 = state and COLORS.Text or COLORS.Muted,
						Position = state and UDim2.new(1, -16, 0.5, -6) or UDim2.fromOffset(4, 4),
					}):Play()
					if fire then
						safeCallback(callback, state, view)
					end
				end
				control = {
					Set = function(_, value)
						set(value, true)
					end,
					Get = function()
						return state
					end,
				}
				set(state, false)
				connect(toggle.MouseButton1Click, function()
					control:Set(not state)
				end)
				table.insert(view._settings, control)
				return control
			end

			if settingOptions.Type == "keybind" then
				local keyCode = resolveKeyCode(settingOptions.Default)
				local listening = false
				local button = create("TextButton", {
					Position = UDim2.new(1, -96, 0.5, -13),
					Size = UDim2.fromOffset(84, 26),
					BackgroundColor3 = COLORS.Control,
					Text = keyCode.Name,
					TextColor3 = COLORS.Text,
					TextSize = 10,
					Font = FONTS.Semibold,
					AutoButtonColor = false,
					ZIndex = 12,
				}, row)
				addCorner(button, 4)
				addStroke(button, COLORS.Line, 0.15)
				local control
				local function refreshButton()
					button.Text = listening and "press key" or keyCode.Name
					button.TextColor3 = listening and COLORS.Text or COLORS.Text
				end
				local function setKey(value, fire)
					keyCode = resolveKeyCode(value)
					listening = false
					self._keyCapture = false
					refreshButton()
					if fire then
						safeCallback(callback, keyCode, view)
					end
				end
				connect(button.MouseEnter, function()
					TweenService:Create(button, TweenInfo.new(0.1), {
						BackgroundColor3 = Color3.fromRGB(42, 42, 50),
					}):Play()
				end)
				connect(button.MouseLeave, function()
					TweenService:Create(button, TweenInfo.new(0.12), {
						BackgroundColor3 = COLORS.Control,
					}):Play()
				end)
				connect(button.MouseButton1Click, function()
					listening = true
					self._keyCapture = true
					refreshButton()
				end)
				connect(UserInputService.InputBegan, function(input)
					if not listening or input.UserInputType ~= Enum.UserInputType.Keyboard then
						return
					end
					if input.KeyCode == Enum.KeyCode.Escape then
						listening = false
						self._keyCapture = false
						refreshButton()
						return
					end
					setKey(input.KeyCode, true)
				end)
				control = {
					Set = function(_, value)
						setKey(value, true)
					end,
					Get = function()
						return keyCode
					end,
				}
				table.insert(view._settings, control)
				return control
			end

			local button = create("TextButton", {
				Position = UDim2.new(1, -96, 0.5, -13),
				Size = UDim2.fromOffset(84, 26),
				BackgroundColor3 = COLORS.Control,
				Text = settingOptions.Value or "open",
				TextColor3 = COLORS.Text,
				TextSize = 10,
				Font = FONTS.Semibold,
				AutoButtonColor = false,
				ZIndex = 12,
			}, row)
			addCorner(button, 4)
			addStroke(button, COLORS.Line, 0.15)
			connect(button.MouseEnter, function()
				TweenService:Create(button, TweenInfo.new(0.1), {
					BackgroundColor3 = Color3.fromRGB(42, 42, 50),
				}):Play()
			end)
			connect(button.MouseLeave, function()
				TweenService:Create(button, TweenInfo.new(0.12), {
					BackgroundColor3 = COLORS.Control,
				}):Play()
			end)
			connect(button.MouseButton1Click, function()
				safeCallback(callback, view)
			end)
			return button
		end

		view.AddAction = view.AddSetting

		view:AddSetting("Toggle key", function(value)
			self:SetToggleKey(value)
		end, {
			Type = "keybind",
			Default = self._toggleKey,
			Description = "Change the key used to hide or restore RemoteSpy",
		})

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

	function self:Notify(options)
		if self._destroyed then
			return nil
		end

		local data = type(options) == "table" and options or {Text = tostring(options)}
		local notification = create("Frame", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -16, 1, -16),
			Size = UDim2.fromOffset(270, 58),
			BackgroundColor3 = COLORS.PanelRaised,
			BorderSizePixel = 0,
			ZIndex = 80,
		}, self.Gui)
		addCorner(notification, 6)
		addStroke(notification, COLORS.LineBright)
		addGradient(notification, Color3.fromRGB(43, 43, 51), Color3.fromRGB(23, 23, 29), 90)
		create("Frame", {
			Position = UDim2.fromOffset(7, 8),
			Size = UDim2.new(0, 2, 1, -16),
			BackgroundColor3 = COLORS.Accent,
			BorderSizePixel = 0,
			ZIndex = 81,
		}, notification)
		addText(notification, data.Title or "RemoteSpy", 10, COLORS.Text, {
			Position = UDim2.fromOffset(17, 8),
			Size = UDim2.new(1, -26, 0, 16),
			Font = FONTS.Bold,
			ZIndex = 81,
		})
		addText(notification, data.Text or data.Content or "", 9, COLORS.Muted, {
			Position = UDim2.fromOffset(17, 27),
			Size = UDim2.new(1, -26, 0, 22),
			TextWrapped = true,
			ZIndex = 81,
		})

		task.delay(tonumber(data.Duration) or 2.4, function()
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
