local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local ProtectGui = protectgui or (syn and syn.protect_gui) or function()
end
local RenderStepped = RunService.RenderStepped

local Themes = {
    Names = {
        "Dark",
        "Light"
    },

    Dark = {  
        Name = "Dark",
        Accent = Color3.fromRGB(240, 240, 255), 
        TitleBarLine = Color3.fromRGB(60, 60, 70),
        Tab = Color3.fromRGB(200, 200, 200),
        Element = Color3.fromRGB(20, 20, 25),
        ElementBorder = Color3.fromRGB(60, 60, 70),
        InElementBorder = Color3.fromRGB(40, 40, 50),
        ElementTransparency = 0.5,
        ToggleSlider = Color3.fromRGB(240, 240, 255),
        ToggleToggled = Color3.fromRGB(15, 15, 20),
        SliderRail = Color3.fromRGB(50, 50, 60),
        DropdownFrame = Color3.fromRGB(25, 25, 30),
        DropdownHolder = Color3.fromRGB(20, 20, 25),
        DropdownBorder = Color3.fromRGB(60, 60, 70),
        DropdownOption = Color3.fromRGB(240, 240, 240),
        Keybind = Color3.fromRGB(240, 240, 240),
        Input = Color3.fromRGB(20, 20, 25),
        InputFocused = Color3.fromRGB(25, 25, 30),
        InputIndicator = Color3.fromRGB(240, 240, 255),
        Dialog = Color3.fromRGB(25, 25, 30),
        DialogHolder = Color3.fromRGB(15, 15, 20),
        DialogButton = Color3.fromRGB(35, 35, 45),
        DialogButtonBorder = Color3.fromRGB(70, 70, 80),
        DialogBorder = Color3.fromRGB(60, 60, 70),
        DialogInput = Color3.fromRGB(20, 20, 25),
        DialogInputLine = Color3.fromRGB(240, 240, 255),
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(180, 180, 190),
        ImageColor = Color3.fromRGB(255, 255, 255),
        Hover = Color3.fromRGB(255, 255, 255),
        Separator = Color3.fromRGB(60, 60, 70),
        HoverChange = 0.15 
    },  

    Light = {
        Name = "Light",
        Accent = Color3.fromRGB(20, 20, 20),
        TitleBarLine = Color3.fromRGB(210, 210, 220),
        Tab = Color3.fromRGB(100, 100, 100),
        Element = Color3.fromRGB(255, 255, 255),
        ElementBorder = Color3.fromRGB(200, 200, 215),
        InElementBorder = Color3.fromRGB(225, 225, 235),
        ElementTransparency = 0.4,
        ToggleSlider = Color3.fromRGB(30, 30, 30),
        ToggleToggled = Color3.fromRGB(250, 250, 255),
        SliderRail = Color3.fromRGB(200, 200, 210),
        DropdownFrame = Color3.fromRGB(255, 255, 255),
        DropdownHolder = Color3.fromRGB(240, 240, 250),
        DropdownBorder = Color3.fromRGB(200, 200, 210),
        DropdownOption = Color3.fromRGB(40, 40, 40),
        Keybind = Color3.fromRGB(40, 40, 40),
        Input = Color3.fromRGB(240, 240, 250),
        InputFocused = Color3.fromRGB(255, 255, 255),
        InputIndicator = Color3.fromRGB(30, 30, 30),
        Dialog = Color3.fromRGB(255, 255, 255),
        DialogHolder = Color3.fromRGB(240, 240, 250),
        DialogButton = Color3.fromRGB(245, 245, 250),
        DialogButtonBorder = Color3.fromRGB(200, 200, 210),
        DialogBorder = Color3.fromRGB(190, 190, 200),
        DialogInput = Color3.fromRGB(250, 250, 255),
        DialogInputLine = Color3.fromRGB(30, 30, 30),
        Text = Color3.fromRGB(20, 20, 20),
        ImageColor = Color3.fromRGB(20, 20, 20),
        SubText = Color3.fromRGB(120, 120, 130),
        Separator = Color3.fromRGB(210, 210, 220),
        Hover = Color3.fromRGB(100, 100, 100),
        HoverChange = 0.08
    }
}

local Library = {
    OpenFrames = {},
    Options = {},
    Themes = Themes.Names,
    Window = nil,
    WindowFrame = nil,
    Unloaded = false,
    Creator = nil,
    DialogOpen = false,
    UseAcrylic = false,
    Acrylic = false,
    Transparency = false,
    MinimizeKeybind = nil,
    MinimizeKey = Enum.KeyCode.LeftControl
}

local function isMotor(value)
    local motorType = tostring(value):match("^Motor%((.+)%)$")
    if motorType then
        return true, motorType
    else
        return false
    end
end

local Connection = {}

Connection.__index = Connection

function Connection.new(signal, handler)
    return setmetatable({
        signal = signal,
        connected = true,
        _handler = handler,
    }, Connection)
end

function Connection:disconnect()
    if self.connected then
        self.connected = false
        for index, connection in pairs(self.signal._connections) do
            if connection == self then
                table.remove(self.signal._connections, index)
                return
            end
        end
    end
end

local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({
        _connections = {},
        _threads = {},
    }, Signal)
end

function Signal:fire(...)
    for _, connection in pairs(self._connections) do
        connection._handler(...)
    end
    for _, thread in pairs(self._threads) do
        coroutine.resume(thread, ...)
    end
    self._threads = {}
end

function Signal:connect(handler)
    local connection = Connection.new(self, handler)
    table.insert(self._connections, connection)
    return connection
end

function Signal:wait()
    table.insert(self._threads, coroutine.running())
    return coroutine.yield()
end

local Linear = {}
Linear.__index = Linear

function Linear.new(targetValue, options)
    assert(targetValue, "Missing argument #1: targetValue")
    options = options or {}
    return setmetatable({
        _targetValue = targetValue,
        _velocity = options.velocity or 1,
    }, Linear)
end

function Linear:step(state, dt)
    local position = state.value
    local velocity = self._velocity
    local goal = self._targetValue
    local dPos = dt * velocity
    local complete = dPos >= math.abs(goal - position)
    position = position + dPos * (goal > position and 1 or - 1)
    if complete then
        position = self._targetValue
        velocity = 0
    end
    return {
        complete = complete,
        value = position,
        velocity = velocity,
    }
end

local Instant = {}
Instant.__index = Instant

function Instant.new(targetValue)
    return setmetatable({
        _targetValue = targetValue,
    }, Instant)
end

function Instant:step()
    return {
        complete = true,
        value = self._targetValue,
    }
end

local VELOCITY_THRESHOLD = 0
local POSITION_THRESHOLD = 0

local EPS = 0

local Spring = {}
Spring.__index = Spring

function Spring.new(targetValue, options)
    assert(targetValue, "Missing argument #1: targetValue")
    options = options or {}
    return setmetatable({
        _targetValue = targetValue,
        _frequency = options.frequency or 4,
        _dampingRatio = options.dampingRatio or 1,
    }, Spring)
end

function Spring:step(state, dt)
    local d = self._dampingRatio
    local f = self._frequency * 2 * math.pi
    local g = self._targetValue
    local p0 = state.value
    local v0 = state.velocity or 0
    local offset = p0 - g
    local decay = math.exp(- d * f * dt)
    local p1, v1
    if d == 1 then
        p1 = (offset * (1 + f * dt) + v0 * dt) * decay + g
        v1 = (v0 * (1 - f * dt) - offset * (f * f * dt)) * decay
    elseif d < 1 then
        local c = math.sqrt(1 - d * d)
        local i = math.cos(f * c * dt)
        local j = math.sin(f * c * dt)
        local z
        if c > EPS then
            z = j / c
        else
            local a = dt * f
            z = a + ((a * a) * (c * c) * (c * c) / 20 - c * c) * (a * a * a) / 6
        end
        local y
        if f * c > EPS then
            y = j / (f * c)
        else
            local b = f * c
            y = dt + ((dt * dt) * (b * b) * (b * b) / 20 - b * b) * (dt * dt * dt) / 6
        end
        p1 = (offset * (i + d * z) + v0 * y) * decay + g
        v1 = (v0 * (i - z * d) - offset * (z * f)) * decay
    else
        local c = math.sqrt(d * d - 1)
        local r1 = - f * (d - c)
        local r2 = - f * (d + c)
        local co2 = (v0 - offset * r1) / (2 * f * c)
        local co1 = offset - co2
        local e1 = co1 * math.exp(r1 * dt)
        local e2 = co2 * math.exp(r2 * dt)
        p1 = e1 + e2 + g
        v1 = e1 * r1 + e2 * r2
    end
    local complete = math.abs(v1) < VELOCITY_THRESHOLD and math.abs(p1 - g) < POSITION_THRESHOLD
    return {
        complete = complete,
        value = complete and g or p1,
        velocity = v1,
    }
end

local noop = function()
end

local BaseMotor = {}
BaseMotor.__index = BaseMotor

function BaseMotor.new()
    return setmetatable({
        _onStep = Signal.new(),
        _onStart = Signal.new(),
        _onComplete = Signal.new(),
    }, BaseMotor)
end

function BaseMotor:onStep(handler)
    return self._onStep:connect(handler)
end

function BaseMotor:onStart(handler)
    return self._onStart:connect(handler)
end

function BaseMotor:onComplete(handler)
    return self._onComplete:connect(handler)
end

function BaseMotor:start()
    if not self._connection then
        self._connection = RunService.RenderStepped:Connect(function(deltaTime)
            self:step(deltaTime)
        end)
    end
end

function BaseMotor:stop()
    if self._connection then
        self._connection:Disconnect()
        self._connection = nil
    end
end

BaseMotor.destroy = BaseMotor.stop

BaseMotor.step = noop
BaseMotor.getValue = noop
BaseMotor.setGoal = noop

function BaseMotor:__tostring()
    return "Motor"
end

local SingleMotor = setmetatable({}, BaseMotor)
SingleMotor.__index = SingleMotor

function SingleMotor.new(initialValue, useImplicitConnections)
    assert(initialValue, "Missing argument #1: initialValue")
    assert(typeof(initialValue) == "number", "initialValue must be a number!")
    local self = setmetatable(BaseMotor.new(), SingleMotor)
    if useImplicitConnections ~= nil then
        self._useImplicitConnections = useImplicitConnections
    else
        self._useImplicitConnections = true
    end
    self._goal = nil
    self._state = {
        complete = true,
        value = initialValue,
    }
    return self
end

function SingleMotor:step(deltaTime)
    if self._state.complete then
        return true
    end
    local newState = self._goal:step(self._state, deltaTime)
    self._state = newState
    self._onStep:fire(newState.value)
    if newState.complete then
        if self._useImplicitConnections then
            self:stop()
        end
        self._onComplete:fire()
    end
    return newState.complete
end

function SingleMotor:getValue()
    return self._state.value
end

function SingleMotor:setGoal(goal)
    self._state.complete = false
    self._goal = goal
    self._onStart:fire()
    if self._useImplicitConnections then
        self:start()
    end
end

function SingleMotor:__tostring()
    return "Motor(Single)"
end

local GroupMotor = setmetatable({}, BaseMotor)
GroupMotor.__index = GroupMotor

local function toMotor(value)
    if isMotor(value) then
        return value
    end
    local valueType = typeof(value)
    if valueType == "number" then
        return SingleMotor.new(value, false)
    elseif valueType == "table" then
        return GroupMotor.new(value, false)
    end
    error(("Unable to convert %q to motor; type %s is unsupported"):format(value, valueType), 2)
end

function GroupMotor.new(initialValues, useImplicitConnections)
    assert(initialValues, "Missing argument #1: initialValues")
    assert(typeof(initialValues) == "table", "initialValues must be a table!")
    assert(not initialValues.step, 'initialValues contains disallowed property "step". Did you mean to put a table of values here?')
    local self = setmetatable(BaseMotor.new(), GroupMotor)
    if useImplicitConnections ~= nil then
        self._useImplicitConnections = useImplicitConnections
    else
        self._useImplicitConnections = true
    end
    self._complete = true
    self._motors = {}
    for key, value in pairs(initialValues) do
        self._motors[key] = toMotor(value)
    end
    return self
end

function GroupMotor:step(deltaTime)
    if self._complete then
        return true
    end
    local allMotorsComplete = true
    for _, motor in pairs(self._motors) do
        local complete = motor:step(deltaTime)
        if not complete then
            allMotorsComplete = false
        end
    end
    self._onStep:fire(self:getValue())
    if allMotorsComplete then
        if self._useImplicitConnections then
            self:stop()
        end
        self._complete = true
        self._onComplete:fire()
    end
    return allMotorsComplete
end

function GroupMotor:setGoal(goals)
    assert(not goals.step, 'goals contains disallowed property "step". Did you mean to put a table of goals here?')
    self._complete = false
    self._onStart:fire()
    for key, goal in pairs(goals) do
        local motor = assert(self._motors[key], ("Unknown motor for key %s"):format(key))
        motor:setGoal(goal)
    end
    if self._useImplicitConnections then
        self:start()
    end
end

function GroupMotor:getValue()
    local values = {}
    for key, motor in pairs(self._motors) do
        values[key] = motor:getValue()
    end
    return values
end

function GroupMotor:__tostring()
    return "Motor(Group)"
end

local Flipper = {
    SingleMotor = SingleMotor,
    GroupMotor = GroupMotor,
    Instant = Instant,
    Linear = Linear,
    Spring = Spring,
    isMotor = isMotor,
}

local Creator = {
    Registry = {},
    Signals = {},
    TransparencyMotors = {},
    DefaultProperties = {
        ScreenGui = {
            Name = "Lucid",
            IgnoreGuiInset = true,
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Global,
            DisplayOrder = math.huge,
        },
        Frame = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0,
        },
        ScrollingFrame = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            ScrollBarImageColor3 = Color3.new(0, 0, 0),
        },
        TextLabel = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            Font = Enum.Font.SourceSans,
            Text = "",
            TextColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            TextSize = 14,
        },
        TextButton = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            AutoButtonColor = false,
            Font = Enum.Font.SourceSans,
            Text = "",
            TextColor3 = Color3.new(0, 0, 0),
            TextSize = 14,
        },
        TextBox = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            ClearTextOnFocus = false,
            Font = Enum.Font.SourceSans,
            Text = "",
            TextColor3 = Color3.new(0, 0, 0),
            TextSize = 14,
        },
        ImageLabel = {
            BackgroundTransparency = 1,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0,
        },
        ImageButton = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            AutoButtonColor = false,
        },
        CanvasGroup = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0,
        },
    },
}

local function ApplyCustomProps(Object, Props)
    if Props.ThemeTag then
        Creator.AddThemeObject(Object, Props.ThemeTag)
    end
end

function Creator.AddSignal(Signal, Function)
    local Connected = Signal:Connect(Function)
    table.insert(Creator.Signals, Connected)
    return Connected
end

function Creator.Disconnect()
    for Idx = # Creator.Signals, 1, - 1 do
        local Connection = table.remove(Creator.Signals, Idx)
        if Connection.Disconnect then
            Connection:Disconnect()
        end
    end
end

function Creator.UpdateTheme()
    for Instance, Object in next, Creator.Registry do
        for Property, ColorIdx in next, Object.Properties do
            local value = Creator.GetThemeProperty(ColorIdx)
            if value ~= nil then
                Instance[Property] = value
            end
        end
    end
    for _, Motor in next, Creator.TransparencyMotors do
        local v = Creator.GetThemeProperty("ElementTransparency")
        if v ~= nil then
            Motor:setGoal(Flipper.Instant.new(v))
        end
    end
end

function Creator.AddThemeObject(Object, Properties)
    local Idx = # Creator.Registry + 1
    local Data = {
        Object = Object,
        Properties = Properties,
        Idx = Idx,
    }
    Creator.Registry[Object] = Data
    Creator.UpdateTheme()
    return Object
end

function Creator.OverrideTag(Object, Properties)
    Creator.Registry[Object].Properties = Properties
    Creator.UpdateTheme()
end

function Creator.GetThemeProperty(Property)
    if Themes[Library.Theme][Property] then
        return Themes[Library.Theme][Property]
    end
    return Themes["Dark"][Property]
end

function Creator.New(Name, Properties, Children)
    local Object = Instance.new(Name)
    for Name, Value in next, Creator.DefaultProperties[Name] or {} do
        Object[Name] = Value
    end
    for Name, Value in next, Properties or {} do
        if Name ~= "ThemeTag" then
            Object[Name] = Value
        end
    end
    for _, Child in next, Children or {} do
        Child.Parent = Object
    end
    if Properties then
        ApplyCustomProps(Object, Properties)
    end
    return Object
end

function Creator.SpringMotor(Initial, Instance, Prop, IgnoreDialogCheck, ResetOnThemeChange)
    IgnoreDialogCheck = IgnoreDialogCheck or false
    ResetOnThemeChange = ResetOnThemeChange or false

    local Motor = Flipper.SingleMotor.new(Initial)
    Motor:onStep(function(value)
        if Instance and Prop and type(Prop) == "string" and value ~= nil then
            Instance[Prop] = value
        end
    end)

    if ResetOnThemeChange then
        table.insert(Creator.TransparencyMotors, Motor)
    end

    local function SetValue(Value, Ignore)
        Ignore = Ignore or false
        if not IgnoreDialogCheck then
            if not Ignore then
                if Prop == "BackgroundTransparency" and Library.DialogOpen then
                    return
                end
            end
        end
        Motor:setGoal(Flipper.Spring.new(Value, {
            frequency = 8
        }))
    end

    return Motor, SetValue
end

Library.Creator = Creator

local New = Creator.New
local safeParent = gethui and gethui() or game:GetService("CoreGui")

local GUI = Instance.new("ScreenGui")
GUI.Name = "Lucid"
GUI.IgnoreGuiInset = true
GUI.ResetOnSpawn = false
GUI.DisplayOrder = math.huge
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Global
GUI.Parent = safeParent

Library.GUI = GUI
ProtectGui(GUI)

function Library:SafeCallback(Function, ...)
    if not Function then
        return
    end
    local Success, Event = pcall(Function, ...)
    if not Success then
        local _, i = Event:find(":%d+: ")
        if not i then
            return Library:Notify({
                Title = "Lucid",
                Content = "",
                SubContent = Event,
                Duration = 5,
            })
        end
        return Library:Notify({
            Title = "Lucid",
            Content = "Callback error",
            SubContent = Event:sub(i + 1),
            Duration = 5,
        })
    end
end

function Library:Round(Number, Factor)
    if Factor == 0 then
        return math.floor(Number)
    end
    Number = tostring(Number)
    return Number:find("%.") and tonumber(Number:sub(1, Number:find("%.") + Factor)) or Number
end

local function map(value, inMin, inMax, outMin, outMax)
    return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
end

local function viewportPointToWorld(location, distance)
    local unitRay = game:GetService("Workspace").CurrentCamera:ScreenPointToRay(location.X, location.Y)
    return unitRay.Origin + unitRay.Direction * distance
end

local function getOffset()
    local viewportSizeY = game:GetService("Workspace").CurrentCamera.ViewportSize.Y
    return map(viewportSizeY, 0, 2560, 8, 56)
end

local viewportPointToWorld, getOffset = unpack({
    viewportPointToWorld,
    getOffset
})

local BlurFolder = Instance.new("Folder", game:GetService("Workspace").CurrentCamera)

local function createAcrylic()
    local Part = Creator.New("Part", {
        Name = "Body",
        Color = Color3.new(0, 0, 0),
        Material = Enum.Material.Glass,
        Size = Vector3.new(1, 1, 0),
        Anchored = true,
        CanCollide = false,
        Locked = true,
        CastShadow = false,
        Transparency = 0.98,
    }, {
        Creator.New("SpecialMesh", {
            MeshType = Enum.MeshType.Brick,
            Offset = Vector3.new(0, 0, - 0.000001),
        }),
    })
    return Part
end

