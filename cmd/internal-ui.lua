--[[
	Internal GUI made for Cmd
]]

local Genv = (getgenv) or function() return _G end
local Settings = {
	Keybind = Enum.KeyCode.LeftAlt
}

--// Connections
local GetService = game.GetService
local Connect = game.Loaded.Connect
local Wait = game.Loaded.Wait
local Clone = game.Clone 
local Destroy = game.Destroy 

if (not game:IsLoaded()) then
	local Loaded = game.Loaded
	Loaded.Wait(Loaded);
end

--// Services
local LogService = game:GetService("LogService");
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");
local InputService = game:GetService("UserInputService");
local InsertService = game:GetService("InsertService");
local Players = game:GetService("Players");
local Http = game:GetService("HttpService");

local File = isfile and isfolder and writefile and readfile
local Player = {
	Mouse = Players.LocalPlayer:GetMouse()
}

if Genv().Internal then
	Genv().Internal:Destroy() 
end

if File then
	if File then
		local Folders = { "LateInternal", "LateInternal/Scripts" }

		for Index, Check in next, Folders do
			if not isfolder(Check) then
				makefolder(Check);
			end
		end
	end
end
--// UI
local Main

if (RunService:IsStudio()) then
	Main = script.Parent:WaitForChild("Background");
else
	Main = InsertService:LoadLocalAsset("rbxassetid://18548169402"):WaitForChild("Background");
end

-- Executor
local Executor = Main["Run"];
local RunTab = Executor["Main"];
local RunButtons = RunTab["Bottom"]["Buttons"];
local RunScroll = RunTab["ScrollingFrame"]
local RunInput = RunScroll["TextBox"];
local Syntax = RunScroll["Syntax"];

-- Console
local Console = Main["Console"];
local ConsoleTab = Console["Main"];
local ConsoleButtons = ConsoleTab["Buttons"];
local ConsoleScroll = ConsoleTab["ScrollingFrame"];

-- ScriptBlox
local Script = Main["Script"];
local ScriptTab = Script["Main"];
local Search = ScriptTab["TextBox"];
local ScriptScroll = ScriptTab["ScrollingFrame"];

Genv().Internal = Main.Parent
Main.Visible = false
xpcall(function() 
	Main.Parent.Parent = game.CoreGui
end, function() 
	Main.Parent.Parent = Players.LocalPlayer.PlayerGui
end)

--// Functions
local Type = nil
local Animations = {}
local Resizing = { 
	Top = { X = Vector2.new(0, 0),    Y = Vector2.new(0, -1)};
	Bottom = { X = Vector2.new(0, 0),    Y = Vector2.new(0, 1)};
	Left = { X = Vector2.new(-1, 0),   Y = Vector2.new(0, 0)};
	Right = { X = Vector2.new(1, 0),    Y = Vector2.new(0, 0)};
	TopLeft = { X = Vector2.new(-1, 0),   Y = Vector2.new(0, -1)};
	TopRight = { X = Vector2.new(1, 0),    Y = Vector2.new(0, -1)};
	BottomLeft = { X = Vector2.new(-1, 0),   Y = Vector2.new(0, 1)};
	BottomRight = { X = Vector2.new(1, 0),    Y = Vector2.new(0, 1)};
}

local Tween = function(Object : Instance, Speed : number, Properties : {},  Info : { EasingStyle: Enum?, EasingDirection: Enum? })
	local Style, Direction

	if Info then
		Style, Direction = Info["EasingStyle"], Info["EasingDirection"]
	else
		Style, Direction = Enum.EasingStyle.Sine, Enum.EasingDirection.Out
	end

	return TweenService:Create(Object, TweenInfo.new(Speed, Style, Direction), Properties):Play()
end

local SetProperty = function(Object: Instance, Properties: {})
	for Index, Property in next, Properties do
		Object[Index] = (Property);
	end

	return Object
end

local Multiply = function(Value, Amount)
	local New = {
		Value.X.Scale * Amount;
		Value.X.Offset * Amount;
		Value.Y.Scale * Amount;
		Value.Y.Offset * Amount;
	}

	return UDim2.new(unpack(New))
end

--// Animations [Window]
function Animations:Open(Window: Instance, Transparency: number)
	local Original = (Window.Size)
	local Multiplied = Multiply(Original, 1.5)

	SetProperty(Window, {
		Size = Multiplied,
		GroupTransparency = 1,
		Visible = true,
	})

	Tween(Window, .25, {
		Size = Original,
		GroupTransparency = Transparency or 0,
	})
end

