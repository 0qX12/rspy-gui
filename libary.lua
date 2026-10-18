-- Library.lua
-- RemoteSpy-only monochrome GUI library.

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

local function typeColor(remoteType)
	return string.lower(tostring(remoteType or "event")) == "function"
		and COLORS.Function
		or COLORS.Event
end

local function displayName(value)
	return tostring(value or "Remote")
end

function Library.new(config)
	config = config or {}

	local self = setmetatable({
		_connections = {},
		_dynamicConnections = {},
		_destroyed = false,
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
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, host)

	self.Window = create("Frame", {
		Size = windowSize,
		Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2),
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel = 0,
		Active = true,
		ClipsDescendants = true,
		ZIndex = 2,
	}, self.Gui)
	addCorner(self.Window, 9)
	addStroke(self.Window, COLORS.Line)
	local windowScale = create("UIScale", {Scale = 0.97}, self.Window)
	TweenService:Create(windowScale, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()

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
	addText(topBar, config.Title or "RemoteSpy", 12, COLORS.Text, {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -150, 1, 0),
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = FONTS.Bold,
		ZIndex = 6,
	})
	local closeButton = create("TextButton", {
		Position = UDim2.new(1, -27, 0, 6),
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
	addStroke(closeButton, COLORS.Line, 0.2)

	local body = create("Frame", {
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(1, 0, 1, -34),
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 3,
	}, self.Window)

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
			TextColor3 = COLORS.Text,
		}):Play()
	end)
	connect(closeButton.MouseLeave, function()
		TweenService:Create(closeButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = COLORS.Control,
			TextColor3 = COLORS.Muted,
		}):Play()
	end)
	connect(closeButton.MouseButton1Click, function()
		self:Destroy()
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
				windowStart.X.Offset + delta.X,
				windowStart.Y.Scale,
				windowStart.Y.Offset + delta.Y
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

		local leftPanel = create("Frame", {
			Size = UDim2.new(0, 230, 1, 0),
			BackgroundColor3 = Color3.fromRGB(11, 11, 14),
			BorderSizePixel = 0,
			ZIndex = 5,
		}, root)
		create("Frame", {
			Position = UDim2.new(1, -1, 0, 0),
			Size = UDim2.new(0, 1, 1, 0),
			BackgroundColor3 = COLORS.Line,
			BorderSizePixel = 0,
			ZIndex = 8,
		}, leftPanel)

		local leftHeader = create("Frame", {
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = Color3.fromRGB(11, 11, 14),
			BorderSizePixel = 0,
			ZIndex = 6,
		}, leftPanel)
		addText(leftHeader, "remote log", 10, COLORS.Text, {
			Position = UDim2.fromOffset(11, 0),
			Size = UDim2.new(1, -80, 1, 0),
			TextYAlignment = Enum.TextYAlignment.Center,
			Font = FONTS.Bold,
			ZIndex = 7,
		})
		local countLabel = addText(leftHeader, "0", 9, COLORS.Muted, {
			Position = UDim2.new(1, -54, 0, 0),
			Size = UDim2.fromOffset(40, 34),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Center,
			Font = FONTS.Medium,
			ZIndex = 7,
		})
		create("Frame", {
			Position = UDim2.new(0, 0, 1, -1),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = COLORS.Line,
			BorderSizePixel = 0,
			ZIndex = 7,
		}, leftHeader)

		local logList = create("ScrollingFrame", {
			Position = UDim2.fromOffset(8, 42),
			Size = UDim2.new(1, -16, 1, -50),
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

		local detailPanel = create("Frame", {
			Position = UDim2.fromOffset(230, 0),
			Size = UDim2.new(1, -230, 1, 0),
			BackgroundColor3 = COLORS.Background,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 5,
		}, root)

		local codePanel = create("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(18, 18, 23),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 6,
		}, detailPanel)
		addStroke(codePanel, COLORS.Line, 0.25)
		local codeLabel = addText(codePanel, options.Code or "-- no remote selected", 12, COLORS.Text, {
			Position = UDim2.fromOffset(13, 14),
			Size = UDim2.new(1, -26, 1, -28),
			Font = FONTS.Code,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = false,
			ZIndex = 7,
		})

		local settingsButton = create("TextButton", {
			Position = UDim2.new(0, 9, 1, -36),
			Size = UDim2.new(1, -19, 0, 27),
			BackgroundColor3 = COLORS.Control,
			Text = "settings",
			TextColor3 = COLORS.Muted,
			TextSize = 9,
			Font = FONTS.Semibold,
			AutoButtonColor = false,
			ZIndex = 12,
		}, leftPanel)
		addCorner(settingsButton, 5)
		addStroke(settingsButton, COLORS.Line, 0.15)

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
		addStroke(settingsPanel, COLORS.Line, 0.1)
		addText(settingsPanel, "settings", 10, COLORS.Text, {
			Position = UDim2.fromOffset(13, 7),
			Size = UDim2.new(1, -26, 0, 22),
			Font = FONTS.Bold,
			ZIndex = 9,
		})
		local settingsClose = create("TextButton", {
			Position = UDim2.new(1, -34, 0, 6),
			Size = UDim2.fromOffset(22, 22),
			BackgroundColor3 = COLORS.Control,
			Text = "×",
			TextColor3 = COLORS.Muted,
			TextSize = 13,
			Font = FONTS.Medium,
			AutoButtonColor = false,
			ZIndex = 10,
		}, settingsPanel)
		addCorner(settingsClose, 4)
		connect(settingsClose.MouseEnter, function()
			TweenService:Create(settingsClose, TweenInfo.new(0.12), {
				BackgroundColor3 = COLORS.PanelRaised,
				TextColor3 = COLORS.Text,
			}):Play()
		end)
		connect(settingsClose.MouseLeave, function()
			TweenService:Create(settingsClose, TweenInfo.new(0.12), {
				BackgroundColor3 = COLORS.Control,
				TextColor3 = COLORS.Muted,
			}):Play()
		end)
		local settingsScale = create("UIScale", {Scale = 0.985}, settingsPanel)
		local settingsList = create("ScrollingFrame", {
			Position = UDim2.fromOffset(9, 36),
			Size = UDim2.new(1, -18, 1, -43),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = COLORS.LineBright,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 9,
		}, settingsPanel)
		create("UIListLayout", {
			Padding = UDim.new(0, 5),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, settingsList)
		local function showSettings()
			settingsPanel.Visible = true
			settingsButton.Visible = false
			settingsPanel.BackgroundTransparency = 1
			settingsScale.Scale = 0.985
			TweenService:Create(settingsPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0,
			}):Play()
			TweenService:Create(settingsScale, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Scale = 1,
			}):Play()
		end

		local function hideSettings()
			local fade = TweenService:Create(settingsPanel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 1,
			})
			TweenService:Create(settingsScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Scale = 0.985,
			}):Play()
			fade.Completed:Connect(function()
				settingsPanel.Visible = false
				settingsButton.Visible = true
			end)
			fade:Play()
		end

		connect(settingsButton.MouseEnter, function()
			TweenService:Create(settingsButton, TweenInfo.new(0.12), {
				BackgroundColor3 = COLORS.PanelRaised,
				TextColor3 = COLORS.Text,
			}):Play()
		end)
		connect(settingsButton.MouseLeave, function()
			TweenService:Create(settingsButton, TweenInfo.new(0.12), {
				BackgroundColor3 = COLORS.Control,
				TextColor3 = COLORS.Muted,
			}):Play()
		end)
		connect(settingsButton.MouseButton1Click, showSettings)
		connect(settingsClose.MouseButton1Click, hideSettings)

		local contextMenu = create("Frame", {
			Size = UDim2.fromOffset(150, 112),
			BackgroundColor3 = COLORS.PanelRaised,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 40,
		}, root)
		addCorner(contextMenu, 6)
		addStroke(contextMenu, COLORS.LineBright, 0.1)
		local contextScale = create("UIScale", {Scale = 0.96}, contextMenu)
		local contextList = create("Frame", {
			Position = UDim2.fromOffset(5, 5),
			Size = UDim2.new(1, -10, 1, -10),
			BackgroundTransparency = 1,
			ZIndex = 41,
		}, contextMenu)
		create("UIListLayout", {Padding = UDim.new(0, 3)}, contextList)

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
		addStroke(bannedPanel, COLORS.LineBright, 0.1)
		addText(bannedPanel, "banned remotes", 10, COLORS.Text, {
			Position = UDim2.fromOffset(18, 10),
			Size = UDim2.new(1, -70, 0, 24),
			Font = FONTS.Bold,
			ZIndex = 31,
		})
		local bannedClose = create("TextButton", {
			Position = UDim2.new(1, -38, 0, 7),
			Size = UDim2.fromOffset(24, 24),
			BackgroundColor3 = COLORS.Control,
			Text = "×",
			TextColor3 = COLORS.Muted,
			TextSize = 13,
			Font = FONTS.Medium,
			AutoButtonColor = false,
			ZIndex = 32,
		}, bannedPanel)
		addCorner(bannedClose, 4)
		connect(bannedClose.MouseEnter, function()
			TweenService:Create(bannedClose, TweenInfo.new(0.12), {
				BackgroundColor3 = COLORS.PanelRaised,
				TextColor3 = COLORS.Text,
			}):Play()
		end)
		connect(bannedClose.MouseLeave, function()
			TweenService:Create(bannedClose, TweenInfo.new(0.12), {
				BackgroundColor3 = COLORS.Control,
				TextColor3 = COLORS.Muted,
			}):Play()
		end)
		local bannedList = create("ScrollingFrame", {
			Position = UDim2.fromOffset(18, 52),
			Size = UDim2.new(1, -36, 1, -70),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 31,
		}, bannedPanel)
		create("UIListLayout", {Padding = UDim.new(0, 4)}, bannedList)
		local bannedScale = create("UIScale", {Scale = 0.985}, bannedPanel)
		local function showBanned()
			settingsPanel.Visible = false
			settingsButton.Visible = false
			bannedPanel.Visible = true
			bannedPanel.BackgroundTransparency = 1
			bannedScale.Scale = 0.985
			TweenService:Create(bannedPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0,
			}):Play()
			TweenService:Create(bannedScale, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Scale = 1,
			}):Play()
		end
		local function hideBanned()
			local fade = TweenService:Create(bannedPanel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 1,
			})
			TweenService:Create(bannedScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Scale = 0.985,
			}):Play()
			fade.Completed:Connect(function()
				bannedPanel.Visible = false
				settingsButton.Visible = true
			end)
			fade:Play()
		end
		connect(bannedClose.MouseButton1Click, function()
			hideBanned()
		end)

		local function updateCount()
			local visibleCount = 0
			for _, target in ipairs(view._logs) do
				if target.row.Parent and target.row.Visible then
					visibleCount += 1
				end
			end
			countLabel.Text = tostring(visibleCount)
		end

		function view:SetCode(code)
			codeLabel.Text = tostring(code or "-- no remote selected")
		end

		local function selectTarget(target)
			if view._selected and view._selected.row.Parent then
				TweenService:Create(view._selected.row, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundColor3 = Color3.fromRGB(17, 17, 21),
				}):Play()
				view._selected.selectionStroke.Transparency = 1
			end

			view._selected = target
		TweenService:Create(target.row, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			BackgroundColor3 = Color3.fromRGB(38, 38, 46),
		}):Play()
		target.selectionStroke.Transparency = 0.2
			view:SetCode(target.data.Code or "-- no selected call", target.name)
			safeCallback(target.data.Callback, target.data, view)
		end

		function view:RefreshBanned()
			for _, item in ipairs(bannedList:GetChildren()) do
				if item:IsA("GuiObject") then
					item:Destroy()
				end
			end

			for name in pairs(view._banned) do
				local item = create("TextButton", {
					Size = UDim2.new(1, 0, 0, 28),
					BackgroundColor3 = COLORS.Control,
					Text = "  " .. tostring(name) .. "                         unban",
					TextColor3 = COLORS.Text,
					TextSize = 9,
					Font = FONTS.Medium,
					TextXAlignment = Enum.TextXAlignment.Left,
					AutoButtonColor = false,
					ZIndex = 37,
				}, bannedList)
				addCorner(item, 4)
				connect(item.MouseButton1Click, function()
					view._banned[name] = nil
					for _, target in ipairs(view._logs) do
						if target.name == name and target.row.Parent then
							target.row.Visible = true
						end
					end
					view:RefreshBanned()
					updateCount()
				end)
			end
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
				view:SetCode("-- remote is banned", "banned")
			end

			contextMenu.Visible = false
			view:RefreshBanned()
			updateCount()
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

			local fade = TweenService:Create(contextScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Scale = 0.96,
			})
			fade.Completed:Connect(function()
				contextMenu.Visible = false
				view._contextTarget = nil
			end)
			fade:Play()
		end
		local function openContext(position)
			contextMenu.Position = position
			contextMenu.Visible = true
			contextScale.Scale = 0.96
			TweenService:Create(contextScale, TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Scale = 1,
			}):Play()
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
				ZIndex = 42,
			}, contextList)
			addCorner(button, 4)
			connect(button.MouseEnter, function()
				TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundColor3 = Color3.fromRGB(42, 42, 50),
				}):Play()
			end)
			connect(button.MouseLeave, function()
				TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundColor3 = COLORS.Control,
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
			view:SetCode(data.Code or "-- no selected call", "preview only")
		end)
		contextAction("Copy code", function(data)
			if type(setclipboard) == "function" then
				pcall(setclipboard, tostring(data.Code or ""))
			end
			view:SetCode(data.Code or "-- no selected call", "copied")
		end)
		contextAction("Ban remote", function(data)
			view:Ban(data)
		end)

		function view:AddLog(entry)
			local data = type(entry) == "table" and entry or {Name = tostring(entry)}
			local remoteName = displayName(data.Name)
			local remoteType = string.lower(tostring(data.Type or "event"))
			local row = create("TextButton", {
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundColor3 = Color3.fromRGB(17, 17, 21),
				Text = "",
				AutoButtonColor = false,
				ZIndex = 7,
			}, logList)
			addCorner(row, 4)
			addStroke(row, COLORS.Line, 0.35)
			create("Frame", {
				Size = UDim2.new(0, 3, 1, 0),
				BackgroundColor3 = data.Color or typeColor(remoteType),
				BorderSizePixel = 0,
				ZIndex = 8,
			}, row)
			local selectionStroke = addStroke(row, data.Color or typeColor(remoteType), 1)
			addText(row, remoteName, 10, COLORS.Text, {
				Position = UDim2.fromOffset(12, 0),
				Size = UDim2.new(1, -72, 1, 0),
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Font = FONTS.Medium,
				ZIndex = 8,
			})
			local target = {data = data, name = remoteName, row = row, selectionStroke = selectionStroke}
			connect(row.MouseEnter, function()
				if view._selected ~= target then
					TweenService:Create(row, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundColor3 = Color3.fromRGB(28, 28, 35),
					}):Play()
				end
			end)
			connect(row.MouseLeave, function()
				if view._selected ~= target then
					TweenService:Create(row, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundColor3 = Color3.fromRGB(17, 17, 21),
					}):Play()
				end
			end)
			connect(row.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton2 then
					view._contextTarget = target
					local rootPosition = root.AbsolutePosition
					local x = math.clamp(input.Position.X - rootPosition.X + 4, 4, math.max(root.AbsoluteSize.X - 154, 4))
					local y = math.clamp(input.Position.Y - rootPosition.Y + 4, 36, math.max(root.AbsoluteSize.Y - 118, 36))
					openContext(UDim2.fromOffset(x, y))
				end
			end)
			connect(row.MouseButton1Click, function()
				closeContext()
				selectTarget(target)
			end)

			row.Visible = view._banned[remoteName] ~= true
			table.insert(view._logs, target)
			if not view._selected and row.Visible then
				selectTarget(target)
			end
			updateCount()
			return row
		end

		function view:AddSetting(name, callback, settingOptions)
			settingOptions = settingOptions or {}
			local row = create("Frame", {
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundColor3 = COLORS.Panel,
				BorderSizePixel = 0,
				ZIndex = 10,
			}, settingsList)
			addCorner(row, 4)
			addStroke(row, COLORS.Line, 0.4)
			addText(row, name, 10, COLORS.Muted, {
				Position = UDim2.fromOffset(9, 0),
				Size = UDim2.new(1, -115, 1, 0),
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Font = FONTS.Medium,
				ZIndex = 11,
			})

			if settingOptions.Type == "toggle" then
				local state = settingOptions.Default == true
				local toggle = create("TextButton", {
					Position = UDim2.new(1, -42, 0.5, -9),
					Size = UDim2.fromOffset(34, 18),
					BackgroundColor3 = COLORS.Control,
					Text = "",
					AutoButtonColor = false,
					ZIndex = 12,
				}, row)
				addCorner(toggle, 6)
				addStroke(toggle, COLORS.Line)
				local knob = create("Frame", {
					Size = UDim2.fromOffset(10, 10),
					BorderSizePixel = 0,
					ZIndex = 13,
				}, toggle)
				addCorner(knob, 4)
				local control
				local function set(value, fire)
					state = value == true
					TweenService:Create(toggle, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundColor3 = state and Color3.fromRGB(42, 42, 50) or COLORS.Control,
					}):Play()
					TweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						BackgroundColor3 = state and COLORS.Text or COLORS.Muted,
						Position = state and UDim2.new(1, -14, 0.5, -5) or UDim2.fromOffset(3, 4),
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

			local button = create("TextButton", {
				Position = UDim2.new(1, -78, 0.5, -10),
				Size = UDim2.fromOffset(68, 20),
				BackgroundColor3 = COLORS.Control,
				Text = settingOptions.Value or "open",
				TextColor3 = COLORS.Text,
				TextSize = 9,
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

		function view:Clear()
			for _, target in ipairs(view._logs) do
				if target.row then
					target.row:Destroy()
				end
			end
			table.clear(view._logs)
			view._selected = nil
			view:SetCode("-- no remote selected", "preview")
			updateCount()
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