function AcrylicBlur()
    local function createAcrylicBlur(distance)
        local cleanups = {}
        distance = distance or 0.001
        local positions = {
            topLeft = Vector2.new(),
            topRight = Vector2.new(),
            bottomRight = Vector2.new(),
        }
        local model = createAcrylic()
        model.Parent = BlurFolder
        local function updatePositions(size, position)
            positions.topLeft = position
            positions.topRight = position + Vector2.new(size.X, 0)
            positions.bottomRight = position + size
        end
        local function render()
            local res = game:GetService("Workspace").CurrentCamera
            if res then
                res = res.CFrame
            end
            local cond = res
            if not cond then
                cond = CFrame.new()
            end
            local camera = cond
            local topLeft = positions.topLeft
            local topRight = positions.topRight
            local bottomRight = positions.bottomRight
            local topLeft3D = viewportPointToWorld(topLeft, distance)
            local topRight3D = viewportPointToWorld(topRight, distance)
            local bottomRight3D = viewportPointToWorld(bottomRight, distance)
            local width = (topRight3D - topLeft3D).Magnitude
            local height = (topRight3D - bottomRight3D).Magnitude
            model.CFrame = CFrame.fromMatrix((topLeft3D + bottomRight3D) / 2, camera.XVector, camera.YVector, camera.ZVector)
            model.Mesh.Scale = Vector3.new(width, height, 0)
        end
        local function onChange(rbx)
            local offset = getOffset()
            local size = rbx.AbsoluteSize - Vector2.new(offset, offset)
            local position = rbx.AbsolutePosition + Vector2.new(offset / 2, offset / 2)
            updatePositions(size, position)
            task.spawn(render)
        end
        local function renderOnChange()
            local camera = game:GetService("Workspace").CurrentCamera
            if not camera then
                return
            end
            table.insert(cleanups, camera:GetPropertyChangedSignal("CFrame"):Connect(render))
            table.insert(cleanups, camera:GetPropertyChangedSignal("ViewportSize"):Connect(render))
            table.insert(cleanups, camera:GetPropertyChangedSignal("FieldOfView"):Connect(render))
            task.spawn(render)
        end
        model.Destroying:Connect(function()
            for _, item in cleanups do
                pcall(function()
                    item:Disconnect()
                end)
            end
        end)
        renderOnChange()
        return onChange, model
    end
    return function(distance)
        local Blur = {}
        local onChange, model = createAcrylicBlur(distance)
        local comp = Creator.New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
        })
        Creator.AddSignal(comp:GetPropertyChangedSignal("AbsolutePosition"), function()
            onChange(comp)
        end)
        Creator.AddSignal(comp:GetPropertyChangedSignal("AbsoluteSize"), function()
            onChange(comp)
        end)
        Blur.AddParent = function(Parent)
            Creator.AddSignal(Parent:GetPropertyChangedSignal("Visible"), function()
                Blur.SetVisibility(Parent.Visible)
            end)
        end
        Blur.SetVisibility = function(Value)
            model.Transparency = Value and 0.98 or 1
        end
        Blur.Frame = comp
        Blur.Model = model
        return Blur
    end
end

function AcrylicPaint()
    local New = Creator.New
    local AcrylicBlur = AcrylicBlur()
    return function(props)
        local AcrylicPaint = {}
        AcrylicPaint.Frame = New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 0.9,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
        }, {
            New("ImageLabel", {
                Image = "rbxassetid://8992230677",
                ScaleType = "Slice",
                SliceCenter = Rect.new(Vector2.new(99, 99), Vector2.new(99, 99)),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(1, 120, 1, 116),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 1,
                ImageColor3 = Color3.fromRGB(0, 0, 0),
                ImageTransparency = 0.7,
            }),
            New("UICorner", {
                CornerRadius = UDim.new(0, 8),
            }),
            New("Frame", {
                BackgroundTransparency = 0,
                Size = UDim2.fromScale(1, 1),
                Name = "Background",
                ThemeTag = {
                    BackgroundColor3 = "AcrylicMain",
                },
            }, {
                New("UICorner", {
                    CornerRadius = UDim.new(0, 8),
                }),
            }),
            New("Frame", {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0,
                Size = UDim2.fromScale(1, 1),
            }, {
                New("UICorner", {
                    CornerRadius = UDim.new(0, 8),
                }),
                New("UIGradient", {
                    Rotation = 90,
                    ThemeTag = {
                        Color = "AcrylicGradient",
                    },
                }),
            }),
            New("ImageLabel", {
                Image = "rbxassetid://9968344105",
                ImageTransparency = 0.98,
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.new(0, 128, 0, 128),
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
            }, {
                New("UICorner", {
                    CornerRadius = UDim.new(0, 8),
                }),
            }),
            New("ImageLabel", {
                Image = "rbxassetid://9968344227",
                ImageTransparency = 0.9,
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.new(0, 128, 0, 128),
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                ThemeTag = {
                    ImageTransparency = "AcrylicNoise",
                },
            }, {
                New("UICorner", {
                    CornerRadius = UDim.new(0, 8),
                }),
            }),
            New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                ZIndex = 2,
            }, {
                New("UICorner", {
                    CornerRadius = UDim.new(0, 8),
                }),
                New("UIStroke", {
                    Transparency = 0.5,
                    Thickness = 1,
                    ThemeTag = {
                        Color = "AcrylicBorder",
                    },
                }),
            }),
        })
        local Blur
        if Library.UseAcrylic then
            Blur = AcrylicBlur()
            Blur.Frame.Parent = AcrylicPaint.Frame
            AcrylicPaint.Model = Blur.Model
            AcrylicPaint.AddParent = Blur.AddParent
            AcrylicPaint.SetVisibility = Blur.SetVisibility
        end
        return AcrylicPaint
    end
end

local Acrylic = {
    AcrylicBlur = AcrylicBlur(),
    CreateAcrylic = createAcrylic,
    AcrylicPaint = AcrylicPaint(),
}

function Acrylic.init()
    local baseEffect = Instance.new("DepthOfFieldEffect")
    baseEffect.FarIntensity = 0
    baseEffect.InFocusRadius = 0.1
    baseEffect.NearIntensity = 1
    local depthOfFieldDefaults = {}
    function Acrylic.Enable()
        for _, effect in pairs(depthOfFieldDefaults) do
            effect.Enabled = false
        end
        baseEffect.Parent = game:GetService("Lighting")
    end
    function Acrylic.Disable()
        for _, effect in pairs(depthOfFieldDefaults) do
            effect.Enabled = effect.enabled
        end
        baseEffect.Parent = nil
    end
    local function registerDefaults()
        local function register(object)
            if object:IsA("DepthOfFieldEffect") then
                depthOfFieldDefaults[object] = {
                    enabled = object.Enabled
                }
            end
        end
        for _, child in pairs(game:GetService("Lighting"):GetChildren()) do
            register(child)
        end
        if game:GetService("Workspace").CurrentCamera then
            for _, child in pairs(game:GetService("Workspace").CurrentCamera:GetChildren()) do
                register(child)
            end
        end
    end
    registerDefaults()
    Acrylic.Enable()
end

local Components = {
    Assets = {
        Close = "rbxassetid://10747384394",
        Min = "rbxassetid://10734896206",
        Max = "rbxassetid://10734886496",
        Restore = "rbxassetid://10734895530",
        Dark = "rbxassetid://10734897102",
        Light = "rbxassetid://10734974297",
        Search = "rbxassetid://10734943674"
    },
}

Components.Element = (function()
    local New = Creator.New
    local Spring = Flipper.Spring.new
    return function(Title, Desc, Parent, Hover, Options)
        local Element = {}
        local Options = Options or {}
        Element.TitleLabel = New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
            Text = Title,
            TextColor3 = Creator.GetThemeProperty("Text"),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            ThemeTag = {
                TextColor3 = "Text",
            },
        })
        Element.DescLabel = New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            Text = Desc,
            TextColor3 = Creator.GetThemeProperty("SubText"),
            TextSize = 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            ThemeTag = {
                TextColor3 = "SubText",
            },
        })
        Element.LabelHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, - 28, 0, 0),
        }, {
            New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            }),
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 13),
                PaddingTop = UDim.new(0, 13),
            }),
            Element.TitleLabel,
            Element.DescLabel,
        })
        Element.Border = New("UIStroke", {
            Transparency = 0.5,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = Creator.GetThemeProperty("ElementBorder"),
            ThemeTag = {
                Color = "ElementBorder",
            },
        })
        Element.Frame = New("TextButton", {
            Visible = Options.Visible ~= false,
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = Creator.GetThemeProperty("ElementTransparency"),
            BackgroundColor3 = Creator.GetThemeProperty("Element"),
            Parent = Parent,
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            LayoutOrder = 7,
            ThemeTag = {
                BackgroundColor3 = "Element",
                BackgroundTransparency = "ElementTransparency",
            },
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(0, 4),
            }),
            Element.Border,
            Element.LabelHolder,
        })
        function Element:SetTitle(Set)
            Element.TitleLabel.Text = Set
        end
        function Element:Visible(Bool)
            Element.Frame.Visible = Bool
        end
        function Element:SetDesc(Set)
            if Set == nil then
                Set = ""
            end
            if Set == "" then
                Element.DescLabel.Visible = false
            else
                Element.DescLabel.Visible = true
            end
            Element.DescLabel.Text = Set
        end
        function Element:GetTitle()
            return Element.TitleLabel.Text
        end
        function Element:GetDesc()
            return Element.DescLabel.Text
        end
        function Element:Destroy()
            Element.Frame:Destroy()
        end
        Element:SetTitle(Title)
        Element:SetDesc(Desc)
        if Hover then
            local Motor, SetTransparency = Creator.SpringMotor(
				Creator.GetThemeProperty("ElementTransparency"), Element.Frame, "BackgroundTransparency", false, true)
            Creator.AddSignal(Element.Frame.MouseEnter, function()
                SetTransparency(Creator.GetThemeProperty("ElementTransparency") - Creator.GetThemeProperty("HoverChange"))
            end)
            Creator.AddSignal(Element.Frame.MouseLeave, function()
                SetTransparency(Creator.GetThemeProperty("ElementTransparency"))
            end)
            Creator.AddSignal(Element.Frame.MouseButton1Down, function()
                SetTransparency(Creator.GetThemeProperty("ElementTransparency") + Creator.GetThemeProperty("HoverChange"))
            end)
            Creator.AddSignal(Element.Frame.MouseButton1Up, function()
                SetTransparency(Creator.GetThemeProperty("ElementTransparency") - Creator.GetThemeProperty("HoverChange"))
            end)
        end
        return Element
    end
end)()
Components.Tab = (function()
    local New = Creator.New
    local Spring = Flipper.Spring.new
    local Components = Components
    local TabModule = {
        Window = nil,
        Tabs = {},
        Containers = {},
        SelectedTab = 0,
        TabCount = 0,
    }
    function TabModule:Init(Window)
        TabModule.Window = Window
        return TabModule
    end
    function TabModule:GetCurrentTabPos()
        local TabHolderPos = TabModule.Window.TabHolder.AbsolutePosition.Y
        local TabPos = TabModule.Tabs[TabModule.SelectedTab].Frame.AbsolutePosition.Y
        return TabPos - TabHolderPos
    end
    function TabModule:New(Title, Icon, Parent)
        local Window = TabModule.Window
        local Elements = Library.Elements
        TabModule.TabCount += 1
        local TabIndex = TabModule.TabCount
        local Tab = {
            Selected = false,
            Name = Title,
            Type = "Tab"
        }
        if Library:GetIcon(Icon) then
            Icon = Library:GetIcon(Icon)
        end
        if Icon == "" or Icon == nil then
            Icon = nil
        end
        Tab.Frame = New("TextButton", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = Parent,
            Text = "",
            AutoButtonColor = false,
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            New("TextLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = Icon and UDim2.new(0, 34, 0.5, 0) or UDim2.new(0, 14, 0.5, 0),
                Text = Title,
                RichText = true,
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
                TextSize = 14,
                TextXAlignment = "Left",
                TextYAlignment = "Center",
                Size = UDim2.new(1, - 12, 1, 0),
                BackgroundTransparency = 1,
                ThemeTag = {
                    TextColor3 = "Text"
                },
            }),
            New("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.fromOffset(18, 18),
                Position = UDim2.new(0, 10, 0.5, 0),
                BackgroundTransparency = 1,
                Image = Icon,
                ThemeTag = {
                    ImageColor3 = "Text"
                },
            }),
        })
        local ContainerLayout = New("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        Tab.ContainerFrame = New("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Parent = Window.ContainerHolder,
            Visible = false,
            ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
            ScrollBarImageTransparency = 0.9,
            ScrollBarThickness = 2,
            BorderSizePixel = 0,
            CanvasSize = UDim2.fromScale(0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y,
        }, {
            ContainerLayout,
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
            }),
        })
        Creator.AddSignal(ContainerLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            Tab.ContainerFrame.CanvasSize = UDim2.new(0, 0, 0, ContainerLayout.AbsoluteContentSize.Y + 8)
        end)
        Creator.AddSignal(Tab.Frame.MouseButton1Click, function()
            TabModule:SelectTab(TabIndex)
        end)
        TabModule.Containers[TabIndex] = Tab.ContainerFrame
        TabModule.Tabs[TabIndex] = Tab
        Tab.Container = Tab.ContainerFrame
        Tab.ScrollFrame = Tab.Container
        function Tab:AddSection(SectionTitle)
            local Section = {
                Type = "Section"
            }
            local SectionFrame = Components.Section(SectionTitle, Tab.Container)
            Section.Container = SectionFrame.Container
            Section.ScrollFrame = Tab.Container
            setmetatable(Section, Elements)
            return Section
        end
        setmetatable(Tab, Elements)
        if TabIndex == 1 then
            task.defer(function()
                TabModule:SelectTab(1)
            end)
        end
        return Tab
    end
    function TabModule:SelectTab(Tab)
        local Window = TabModule.Window
        TabModule.SelectedTab = Tab
        for _, t in next, TabModule.Tabs do
            t.Selected = false
        end
        local sel = TabModule.Tabs[Tab]
        sel.Selected = true
        Window.TabDisplay.Text = sel.Name
        if Window.Selector then
            Window.Selector.Visible = false
        end
        task.spawn(function()
            Window.ContainerHolder.Parent = Window.ContainerAnim
            Window.ContainerPosMotor:setGoal(Spring(15, {
                frequency = 10
            }))
            Window.ContainerBackMotor:setGoal(Spring(1, {
                frequency = 10
            }))
            if Window.ContainerFadeMotor then
                Window.ContainerFadeMotor:setGoal(Spring(1, {
                    frequency = 10
                }))
            end
            task.wait(0.12)
            for _, c in next, TabModule.Containers do
                c.Visible = false
            end
            TabModule.Containers[Tab].Visible = true
            Window.ContainerPosMotor:setGoal(Spring(0, {
                frequency = 5
            }))
            Window.ContainerBackMotor:setGoal(Spring(0, {
                frequency = 8
            }))
            if Window.ContainerFadeMotor then
                Window.ContainerFadeMotor:setGoal(Spring(0, {
                    frequency = 6
                }))
            end
            task.wait(0.12)
            Window.ContainerHolder.Parent = Window.ContainerCanvas
        end)
    end
    return TabModule
end)()
Components.Button = (function()
    local New = Creator.New
    return function(Theme, Parent, DialogCheck)
        DialogCheck = DialogCheck or false
        local Button = {}
        Button.Title = New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            Text = "Button",
            TextColor3 = Creator.GetThemeProperty("Text"),
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            ThemeTag = {
                TextColor3 = "Text"
            },
        })
        Button.HoverFrame = New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BackgroundColor3 = Creator.GetThemeProperty("Hover"),
            ThemeTag = {
                BackgroundColor3 = "Hover"
            },
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
        })
        Button.Frame = New("TextButton", {
            Size = UDim2.new(0, 200, 0, 36),
            Parent = Parent,
            AutoButtonColor = false,
            Text = "",
            BackgroundColor3 = Creator.GetThemeProperty("DialogButton"),
            BackgroundTransparency = Creator.GetThemeProperty("DialogButtonTransparency"),
            ThemeTag = {
                BackgroundColor3 = "DialogButton",
                BackgroundTransparency = "DialogButtonTransparency",
            },
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Transparency = 0.5,
                Thickness = 1.2,
                Color = Creator.GetThemeProperty("DialogButtonBorder"),
                ThemeTag = {
                    Color = "DialogButtonBorder"
                },
            }),
            Button.HoverFrame,
            Button.Title,
        })
        local Motor, SetTransparency = Creator.SpringMotor(1, Button.HoverFrame, "BackgroundTransparency", DialogCheck)
        Creator.AddSignal(Button.Frame.MouseEnter, function()
            SetTransparency(1 - Creator.GetThemeProperty("HoverChange"))
        end)
        Creator.AddSignal(Button.Frame.MouseLeave, function()
            SetTransparency(1)
        end)
        Creator.AddSignal(Button.Frame.MouseButton1Down, function()
            SetTransparency(1 - (Creator.GetThemeProperty("HoverChange") * 1.5))
        end)
        Creator.AddSignal(Button.Frame.MouseButton1Up, function()
            SetTransparency(1 - Creator.GetThemeProperty("HoverChange"))
        end)
        return Button
    end