function Animations:Close(Window: Instance)
	local Original = Window.Size
	local Multiplied = Multiply(Original, 1.5)

	SetProperty(Window, {
		Size = Original,
	})

	Tween(Window, .25, {
		Size = Multiplied,
		GroupTransparency = 1,
	})

	task.wait(.25)
	Window.Size = Original
	Window.Visible = false
end

local Resizeable = function(Tab, Minimum, Maximum)
	task.spawn(function()
		local MousePos, Size, UIPos = nil, nil, nil

		if Tab and Tab:FindFirstChild("Resize") then
			local Positions = Tab:FindFirstChild("Resize")

			for Index, Types in next, Positions:GetChildren() do
				Connect(Types.InputBegan, function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then
						Type = Types
						MousePos = Vector2.new(Player.Mouse.X, Player.Mouse.Y)
						Size = Tab.AbsoluteSize
						UIPos = Tab.Position
					end
				end)

				Connect(Types.InputEnded, function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then
						Type = nil
					end
				end)
			end
		end

		local Resize = function(Delta)
			if Type and MousePos and Size and UIPos and Tab:FindFirstChild("Resize")[Type.Name] == Type then
				local Mode = Resizing[Type.Name]
				local NewSize = Vector2.new(Size.X + Delta.X * Mode.X.X, Size.Y + Delta.Y * Mode.Y.Y)
				NewSize = Vector2.new(math.clamp(NewSize.X, Minimum.X, Maximum.X), math.clamp(NewSize.Y, Minimum.Y, Maximum.Y))

				local AnchorOffset = Vector2.new(Tab.AnchorPoint.X * Size.X, Tab.AnchorPoint.Y * Size.Y)
				local NewAnchorOffset = Vector2.new(Tab.AnchorPoint.X * NewSize.X, Tab.AnchorPoint.Y * NewSize.Y)
				local DeltaAnchorOffset = NewAnchorOffset - AnchorOffset

				Tab.Size = UDim2.new(0, NewSize.X, 0, NewSize.Y)

				local NewPosition = UDim2.new(
					UIPos.X.Scale, 
					UIPos.X.Offset + DeltaAnchorOffset.X * Mode.X.X,
					UIPos.Y.Scale,
					UIPos.Y.Offset + DeltaAnchorOffset.Y * Mode.Y.Y
				)
				Tab.Position = NewPosition
			end
		end

		Connect(Player.Mouse.Move, function()
			if Type then
				pcall(function()
					Resize(Vector2.new(Player.Mouse.X, Player.Mouse.Y) - MousePos)
				end)
			end
		end)
	end)
end

local Drag = function(Canvas)
	if Canvas then
		local Dragging;
		local DragInput;
		local Start;
		local StartPosition;

		local function Update(input)
			local delta = input.Position - Start
			Canvas.Position = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + delta.Y)
		end

		Connect(Canvas.InputBegan, function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch and not Type then
				Dragging = true
				Start = Input.Position
				StartPosition = Canvas.Position

				Connect(Input.Changed, function()
					if Input.UserInputState == Enum.UserInputState.End then
						Dragging = false
					end
				end)
			end
		end)

		Connect(Canvas.InputChanged, function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch and not Type then
				DragInput = Input
			end
		end)

		Connect(InputService.InputChanged, function(Input)
			if Input == DragInput and Dragging and not Type then
				Update(Input)
			end
		end)
	end
end

local GetExample = function(Window: CanvasGroup, Name: string) 
	for Index, Example in next, Window:GetDescendants() do
		if Example.Name:lower():find("example") and Example.Name == Name then
			return Example
		end
	end
end

local SetupButton = function(Button: TextButton, Path, Code)
	Connect(Button.MouseButton1Click, function() 
		loadstring(Code)();
	end)

	Connect(Button.MouseButton2Click, function() 
		for Index, Unclosed in next, Main:GetChildren() do
			if Unclosed.Name == "Popup" then 
				Unclosed:Destroy() 
			end 
		end

		local Popup = Clone(Main["Frame"]);

		Popup.Name = "Popup"
		Popup.Parent = Main
		Popup.Visible = true
		Popup.Position = UDim2.fromOffset(Player.Mouse.X, Player.Mouse.Y)

		for Index, Option in next, Popup:GetChildren() do
			if Option:IsA("TextButton") then
				local Type = (Option.Name)

				Connect(Option.MouseButton1Click, function()
					if Type == "Execute" then
						task.spawn(function()
							loadstring(Code)();
						end)
					elseif Type == "Paste" then
						RunInput.Text = Code 
					elseif Type == "Delete" then
						delfile(Path);
						Destroy(Button)
					end

					Destroy(Popup)
				end)
			end
		end
	end)
end
--// Syntax Highlighter, made by @NiceBuild1