end)()
Components.Dialog = (function()
    local Spring = Flipper.Spring.new
    local New = Creator.New
    local Dialog = {
        Window = nil
    }
    function Dialog:Init(Window)
        Dialog.Window = Window
        return Dialog
    end
    function Dialog:Create()
        local NewDialog = {
            Buttons = 0
        }
        NewDialog.TintFrame = New("TextButton", {
            Text = "",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Parent = Dialog.Window.Root,
        })
        local TintMotor, TintTransparency = Creator.SpringMotor(1, NewDialog.TintFrame, "BackgroundTransparency", true)
        NewDialog.Root = New("CanvasGroup", {
            Size = UDim2.fromOffset(340, 180),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            GroupTransparency = 1,
            Parent = NewDialog.TintFrame,
            ThemeTag = {
                BackgroundColor3 = "Dialog"
            },
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(0, 10)
            }),
            New("UIStroke", {
                Transparency = 0.35,
                Thickness = 1.5,
                ThemeTag = {
                    Color = "DialogBorder"
                },
            }),
        })
        NewDialog.Title = New("TextLabel", {
            Text = "Dialog",
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
            TextSize = 20,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, - 40, 0, 24),
            Position = UDim2.fromOffset(20, 18),
            BackgroundTransparency = 1,
            ThemeTag = {
                TextColor3 = "Text"
            },
            Parent = NewDialog.Root,
        })
        NewDialog.ButtonHolder = New("Frame", {
            Size = UDim2.new(1, - 40, 0, 36),
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, - 15),
            BackgroundTransparency = 1,
            Parent = NewDialog.Root,
        }, {
            New("UIGridLayout", {
                CellPadding = UDim2.new(0, 10, 0, 0),
                CellSize = UDim2.new(0.5, - 5, 1, 0),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })
        NewDialog.Scale = New("UIScale", {
            Scale = 1.05,
            Parent = NewDialog.Root
        })
        local RootMotor, RootTransparency = Creator.SpringMotor(1, NewDialog.Root, "GroupTransparency")
        local ScaleMotor, SetScale = Creator.SpringMotor(1.05, NewDialog.Scale, "Scale")
        function NewDialog:Open()
            Library.DialogOpen = true
            NewDialog.Scale.Scale = 1.08
            TintTransparency(1)
            RootTransparency(0)
            SetScale(1)
        end
        function NewDialog:Close()
            Library.DialogOpen = false
            NewDialog.TintFrame:Destroy()
        end
        function NewDialog:Button(Title, Callback)
            NewDialog.Buttons += 1
            local Button = Components.Button("", NewDialog.ButtonHolder, true)
            Button.Title.Text = Title or "Button"
            Creator.AddSignal(Button.Frame.MouseButton1Click, function()
                Library:SafeCallback(Callback or function()
                end)
                NewDialog:Close()
            end)
            return Button
        end
        return NewDialog
    end
    return Dialog
end)()
Components.Notification = (function()
    local Spring = Flipper.Spring.new
    local New = Creator.New
    local Notification = {}

    function Notification:Init(GUI)
        Notification.Holder = New("Frame", {
            Position = UDim2.new(1, - 20, 1, - 20),
            Size = UDim2.new(0, 260, 1, - 20),
            AnchorPoint = Vector2.new(1, 1),
            BackgroundTransparency = 1,
            Parent = GUI
        }, {
            New("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                Padding = UDim.new(0, 6),
            }),
        })
    end

    function Notification:New(Config)
        if Library.Unloaded then
            return false
        end
        Config.Title = Config.Title or ""
        Config.Content = Config.Content or ""
        Config.SubContent = Config.SubContent or ""
        Config.Duration = Config.Duration or 5

        local NewNotification = {
            Closed = false
        }
        NewNotification.AcrylicPaint = Acrylic.AcrylicPaint()

        NewNotification.Title = New("TextLabel", {
            Position = UDim2.fromOffset(10, 8),
            Text = Config.Title,
            RichText = true,
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ThemeTag = { TextColor3 = "Text" },
            Size = UDim2.new(1, - 30, 0, 14),
            BackgroundTransparency = 1,
        })

        NewNotification.ContentLabel = New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            Text = Config.Content,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, - 20, 0, 12),
            Position = UDim2.fromOffset(10, 26),
            ThemeTag = { TextColor3 = "Text" },
            BackgroundTransparency = 1,
            TextWrapped = true,
        })

        NewNotification.SubContentLabel = New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            Text = Config.SubContent,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, - 20, 0, 12),
            Position = UDim2.fromOffset(10, 40),
            ThemeTag = { TextColor3 = "Text" },
            BackgroundTransparency = 1,
            TextWrapped = true,
            Visible = Config.SubContent ~= "",
        })

        NewNotification.CloseButton = New("ImageButton", {
            Image = "rbxassetid://10747384394",
            Position = UDim2.new(1, - 8, 0, 6),
            Size = UDim2.fromOffset(16, 16),
            AnchorPoint = Vector2.new(1, 0),
            ThemeTag = { ImageColor3 = "ImageColor" },
            BackgroundTransparency = 1,
            ScaleType = Enum.ScaleType.Fit,
        })

        NewNotification.Root = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 60),
            Position = UDim2.fromScale(1, 0),
        }, {
            NewNotification.AcrylicPaint.Frame,
            New("UICorner", {
                CornerRadius = UDim.new(0, 6)
            }),
            New("UIStroke", {
                Transparency = 0.4,
                Color = Color3.fromRGB(100, 100, 100),
            }),
            NewNotification.Title,
            NewNotification.ContentLabel,
            NewNotification.SubContentLabel,
            NewNotification.CloseButton,
        })

        NewNotification.Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 60),
            Parent = Notification.Holder,
        }, {
            NewNotification.Root
        })

        local RootMotor = Flipper.GroupMotor.new({
            Offset = 30,
            Opacity = 1,
            Scale = 0.95
        })
        RootMotor:onStep(function(Values)
            NewNotification.Root.Position = UDim2.new(0, Values.Offset, 0, 0)
            NewNotification.Root.BackgroundTransparency = Values.Opacity
            NewNotification.AcrylicPaint.Frame.BackgroundTransparency = Values.Opacity
            NewNotification.Root.Size = UDim2.new(1 * Values.Scale, 0, 0, NewNotification.Holder.Size.Y.Offset * Values.Scale)
        end)

        NewNotification.CloseButton.MouseEnter:Connect(function()
            game:GetService("TweenService"):Create(
                NewNotification.CloseButton, TweenInfo.new(0.2), {
                ImageColor3 = Color3.fromRGB(255, 100, 100)
            }):Play()
        end)
        NewNotification.CloseButton.MouseLeave:Connect(function()
            game:GetService("TweenService"):Create(
                NewNotification.CloseButton, TweenInfo.new(0.2), {
                ImageColor3 = Color3.fromRGB(220, 220, 220)
            }):Play()
        end)

        NewNotification.CloseButton.MouseButton1Click:Connect(function()
            NewNotification:Close()
        end)

        function NewNotification:Open()
            local totalHeight = 30 + NewNotification.ContentLabel.AbsoluteSize.Y
            if Config.SubContent ~= "" then
                totalHeight = totalHeight + NewNotification.SubContentLabel.AbsoluteSize.Y + 4
            end
            NewNotification.Holder.Size = UDim2.new(1, 0, 0, totalHeight)

            RootMotor:setGoal({
                Offset = Spring(0, {
                    frequency = 5,
                    dampingRatio = 0.75
                }),
                Opacity = Spring(0, {
                    frequency = 5,
                    dampingRatio = 0.75
                }),
                Scale = Spring(1, {
                    frequency = 5,
                    dampingRatio = 0.75
                }),
            })
        end

        function NewNotification:Close()
            if not NewNotification.Closed then
                NewNotification.Closed = true
                task.spawn(function()
                    RootMotor:setGoal({
                        Offset = Spring(30, {
                            frequency = 5,
                            dampingRatio = 0.75
                        }),
                        Opacity = Spring(1, {
                            frequency = 5,
                            dampingRatio = 0.75
                        }),
                        Scale = Spring(0.95, {
                            frequency = 5,
                            dampingRatio = 0.75
                        }),
                    })
                    task.wait(0.3)
                    if Library.UseAcrylic then
                        NewNotification.AcrylicPaint.Model:Destroy()
                    end
                    NewNotification.Holder:Destroy()
                end)
            end
        end

        NewNotification:Open()
        if Config.Duration then
            task.delay(Config.Duration, function()
                NewNotification:Close()
            end)
        end

        return NewNotification
    end

    return Notification
end)()
Components.Textbox = (function()
    local New = Creator.New

    return function(Parent, Acrylic)
        Acrylic = Acrylic or false
        local Textbox = {}

        Textbox.Input = New("TextBox", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextColor3 = Color3.fromRGB(235, 235, 235),
            TextSize = 15,
            PlaceholderText = "...",
            PlaceholderColor3 = Color3.fromRGB(160, 160, 160),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromOffset(10, 0),
            ThemeTag = {
                TextColor3 = "Text",
                PlaceholderColor3 = "SubText",
            },
        })

        Textbox.Container = New("Frame", {
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(1, - 16, 1, 0),
        }, {
            Textbox.Input
        })

        Textbox.Frame = New("Frame", {
            Size = UDim2.new(0, 0, 0, 36),
            BackgroundTransparency = Acrylic and 0.85 or 0,
            Parent = Parent,
            ThemeTag = {
                BackgroundColor3 = Acrylic and "Input" or "DialogInput"
            },
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(0, 8)
            }),
            New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Transparency = Acrylic and 0.35 or 0.5,
                ThemeTag = {
                    Color = Acrylic and "InElementBorder" or "DialogButtonBorder"
                },
            }),
            Textbox.Container,
        })

        local function Update()
            local PADDING = 6
            local Reveal = Textbox.Container.AbsoluteSize.X
            if not Textbox.Input:IsFocused() or Textbox.Input.TextBounds.X <= Reveal - 2 * PADDING then
                Textbox.Input.Position = UDim2.new(0, PADDING, 0, 0)
            else
                local Cursor = Textbox.Input.CursorPosition
                if Cursor ~= - 1 then
                    local subtext = string.sub(Textbox.Input.Text, 1, Cursor - 1)
                    local width = TextService:GetTextSize(
                        subtext, Textbox.Input.TextSize, Textbox.Input.Font, Vector2.new(math.huge, math.huge)).X
                    local CurrentCursorPos = Textbox.Input.Position.X.Offset + width
                    if CurrentCursorPos < PADDING then
                        Textbox.Input.Position = UDim2.fromOffset(PADDING - width, 0)
                    elseif CurrentCursorPos > Reveal - PADDING - 1 then
                        Textbox.Input.Position = UDim2.fromOffset(Reveal - width - PADDING - 1, 0)
                    end
                end
            end
        end

        task.spawn(Update)
        Creator.AddSignal(Textbox.Input:GetPropertyChangedSignal("Text"), Update)
        Creator.AddSignal(Textbox.Input:GetPropertyChangedSignal("CursorPosition"), Update)

        Creator.AddSignal(Textbox.Input.Focused, function()
            Update()
            Creator.OverrideTag(Textbox.Frame, {
                BackgroundColor3 = Acrylic and "InputFocused" or "DialogHolder"
            })
        end)

        Creator.AddSignal(Textbox.Input.FocusLost, function()
            Update()
            Creator.OverrideTag(Textbox.Frame, {
                BackgroundColor3 = Acrylic and "Input" or "DialogInput"
            })
        end)

        return Textbox
    end
end)()

Components.TitleBar = (function()
    local New = Creator.New
    local AddSignal = Creator.AddSignal

    return function(Config)
        local TitleBar = {}

        local function BarButton(Icon, Pos, Parent, Callback)
            local Button = {
                Callback = Callback or function()
                end
            }

            Button.Frame = New("TextButton", {
                Size = UDim2.new(0, 36, 1, - 6),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Parent = Parent,
                Position = Pos,
                Text = "",
            }, {
                New("UICorner", {
                    CornerRadius = UDim.new(0, 8)
                }),
                New("ImageLabel", {
                    Image = Icon,
                    Size = UDim2.fromOffset(18, 18),
                    Position = UDim2.fromScale(0.5, 0.5),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Name = "Icon",
                    ThemeTag = {
                        ImageColor3 = "Text"
                    },
                }),
            })

            local _, SetTransparency = Creator.SpringMotor(1, Button.Frame)

            AddSignal(Button.Frame.MouseEnter, function()
                SetTransparency(0.92)
            end)
            AddSignal(Button.Frame.MouseLeave, function()
                SetTransparency(1, true)
            end)
            AddSignal(Button.Frame.MouseButton1Down, function()
                SetTransparency(0.95)
            end)
            AddSignal(Button.Frame.MouseButton1Up, function()
                SetTransparency(0.92)
            end)
            AddSignal(Button.Frame.MouseButton1Click, function()
                Button.Callback()
            end)

            function Button:SetCallback(Func)
                self.Callback = Func
            end

            return Button
        end

        local hasSubtitle = Config.SubTitle and # Config.SubTitle > 0

        TitleBar.Frame = New("Frame", {
            Size = UDim2.new(1, 0, 0, 48),
            BackgroundTransparency = 1,
            Parent = Config.Parent,
        }, {
            New("Frame", {
                Size = UDim2.new(1, - 20, 1, 0),
                Position = UDim2.new(0, 16, 0, 0),
                BackgroundTransparency = 1,
            }, {
                New("UIListLayout", {
                    Padding = UDim.new(0, 10),
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                }),
                New("ImageLabel", {
                    Size = UDim2.new(0, 32, 0, 32),
                    BackgroundTransparency = 1,
                    Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%s&width=420&height=420&format=png", tostring(game.Players.LocalPlayer.UserId)),
                }, {
                    New("UICorner", {
                        CornerRadius = UDim.new(1, 0)
                    })
                }),
                New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 320, 0, 28),
                }, {
                    New("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 8),
                    }),
                    New("TextLabel", {
                        Text = Config.Title,
                        RichText = true,
                        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                        TextSize = 15,
                        BackgroundTransparency = 1,
                        ThemeTag = {
                            TextColor3 = "Text",
                        },
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        AutomaticSize = Enum.AutomaticSize.X,
                    }),
                    hasSubtitle and New("TextLabel", {
                        Text = Config.SubTitle,
                        TextTransparency = 0.35,
                        RichText = true,
                        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Italic),
                        TextSize = 12,
                        BackgroundTransparency = 1,
                        ThemeTag = {
                            TextColor3 = "Text",
                        },
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        AutomaticSize = Enum.AutomaticSize.X,
                    }) or nil,
                }),
            }),
            New("Frame", {
                BackgroundTransparency = 0,
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.new(0, 0, 1, 0),
                ThemeTag = {
                    BackgroundColor3 = "TitleBarLine"
                },
            }),
        })

        TitleBar.CloseButton = BarButton(Components.Assets.Close, UDim2.new(1, - 4, 0, 6), TitleBar.Frame, function()
            Library.Window:Dialog({
                Title = "Lucid",
                Content = "Are you sure you want to close?",
                Buttons = {
                    {
                        Title = "Cancel"
                    },
                    {
                        Title = "OK",
                        Callback = function()
                            Library:Destroy()
                        end
                    },
                },
            })
        end)

        TitleBar.MaxButton = BarButton(Components.Assets.Max, UDim2.new(1, - 44, 0, 6), TitleBar.Frame, function()
            Config.Window.Maximize(not Config.Window.Maximized)
        end)

        TitleBar.MinButton = BarButton(Components.Assets.Min, UDim2.new(1, - 84, 0, 6), TitleBar.Frame, function()
            Library.Window:Minimize()
        end)

        TitleBar.ThemeButton = BarButton(
            Components.Assets.Light, UDim2.new(1, - 124, 0, 6), TitleBar.Frame, function()
            local currentTheme = Config.Theme
            local newTheme = (currentTheme == "Dark") and "Light" or "Dark"
            TitleBar.ThemeButton.Frame.Icon.Image = (newTheme == "Light") and Components.Assets.Dark or Components.Assets.Light
            Config.Theme = newTheme
            Library:SetTheme(newTheme)
        end)

        TitleBar.SearchButton = BarButton(
            Components.Assets.Search, UDim2.new(1, - 164, 0, 6), TitleBar.Frame, function()
        end)

        return TitleBar
    end
end)()

Components.Window = (function()
    local Spring = Flipper.Spring.new
    local Instant = Flipper.Instant.new
    local New = Creator.New

    return function(Config)
        local Window = {
            Minimized = false,
            Maximized = false,
            Size = Config.Size,
            CurrentPos = 0,
            TabWidth = Config.TabWidth or 220,
            Position = UDim2.fromOffset(
				Camera.ViewportSize.X / 2 - Config.Size.X.Offset / 2, Camera.ViewportSize.Y / 2 - Config.Size.Y.Offset / 2),
        }
        
        local Dragging, DragInput, MousePos, StartPos = false
        local Resizing, ResizePos = false
        local MinimizeNotif = false
        
        Window.AcrylicPaint = Acrylic.AcrylicPaint()
        
        local ResizeStartFrame = New("Frame", {
            Size = UDim2.fromOffset(18, 18),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, - 18, 1, - 18),
        })
        
        Window.TabHolder = New("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 0,
            BorderSizePixel = 0,
            CanvasSize = UDim2.fromScale(0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y,
        }, {
            New("UIListLayout", {
                Padding = UDim.new(0, 6)
            }),
        })

        local TabFrame = New("Frame", {
            Size = UDim2.new(0, Window.TabWidth, 1, - 64),
            Position = UDim2.new(0, 12, 0, 52),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
        }, {
            Window.TabHolder,
        })
        
        Window.TabDisplay = New("TextLabel", {
            Text = "Tab",
            RichText = true,
            FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
            TextSize = 26,
            TextXAlignment = "Left",
            TextYAlignment = "Center",
            Size = UDim2.new(1, - 16, 0, 26),
            Position = UDim2.fromOffset(Window.TabWidth + 28, 56),
            BackgroundTransparency = 1,
            ThemeTag = {
                TextColor3 = "Text"
            },
        })
        
        Window.ContainerHolder = New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
        })
        
        Window.ContainerAnim = New("CanvasGroup", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
        })
        
        Window.ContainerCanvas = New("Frame", {
            Size = UDim2.new(1, - Window.TabWidth - 32, 1, - 100),
            Position = UDim2.fromOffset(Window.TabWidth + 28, 88),
            BackgroundTransparency = 1,
        }, {
            Window.ContainerAnim,
            Window.ContainerHolder
        })
        
        local TabSeparator = New("Frame", {
            Name = "Separator",
            Size = UDim2.new(0, 1, 1, - 49),
            Position = UDim2.fromOffset(Window.TabWidth + 20, 49),
            ThemeTag = { BackgroundColor3 = "Separator" },
            BackgroundTransparency = 0
        })

        Window.BackgroundImage = New("ImageLabel", {
            Name = "Background",
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromScale(0, 0),
            Image = "rbxassetid://106023436512699",
            BackgroundTransparency = 1,
            ScaleType = Enum.ScaleType.Crop,
            ZIndex = 0
        })

        Window.Root = New("Frame", {
            Size = Window.Size,
            Position = Window.Position,
            BackgroundTransparency = 1,
            Parent = Config.Parent,
            ClipsDescendants = false, 
        }, {
            Window.BackgroundImage,
            Window.AcrylicPaint.Frame,
            Window.TabDisplay,
            Window.ContainerCanvas,
            TabFrame,
            ResizeStartFrame,
            TabSeparator,
        })
        
        Window.TitleBar = Components.TitleBar({
            Title = Config.Title,
            SubTitle = Config.SubTitle,
            Parent = Window.Root,
            Window = Window,
        })
        
        if Library.UseAcrylic then
            Window.AcrylicPaint.AddParent(Window.Root)
        end
        
        local SizeMotor = Flipper.GroupMotor.new({
            X = Window.Size.X.Offset,
            Y = Window.Size.Y.Offset
        })
        local PosMotor = Flipper.GroupMotor.new({
            X = Window.Position.X.Offset,
            Y = Window.Position.Y.Offset
        })
        
        Window.SelectorPosMotor = Flipper.SingleMotor.new(18)
        Window.SelectorSizeMotor = Flipper.SingleMotor.new(0)
        Window.ContainerBackMotor = Flipper.SingleMotor.new(0)
        Window.ContainerPosMotor = Flipper.SingleMotor.new(94)
        
        local OpenMotor = Flipper.SingleMotor.new(0)

        OpenMotor:setGoal(Spring(1, {
            frequency = 4,
            dampingRatio = 0.8
        }))

        SizeMotor:onStep(function(values)
            Window.Root.Size = UDim2.new(0, values.X, 0, values.Y)
        end)
        PosMotor:onStep(function(values)
            Window.Root.Position = UDim2.new(0, values.X, 0, values.Y)
        end)
        
        Window.SelectorSizeMotor:onStep(function(Value)
        end)
        Window.ContainerBackMotor:onStep(function(Value)
            Window.ContainerAnim.GroupTransparency = Value
        end)
        Window.ContainerPosMotor:onStep(function(Value)
            Window.ContainerAnim.Position = UDim2.fromOffset(0, Value)
        end)
        
        local OldSizeX, OldSizeY, OldPosX, OldPosY
        Window.Maximize = function(Value, NoPos)
            if Value and not Window.Maximized then
                OldSizeX, OldSizeY = Window.Root.Size.X.Offset, Window.Root.Size.Y.Offset
                OldPosX, OldPosY = Window.Root.Position.X.Offset, Window.Root.Position.Y.Offset
            end
            Window.Maximized = Value
            Window.TitleBar.MaxButton.Frame.Icon.Image = Value and Components.Assets.Restore or Components.Assets.Max
            local SizeX = Value and Camera.ViewportSize.X or OldSizeX
            local SizeY = Value and Camera.ViewportSize.Y or OldSizeY
            local PosX, PosY = Value and 0 or OldPosX, Value and 0 or OldPosY
            Window.Root.Size = UDim2.fromOffset(SizeX, SizeY)
            Window.Root.Position = UDim2.fromOffset(PosX, PosY)
            if Window.ToggleButton then
                Window.ToggleButton.Visible = not Value
            end
        end
        
        Creator.AddSignal(Window.TitleBar.Frame.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging, MousePos, StartPos = true, Input.Position, Window.Root.Position
                if Window.Maximized then
                    StartPos = UDim2.fromOffset(
						Mouse.X - (Mouse.X * ((OldSizeX - 100) / Window.Root.AbsoluteSize.X)), Mouse.Y - (Mouse.Y * (OldSizeY / Window.Root.AbsoluteSize.Y)))
                end
                Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        Dragging = false
                    end
                end)
            end
        end)
        
        Creator.AddSignal(Window.TitleBar.Frame.InputChanged, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                DragInput = Input
            end
        end)
        
        Creator.AddSignal(ResizeStartFrame.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Resizing, ResizePos = true, Input.Position
            end
        end)
        
        Creator.AddSignal(UserInputService.InputChanged, function(Input)
            if Input == DragInput and Dragging then
                local Delta = Input.Position - MousePos
                local NewX = StartPos.X.Offset + Delta.X
                local NewY = StartPos.Y.Offset + Delta.Y
                local Viewport = Camera.ViewportSize
                local WindowSize = Window.Root.Size
                NewX = math.clamp(NewX, 0, Viewport.X - WindowSize.X.Offset)
                NewY = math.clamp(NewY, 0, Viewport.Y - WindowSize.Y.Offset)
                Window.Position = UDim2.fromOffset(NewX, NewY)
                PosMotor:setGoal({
                    X = Instant(NewX),
                    Y = Instant(NewY),
                })
                if Window.Maximized then
                    Window.Maximize(false, true, true)
                end
            end
            if (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) and Resizing then
                local Delta = Input.Position - ResizePos
                local StartSize = Window.Size
                local TargetSize = Vector3.new(StartSize.X.Offset, StartSize.Y.Offset, 0) + Vector3.new(1, 1, 0) * Delta
                SizeMotor:setGoal({
                    X = Flipper.Instant.new(TargetSize.X),
                    Y = Flipper.Instant.new(TargetSize.Y)
                })
            end
        end)
        
        Creator.AddSignal(UserInputService.InputEnded, function(Input)
            if Resizing == true or Input.UserInputType == Enum.UserInputType.Touch then
                Resizing = false
                Window.Size = UDim2.fromOffset(SizeMotor:getValue().X, SizeMotor:getValue().Y)
            end
        end)
        
        Creator.AddSignal(Window.TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            Window.TabHolder.CanvasSize = UDim2.new(0, 0, 0, Window.TabHolder.UIListLayout.AbsoluteContentSize.Y)
        end)
        
        Creator.AddSignal(UserInputService.InputBegan, function(Input)
            if type(Library.MinimizeKeybind) == "table" and Library.MinimizeKeybind.Type == "Keybind" and not UserInputService:GetFocusedTextBox() then
                if Input.KeyCode.Name == Library.MinimizeKeybind.Value then
                    Window:Minimize()
                end
            elseif Input.KeyCode == Library.MinimizeKey and not UserInputService:GetFocusedTextBox() then
                Window:Minimize()
            end
        end)
        
        function Window:Minimize()
            Window.Minimized = not Window.Minimized
            Window.Root.Visible = not Window.Minimized
            
            if Window.Minimized then
                OpenMotor:setGoal(Spring(0, {
                    frequency = 6,
                    dampingRatio = 0.9
                })) 
            else
                OpenMotor:setGoal(Spring(1, {
                    frequency = 6,
                    dampingRatio = 0.9
                })) 
            end

            if Window.ToggleButton then
                if Window.Minimized then
                    Window.ToggleButton.Visible = true
                else
                    Window.ToggleButton.Visible = not Window.Maximized
                end
            end
            if not MinimizeNotif then
                MinimizeNotif = true
            end
        end
        
        function Window:Destroy()
            if Library.UseAcrylic then
                Window.AcrylicPaint.Model:Destroy()
            end
            Window.Root:Destroy()
        end
        
        local DialogModule = Components.Dialog:Init(Window)
        function Window:Dialog(Config)
            local Dialog = DialogModule:Create()
            Dialog.Title.Text = Config.Title
            local Content = New("TextLabel", {
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                Text = Config.Content,
                TextColor3 = Color3.fromRGB(240, 240, 240),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                Size = UDim2.new(1, - 40, 1, 0),
                Position = UDim2.fromOffset(20, 60),
                BackgroundTransparency = 1,
                Parent = Dialog.Root,
                ClipsDescendants = false,
                ThemeTag = {
                    TextColor3 = "Text"
                },
            })
            New("UISizeConstraint", {
                MinSize = Vector2.new(300, 165),
                MaxSize = Vector2.new(620, math.huge),
                Parent = Dialog.Root,
            })
            Dialog.Root.Size = UDim2.fromOffset(Content.TextBounds.X + 40, 165)
            if Content.TextBounds.X + 40 > Window.Size.X.Offset - 120 then
                Dialog.Root.Size = UDim2.fromOffset(Window.Size.X.Offset - 120, 165)
                Content.TextWrapped = true
                Dialog.Root.Size = UDim2.fromOffset(Window.Size.X.Offset - 120, Content.TextBounds.Y + 150)
            end
            for _, Button in next, Config.Buttons do
                Dialog:Button(Button.Title, Button.Callback)
            end
            Dialog:Open()
        end
        
        local TabModule = Components.Tab:Init(Window)
        function Window:AddTab(TabConfig)
            return TabModule:New(TabConfig.Title, TabConfig.Icon, Window.TabHolder)
        end
        function Window:SelectTab(Tab)
            TabModule:SelectTab(Tab)
        end
        
        Creator.AddSignal(Window.TabHolder:GetPropertyChangedSignal("CanvasPosition"), function()
            Window.SelectorPosMotor:setGoal(Instant(TabModule:GetCurrentTabPos()))
        end)
        
        local SearchModal = {
            Visible = false,
            Results = {}
        }

        local SearchWrapper = New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = Window.Root,
            ZIndex = 200
        })

        local SearchOverlay = New("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1, 
            Text = "",
            AutoButtonColor = false,
            Parent = SearchWrapper,
            ZIndex = 201 
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(0, 10)
            })
        })

        local SearchContainer = New("Frame", {
            Size = UDim2.fromOffset(360, 38),
            AnchorPoint = Vector2.new(0.5, 0), 
            Position = UDim2.fromScale(0.5, 0.15),
            BackgroundColor3 = Color3.fromRGB(25, 25, 30),
            BackgroundTransparency = 0.2,
            Parent = SearchWrapper,
            ZIndex = 205,
            ClipsDescendants = true 
        })

        local SearchGradient = New("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 35)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 25))
            }),
            Rotation = 45,
            Parent = SearchContainer
        })

        New("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = SearchContainer
        })
        
        local ContainerStroke = New("UIStroke", {
            Transparency = 0.6,
            Thickness = 1,
            Color = Color3.fromRGB(255, 255, 255),
            Parent = SearchContainer
        })
        
        local SearchIcon = New("ImageLabel", {
            Size = UDim2.fromOffset(16, 16),
            Position = UDim2.fromOffset(12, 11),
            BackgroundTransparency = 1,
            Image = "rbxassetid://6031154871",
            ImageColor3 = Color3.fromRGB(200, 200, 200),
            Parent = SearchContainer,
            ZIndex = 210
        })

        local SearchCloseBtn = New("ImageButton", {
            Size = UDim2.fromOffset(18, 18), 
            Position = UDim2.new(1, - 30, 0, 10), 
            BackgroundTransparency = 1,
            Image = "rbxassetid://10747384394", 
            ImageColor3 = Color3.fromRGB(200, 200, 200),
            Parent = SearchContainer,
            ZIndex = 210,
        })

        local SearchBox = New("TextBox", {
            Size = UDim2.new(1, - 70, 0, 38), 
            Position = UDim2.fromOffset(38, 0), 
            BackgroundTransparency = 1,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            PlaceholderText = "Type to search...",
            PlaceholderColor3 = Color3.fromRGB(150, 150, 160),
            TextSize = 14,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = SearchContainer,
            ClearTextOnFocus = false,
            ZIndex = 210
        })

        local SearchResults = New("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, - 40),
            Position = UDim2.fromOffset(0, 40),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90),
            Parent = SearchContainer,
            ZIndex = 210,
        }, {
            New("UIListLayout", {
                Padding = UDim.new(0, 4)
            }),
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8)
            })
        })
        
        New("Frame", {
            Size = UDim2.new(1, -32, 0, 1),
            Position = UDim2.new(0, 16, 0, 38),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.9,
            Parent = SearchContainer,
            ZIndex = 206
        })

        local OverlayMotor = Flipper.SingleMotor.new(1)
        local HeightMotor = Flipper.SingleMotor.new(38)

        OverlayMotor:onStep(function(v)
            SearchOverlay.BackgroundTransparency = 0.4 + (v * 0.6) 
            SearchContainer.BackgroundTransparency = 0.2 + (v * 0.8) 
            ContainerStroke.Transparency = 0.6 + (v * 0.4)
            SearchBox.TextTransparency = v
            SearchIcon.ImageTransparency = v
            SearchCloseBtn.ImageTransparency = v
            
            SearchContainer.Position = UDim2.fromScale(0.5, 0.23 - (v * 0.08))
        end)
        
        HeightMotor:onStep(function(v)
            SearchContainer.Size = UDim2.fromOffset(360, v)
        end)
        
        local function CloseSearch()
            SearchModal.Visible = false
            SearchBox:ReleaseFocus()
            SearchWrapper.Visible = false
            OverlayMotor:setGoal(Instant(1))
            HeightMotor:setGoal(Instant(38))
        end

        local function OpenSearch()
            if SearchModal.Visible then return end
            SearchModal.Visible = true
            SearchWrapper.Visible = true
            SearchBox.Text = ""
            
            for _, v in pairs(SearchResults:GetChildren()) do
                if v:IsA("TextButton") or v:IsA("Frame") then v:Destroy() end
            end
            
            OverlayMotor:setGoal(Spring(0, {frequency = 5, dampingRatio = 0.8})) 
            HeightMotor:setGoal(Instant(38))
            SearchBox:CaptureFocus()
        end

        Window.TitleBar.SearchButton:SetCallback(function()
            if not SearchModal.Visible then OpenSearch() end
        end)

        SearchCloseBtn.MouseButton1Click:Connect(CloseSearch)

        local function GetDeepText(element)
            local foundText = ""
            local labelHolder = element:FindFirstChild("LabelHolder")
            if labelHolder then
                for _, child in pairs(labelHolder:GetDescendants()) do
                    if child:IsA("TextLabel") then foundText = foundText .. " " .. child.Text end
                end
            end
            if foundText == "" then
                for _, child in pairs(element:GetDescendants()) do
                    if child:IsA("TextLabel") then foundText = foundText .. " " .. child.Text end
                end
            end
            return string.lower(foundText)
        end

        local function UpdateSearch(text)
            for _, v in pairs(SearchResults:GetChildren()) do
                if v:IsA("TextButton") or v:IsA("Frame") then v:Destroy() end
            end

            if text == "" then 
                HeightMotor:setGoal(Instant(38))
                return 
            end
            
            text = text:lower()
            local matches = 0

            for tabIndex, tabObj in pairs(Components.Tab.Tabs) do
                local container = Components.Tab.Containers[tabIndex]
                
                for _, elementFrame in pairs(container:GetChildren()) do
                    if elementFrame:IsA("TextButton") or elementFrame:IsA("Frame") then
                        local content = GetDeepText(elementFrame)
                        
                        if string.find(content, text, 1, true) then
                            matches = matches + 1
                            
                            local title = "Unknown Feature"
                            local labelHolder = elementFrame:FindFirstChild("LabelHolder")
                            if labelHolder and labelHolder:FindFirstChild("TitleLabel") then
                                title = labelHolder.TitleLabel.Text
                            else
                                for _, descendant in ipairs(elementFrame:GetDescendants()) do
                                    if descendant:IsA("TextLabel") and descendant.Name == "TitleLabel" then
                                        title = descendant.Text; break
                                    end
                                end
                                if title == "Unknown Feature" then
                                    for _, descendant in ipairs(elementFrame:GetDescendants()) do
                                        if descendant:IsA("TextLabel") and descendant.Text ~= "" and string.len(descendant.Text) < 50 then
                                            title = descendant.Text; break
                                        end
                                    end
                                end
                            end

                            local resBtn = New("TextButton", {
                                Size = UDim2.new(1, 0, 0, 36),
                                BackgroundColor3 = Color3.fromRGB(40, 40, 45),
                                BackgroundTransparency = 0.5,
                                Text = "",
                                Parent = SearchResults,
                                ZIndex = 215,
                                AutoButtonColor = false,
                            }, {
                                New("UICorner", { CornerRadius = UDim.new(0, 6) }),
                                New("UIStroke", {
                                    Color = Color3.fromRGB(80, 80, 90),
                                    Thickness = 1,
                                    Transparency = 0.7
                                }),
                                New("TextLabel", {
                                    Text = title,
                                    Font = Enum.Font.GothamBold,
                                    TextSize = 13,
                                    TextColor3 = Color3.fromRGB(240, 240, 240),
                                    Position = UDim2.new(0, 10, 0, 0),
                                    Size = UDim2.new(1, - 10, 1, 0),
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    BackgroundTransparency = 1,
                                    ZIndex = 216,
                                }),
                                New("TextLabel", {
                                    Text = tabObj.Name,
                                    Font = Enum.Font.Gotham,
                                    TextSize = 10,
                                    TextColor3 = Color3.fromRGB(180, 180, 180),
                                    Position = UDim2.new(1, - 10, 0, 0),
                                    Size = UDim2.new(0, 0, 1, 0),
                                    TextXAlignment = Enum.TextXAlignment.Right,
                                    BackgroundTransparency = 1,
                                    ZIndex = 216,
                                })
                            })
                            
                            resBtn.MouseEnter:Connect(function()
                                game.TweenService:Create(resBtn, TweenInfo.new(0.2), {
                                    BackgroundTransparency = 0.3,
                                    BackgroundColor3 = Color3.fromRGB(60, 60, 65)
                                }):Play()
                                game.TweenService:Create(resBtn.UIStroke, TweenInfo.new(0.2), {
                                    Transparency = 0.5,
                                    Color = Color3.fromRGB(200, 200, 200)
                                }):Play()
                            end)
                            
                            resBtn.MouseLeave:Connect(function()
                                game.TweenService:Create(resBtn, TweenInfo.new(0.2), {
                                    BackgroundTransparency = 0.5,
                                    BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                                }):Play()
                                game.TweenService:Create(resBtn.UIStroke, TweenInfo.new(0.2), {
                                    Transparency = 0.7,
                                    Color = Color3.fromRGB(80, 80, 90)
                                }):Play()
                            end)

                            resBtn.MouseButton1Click:Connect(function()
                                CloseSearch()
                                Window:SelectTab(tabIndex)
                                task.delay(0.1, function()
                                    local elemY = elementFrame.AbsolutePosition.Y
                                    local scrollY = container.AbsolutePosition.Y
                                    local currentCanvasY = container.CanvasPosition.Y
                                    local targetOffset = (elemY - scrollY) + currentCanvasY - 10
                                    
                                    local flash = New("Frame", {
                                        Size = UDim2.fromScale(1, 1),
                                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                        BackgroundTransparency = 0.6,
                                        Parent = elementFrame,
                                        ZIndex = 100
                                    }, { New("UICorner", { CornerRadius = UDim.new(0, 4) }) })
                                    
                                    game.TweenService:Create(container, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {
                                        CanvasPosition = Vector2.new(0, targetOffset)
                                    }):Play()

                                    game.TweenService:Create(flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
                                    game.Debris:AddItem(flash, 0.5)
                                end)
                            end)
                        end
                    end
                end
            end
            
            SearchResults.CanvasSize = UDim2.new(0, 0, 0, matches * 40)
            
            if matches == 0 then
                local noRes = New("TextLabel", {
                    Text = "No results found.",
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextColor3 = Color3.fromRGB(150, 150, 160),
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 1,
                    Parent = SearchResults,
                    ZIndex = 216,
                })
                HeightMotor:setGoal(Instant(80))
            else
                local targetHeight = 38 + math.min(matches * 40 + 8, 212)
                HeightMotor:setGoal(Instant(targetHeight))
            end
        end

        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            UpdateSearch(SearchBox.Text)
        end)
        
        SearchBox.FocusLost:Connect(function(enter)
            if enter then UpdateSearch(SearchBox.Text) end
        end)

        return Window
    end
end)()

local ElementsTable = {}
local AddSignal = Creator.AddSignal

ElementsTable.Button = (function()
    local Element = {}
    Element.__index = Element
    Element.__type = "Button"
    function Element:New(Config)
        if Library.Unloaded then
            return false
        end
        assert(Config.Title, "Button - Missing Title")
        Config.Callback = Config.Callback or function()
        end
        local ButtonFrame = Components.Element(Config.Title, Config.Description, self.Container, true, Config)
        local ButtonIco = New("ImageLabel", {
            Image = "rbxassetid://10734898355",
            Size = UDim2.fromOffset(16, 16),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, - 10, 0.5, 0),
            BackgroundTransparency = 1,
            Parent = ButtonFrame.Frame,
            ThemeTag = {
                ImageColor3 = "Text",
            },
        })
        Creator.AddSignal(ButtonFrame.Frame.MouseButton1Click, function()
            Library:SafeCallback(Config.Callback)
        end)
        return ButtonFrame
    end
    return Element
end)()
ElementsTable.Toggle = (function()
    local Element = {}
    Element.__index = Element
    Element.__type = "Toggle"
    function Element:New(Idx, Config)
        assert(Config.Title, "Toggle - Missing Title")
        local Toggle = {
            Value = Config.Default or false,
            Callback = Config.Callback or function(Value)
            end,
            Type = "Toggle",
        }
        local ToggleFrame = Components.Element(Config.Title, Config.Description, self.Container, true, Config)
        ToggleFrame.DescLabel.Size = UDim2.new(1, - 54, 0, 14)
        Toggle.SetTitle = ToggleFrame.SetTitle
        Toggle.SetDesc = ToggleFrame.SetDesc
        Toggle.Visible = ToggleFrame.Visible
        Toggle.Elements = ToggleFrame
        local ToggleCircle = New("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.fromOffset(14, 14),
            Position = UDim2.new(0, 2, 0.5, 0),
            Image = "http://www.roblox.com/asset/?id=12266946128",
            ImageTransparency = 0.5,
            ThemeTag = {
                ImageColor3 = "ToggleSlider",
            },
        })
        local ToggleBorder = New("UIStroke", {
            Transparency = 0.5,
            ThemeTag = {
                Color = "ToggleSlider",
            },
        })
        local ToggleSlider = New("Frame", {
            Size = UDim2.fromOffset(36, 18),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, - 10, 0.5, 0),
            Parent = ToggleFrame.Frame,
            BackgroundTransparency = 1,
            ThemeTag = {
                BackgroundColor3 = "Accent",
            },
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(0, 9),
            }),
            ToggleBorder,
            ToggleCircle,
        })
        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
            Func(Toggle.Value)
        end
        function Toggle:SetValue(Value)
            Value = not not Value
            Toggle.Value = Value
            Creator.OverrideTag(ToggleBorder, {
                Color = Toggle.Value and "Accent" or "ToggleSlider"
            })
            Creator.OverrideTag(ToggleCircle, {
                ImageColor3 = Toggle.Value and "ToggleToggled" or "ToggleSlider"
            })
            TweenService:Create(
				ToggleCircle, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, Toggle.Value and 19 or 2, 0.5, 0)
            }):Play()
            TweenService:Create(
				ToggleSlider, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                BackgroundTransparency = Toggle.Value and 0.45 or 1
            }):Play()
            ToggleCircle.ImageTransparency = Toggle.Value and 0 or 0.5
            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
        end
        function Toggle:Destroy()
            ToggleFrame:Destroy()
            Library.Options[Idx] = nil
        end
        Creator.AddSignal(ToggleFrame.Frame.MouseButton1Click, function()
            Toggle:SetValue(not Toggle.Value)
        end)
        Toggle:SetValue(Toggle.Value)
        Library.Options[Idx] = Toggle
        return Toggle
    end
    return Element