local Highlighter = {}
local Keywords = {
	lua = {
		"and", "break", "or", "else", "elseif", "if", "then", "until", "repeat", "while", "do", "for", "in", "end",
		"local", "return", "function", "export"
	},
	rbx = {
		"game", "workspace", "script", "math", "string", "table", "task", "wait", "select", "next", "Enum",
		"error", "warn", "tick", "assert", "shared", "loadstring", "tonumber", "tostring", "type",
		"typeof", "unpack", "print", "Instance", "CFrame", "Vector3", "Vector2", "Color3", "UDim", "UDim2", "Ray", "BrickColor",
		"OverlapParams", "RaycastParams", "Axes", "Random", "Region3", "Rect", "TweenInfo",
		"collectgarbage", "not", "utf8", "pcall", "xpcall", "_G", "setmetatable", "getmetatable", "os", "pairs", "ipairs"
	},
	operators = {
		"#", "+", "-", "*", "%", "/", "^", "=", "~", "=", "<", ">", ",", ".", "(", ")", "{", "}", "[", "]", ";", ":"
	}
}

local Normal = function(str) 
	return str:gsub("LateInternal/Scripts", ""):gsub("/", "")
end

local Colors = {
	numbers = Color3.fromRGB(255, 198, 0),
	boolean = Color3.fromRGB(214, 128, 23),
	operator = Color3.fromRGB(232, 210, 40),
	lua = Color3.fromRGB(160, 87, 248),
	rbx = Color3.fromRGB(146, 180, 253),
	str = Color3.fromRGB(108, 241, 128),
	comment = Color3.fromRGB(103, 110, 149),
	null = Color3.fromRGB(79, 79, 79),
	call = Color3.fromRGB(130, 170, 255),
	self_call = Color3.fromRGB(227, 201, 141),
	local_color = Color3.fromRGB(199, 146, 234),
	function_color = Color3.fromRGB(241, 122, 124),
	self_color = Color3.fromRGB(146, 134, 234),
	local_property = Color3.fromRGB(129, 222, 255),
}

local function createKeywordSet(Keywords)
	local keywordSet = {}
	for _, keyword in ipairs(Keywords) do
		keywordSet[keyword] = true
	end
	return keywordSet
end

local luaSet = createKeywordSet(Keywords.lua)
local rbxSet = createKeywordSet(Keywords.rbx)
local operatorsSet = createKeywordSet(Keywords.operators)

local function getHighlight(tokens, index)
	local token = tokens[index]

	if Colors[token .. "_color"] then
		return Colors[token .. "_color"]
	end

	if tonumber(token) then
		return Colors.numbers
	elseif token == "nil" then
		return Colors.null
	elseif token:sub(1, 2) == "--" then
		return Colors.comment
	elseif operatorsSet[token] then
		return Colors.operator
	elseif luaSet[token] then
		return Colors.rbx
	elseif rbxSet[token] then
		return Colors.lua
	elseif token:sub(1, 1) == "\"" or token:sub(1, 1) == "\'" then
		return Colors.str
	elseif token == "true" or token == "false" then
		return Colors.boolean
	end

	if tokens[index + 1] == "(" then
		if tokens[index - 1] == ":" then
			return Colors.self_call
		end

		return Colors.call
	end

	if tokens[index - 1] == "." then
		if tokens[index - 2] == "Enum" then
			return Colors.rbx
		end

		return Colors.local_property
	end
end

function Highlighter.Run(Source: string)
	local tokens = {}
	local currentToken = ""

	local inString = false
	local inComment = false
	local commentPersist = false

	for i = 1, #Source do
		local character = Source:sub(i, i)

		if inComment then
			if character == "\n" and not commentPersist then
				table.insert(tokens, currentToken)
				table.insert(tokens, character)
				currentToken = ""

				inComment = false
			elseif Source:sub(i - 1, i) == "]]" and commentPersist then
				currentToken ..= "]"

				table.insert(tokens, currentToken)
				currentToken = ""

				inComment = false
				commentPersist = false
			else
				currentToken = currentToken .. character
			end
		elseif inString then
			if character == inString and Source:sub(i-1, i-1) ~= "\\" or character == "\n" then
				currentToken = currentToken .. character
				inString = false
			else
				currentToken = currentToken .. character
			end
		else
			if Source:sub(i, i + 1) == "--" then
				table.insert(tokens, currentToken)
				currentToken = "-"
				inComment = true
				commentPersist = Source:sub(i + 2, i + 3) == "[["
			elseif character == "\"" or character == "\'" then
				table.insert(tokens, currentToken)
				currentToken = character
				inString = character
			elseif operatorsSet[character] then
				table.insert(tokens, currentToken)
				table.insert(tokens, character)
				currentToken = ""
			elseif character:match("[%w_]") then
				currentToken = currentToken .. character
			else
				table.insert(tokens, currentToken)
				table.insert(tokens, character)
				currentToken = ""
			end
		end
	end

	table.insert(tokens, currentToken)

	local highlighted = {}

	for i, token in ipairs(tokens) do
		local highlight = getHighlight(tokens, i)

		if highlight then
			local syntax = string.format("<font color = \"#%s\">%s</font>", highlight:ToHex(), token:gsub("<", "&lt;"):gsub(">", "&gt;"))

			table.insert(highlighted, syntax)
		else
			table.insert(highlighted, token)
		end
	end

	return table.concat(highlighted)