end)()
ElementsTable.Dropdown = (function()
    local Element = {}
    Element.__index = Element
    Element.__type = "Dropdown"
    function Element:New(Idx, Config)
        local Dropdown = {
            Values = Config.Values,
            Value = Config.Default,
            Multi = Config.Multi,
            Buttons = {},
            Opened = false,
            Type = "Dropdown",
            Callback = Config.Callback or function()
            end,
        }
        if Dropdown.Multi and Config.AllowNull then
            Dropdown.Value = {}
        end
        local DropdownFrame = Components.Element(Config.Title, Config.Description, self.Container, false, Config)
        DropdownFrame.DescLabel.Size = UDim2.new(1, - 170, 0, 14)
        Dropdown.SetTitle = DropdownFrame.SetTitle
        Dropdown.SetDesc = DropdownFrame.SetDesc
        Dropdown.Visible = DropdownFrame.Visible
        Dropdown.Elements = DropdownFrame
        
        local DropdownDisplay = New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            Text = "Value",
            TextColor3 = Color3.fromRGB(240, 240, 240),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, - 30, 0, 14),
            Position = UDim2.new(0, 8, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ThemeTag = {
                TextColor3 = "Text"
            },
        })
        local DropdownIco = New("ImageLabel", {
            Image = "rbxassetid://10709790948",
            Size = UDim2.fromOffset(16, 16),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, - 8, 0.5, 0),
            BackgroundTransparency = 1,
            ThemeTag = {
                ImageColor3 = "SubText"
            },
        })
        local DropdownInner = New("TextButton", {
            Size = UDim2.fromOffset(160, 30),
            Position = UDim2.new(1, - 10, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 0.9,
            Parent = DropdownFrame.Frame,
            ThemeTag = {
                BackgroundColor3 = "DropdownFrame"
            },
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(0, 5)
            }),
            New("UIStroke", {
                Transparency = 0.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                ThemeTag = {
                    Color = "InElementBorder"
                },
            }),
            DropdownIco,
            DropdownDisplay,
        })
        
        local DropdownListLayout = New("UIListLayout", {
            Padding = UDim.new(0, 3)
        })
        
        local DropdownScrollFrame = New("ScrollingFrame", {
            Size = UDim2.new(1, - 5, 1, - 10),
            Position = UDim2.fromOffset(5, 5),
            BackgroundTransparency = 1,
            BottomImage = "rbxassetid://6889812791",
            MidImage = "rbxassetid://6889812721",
            TopImage = "rbxassetid://6276641225",
            ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
            ScrollBarImageTransparency = 0.75,
            ScrollBarThickness = 0,
            BorderSizePixel = 0,
            CanvasSize = UDim2.fromScale(0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y,
        }, {
            DropdownListLayout
        })

        local DropdownHolderFrame = New("Frame", {
            Size = UDim2.fromScale(1, 0.6),
            ThemeTag = {
                BackgroundColor3 = "DropdownHolder"
            },
        }, {
            DropdownScrollFrame,
            New("UICorner", {
                CornerRadius = UDim.new(0, 7)
            }),
            New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                ThemeTag = {
                    Color = "DropdownBorder"
                }
            }),
            New("ImageLabel", {
                BackgroundTransparency = 1,
                Image = "http://www.roblox.com/asset/?id=5554236805",
                ScaleType = Enum.ScaleType.Slice,
                SliceCenter = Rect.new(23, 23, 277, 277),
                Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(30, 30),
                Position = UDim2.fromOffset(- 15, - 15),
                ImageColor3 = Color3.fromRGB(0, 0, 0),
                ImageTransparency = 0.1,
            }),
        })

        local DropdownHolderCanvas = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(170, 300),
            Parent = Library.GUI,
            Visible = false,
            ZIndex = 999
        }, {
            DropdownHolderFrame,
            New("UISizeConstraint", {
                MinSize = Vector2.new(170, 0)
            }),
        })
        table.insert(Library.OpenFrames, DropdownHolderCanvas)

        local function RecalculateListPositionAndSize()
            local MainGUI = Library.GUI
            if not MainGUI then return end

            local btnPos = DropdownInner.AbsolutePosition
            
            local boxWidth = 170
            local padding = 5
            
            local listX = btnPos.X - boxWidth - padding
            local listY = btnPos.Y 
            
            local windowBottom = MainGUI.AbsolutePosition.Y + MainGUI.AbsoluteSize.Y
            local spaceBelow = windowBottom - listY - 5
            
            local contentHeight = DropdownListLayout.AbsoluteContentSize.Y + 10
            
            local finalHeight = contentHeight
            if finalHeight > spaceBelow then
                finalHeight = math.max(spaceBelow, 50)
            end

            DropdownHolderCanvas.Position = UDim2.fromOffset(listX, listY)
            DropdownHolderFrame.Size = UDim2.new(1, 0, 0, finalHeight)
            
            DropdownScrollFrame.CanvasSize = UDim2.fromOffset(0, DropdownListLayout.AbsoluteContentSize.Y)
        end

        function Dropdown:GetActiveValues()
            if self.Multi then
                local count = 0
                for _, v in pairs(self.Value) do
                    if v then
                        count = count + 1
                    end
                end
                return count
            else
                return self.Value and 1 or 0
            end
        end

        Creator.AddSignal(DropdownInner:GetPropertyChangedSignal("AbsolutePosition"), RecalculateListPositionAndSize)
        Creator.AddSignal(DropdownInner.MouseButton1Click, function()
            Dropdown:Open()
        end)
        
        Creator.AddSignal(UserInputService.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local AbsPos, AbsSize = DropdownHolderFrame.AbsolutePosition, DropdownHolderFrame.AbsoluteSize
                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then
                    Dropdown:Close()
                end
            end
        end)

        local ScrollFrame = self.ScrollFrame
        function Dropdown:Open()
            if Library.CurrentOpenDropdown and Library.CurrentOpenDropdown ~= Dropdown then
                Library.CurrentOpenDropdown:Close()
            end
            Library.CurrentOpenDropdown = Dropdown
            Dropdown.Opened = true
            ScrollFrame.ScrollingEnabled = false
            DropdownHolderCanvas.Visible = true
            task.defer(RecalculateListPositionAndSize)
        end

        function Dropdown:Close()
            if Library.CurrentOpenDropdown == Dropdown then
                Library.CurrentOpenDropdown = nil
            end
            Dropdown.Opened = false
            ScrollFrame.ScrollingEnabled = true
            DropdownHolderCanvas.Visible = false
        end

        function Dropdown:Display()
            local Values = Dropdown.Values
            local Str = ""
            if Config.Multi then
                for _, Value in next, Values do
                    if Dropdown.Value[Value] then
                        Str = Str .. Value .. ", "
                    end
                end
                Str = Str:sub(1, # Str - 2)
            else
                Str = Dropdown.Value or ""
            end
            DropdownDisplay.Text = (Str == "" and "---" or Str)
        end

        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values
            local Buttons = {}
            for _, Element in next, DropdownScrollFrame:GetChildren() do
                if not Element:IsA("UIListLayout") then
                    Element:Destroy()
                end
            end
            for _, Value in next, Values do
                local Table = {}
                local ButtonLabel = New("TextLabel", {
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
                    Text = Value,
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 10, 0.5, 0),
                    Name = "ButtonLabel",
                    ThemeTag = {
                        TextColor3 = "Text"
                    }
                })
                local ButtonSelector = New("Frame", {
                    Size = UDim2.fromOffset(4, 20),
                    BackgroundColor3 = Color3.fromRGB(76, 194, 255),
                    Position = UDim2.new(0, - 1, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Visible = false,
                    ThemeTag = {
                        BackgroundColor3 = "Accent"
                    }
                }, {
                    New("UICorner", {
                        CornerRadius = UDim.new(0, 2)
                    })
                })
                local Button = New("TextButton", {
                    Size = UDim2.new(1, - 5, 0, 32),
                    BackgroundTransparency = 1,
                    ZIndex = 23,
                    Text = "",
                    Parent = DropdownScrollFrame,
                    ThemeTag = {
                        BackgroundColor3 = "DropdownOption"
                    }
                }, {
                    ButtonSelector,
                    ButtonLabel
                })
                local Selected = Config.Multi and Dropdown.Value[Value] or Dropdown.Value == Value
                function Table:UpdateButton()
                    Selected = Config.Multi and Dropdown.Value[Value] or Dropdown.Value == Value
                    ButtonSelector.Visible = Selected
                end
                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        local Try = not Selected
                        if Dropdown:GetActiveValues() == 1 and not Try and not Config.AllowNull then
                            return
                        end
                        if Config.Multi then
                            Dropdown.Value[Value] = Try and true or nil
                        else
                            Dropdown.Value = Try and Value or nil
                            for _, OtherButton in next, Buttons do
                                OtherButton:UpdateButton()
                            end
                        end
                        Table:UpdateButton()
                        Dropdown:Display()
                        Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                        Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                    end
                end)
                Table:UpdateButton()
                Dropdown:Display()
                Buttons[Button] = Table
            end
            
            DropdownHolderCanvas.Size = UDim2.fromOffset(170, DropdownHolderCanvas.Size.Y.Offset)
            
            task.defer(RecalculateListPositionAndSize)
        end
        function Dropdown:SetValues(NewValues)
            if NewValues then
                Dropdown.Values = NewValues
            end
            Dropdown:BuildDropdownList()
        end
        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func
            Func(Dropdown.Value)
        end
        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local nTable = {}
                for Value, Bool in next, Val do
                    if table.find(Dropdown.Values, Value) then
                        nTable[Value] = true
                    end
                end
                Dropdown.Value = nTable
            else
                if not Val then
                    Dropdown.Value = nil
                elseif table.find(Dropdown.Values, Val) then
                    Dropdown.Value = Val
                end
            end
            Dropdown:BuildDropdownList()
            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
        end
        function Dropdown:Destroy()
            DropdownFrame:Destroy()
            Library.Options[Idx] = nil
        end
        Dropdown:BuildDropdownList()
        Dropdown:Display()
        Library.Options[Idx] = Dropdown
        return Dropdown
    end
    return Element
end)()

ElementsTable.Paragraph = (function()
    local Paragraph = {}
    Paragraph.__index = Paragraph
    Paragraph.__type = "Paragraph"
    function Paragraph:New(Config)
        if Library.Unloaded then
            return false
        end
        assert(Config.Title, "Paragraph - Missing Title")
        Config.Content = Config.Content or ""
        local Paragraph = Components.Element(Config.Title, Config.Content, Paragraph.Container, false, Config)
        Paragraph.Frame.BackgroundTransparency = 0
        Paragraph.Border.Transparency = 0.6
        Paragraph.SetTitle = Paragraph.SetTitle
        Paragraph.SetDesc = Paragraph.SetDesc
        Paragraph.Visible = Paragraph.Visible
        Paragraph.Elements = Paragraph
        return Paragraph
    end
    return Paragraph
end)()
ElementsTable.Slider = (function()
    local Element = {}
    Element.__index = Element
    Element.__type = "Slider"
    function Element:New(Idx, Config)
        if Library.Unloaded then
            return false
        end
        assert(Config.Title, "Slider - Missing Title.")
        assert(Config.Default, "Slider - Missing default value.")
        assert(Config.Min, "Slider - Missing minimum value.")
        assert(Config.Max, "Slider - Missing maximum value.")
        assert(Config.Rounding, "Slider - Missing rounding value.")
        local Slider = {
            Value = nil,
            Min = Config.Min,
            Max = Config.Max,
            Rounding = Config.Rounding,
            Callback = Config.Callback or function(Value)
            end,
            Type = "Slider",
        }
        local Dragging = false
        local SliderFrame = Components.Element(Config.Title, Config.Description, self.Container, false, Config)
        SliderFrame.DescLabel.Size = UDim2.new(1, - 170, 0, 14)
        Slider.Elements = SliderFrame
        Slider.SetTitle = SliderFrame.SetTitle
        Slider.SetDesc = SliderFrame.SetDesc
        Slider.Visible = SliderFrame.Visible
        local SliderDot = New("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, - 7, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            Image = "http://www.roblox.com/asset/?id=12266946128",
            ThemeTag = {
                ImageColor3 = "Accent",
            },
        })
        local SliderRail = New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(7, 0),
            Size = UDim2.new(1, - 14, 1, 0),
        }, {
            SliderDot,
        })
        local SliderFill = New("Frame", {
            Size = UDim2.new(0, 0, 1, 0),
            ThemeTag = {
                BackgroundColor3 = "Accent",
            },
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(1, 0),
            }),
        })
        local SliderDisplay = New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            Text = "Value",
            TextSize = 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Right,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 100, 0, 14),
            Position = UDim2.new(0, - 4, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            ThemeTag = {
                TextColor3 = "SubText",
            },
        })
        local SliderInner = New("Frame", {
            Size = UDim2.new(1, 0, 0, 4),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, - 10, 0.5, 0),
            BackgroundTransparency = 0,
            Parent = SliderFrame.Frame,
            ThemeTag = {
                BackgroundColor3 = "SliderRail",
            },
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(1, 0),
            }),
            New("UISizeConstraint", {
                MaxSize = Vector2.new(150, math.huge),
            }),
            SliderDisplay,
            SliderFill,
            SliderRail,
        })
        Creator.AddSignal(SliderDot.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
            end
        end)
        Creator.AddSignal(SliderDot.InputEnded, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false
            end
        end)
        Creator.AddSignal(UserInputService.InputChanged, function(Input)
            if Dragging and (
					Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
                local SizeScale = math.clamp((Input.Position.X - SliderRail.AbsolutePosition.X) / SliderRail.AbsoluteSize.X, 0, 1)
                Slider:SetValue(Slider.Min + ((Slider.Max - Slider.Min) * SizeScale))
            end
        end)
        function Slider:OnChanged(Func)
            Slider.Changed = Func
            Func(Slider.Value)
        end
        function Slider:SetValue(Value)
            self.Value = Library:Round(math.clamp(Value, Slider.Min, Slider.Max), Slider.Rounding)
            SliderDot.Position = UDim2.new((self.Value - Slider.Min) / (Slider.Max - Slider.Min), - 7, 0.5, 0)
            SliderFill.Size = UDim2.fromScale((self.Value - Slider.Min) / (Slider.Max - Slider.Min), 1)
            SliderDisplay.Text = tostring(self.Value)
            Library:SafeCallback(Slider.Callback, self.Value)
            Library:SafeCallback(Slider.Changed, self.Value)
        end
        function Slider:Destroy()
            SliderFrame:Destroy()
            Library.Options[Idx] = nil
        end
        Slider:SetValue(Config.Default)
        Library.Options[Idx] = Slider
        return Slider
    end
    return Element
end)()
ElementsTable.Keybind = (function()
    local Element = {}
    Element.__index = Element
    Element.__type = "Keybind"
    function Element:New(Idx, Config)
        assert(Config.Title, "KeyBind - Missing Title")
        assert(Config.Default, "KeyBind - Missing default value.")
        local Keybind = {
            Value = Config.Default,
            Toggled = false,
            Mode = Config.Mode or "Toggle",
            Type = "Keybind",
            Callback = Config.Callback or function(Value)
            end,
            ChangedCallback = Config.ChangedCallback or function(New)
            end,
        }
        local Picking = false
        local KeybindFrame = Components.Element(Config.Title, Config.Description, self.Container, true)
        Keybind.SetTitle = KeybindFrame.SetTitle
        Keybind.SetDesc = KeybindFrame.SetDesc
        Keybind.Visible = KeybindFrame.Visible
        Keybind.Elements = KeybindFrame
        local KeybindDisplayLabel = New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            Text = Config.Default,
            TextColor3 = Color3.fromRGB(240, 240, 240),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.new(0, 0, 0, 14),
            Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            ThemeTag = {
                TextColor3 = "Text",
            },
        })
        local KeybindDisplayFrame = New("TextButton", {
            Size = UDim2.fromOffset(0, 30),
            Position = UDim2.new(1, - 10, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 0,
            Parent = KeybindFrame.Frame,
            AutomaticSize = Enum.AutomaticSize.X,
            ThemeTag = {
                BackgroundColor3 = "Keybind",
            },
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(0, 5),
            }),
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
            }),
            New("UIStroke", {
                Transparency = 0.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                ThemeTag = {
                    Color = "InElementBorder",
                },
            }),
            KeybindDisplayLabel,
        })
        function Keybind:GetState()
            if UserInputService:GetFocusedTextBox() and Keybind.Mode ~= "Always" then
                return false
            end
            if Keybind.Mode == "Always" then
                return true
            elseif Keybind.Mode == "Hold" then
                if Keybind.Value == "None" then
                    return false
                end
                local Key = Keybind.Value
                if Key == "MouseLeft" or Key == "MouseRight" then
                    return Key == "MouseLeft" and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or Key == "MouseRight" and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                else
                    return UserInputService:IsKeyDown(Enum.KeyCode[Keybind.Value])
                end
            else
                return Keybind.Toggled
            end
        end
        function Keybind:SetValue(Key, Mode)
            Key = Key or Keybind.Key
            Mode = Mode or Keybind.Mode
            KeybindDisplayLabel.Text = Key
            Keybind.Value = Key
            Keybind.Mode = Mode
        end
        function Keybind:OnClick(Callback)
            Keybind.Clicked = Callback
        end
        function Keybind:OnChanged(Callback)
            Keybind.Changed = Callback
            Callback(Keybind.Value)
        end
        function Keybind:DoClick()
            Library:SafeCallback(Keybind.Callback, Keybind.Toggled)
            Library:SafeCallback(Keybind.Clicked, Keybind.Toggled)
        end
        function Keybind:Destroy()
            KeybindFrame:Destroy()
            Library.Options[Idx] = nil
        end
        Creator.AddSignal(KeybindDisplayFrame.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Picking = true
                KeybindDisplayLabel.Text = "..."
                wait(0.2)
                local Event
                Event = UserInputService.InputBegan:Connect(function(Input)
                    local Key
                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        Key = Input.KeyCode.Name
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Key = "MouseLeft"
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                        Key = "MouseRight"
                    end
                    local EndedEvent
                    EndedEvent = UserInputService.InputEnded:Connect(function(Input)
                        if Input.KeyCode.Name == Key or Key == "MouseLeft" and Input.UserInputType == Enum.UserInputType.MouseButton1 or Key == "MouseRight" and Input.UserInputType == Enum.UserInputType.MouseButton2 then
                            Picking = false
                            KeybindDisplayLabel.Text = Key
                            Keybind.Value = Key
                            Library:SafeCallback(Keybind.ChangedCallback, Input.KeyCode or Input.UserInputType)
                            Library:SafeCallback(Keybind.Changed, Input.KeyCode or Input.UserInputType)
                            Event:Disconnect()
                            EndedEvent:Disconnect()
                        end
                    end)
                end)
            end
        end)
        Creator.AddSignal(UserInputService.InputBegan, function(Input)
            if not Picking and not UserInputService:GetFocusedTextBox() then
                if Keybind.Mode == "Toggle" then
                    local Key = Keybind.Value
                    if Key == "MouseLeft" or Key == "MouseRight" then
                        if Key == "MouseLeft" and Input.UserInputType == Enum.UserInputType.MouseButton1 or Key == "MouseRight" and Input.UserInputType == Enum.UserInputType.MouseButton2 then
                            Keybind.Toggled = not Keybind.Toggled
                            Keybind:DoClick()
                        end
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            Keybind.Toggled = not Keybind.Toggled
                            Keybind:DoClick()
                        end
                    end
                end
            end
        end)
        Library.Options[Idx] = Keybind
        return Keybind
    end
    return Element
end)()
ElementsTable.Colorpicker = (function()
    local Element = {}
    Element.__index = Element
    Element.__type = "Colorpicker"
    function Element:New(Idx, Config)
        assert(Config.Title, "Colorpicker - Missing Title")
        assert(Config.Default, "AddColorPicker: Missing default value.")
        local Colorpicker = {
            Value = Config.Default,
            Transparency = Config.Transparency or 0,
            Type = "Colorpicker",
            Title = type(Config.Title) == "string" and Config.Title or "Colorpicker",
            Callback = Config.Callback or function(Color)
            end,
        }
        function Colorpicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color)
            Colorpicker.Hue = H
            Colorpicker.Sat = S
            Colorpicker.Vib = V
        end
        Colorpicker:SetHSVFromRGB(Colorpicker.Value)
        local ColorpickerFrame = Components.Element(Config.Title, Config.Description, self.Container, true)
        Colorpicker.SetTitle = ColorpickerFrame.SetTitle
        Colorpicker.SetDesc = ColorpickerFrame.SetDesc
        Colorpicker.Visible = ColorpickerFrame.Visible
        Colorpicker.Elements = ColorpickerFrame
        local DisplayFrameColor = New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Colorpicker.Value,
            Parent = ColorpickerFrame.Frame,
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(0, 4),
            }),
        })
        local DisplayFrame = New("ImageLabel", {
            Size = UDim2.fromOffset(26, 26),
            Position = UDim2.new(1, - 10, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            Parent = ColorpickerFrame.Frame,
            Image = "http://www.roblox.com/asset/?id=14204231522",
            ImageTransparency = 0.45,
            ScaleType = Enum.ScaleType.Tile,
            TileSize = UDim2.fromOffset(40, 40),
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(0, 4),
            }),
            DisplayFrameColor,
        })
        local function CreateColorDialog()
            local Dialog = Components.Dialog:Create()
            Dialog.Title.Text = Colorpicker.Title
            Dialog.Root.Size = UDim2.fromOffset(430, 330)
            local Hue, Sat, Vib = Colorpicker.Hue, Colorpicker.Sat, Colorpicker.Vib
            local Transparency = Colorpicker.Transparency
            local function CreateInput()
                local Box = Components.Textbox()
                Box.Frame.Parent = Dialog.Root
                Box.Frame.Size = UDim2.new(0, 90, 0, 32)
                return Box
            end
            local function CreateInputLabel(Text, Pos)
                return New("TextLabel", {
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
                    Text = Text,
                    TextColor3 = Color3.fromRGB(240, 240, 240),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, 0, 0, 32),
                    Position = Pos,
                    BackgroundTransparency = 1,
                    Parent = Dialog.Root,
                    ThemeTag = {
                        TextColor3 = "Text",
                    },
                })
            end
            local function GetRGB()
                local Value = Color3.fromHSV(Hue, Sat, Vib)
                return {
                    R = math.floor(Value.r * 255),
                    G = math.floor(Value.g * 255),
                    B = math.floor(Value.b * 255)
                }
            end
            local SatCursor = New("ImageLabel", {
                Size = UDim2.new(0, 18, 0, 18),
                ScaleType = Enum.ScaleType.Fit,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = "http://www.roblox.com/asset/?id=4805639000",
            })
            local SatVibMap = New("ImageLabel", {
                Size = UDim2.fromOffset(180, 160),
                Position = UDim2.fromOffset(20, 55),
                Image = "rbxassetid://4155801252",
                BackgroundColor3 = Colorpicker.Value,
                BackgroundTransparency = 0,
                Parent = Dialog.Root,
            }, {
                New("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                }),
                SatCursor,
            })
            local OldColorFrame = New("Frame", {
                BackgroundColor3 = Colorpicker.Value,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = Colorpicker.Transparency,
            }, {
                New("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                }),
            })
            local OldColorFrameChecker = New("ImageLabel", {
                Image = "http://www.roblox.com/asset/?id=14204231522",
                ImageTransparency = 0.45,
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.fromOffset(40, 40),
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(112, 220),
                Size = UDim2.fromOffset(88, 24),
                Parent = Dialog.Root,
            }, {
                New("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                }),
                New("UIStroke", {
                    Thickness = 2,
                    Transparency = 0.75,
                }),
                OldColorFrame,
            })
            local DialogDisplayFrame = New("Frame", {
                BackgroundColor3 = Colorpicker.Value,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 0,
            }, {
                New("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                }),
            })
            local DialogDisplayFrameChecker = New("ImageLabel", {
                Image = "http://www.roblox.com/asset/?id=14204231522",
                ImageTransparency = 0.45,
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.fromOffset(40, 40),
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(20, 220),
                Size = UDim2.fromOffset(88, 24),
                Parent = Dialog.Root,
            }, {
                New("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                }),
                New("UIStroke", {
                    Thickness = 2,
                    Transparency = 0.75,
                }),
                DialogDisplayFrame,
            })
            local SequenceTable = {}
            for Color = 0, 1, 0.1 do
                table.insert(SequenceTable, ColorSequenceKeypoint.new(Color, Color3.fromHSV(Color, 1, 1)))
            end
            local HueSliderGradient = New("UIGradient", {
                Color = ColorSequence.new(SequenceTable),
                Rotation = 90,
            })
            local HueDragHolder = New("Frame", {
                Size = UDim2.new(1, 0, 1, - 10),
                Position = UDim2.fromOffset(0, 5),
                BackgroundTransparency = 1,
            })
            local HueDrag = New("ImageLabel", {
                Size = UDim2.fromOffset(14, 14),
                Image = "http://www.roblox.com/asset/?id=12266946128",
                Parent = HueDragHolder,
                ThemeTag = {
                    ImageColor3 = "DialogInput",
                },
            })
            local HueSlider = New("Frame", {
                Size = UDim2.fromOffset(12, 190),
                Position = UDim2.fromOffset(210, 55),
                Parent = Dialog.Root,
            }, {
                New("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                }),
                HueSliderGradient,
                HueDragHolder,
            })
            local HexInput = CreateInput()
            HexInput.Frame.Position = UDim2.fromOffset(Config.Transparency and 260 or 240, 55)
            CreateInputLabel("Hex", UDim2.fromOffset(Config.Transparency and 360 or 340, 55))
            local RedInput = CreateInput()
            RedInput.Frame.Position = UDim2.fromOffset(Config.Transparency and 260 or 240, 95)
            CreateInputLabel("Red", UDim2.fromOffset(Config.Transparency and 360 or 340, 95))
            local GreenInput = CreateInput()
            GreenInput.Frame.Position = UDim2.fromOffset(Config.Transparency and 260 or 240, 135)
            CreateInputLabel("Green", UDim2.fromOffset(Config.Transparency and 360 or 340, 135))
            local BlueInput = CreateInput()
            BlueInput.Frame.Position = UDim2.fromOffset(Config.Transparency and 260 or 240, 175)
            CreateInputLabel("Blue", UDim2.fromOffset(Config.Transparency and 360 or 340, 175))
            local AlphaInput
            if Config.Transparency then
                AlphaInput = CreateInput()
                AlphaInput.Frame.Position = UDim2.fromOffset(260, 215)
                CreateInputLabel("Alpha", UDim2.fromOffset(360, 215))
            end
            local TransparencySlider, TransparencyDrag, TransparencyColor
            if Config.Transparency then
                local TransparencyDragHolder = New("Frame", {
                    Size = UDim2.new(1, 0, 1, - 10),
                    Position = UDim2.fromOffset(0, 5),
                    BackgroundTransparency = 1,
                })
                TransparencyDrag = New("ImageLabel", {
                    Size = UDim2.fromOffset(14, 14),
                    Image = "http://www.roblox.com/asset/?id=12266946128",
                    Parent = TransparencyDragHolder,
                    ThemeTag = {
                        ImageColor3 = "DialogInput",
                    },
                })
                TransparencyColor = New("Frame", {
                    Size = UDim2.fromScale(1, 1),
                }, {
                    New("UIGradient", {
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(1, 1),
                        }),
                        Rotation = 270,
                    }),
                    New("UICorner", {
                        CornerRadius = UDim.new(1, 0),
                    }),
                })
                TransparencySlider = New("Frame", {
                    Size = UDim2.fromOffset(12, 190),
                    Position = UDim2.fromOffset(230, 55),
                    Parent = Dialog.Root,
                    BackgroundTransparency = 1,
                }, {
                    New("UICorner", {
                        CornerRadius = UDim.new(1, 0),
                    }),
                    New("ImageLabel", {
                        Image = "http://www.roblox.com/asset/?id=14204231522",
                        ImageTransparency = 0.45,
                        ScaleType = Enum.ScaleType.Tile,
                        TileSize = UDim2.fromOffset(40, 40),
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 1),
                        Parent = Dialog.Root,
                    }, {
                        New("UICorner", {
                            CornerRadius = UDim.new(1, 0),
                        }),
                    }),
                    TransparencyColor,
                    TransparencyDragHolder,
                })
            end
            local function Display()
                SatVibMap.BackgroundColor3 = Color3.fromHSV(Hue, 1, 1)
                HueDrag.Position = UDim2.new(0, - 1, Hue, - 6)
                SatCursor.Position = UDim2.new(Sat, 0, 1 - Vib, 0)
                DialogDisplayFrame.BackgroundColor3 = Color3.fromHSV(Hue, Sat, Vib)
                HexInput.Input.Text = "#" .. Color3.fromHSV(Hue, Sat, Vib):ToHex()
                RedInput.Input.Text = GetRGB()["R"]
                GreenInput.Input.Text = GetRGB()["G"]
                BlueInput.Input.Text = GetRGB()["B"]
                if Config.Transparency then
                    TransparencyColor.BackgroundColor3 = Color3.fromHSV(Hue, Sat, Vib)
                    DialogDisplayFrame.BackgroundTransparency = Transparency
                    TransparencyDrag.Position = UDim2.new(0, - 1, 1 - Transparency, - 6)
                    AlphaInput.Input.Text = Library:Round((1 - Transparency) * 100, 0) .. "%"
                end
            end
            Creator.AddSignal(HexInput.Input.FocusLost, function(Enter)
                if Enter then
                    local Success, Result = pcall(Color3.fromHex, HexInput.Input.Text)
                    if Success and typeof(Result) == "Color3" then
                        Hue, Sat, Vib = Color3.toHSV(Result)
                    end
                end
                Display()
            end)
            Creator.AddSignal(RedInput.Input.FocusLost, function(Enter)
                if Enter then
                    local CurrentColor = GetRGB()
                    local Success, Result = pcall(Color3.fromRGB, RedInput.Input.Text, CurrentColor["G"], CurrentColor["B"])
                    if Success and typeof(Result) == "Color3" then
                        if tonumber(RedInput.Input.Text) <= 255 then
                            Hue, Sat, Vib = Color3.toHSV(Result)
                        end
                    end
                end
                Display()
            end)
            Creator.AddSignal(GreenInput.Input.FocusLost, function(Enter)
                if Enter then
                    local CurrentColor = GetRGB()
                    local Success, Result = pcall(Color3.fromRGB, CurrentColor["R"], GreenInput.Input.Text, CurrentColor["B"])
                    if Success and typeof(Result) == "Color3" then
                        if tonumber(GreenInput.Input.Text) <= 255 then
                            Hue, Sat, Vib = Color3.toHSV(Result)
                        end
                    end
                end
                Display()
            end)
            Creator.AddSignal(BlueInput.Input.FocusLost, function(Enter)
                if Enter then
                    local CurrentColor = GetRGB()
                    local Success, Result = pcall(Color3.fromRGB, CurrentColor["R"], CurrentColor["G"], BlueInput.Input.Text)
                    if Success and typeof(Result) == "Color3" then
                        if tonumber(BlueInput.Input.Text) <= 255 then
                            Hue, Sat, Vib = Color3.toHSV(Result)
                        end
                    end
                end
                Display()
            end)
            if Config.Transparency then
                Creator.AddSignal(AlphaInput.Input.FocusLost, function(Enter)
                    if Enter then
                        pcall(function()
                            local Value = tonumber(AlphaInput.Input.Text)
                            if Value >= 0 and Value <= 100 then
                                Transparency = 1 - Value * 0.01
                            end
                        end)
                    end
                    Display()
                end)
            end
            Creator.AddSignal(SatVibMap.InputBegan, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        local MinX = SatVibMap.AbsolutePosition.X
                        local MaxX = MinX + SatVibMap.AbsoluteSize.X
                        local MouseX = math.clamp(Mouse.X, MinX, MaxX)
                        local MinY = SatVibMap.AbsolutePosition.Y
                        local MaxY = MinY + SatVibMap.AbsoluteSize.Y
                        local MouseY = math.clamp(Mouse.Y, MinY, MaxY)
                        Sat = (MouseX - MinX) / (MaxX - MinX)
                        Vib = 1 - ((MouseY - MinY) / (MaxY - MinY))
                        Display()
                        RenderStepped:Wait()
                    end
                end
            end)
            Creator.AddSignal(HueSlider.InputBegan, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        local MinY = HueSlider.AbsolutePosition.Y
                        local MaxY = MinY + HueSlider.AbsoluteSize.Y
                        local MouseY = math.clamp(Mouse.Y, MinY, MaxY)
                        Hue = ((MouseY - MinY) / (MaxY - MinY))
                        Display()
                        RenderStepped:Wait()
                    end
                end
            end)
            if Config.Transparency then
                Creator.AddSignal(TransparencySlider.InputBegan, function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                            local MinY = TransparencySlider.AbsolutePosition.Y
                            local MaxY = MinY + TransparencySlider.AbsoluteSize.Y
                            local MouseY = math.clamp(Mouse.Y, MinY, MaxY)
                            Transparency = 1 - ((MouseY - MinY) / (MaxY - MinY))
                            Display()
                            RenderStepped:Wait()
                        end
                    end
                end)
            end
            Display()
            Dialog:Button("OK", function()
                Colorpicker:SetValue({
                    Hue,
                    Sat,
                    Vib
                }, Transparency)
            end)
            Dialog:Button("Cancel")
            Dialog:Open()
        end
        function Colorpicker:Display()
            Colorpicker.Value = Color3.fromHSV(Colorpicker.Hue, Colorpicker.Sat, Colorpicker.Vib)
            DisplayFrameColor.BackgroundColor3 = Colorpicker.Value
            DisplayFrameColor.BackgroundTransparency = Colorpicker.Transparency
            Element.Library:SafeCallback(Colorpicker.Callback, Colorpicker.Value)
            Element.Library:SafeCallback(Colorpicker.Changed, Colorpicker.Value)
        end
        function Colorpicker:SetValue(HSV, Transparency)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])
            Colorpicker.Transparency = Transparency or 0
            Colorpicker:SetHSVFromRGB(Color)
            Colorpicker:Display()
        end
        function Colorpicker:SetValueRGB(Color, Transparency)
            Colorpicker.Transparency = Transparency or 0
            Colorpicker:SetHSVFromRGB(Color)
            Colorpicker:Display()
        end
        function Colorpicker:OnChanged(Func)
            Colorpicker.Changed = Func
            Func(Colorpicker.Value)
        end
        function Colorpicker:Destroy()
            ColorpickerFrame:Destroy()
            Library.Options[Idx] = nil
        end
        Creator.AddSignal(ColorpickerFrame.Frame.MouseButton1Click, function()
            CreateColorDialog()
        end)
        Colorpicker:Display()
        Library.Options[Idx] = Colorpicker
        return Colorpicker
    end
    return Element
end)()
ElementsTable.Input = (function()
    local Element = {}
    Element.__index = Element
    Element.__type = "Input"
    function Element:New(Idx, Config)
        assert(Config.Title, "Input - Missing Title")
        Config.Callback = Config.Callback or function()
        end
        local Input = {
            Value = Config.Default or "",
            Numeric = Config.Numeric or false,
            Finished = Config.Finished or false,
            Callback = Config.Callback or function(Value)
            end,
            Type = "Input",
        }
        local InputFrame = Components.Element(Config.Title, Config.Description, self.Container, false)
        Input.SetTitle = InputFrame.SetTitle
        Input.SetDesc = InputFrame.SetDesc
        Input.Visible = InputFrame.Visible
        Input.Elements = InputFrame
        local Textbox = Components.Textbox(InputFrame.Frame, true)
        Textbox.Frame.Position = UDim2.new(1, - 10, 0.5, 0)
        Textbox.Frame.AnchorPoint = Vector2.new(1, 0.5)
        Textbox.Frame.Size = UDim2.fromOffset(160, 30)
        Textbox.Input.Text = Config.Default
        Textbox.Input.PlaceholderText = Config.Placeholder
        local Box = Textbox.Input
        function Input:SetValue(Text)
            if Config.MaxLength and # Text > Config.MaxLength then
                Text = Text:sub(1, Config.MaxLength)
            end
            if Input.Numeric then
                if (not tonumber(Text)) and Text:len() > 0 then
                    Text = Input.Value
                end
            end
            Input.Value = Text
            Box.Text = Text
            Library:SafeCallback(Input.Callback, Input.Value)
            Library:SafeCallback(Input.Changed, Input.Value)
        end
        if Input.Finished then
            AddSignal(Box.FocusLost, function(enter)
                if not enter then
                    return
                end
                Input:SetValue(Box.Text)
            end)
        else
            AddSignal(Box:GetPropertyChangedSignal("Text"), function()
                Input:SetValue(Box.Text)
            end)
        end
        function Input:OnChanged(Func)
            Input.Changed = Func
            Func(Input.Value)
        end
        function Input:Destroy()
            InputFrame:Destroy()
            Library.Options[Idx] = nil
        end
        Library.Options[Idx] = Input
        return Input
    end
    return Element
end)()

local safeParent = gethui and gethui() or game:GetService("CoreGui")
local NotifyGUI = Instance.new("ScreenGui")
NotifyGUI.Name = "FluentNotify"
NotifyGUI.DisplayOrder = math.huge 
NotifyGUI.IgnoreGuiInset = true
NotifyGUI.ResetOnSpawn = false
NotifyGUI.ZIndexBehavior = Enum.ZIndexBehavior.Global
NotifyGUI.Parent = safeParent

local NotificationModule = Components.Notification
NotificationModule:Init(NotifyGUI)

local New = Creator.New