end

--// Main  
local Order = 0

Drag(Console);  Resizeable(Console, Vector2.new(341, 228), Vector2.new(9e9, 9e9))
Drag(Executor); Resizeable(Executor, Vector2.new(341, 228), Vector2.new(9e9, 9e9))
Drag(Script);  Resizeable(Script, Vector2.new(341, 228), Vector2.new(9e9, 9e9))
Search.Text = ""

Connect(RunButtons["Execute"].MouseButton1Click, function() 
	loadstring(RunInput.Text)();
end)

Connect(RunButtons["Clear"].MouseButton1Click, function() 
	RunInput.Text = ""
end)

Connect(RunButtons["Save"].MouseButton1Click, function() 
	local TextBox = RunButtons["TextBox"]
	TextBox.ZIndex = 100
	TextBox.Visible = true

	Wait(TextBox.FocusLost);
	local Format = string.format("LateInternal/Scripts/%s.lua", TextBox.Text)
	local Code = RunInput.Text 
	local Button = Clone(GetExample(Executor, "ButtonExample"));
	local Name = (not isfile(Format) and Format) or string.format("LateInternal/Scripts/Unnamed-%s.lua", tostring(math.random(1, 1000)))

	writefile(Name, RunInput.Text)
	TextBox.Visible = false
	Button.Text = Normal(Name)
	Button.Visible = true
	Button.Parent = Executor["Workspace"]["ScrollingFrame"]

	SetupButton(Button, Name, Code)
end)

Connect(ConsoleButtons["Clear"].MouseButton1Click, function() 
	for Index, Output in next, ConsoleScroll:GetChildren() do
		if Output:IsA("TextLabel") then
			Output:Destroy()
		end
	end
end)

Connect(InputService.InputBegan, function(Input, Processed) 
	if (Input.KeyCode == Settings.Keybind) and not Processed then
		Main.Visible = not Main.Visible
	end
end)

Connect(RunInput:GetPropertyChangedSignal("Text"), function() 
	Syntax.Text = Highlighter.Run(RunInput.Text)
end)

Connect(Search.FocusLost, function() 
	for Index, Result in next, ScriptScroll:GetChildren() do
		if Result:IsA("TextButton") then
			Result:Destroy()
		end
	end

	local Scripts = Http:JSONDecode(game:HttpGet(string.format("https://scriptblox.com/api/script/search?q=%s&max=200&mode=free", Search.Text or "a")))
	for Index, Post in next, Scripts.result.scripts do
		local Button = Clone(GetExample(Script, "ScriptExample"))
		local Buttons = Button.Buttons
		local Title, Name, Code = Post.title, Post.game.name, Post.script 

		Button.Parent = ScriptScroll 
		Button.Label.Title.Text = Title 
		Button.Label.Type.Text = Name
		Button.Visible = true

		Connect(Buttons["Run"].MouseButton1Click, function() 
			loadstring(Code)();
		end)

		Connect(Buttons["Paste"].MouseButton1Click, function() 
			RunInput.Text = Code
		end)
	end

end)

Connect(LogService.MessageOut, function(Output, MessageType)
	local Message, Type = Enum.MessageType, nil

	if MessageType == Message.MessageError then
		Type = "Error"
	elseif MessageType == Message.MessageWarning then
		Type = "Warn"
	elseif MessageType == Message.MessageOutput then
		Type = "Print"
	end

	if Type and typeof(Type) == "string" then
		Order = Order - 1
		local Label = Clone(GetExample(Console, string.format("%sExample", Type)))
		Label.Parent = ConsoleScroll
		Label.Visible = true 
		Label.Text = Output
		Label.LayoutOrder = Order
	end
end)

if File then
	for Index, Script in next, listfiles("LateInternal/Scripts") or {} do
		local Button = Clone(GetExample(Executor, "ButtonExample"));
		Button.Text = Normal(Script)
		Button.Visible = true
		Button.Parent = Executor["Workspace"]["ScrollingFrame"]

		SetupButton(Button, Script, readfile(Script))
	end
end