local Icons = {["accessibility"] = "rbxassetid://10709751939",["activity"] = "rbxassetid://10709752035",["air-vent"] = "rbxassetid://10709752131",["airplay"] = "rbxassetid://10709752254",["alarm-check"] = "rbxassetid://10709752405",["alarm-clock"] = "rbxassetid://10709752630",["alarm-clock-off"] = "rbxassetid://10709752508",["alarm-minus"] = "rbxassetid://10709752732",["alarm-plus"] = "rbxassetid://10709752825",["album"] = "rbxassetid://10709752906",["alert-circle"] = "rbxassetid://10709752996",["alert-octagon"] = "rbxassetid://10709753064",["alert-triangle"] = "rbxassetid://10709753149",["align-center"] = "rbxassetid://10709753570",["align-center-horizontal"] = "rbxassetid://10709753272",["align-center-vertical"] = "rbxassetid://10709753421",["align-end-horizontal"] = "rbxassetid://10709753692",["align-end-vertical"] = "rbxassetid://10709753808",["align-horizontal-distribute-center"] = "rbxassetid://10747779791",["align-horizontal-distribute-end"] = "rbxassetid://10747784534",["align-horizontal-distribute-start"] = "rbxassetid://10709754118",["align-horizontal-justify-center"] = "rbxassetid://10709754204",["align-horizontal-justify-end"] = "rbxassetid://10709754317",["align-horizontal-justify-start"] = "rbxassetid://10709754436",["align-horizontal-space-around"] = "rbxassetid://10709754590",["align-horizontal-space-between"] = "rbxassetid://10709754749",["align-justify"] = "rbxassetid://10709759610",["align-left"] = "rbxassetid://10709759764",["align-right"] = "rbxassetid://10709759895",["align-start-horizontal"] = "rbxassetid://10709760051",["align-start-vertical"] = "rbxassetid://10709760244",["align-vertical-distribute-center"] = "rbxassetid://10709760351",["align-vertical-distribute-end"] = "rbxassetid://10709760434",["align-vertical-distribute-start"] = "rbxassetid://10709760612",["align-vertical-justify-center"] = "rbxassetid://10709760814",["align-vertical-justify-end"] = "rbxassetid://10709761003",["align-vertical-justify-start"] = "rbxassetid://10709761176",["align-vertical-space-around"] = "rbxassetid://10709761324",["align-vertical-space-between"] = "rbxassetid://10709761434",["anchor"] = "rbxassetid://10709761530",["angry"] = "rbxassetid://10709761629",["annoyed"] = "rbxassetid://10709761722",["aperture"] = "rbxassetid://10709761813",["apple"] = "rbxassetid://10709761889",["archive"] = "rbxassetid://10709762233",["archive-restore"] = "rbxassetid://10709762058",["armchair"] = "rbxassetid://10709762327",["arrow-big-down"] = "rbxassetid://10747796644",["arrow-big-left"] = "rbxassetid://10709762574",["arrow-big-right"] = "rbxassetid://10709762727",["arrow-big-up"] = "rbxassetid://10709762879",["arrow-down"] = "rbxassetid://10709767827",["arrow-down-circle"] = "rbxassetid://10709763034",["arrow-down-left"] = "rbxassetid://10709767656",["arrow-down-right"] = "rbxassetid://10709767750",["arrow-left"] = "rbxassetid://10709768114",["arrow-left-circle"] = "rbxassetid://10709767936",["arrow-left-right"] = "rbxassetid://10709768019",["arrow-right"] = "rbxassetid://10709768347",["arrow-right-circle"] = "rbxassetid://10709768226",["arrow-up"] = "rbxassetid://10709768939",["arrow-up-circle"] = "rbxassetid://10709768432",["arrow-up-down"] = "rbxassetid://10709768538",["arrow-up-left"] = "rbxassetid://10709768661",["arrow-up-right"] = "rbxassetid://10709768787",["asterisk"] = "rbxassetid://10709769095",["at-sign"] = "rbxassetid://10709769286",["award"] = "rbxassetid://10709769406",["axe"] = "rbxassetid://10709769508",["axis-3d"] = "rbxassetid://10709769598",["baby"] = "rbxassetid://10709769732",["backpack"] = "rbxassetid://10709769841",["baggage-claim"] = "rbxassetid://10709769935",["banana"] = "rbxassetid://10709770005",["banknote"] = "rbxassetid://10709770178",["bar-chart"] = "rbxassetid://10709773755",["bar-chart-2"] = "rbxassetid://10709770317",["bar-chart-3"] = "rbxassetid://10709770431",["bar-chart-4"] = "rbxassetid://10709770560",["bar-chart-horizontal"] = "rbxassetid://10709773669",["barcode"] = "rbxassetid://10747360675",["baseline"] = "rbxassetid://10709773863",["bath"] = "rbxassetid://10709773963",["battery"] = "rbxassetid://10709774640",["battery-charging"] = "rbxassetid://10709774068",["battery-full"] = "rbxassetid://10709774206",["battery-low"] = "rbxassetid://10709774370",["battery-medium"] = "rbxassetid://10709774513",["beaker"] = "rbxassetid://10709774756",["bed"] = "rbxassetid://10709775036",["bed-double"] = "rbxassetid://10709774864",["bed-single"] = "rbxassetid://10709774968",["beer"] = "rbxassetid://10709775167",["bell"] = "rbxassetid://10709775704",["bell-minus"] = "rbxassetid://10709775241",["bell-off"] = "rbxassetid://10709775320",["bell-plus"] = "rbxassetid://10709775448",["bell-ring"] = "rbxassetid://10709775560",["bike"] = "rbxassetid://10709775894",["binary"] = "rbxassetid://10709776050",["bitcoin"] = "rbxassetid://10709776126",["bluetooth"] = "rbxassetid://10709776655",["bluetooth-connected"] = "rbxassetid://10709776240",["bluetooth-off"] = "rbxassetid://10709776344",["bluetooth-searching"] = "rbxassetid://10709776501",["bold"] = "rbxassetid://10747813908",["bomb"] = "rbxassetid://10709781460",["bone"] = "rbxassetid://10709781605",["book"] = "rbxassetid://10709781824",["book-open"] = "rbxassetid://10709781717",["bookmark"] = "rbxassetid://10709782154",["bookmark-minus"] = "rbxassetid://10709781919",["bookmark-plus"] = "rbxassetid://10709782044",["bot"] = "rbxassetid://10709782230",["box"] = "rbxassetid://10709782497",["box-select"] = "rbxassetid://10709782342",["boxes"] = "rbxassetid://10709782582",["briefcase"] = "rbxassetid://10709782662",["brush"] = "rbxassetid://10709782758",["bug"] = "rbxassetid://10709782845",["building"] = "rbxassetid://10709783051",["building-2"] = "rbxassetid://10709782939",["bus"] = "rbxassetid://10709783137",["cake"] = "rbxassetid://10709783217",["calculator"] = "rbxassetid://10709783311",["calendar"] = "rbxassetid://10709789505",["calendar-check"] = "rbxassetid://10709783474",["calendar-check-2"] = "rbxassetid://10709783392",["calendar-clock"] = "rbxassetid://10709783577",["calendar-days"] = "rbxassetid://10709783673",["calendar-heart"] = "rbxassetid://10709783835",["calendar-minus"] = "rbxassetid://10709783959",["calendar-off"] = "rbxassetid://10709788784",["calendar-plus"] = "rbxassetid://10709788937",["calendar-range"] = "rbxassetid://10709789053",["calendar-search"] = "rbxassetid://10709789200",["calendar-x"] = "rbxassetid://10709789407",["calendar-x-2"] = "rbxassetid://10709789329",["camera"] = "rbxassetid://10709789686",["camera-off"] = "rbxassetid://10747822677",["car"] = "rbxassetid://10709789810",["carrot"] = "rbxassetid://10709789960",["cast"] = "rbxassetid://10709790097",["charge"] = "rbxassetid://10709790202",["check"] = "rbxassetid://10709790644",["check-circle"] = "rbxassetid://10709790387",["check-circle-2"] = "rbxassetid://10709790298",["check-square"] = "rbxassetid://10709790537",["chef-hat"] = "rbxassetid://10709790757",["cherry"] = "rbxassetid://10709790875",["chevron-down"] = "rbxassetid://10709790948",["chevron-first"] = "rbxassetid://10709791015",["chevron-last"] = "rbxassetid://10709791130",["chevron-left"] = "rbxassetid://10709791281",["chevron-right"] = "rbxassetid://10709791437",["chevron-up"] = "rbxassetid://10709791523",["chevrons-down"] = "rbxassetid://10709796864",["chevrons-down-up"] = "rbxassetid://10709791632",["chevrons-left"] = "rbxassetid://10709797151",["chevrons-left-right"] = "rbxassetid://10709797006",["chevrons-right"] = "rbxassetid://10709797382",["chevrons-right-left"] = "rbxassetid://10709797274",["chevrons-up"] = "rbxassetid://10709797622",["chevrons-up-down"] = "rbxassetid://10709797508",["chrome"] = "rbxassetid://10709797725",["circle"] = "rbxassetid://10709798174",["circle-dot"] = "rbxassetid://10709797837",["circle-ellipsis"] = "rbxassetid://10709797985",["circle-slashed"] = "rbxassetid://10709798100",["citrus"] = "rbxassetid://10709798276",["clapperboard"] = "rbxassetid://10709798350",["clipboard"] = "rbxassetid://10709799288",["clipboard-check"] = "rbxassetid://10709798443",["clipboard-copy"] = "rbxassetid://10709798574",["clipboard-edit"] = "rbxassetid://10709798682",["clipboard-list"] = "rbxassetid://10709798792",["clipboard-signature"] = "rbxassetid://10709798890",["clipboard-type"] = "rbxassetid://10709798999",["clipboard-x"] = "rbxassetid://10709799124",["clock"] = "rbxassetid://10709805144",["clock-1"] = "rbxassetid://10709799535",["clock-10"] = "rbxassetid://10709799718",["clock-11"] = "rbxassetid://10709799818",["clock-12"] = "rbxassetid://10709799962",["clock-2"] = "rbxassetid://10709803876",["clock-3"] = "rbxassetid://10709803989",["clock-4"] = "rbxassetid://10709804164",["clock-5"] = "rbxassetid://10709804291",["clock-6"] = "rbxassetid://10709804435",["clock-7"] = "rbxassetid://10709804599",["clock-8"] = "rbxassetid://10709804784",["clock-9"] = "rbxassetid://10709804996",["cloud"] = "rbxassetid://10709806740",["cloud-cog"] = "rbxassetid://10709805262",["cloud-drizzle"] = "rbxassetid://10709805371",["cloud-fog"] = "rbxassetid://10709805477",["cloud-hail"] = "rbxassetid://10709805596",["cloud-lightning"] = "rbxassetid://10709805727",["cloud-moon"] = "rbxassetid://10709805942",["cloud-moon-rain"] = "rbxassetid://10709805838",["cloud-off"] = "rbxassetid://10709806060",["cloud-rain"] = "rbxassetid://10709806277",["cloud-rain-wind"] = "rbxassetid://10709806166",["cloud-snow"] = "rbxassetid://10709806374",["cloud-sun"] = "rbxassetid://10709806631",["cloud-sun-rain"] = "rbxassetid://10709806475",["cloudy"] = "rbxassetid://10709806859",["clover"] = "rbxassetid://10709806995",["code"] = "rbxassetid://10709810463",["code-2"] = "rbxassetid://10709807111",["codepen"] = "rbxassetid://10709810534",["codesandbox"] = "rbxassetid://10709810676",["coffee"] = "rbxassetid://10709810814",["cog"] = "rbxassetid://10709810948",["coins"] = "rbxassetid://10709811110",["columns"] = "rbxassetid://10709811261",["command"] = "rbxassetid://10709811365",["compass"] = "rbxassetid://10709811445",["component"] = "rbxassetid://10709811595",["concierge-bell"] = "rbxassetid://10709811706",["connection"] = "rbxassetid://10747361219",["contact"] = "rbxassetid://10709811834",["contrast"] = "rbxassetid://10709811939",["cookie"] = "rbxassetid://10709812067",["copy"] = "rbxassetid://10709812159",["copyleft"] = "rbxassetid://10709812251",["copyright"] = "rbxassetid://10709812311",["corner-down-left"] = "rbxassetid://10709812396",["corner-down-right"] = "rbxassetid://10709812485",["corner-left-down"] = "rbxassetid://10709812632",["corner-left-up"] = "rbxassetid://10709812784",["corner-right-down"] = "rbxassetid://10709812939",["corner-right-up"] = "rbxassetid://10709813094",["corner-up-left"] = "rbxassetid://10709813185",["corner-up-right"] = "rbxassetid://10709813281",["cpu"] = "rbxassetid://10709813383",["croissant"] = "rbxassetid://10709818125",["crop"] = "rbxassetid://10709818245",["cross"] = "rbxassetid://10709818399",["crosshair"] = "rbxassetid://10709818534",["crown"] = "rbxassetid://10709818626",["cup-soda"] = "rbxassetid://10709818763",["curly-braces"] = "rbxassetid://10709818847",["currency"] = "rbxassetid://10709818931",["container"] = "rbxassetid://17466205552",["database"] = "rbxassetid://10709818996",["delete"] = "rbxassetid://10709819059",["diamond"] = "rbxassetid://10709819149",["dice-1"] = "rbxassetid://10709819266",["dice-2"] = "rbxassetid://10709819361",["dice-3"] = "rbxassetid://10709819508",["dice-4"] = "rbxassetid://10709819670",["dice-5"] = "rbxassetid://10709819801",["dice-6"] = "rbxassetid://10709819896",["dices"] = "rbxassetid://10723343321",["diff"] = "rbxassetid://10723343416",["disc"] = "rbxassetid://10723343537",["divide"] = "rbxassetid://10723343805",["divide-circle"] = "rbxassetid://10723343636",["divide-square"] = "rbxassetid://10723343737",["dollar-sign"] = "rbxassetid://10723343958",["download"] = "rbxassetid://10723344270",["download-cloud"] = "rbxassetid://10723344088",["droplet"] = "rbxassetid://10723344432",["droplets"] = "rbxassetid://10734883356",["drumstick"] = "rbxassetid://10723344737",["edit"] = "rbxassetid://10734883598",["edit-2"] = "rbxassetid://10723344885",["edit-3"] = "rbxassetid://10723345088",["egg"] = "rbxassetid://10723345518",["egg-fried"] = "rbxassetid://10723345347",["electricity"] = "rbxassetid://10723345749",["electricity-off"] = "rbxassetid://10723345643",["equal"] = "rbxassetid://10723345990",["equal-not"] = "rbxassetid://10723345866",["eraser"] = "rbxassetid://10723346158",["euro"] = "rbxassetid://10723346372",["expand"] = "rbxassetid://10723346553",["external-link"] = "rbxassetid://10723346684",["eye"] = "rbxassetid://10723346959",["eye-off"] = "rbxassetid://10723346871",["factory"] = "rbxassetid://10723347051",["fan"] = "rbxassetid://10723354359",["fast-forward"] = "rbxassetid://10723354521",["feather"] = "rbxassetid://10723354671",["figma"] = "rbxassetid://10723354801",["file"] = "rbxassetid://10723374641",["file-archive"] = "rbxassetid://10723354921",["file-audio"] = "rbxassetid://10723355148",["file-audio-2"] = "rbxassetid://10723355026",["file-axis-3d"] = "rbxassetid://10723355272",["file-badge"] = "rbxassetid://10723355622",["file-badge-2"] = "rbxassetid://10723355451",["file-bar-chart"] = "rbxassetid://10723355887",["file-bar-chart-2"] = "rbxassetid://10723355746",["file-box"] = "rbxassetid://10723355989",["file-check"] = "rbxassetid://10723356210",["file-check-2"] = "rbxassetid://10723356100",["file-clock"] = "rbxassetid://10723356329",["file-code"] = "rbxassetid://10723356507",["file-cog"] = "rbxassetid://10723356830",["file-cog-2"] = "rbxassetid://10723356676",["file-diff"] = "rbxassetid://10723357039",["file-digit"] = "rbxassetid://10723357151",["file-down"] = "rbxassetid://10723357322",["file-edit"] = "rbxassetid://10723357495",["file-heart"] = "rbxassetid://10723357637",["file-image"] = "rbxassetid://10723357790",["file-input"] = "rbxassetid://10723357933",["file-json"] = "rbxassetid://10723364435",["file-json-2"] = "rbxassetid://10723364361",["file-key"] = "rbxassetid://10723364605",["file-key-2"] = "rbxassetid://10723364515",["file-line-chart"] = "rbxassetid://10723364725",["file-lock"] = "rbxassetid://10723364957",["file-lock-2"] = "rbxassetid://10723364861",["file-minus"] = "rbxassetid://10723365254",["file-minus-2"] = "rbxassetid://10723365086",["file-output"] = "rbxassetid://10723365457",["file-pie-chart"] = "rbxassetid://10723365598",["file-plus"] = "rbxassetid://10723365877",["file-plus-2"] = "rbxassetid://10723365766",["file-question"] = "rbxassetid://10723365987",["file-scan"] = "rbxassetid://10723366167",["file-search"] = "rbxassetid://10723366550",["file-search-2"] = "rbxassetid://10723366340",["file-signature"] = "rbxassetid://10723366741",["file-spreadsheet"] = "rbxassetid://10723366962",["file-symlink"] = "rbxassetid://10723367098",["file-terminal"] = "rbxassetid://10723367244",["file-text"] = "rbxassetid://10723367380",["file-type"] = "rbxassetid://10723367606",["file-type-2"] = "rbxassetid://10723367509",["file-up"] = "rbxassetid://10723367734",["file-video"] = "rbxassetid://10723373884",["file-video-2"] = "rbxassetid://10723367834",["file-volume"] = "rbxassetid://10723374172",["file-volume-2"] = "rbxassetid://10723374030",["file-warning"] = "rbxassetid://10723374276",["file-x"] = "rbxassetid://10723374544",["file-x-2"] = "rbxassetid://10723374378",["files"] = "rbxassetid://10723374759",["film"] = "rbxassetid://10723374981",["filter"] = "rbxassetid://10723375128",["fingerprint"] = "rbxassetid://10723375250",["flag"] = "rbxassetid://10723375890",["flag-off"] = "rbxassetid://10723375443",["flag-triangle-left"] = "rbxassetid://10723375608",["flag-triangle-right"] = "rbxassetid://10723375727",["flame"] = "rbxassetid://10723376114",["flashlight"] = "rbxassetid://10723376471",["flashlight-off"] = "rbxassetid://10723376365",["flask-conical"] = "rbxassetid://10734883986",["flask-round"] = "rbxassetid://10723376614",["flip-horizontal"] = "rbxassetid://10723376884",["flip-horizontal-2"] = "rbxassetid://10723376745",["flip-vertical"] = "rbxassetid://10723377138",["flip-vertical-2"] = "rbxassetid://10723377026",["flower"] = "rbxassetid://10747830374",["flower-2"] = "rbxassetid://10723377305",["focus"] = "rbxassetid://10723377537",["folder"] = "rbxassetid://10723387563",["folder-archive"] = "rbxassetid://10723384478",["folder-check"] = "rbxassetid://10723384605",["folder-clock"] = "rbxassetid://10723384731",["folder-closed"] = "rbxassetid://10723384893",["folder-cog"] = "rbxassetid://10723385213",["folder-cog-2"] = "rbxassetid://10723385036",["folder-down"] = "rbxassetid://10723385338",["folder-edit"] = "rbxassetid://10723385445",["folder-heart"] = "rbxassetid://10723385545",["folder-input"] = "rbxassetid://10723385721",["folder-key"] = "rbxassetid://10723385848",["folder-lock"] = "rbxassetid://10723386005",["folder-minus"] = "rbxassetid://10723386127",["folder-open"] = "rbxassetid://10723386277",["folder-output"] = "rbxassetid://10723386386",["folder-plus"] = "rbxassetid://10723386531",["folder-search"] = "rbxassetid://10723386787",["folder-search-2"] = "rbxassetid://10723386674",["folder-symlink"] = "rbxassetid://10723386930",["folder-tree"] = "rbxassetid://10723387085",["folder-up"] = "rbxassetid://10723387265",["folder-x"] = "rbxassetid://10723387448",["folders"] = "rbxassetid://10723387721",["form-input"] = "rbxassetid://10723387841",["forward"] = "rbxassetid://10723388016",["frame"] = "rbxassetid://10723394389",["framer"] = "rbxassetid://10723394565",["frown"] = "rbxassetid://10723394681",["fuel"] = "rbxassetid://10723394846",["function-square"] = "rbxassetid://10723395041",["gamepad"] = "rbxassetid://10723395457",["gamepad-2"] = "rbxassetid://10723395215",["gauge"] = "rbxassetid://10723395708",["gavel"] = "rbxassetid://10723395896",["gem"] = "rbxassetid://10723396000",["ghost"] = "rbxassetid://10723396107",["gift"] = "rbxassetid://10723396402",["gift-card"] = "rbxassetid://10723396225",["git-branch"] = "rbxassetid://10723396676",["git-branch-plus"] = "rbxassetid://10723396542",["git-commit"] = "rbxassetid://10723396812",["git-compare"] = "rbxassetid://10723396954",["git-fork"] = "rbxassetid://10723397049",["git-merge"] = "rbxassetid://10723397165",["git-pull-request"] = "rbxassetid://10723397431",["git-pull-request-closed"] = "rbxassetid://10723397268",["git-pull-request-draft"] = "rbxassetid://10734884302",["glass"] = "rbxassetid://10723397788",["glass-2"] = "rbxassetid://10723397529",["glass-water"] = "rbxassetid://10723397678",["glasses"] = "rbxassetid://10723397895",["globe"] = "rbxassetid://10723404337",["globe-2"] = "rbxassetid://10723398002",["grab"] = "rbxassetid://10723404472",["graduation-cap"] = "rbxassetid://10723404691",["grape"] = "rbxassetid://10723404822",["grid"] = "rbxassetid://10723404936",["grip-horizontal"] = "rbxassetid://10723405089",["grip-vertical"] = "rbxassetid://10723405236",["hammer"] = "rbxassetid://10723405360",["hand"] = "rbxassetid://10723405649",["hand-metal"] = "rbxassetid://10723405508",["hard-drive"] = "rbxassetid://10723405749",["hard-hat"] = "rbxassetid://10723405859",["hash"] = "rbxassetid://10723405975",["haze"] = "rbxassetid://10723406078",["headphones"] = "rbxassetid://10723406165",["heart"] = "rbxassetid://10723406885",["heart-crack"] = "rbxassetid://10723406299",["heart-handshake"] = "rbxassetid://10723406480",["heart-off"] = "rbxassetid://10723406662",["heart-pulse"] = "rbxassetid://10723406795",["help-circle"] = "rbxassetid://10723406988",["hexagon"] = "rbxassetid://10723407092",["highlighter"] = "rbxassetid://10723407192",["history"] = "rbxassetid://10723407335",["home"] = "rbxassetid://10723407389",["hourglass"] = "rbxassetid://10723407498",["ice-cream"] = "rbxassetid://10723414308",["image"] = "rbxassetid://10723415040",["image-minus"] = "rbxassetid://10723414487",["image-off"] = "rbxassetid://10723414677",["image-plus"] = "rbxassetid://10723414827",["import"] = "rbxassetid://10723415205",["inbox"] = "rbxassetid://10723415335",["indent"] = "rbxassetid://10723415494",["indian-rupee"] = "rbxassetid://10723415642",["infinity"] = "rbxassetid://10723415766",["info"] = "rbxassetid://10723415903",["inspect"] = "rbxassetid://10723416057",["italic"] = "rbxassetid://10723416195",["japanese-yen"] = "rbxassetid://10723416363",["joystick"] = "rbxassetid://10723416527",["key"] = "rbxassetid://10723416652",["keyboard"] = "rbxassetid://10723416765",["lamp"] = "rbxassetid://10723417513",["lamp-ceiling"] = "rbxassetid://10723416922",["lamp-desk"] = "rbxassetid://10723417016",["lamp-floor"] = "rbxassetid://10723417131",["lamp-wall-down"] = "rbxassetid://10723417240",["lamp-wall-up"] = "rbxassetid://10723417356",["landmark"] = "rbxassetid://10723417608",["languages"] = "rbxassetid://10723417703",["laptop"] = "rbxassetid://10723423881",["laptop-2"] = "rbxassetid://10723417797",["lasso"] = "rbxassetid://10723424235",["lasso-select"] = "rbxassetid://10723424058",["laugh"] = "rbxassetid://10723424372",["layers"] = "rbxassetid://10723424505",["layout"] = "rbxassetid://10723425376",["layout-dashboard"] = "rbxassetid://10723424646",["layout-grid"] = "rbxassetid://10723424838",["layout-list"] = "rbxassetid://10723424963",["layout-template"] = "rbxassetid://10723425187",["leaf"] = "rbxassetid://10723425539",["library"] = "rbxassetid://10723425615",["life-buoy"] = "rbxassetid://10723425685",["lightbulb"] = "rbxassetid://10723425852",["lightbulb-off"] = "rbxassetid://10723425762",["line-chart"] = "rbxassetid://10723426393",["link"] = "rbxassetid://10723426722",["link-2"] = "rbxassetid://10723426595",["link-2-off"] = "rbxassetid://10723426513",["list"] = "rbxassetid://10723433811",["list-checks"] = "rbxassetid://10734884548",["list-end"] = "rbxassetid://10723426886",["list-minus"] = "rbxassetid://10723426986",["list-music"] = "rbxassetid://10723427081",["list-ordered"] = "rbxassetid://10723427199",["list-plus"] = "rbxassetid://10723427334",["list-start"] = "rbxassetid://10723427494",["list-video"] = "rbxassetid://10723427619",["list-todo"] = "rbxassetid://17376008003",["list-x"] = "rbxassetid://10723433655",["loader"] = "rbxassetid://10723434070",["loader-2"] = "rbxassetid://10723433935",["locate"] = "rbxassetid://10723434557",["locate-fixed"] = "rbxassetid://10723434236",["locate-off"] = "rbxassetid://10723434379",["lock"] = "rbxassetid://10723434711",["log-in"] = "rbxassetid://10723434830",["log-out"] = "rbxassetid://10723434906",["luggage"] = "rbxassetid://10723434993",["magnet"] = "rbxassetid://10723435069",["mail"] = "rbxassetid://10734885430",["mail-check"] = "rbxassetid://10723435182",["mail-minus"] = "rbxassetid://10723435261",["mail-open"] = "rbxassetid://10723435342",["mail-plus"] = "rbxassetid://10723435443",["mail-question"] = "rbxassetid://10723435515",["mail-search"] = "rbxassetid://10734884739",["mail-warning"] = "rbxassetid://10734885015",["mail-x"] = "rbxassetid://10734885247",["mails"] = "rbxassetid://10734885614",["map"] = "rbxassetid://10734886202",["map-pin"] = "rbxassetid://10734886004",["map-pin-off"] = "rbxassetid://10734885803",["maximize"] = "rbxassetid://10734886735",["maximize-2"] = "rbxassetid://10734886496",["medal"] = "rbxassetid://10734887072",["megaphone"] = "rbxassetid://10734887454",["megaphone-off"] = "rbxassetid://10734887311",["meh"] = "rbxassetid://10734887603",["menu"] = "rbxassetid://10734887784",["message-circle"] = "rbxassetid://10734888000",["message-square"] = "rbxassetid://10734888228",["mic"] = "rbxassetid://10734888864",["mic-2"] = "rbxassetid://10734888430",["mic-off"] = "rbxassetid://10734888646",["microscope"] = "rbxassetid://10734889106",["microwave"] = "rbxassetid://10734895076",["milestone"] = "rbxassetid://10734895310",["minimize"] = "rbxassetid://10734895698",["minimize-2"] = "rbxassetid://10734895530",["minus"] = "rbxassetid://10734896206",["minus-circle"] = "rbxassetid://10734895856",["minus-square"] = "rbxassetid://10734896029",["monitor"] = "rbxassetid://10734896881",["monitor-off"] = "rbxassetid://10734896360",["monitor-speaker"] = "rbxassetid://10734896512",["moon"] = "rbxassetid://10734897102",["more-horizontal"] = "rbxassetid://10734897250",["more-vertical"] = "rbxassetid://10734897387",["mountain"] = "rbxassetid://10734897956",["mountain-snow"] = "rbxassetid://10734897665",["mouse"] = "rbxassetid://10734898592",["mouse-pointer"] = "rbxassetid://10734898476",["mouse-pointer-2"] = "rbxassetid://10734898194",["mouse-pointer-click"] = "rbxassetid://10734898355",["move"] = "rbxassetid://10734900011",["move-3d"] = "rbxassetid://10734898756",["move-diagonal"] = "rbxassetid://10734899164",["move-diagonal-2"] = "rbxassetid://10734898934",["move-horizontal"] = "rbxassetid://10734899414",["move-vertical"] = "rbxassetid://10734899821",["music"] = "rbxassetid://10734905958",["music-2"] = "rbxassetid://10734900215",["music-3"] = "rbxassetid://10734905665",["music-4"] = "rbxassetid://10734905823",["navigation"] = "rbxassetid://10734906744",["navigation-2"] = "rbxassetid://10734906332",["navigation-2-off"] = "rbxassetid://10734906144",["navigation-off"] = "rbxassetid://10734906580",["network"] = "rbxassetid://10734906975",["newspaper"] = "rbxassetid://10734907168",["octagon"] = "rbxassetid://10734907361",["option"] = "rbxassetid://10734907649",["outdent"] = "rbxassetid://10734907933",["package"] = "rbxassetid://10734909540",["package-2"] = "rbxassetid://10734908151",["package-check"] = "rbxassetid://10734908384",["package-minus"] = "rbxassetid://10734908626",["package-open"] = "rbxassetid://10734908793",["package-plus"] = "rbxassetid://10734909016",["package-search"] = "rbxassetid://10734909196",["package-x"] = "rbxassetid://10734909375",["paint-bucket"] = "rbxassetid://10734909847",["paintbrush"] = "rbxassetid://10734910187",["paintbrush-2"] = "rbxassetid://10734910030",["palette"] = "rbxassetid://10734910430",["palmtree"] = "rbxassetid://10734910680",["paperclip"] = "rbxassetid://10734910927",["party-popper"] = "rbxassetid://10734918735",["pause"] = "rbxassetid://10734919336",["pause-circle"] = "rbxassetid://10735024209",["pause-octagon"] = "rbxassetid://10734919143",["pen-tool"] = "rbxassetid://10734919503",["pencil"] = "rbxassetid://10734919691",["percent"] = "rbxassetid://10734919919",["person-standing"] = "rbxassetid://10734920149",["phone"] = "rbxassetid://10734921524",["phone-call"] = "rbxassetid://10734920305",["phone-forwarded"] = "rbxassetid://10734920508",["phone-incoming"] = "rbxassetid://10734920694",["phone-missed"] = "rbxassetid://10734920845",["phone-off"] = "rbxassetid://10734921077",["phone-outgoing"] = "rbxassetid://10734921288",["pie-chart"] = "rbxassetid://10734921727",["piggy-bank"] = "rbxassetid://10734921935",["pin"] = "rbxassetid://10734922324",["pin-off"] = "rbxassetid://10734922180",["pipette"] = "rbxassetid://10734922497",["pizza"] = "rbxassetid://10734922774",["plane"] = "rbxassetid://10734922971",["plane-landing"] = "rbxassetid://17376029914",["play"] = "rbxassetid://10734923549",["play-circle"] = "rbxassetid://10734923214",["plus"] = "rbxassetid://10734924532",["plus-circle"] = "rbxassetid://10734923868",["plus-square"] = "rbxassetid://10734924219",["podcast"] = "rbxassetid://10734929553",["pointer"] = "rbxassetid://10734929723",["pound-sterling"] = "rbxassetid://10734929981",["power"] = "rbxassetid://10734930466",["power-off"] = "rbxassetid://10734930257",["printer"] = "rbxassetid://10734930632",["puzzle"] = "rbxassetid://10734930886",["quote"] = "rbxassetid://10734931234",["radio"] = "rbxassetid://10734931596",["radio-receiver"] = "rbxassetid://10734931402",["rectangle-horizontal"] = "rbxassetid://10734931777",["rectangle-vertical"] = "rbxassetid://10734932081",["recycle"] = "rbxassetid://10734932295",["redo"] = "rbxassetid://10734932822",["redo-2"] = "rbxassetid://10734932586",["refresh-ccw"] = "rbxassetid://10734933056",["refresh-cw"] = "rbxassetid://10734933222",["refrigerator"] = "rbxassetid://10734933465",["regex"] = "rbxassetid://10734933655",["repeat"] = "rbxassetid://10734933966",["repeat-1"] = "rbxassetid://10734933826",["reply"] = "rbxassetid://10734934252",["reply-all"] = "rbxassetid://10734934132",["rewind"] = "rbxassetid://10734934347",["rocket"] = "rbxassetid://10734934585",["rocking-chair"] = "rbxassetid://10734939942",["rotate-3d"] = "rbxassetid://10734940107",["rotate-ccw"] = "rbxassetid://10734940376",["rotate-cw"] = "rbxassetid://10734940654",["rss"] = "rbxassetid://10734940825",["ruler"] = "rbxassetid://10734941018",["russian-ruble"] = "rbxassetid://10734941199",["sailboat"] = "rbxassetid://10734941354",["save"] = "rbxassetid://10734941499",["scale"] = "rbxassetid://10734941912",["scale-3d"] = "rbxassetid://10734941739",["scaling"] = "rbxassetid://10734942072",["scan"] = "rbxassetid://10734942565",["scan-face"] = "rbxassetid://10734942198",["scan-line"] = "rbxassetid://10734942351",["scissors"] = "rbxassetid://10734942778",["screen-share"] = "rbxassetid://10734943193",["screen-share-off"] = "rbxassetid://10734942967",["scroll"] = "rbxassetid://10734943448",["search"] = "rbxassetid://10734943674",["send"] = "rbxassetid://10734943902",["separator-horizontal"] = "rbxassetid://10734944115",["separator-vertical"] = "rbxassetid://10734944326",["server"] = "rbxassetid://10734949856",["server-cog"] = "rbxassetid://10734944444",["server-crash"] = "rbxassetid://10734944554",["server-off"] = "rbxassetid://10734944668",["settings"] = "rbxassetid://10734950309",["settings-2"] = "rbxassetid://10734950020",["share"] = "rbxassetid://10734950813",["share-2"] = "rbxassetid://10734950553",["sheet"] = "rbxassetid://10734951038",["shield"] = "rbxassetid://10734951847",["shield-alert"] = "rbxassetid://10734951173",["shield-check"] = "rbxassetid://10734951367",["shield-close"] = "rbxassetid://10734951535",["shield-off"] = "rbxassetid://10734951684",["shirt"] = "rbxassetid://10734952036",["shopping-bag"] = "rbxassetid://10734952273",["shopping-cart"] = "rbxassetid://10734952479",["shovel"] = "rbxassetid://10734952773",["shower-head"] = "rbxassetid://10734952942",["shrink"] = "rbxassetid://10734953073",["shrub"] = "rbxassetid://10734953241",["shuffle"] = "rbxassetid://10734953451",["sidebar"] = "rbxassetid://10734954301",["sidebar-close"] = "rbxassetid://10734953715",["sidebar-open"] = "rbxassetid://10734954000",["sigma"] = "rbxassetid://10734954538",["signal"] = "rbxassetid://10734961133",["signal-high"] = "rbxassetid://10734954807",["signal-low"] = "rbxassetid://10734955080",["signal-medium"] = "rbxassetid://10734955336",["signal-zero"] = "rbxassetid://10734960878",["siren"] = "rbxassetid://10734961284",["skip-back"] = "rbxassetid://10734961526",["skip-forward"] = "rbxassetid://10734961809",["skull"] = "rbxassetid://10734962068",["slack"] = "rbxassetid://10734962339",["slash"] = "rbxassetid://10734962600",["slice"] = "rbxassetid://10734963024",["sliders"] = "rbxassetid://10734963400",["sliders-horizontal"] = "rbxassetid://10734963191",["smartphone"] = "rbxassetid://10734963940",["smartphone-charging"] = "rbxassetid://10734963671",["smile"] = "rbxassetid://10734964441",["smile-plus"] = "rbxassetid://10734964188",["snowflake"] = "rbxassetid://10734964600",["sofa"] = "rbxassetid://10734964852",["sort-asc"] = "rbxassetid://10734965115",["sort-desc"] = "rbxassetid://10734965287",["speaker"] = "rbxassetid://10734965419",["sprout"] = "rbxassetid://10734965572",["square"] = "rbxassetid://10734965702",["star"] = "rbxassetid://10734966248",["star-half"] = "rbxassetid://10734965897",["star-off"] = "rbxassetid://10734966097",["stethoscope"] = "rbxassetid://10734966384",["sticker"] = "rbxassetid://10734972234",["sticky-note"] = "rbxassetid://10734972463",["stop-circle"] = "rbxassetid://10734972621",["stretch-horizontal"] = "rbxassetid://10734972862",["stretch-vertical"] = "rbxassetid://10734973130",["strikethrough"] = "rbxassetid://10734973290",["subscript"] = "rbxassetid://10734973457",["sun"] = "rbxassetid://10734974297",["sun-dim"] = "rbxassetid://10734973645",["sun-medium"] = "rbxassetid://10734973778",["sun-moon"] = "rbxassetid://10734973999",["sun-snow"] = "rbxassetid://10734974130",["sunrise"] = "rbxassetid://10734974522",["sunset"] = "rbxassetid://10734974689",["superscript"] = "rbxassetid://10734974850",["swiss-franc"] = "rbxassetid://10734975024",["switch-camera"] = "rbxassetid://10734975214",["sword"] = "rbxassetid://10734975486",["swords"] = "rbxassetid://10734975692",["syringe"] = "rbxassetid://10734975932",["table"] = "rbxassetid://10734976230",["table-2"] = "rbxassetid://10734976097",["tablet"] = "rbxassetid://10734976394",["tag"] = "rbxassetid://10734976528",["tags"] = "rbxassetid://10734976739",["target"] = "rbxassetid://10734977012",["tent"] = "rbxassetid://10734981750",["terminal"] = "rbxassetid://10734982144",["terminal-square"] = "rbxassetid://10734981995",["text-cursor"] = "rbxassetid://10734982395",["text-cursor-input"] = "rbxassetid://10734982297",["thermometer"] = "rbxassetid://10734983134",["thermometer-snowflake"] = "rbxassetid://10734982571",["thermometer-sun"] = "rbxassetid://10734982771",["thumbs-down"] = "rbxassetid://10734983359",["thumbs-up"] = "rbxassetid://10734983629",["ticket"] = "rbxassetid://10734983868",["timer"] = "rbxassetid://10734984606",["timer-off"] = "rbxassetid://10734984138",["timer-reset"] = "rbxassetid://10734984355",["toggle-left"] = "rbxassetid://10734984834",["toggle-right"] = "rbxassetid://10734985040",["tornado"] = "rbxassetid://10734985247",["toy-brick"] = "rbxassetid://10747361919",["train"] = "rbxassetid://10747362105",["trash"] = "rbxassetid://10747362393",["trash-2"] = "rbxassetid://10747362241",["tree-deciduous"] = "rbxassetid://10747362534",["tree-pine"] = "rbxassetid://10747362748",["trees"] = "rbxassetid://10747363016",["trending-down"] = "rbxassetid://10747363205",["trending-up"] = "rbxassetid://10747363465",["triangle"] = "rbxassetid://10747363621",["trophy"] = "rbxassetid://10747363809",["truck"] = "rbxassetid://10747364031",["tv"] = "rbxassetid://10747364593",["tv-2"] = "rbxassetid://10747364302",["type"] = "rbxassetid://10747364761",["umbrella"] = "rbxassetid://10747364971",["underline"] = "rbxassetid://10747365191",["undo"] = "rbxassetid://10747365484",["undo-2"] = "rbxassetid://10747365359",["unlink"] = "rbxassetid://10747365771",["unlink-2"] = "rbxassetid://10747397871",["unlock"] = "rbxassetid://10747366027",["upload"] = "rbxassetid://10747366434",["upload-cloud"] = "rbxassetid://10747366266",["usb"] = "rbxassetid://10747366606",["user"] = "rbxassetid://10747373176",["user-check"] = "rbxassetid://10747371901",["user-cog"] = "rbxassetid://10747372167",["user-minus"] = "rbxassetid://10747372346",["user-plus"] = "rbxassetid://10747372702",["user-x"] = "rbxassetid://10747372992",["users"] = "rbxassetid://10747373426",["utensils"] = "rbxassetid://10747373821",["utensils-crossed"] = "rbxassetid://10747373629",["venetian-mask"] = "rbxassetid://10747374003",["verified"] = "rbxassetid://10747374131",["vibrate"] = "rbxassetid://10747374489",["vibrate-off"] = "rbxassetid://10747374269",["video"] = "rbxassetid://10747374938",["video-off"] = "rbxassetid://10747374721",["view"] = "rbxassetid://10747375132",["voicemail"] = "rbxassetid://10747375281",["volume"] = "rbxassetid://10747376008",["volume-1"] = "rbxassetid://10747375450",["volume-2"] = "rbxassetid://10747375679",["volume-x"] = "rbxassetid://10747375880",["wallet"] = "rbxassetid://10747376205",["wand"] = "rbxassetid://10747376565",["wand-2"] = "rbxassetid://10747376349",["watch"] = "rbxassetid://10747376722",["waves"] = "rbxassetid://10747376931",["webcam"] = "rbxassetid://10747381992",["wifi"] = "rbxassetid://10747382504",["wifi-off"] = "rbxassetid://10747382268",["wind"] = "rbxassetid://10747382750",["wrap-text"] = "rbxassetid://10747383065",["wrench"] = "rbxassetid://10747383470",["x"] = "rbxassetid://10747384394",["x-circle"] = "rbxassetid://10747383819",["x-octagon"] = "rbxassetid://10747384037",["x-square"] = "rbxassetid://10747384217",["zoom-in"] = "rbxassetid://10747384552",["zoom-out"] = "rbxassetid://10747384679",["cat"] = "rbxassetid://16935650691",["message-circle-question"] = "rbxassetid://16970049192",["webhook"] = "rbxassetid://17320556264"}
function Library:GetIcon(Name)
    if Name ~= nil and Icons[Name] then
        return Icons[Name]
    end
    return nil
end
local Elements = {}
Elements.__index = Elements
Elements.__namecall = function(Table, Key, ...)
    return Elements[Key](...)
end

for _, ElementComponent in pairs(ElementsTable) do
    Elements["Add" .. ElementComponent.__type] = function(self, Idx, Config)
        ElementComponent.Container = self.Container
        ElementComponent.Type = self.Type
        ElementComponent.ScrollFrame = self.ScrollFrame
        ElementComponent.Library = Library
        return ElementComponent:New(Idx, Config)
    end
end

Library.Elements = Elements

function Library:CreateWindow(Config)
    assert(Config.Title)
    if Library.Window then
        return
    end
    Library.MinimizeKey = Config.MinimizeKey
    Library.UseAcrylic = Config.Acrylic
    Library.Acrylic = Config.Acrylic
    Library.Theme = Config.Theme
    if Config.Acrylic then
        Acrylic.init()
    end
    local Window = Components.Window({
        Parent = GUI,
        Size = Config.Size,
        Title = Config.Title,
        SubTitle = Config.SubTitle,
        TabWidth = Config.TabWidth,
        Icon = Config.Icon
    })
    Window.Icon = Config.Icon
    Window.ToggleButton = Creator.New("ImageButton", {
        Size = UDim2.fromOffset(45, 45),
        Position = UDim2.new(0, 20, 0, 200),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        Image = Window.Icon or "",
        ScaleType = Enum.ScaleType.Fit,
        Parent = GUI
    })
    Creator.New("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = Window.ToggleButton
    })
    Window.ToggleButton.MouseButton1Click:Connect(function()
        Window:Minimize()
    end)
    local oldDestroy = Window.Destroy
    Window.Destroy = function(self)
        if oldDestroy then
            oldDestroy(self)
        end
        if self.ToggleButton then
            self.ToggleButton:Destroy()
        end
    end
    Library.Window = Window
    Library:SetTheme(Config.Theme)
    return Window
end

function Library:SetTheme(Value)
    if Library.Window and table.find(Library.Themes, Value) then
        Library.Theme = Value
        Creator.UpdateTheme()
    end
end

function Library:Destroy()
    if Library.Window then
        Library.Unloaded = true
        if Library.UseAcrylic then
            Library.Window.AcrylicPaint.Model:Destroy()
        end
        Creator.Disconnect()
        Library.GUI:Destroy()
    end
end
function Library:Notify(Config)
    return NotificationModule:New(Config)
end
return Library