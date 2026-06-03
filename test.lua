-- Dynamic UI Library - Standalone
-- Usage: local Library = loadstring(game:HttpGet(...))()

-- Helper functions (graceful fallback if file I/O not available)
local function EnsureFolder(Path)
    if not isfolder(Path) then
        pcall(function() makefolder(Path) end)
    end
end

local function EnsureFile(Path, DefaultContent)
    if not isfile(Path) then
        pcall(function() writefile(Path, DefaultContent or "{}") end)
    end
end

local Services = {
    CoreGui = game:GetService("CoreGui"),
    RunService = game:GetService("RunService"),
    TextService = game:GetService("TextService"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    Players = game:GetService("Players"),
    HttpService = game:GetService("HttpService"),
    SoundService = game:GetService("SoundService"),
    Lighting = game:GetService("Lighting"),
    GuiService = game:GetService("GuiService"),
}

local Assets = {
    GetFont = function(self, name)
        return Font.new("rbxasset://fonts/families/GothamSSm.json")
    end,
    GetImage = function(self, path)
        -- Returns empty string (no custom images in this version)
        return ""
    end,
    GetSound = function(self, path)
        -- Returns nil (no custom sounds in this version)
        return nil
    end
}

-- Default themes
local DefaultThemes = {
    Bubble = {
        Theme = {
            BackgroundDark = Color3.fromRGB(14, 14, 14),
            HeaderBackground = Color3.fromRGB(18, 18, 18),
            ItemDefault = Color3.fromRGB(28, 28, 28),
            Text = Color3.fromRGB(235, 235, 235),
            Scrollbar = Color3.fromRGB(0, 0, 0)
        },
        Accent = {
            Color3.fromRGB(20, 80, 140),
            Color3.fromRGB(40, 120, 180),
            Color3.fromRGB(60, 160, 210),
            Color3.fromRGB(80, 190, 220),
            Color3.fromRGB(100, 220, 230),
            Color3.fromRGB(120, 240, 240),
            Color3.fromRGB(80, 200, 200)
        }
    },
    Dark = {
        Theme = {
            BackgroundDark = Color3.fromRGB(20, 20, 20),
            HeaderBackground = Color3.fromRGB(25, 25, 25),
            ItemDefault = Color3.fromRGB(35, 35, 35),
            Text = Color3.fromRGB(255, 255, 255),
            Scrollbar = Color3.fromRGB(10, 10, 10)
        },
        Accent = {
            Color3.fromRGB(100, 220, 230),
            Color3.fromRGB(100, 220, 230)
        }
    }
}

local Library = {
    Window = {
        Categories = {},
        Modules = {},
        Elements = {},
    },
    Flags = {},
    ActiveShadows = {},
    FontFaces = {
        GoogleSans = Font.new("rbxasset://fonts/families/GothamSSm.json"),
        ProductSans = Font.new("rbxasset://fonts/families/GothamSSm.json"),
        Lexend = Font.new("rbxasset://fonts/families/GothamSSm.json")
    },
    CurrentTheme = "Bubble",
    Themes = DefaultThemes,
    ExtractedColors = {}
}

local RainbowOffset = 0
local ActiveGradients = {}
local UnsyncOffsets = {}
local UnsyncSpeeds = {}
local ThemeColors = {}

local function ApplyCustomTheme()
	table.clear(ThemeColors)

	local Flags = Library.Flags
	if not Flags then
		return
	end

	local Count = Flags.Interface_Colors or 1

	for Index = 1, Count do
		local Data = Flags["Interface_Color" .. Index]
		if typeof(Data) == "Color3" then
			ThemeColors[#ThemeColors + 1] = Data
		end
	end
end

local function ResolveThemeColors()
	local ThemeName = Library.CurrentTheme
	local ThemeData = ThemeName and Library.Themes and Library.Themes[ThemeName]

	if not ThemeData and ThemeName ~= "Custom" then
		return
	end

	if ThemeName == "Custom" then
		ApplyCustomTheme()
	else
		table.clear(ThemeColors)
		for Index, Color in ipairs(ThemeData.Accent) do
			ThemeColors[Index] = Color
		end
	end
end

ResolveThemeColors()

local function GetThemeColors()
	if #ThemeColors == 0 then
		ResolveThemeColors()
	end
	return ThemeColors
end

function GetTheme()
	local ThemeName = Library.CurrentTheme

	if ThemeName == "Custom" then
		local BaseThemeName = Library.BaseTheme or "Bubble"
		local BaseTheme = Library.Themes and Library.Themes[BaseThemeName]
		return BaseTheme and BaseTheme.Theme or {}
	end

	local ThemeData = ThemeName and Library.Themes and Library.Themes[ThemeName]
	return ThemeData and ThemeData.Theme or {}
end

function SetTheme(ThemeName)
	if Library.CurrentTheme == ThemeName then
		return
	end

	if ThemeName ~= "Custom" and not (Library.Themes and Library.Themes[ThemeName]) then
		return
	end

	Library.CurrentTheme = ThemeName
	ResolveThemeColors()

	if Library.RefreshTheme then
		Library:RefreshTheme()
	end
end

local function GetThemeColor(Index)
	local Colors = GetThemeColors()
	if #Colors == 0 then
		return Color3.new(1, 1, 1)
	end
	return Colors[((Index - 1) % #Colors) + 1]
end

local function BlendThemeColors(Alpha)
	local Colors = GetThemeColors()
	if #Colors == 0 then
		return Color3.new(1, 1, 1)
	end

	local Count = #Colors
	local Segment = (Alpha % 1) * Count
	local Index = math.floor(Segment) + 1
	local Fraction = Segment - math.floor(Segment)

	local ColorA = Colors[((Index - 1) % Count) + 1]
	local ColorB = Colors[(Index % Count) + 1]

	return ColorA:Lerp(ColorB, Fraction)
end

Services.RunService.RenderStepped:Connect(function(DeltaTime)
	if next(ActiveGradients) == nil then return end

	ResolveThemeColors()

	local Mode = Library.Flags.Interface_Style or "Flow"

	if Mode ~= "Static" then
		RainbowOffset = (RainbowOffset + DeltaTime * Library.Flags.Interface_Speed) % 1
	end

	for Gradient in pairs(ActiveGradients) do
		if not Gradient.Parent then
			ActiveGradients[Gradient] = nil
			continue
		end

		local Offset = 0

		if Mode == "Flow" or Mode == "Flux" then
			Offset = RainbowOffset
		elseif Mode == "Breath" then
			Offset = 0.5 + 0.5 * math.sin(tick() * Library.Flags.Interface_Speed * math.pi * 2)
		elseif Mode == "Static" then
			Offset = 0
		end

		if Mode == "Flux" then
			local YFactor = (Gradient.Parent.AbsolutePosition.Y / 600)
			Offset = (Offset + YFactor) % 1
		end

		local ColorA = BlendThemeColors(Offset)
		local ColorB = BlendThemeColors((Offset + 0.1) % 1)

		Gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, ColorA),
			ColorSequenceKeypoint.new(1, ColorB)
		})
	end
end)

local function CreateGradient()
	local Gradient = Instance.new("UIGradient")
	Gradient.Rotation = 0
	return Gradient
end

function AddGradient(TargetInstance)

	local Gradient = CreateGradient()
	Gradient.Parent = TargetInstance
	ActiveGradients[Gradient] = true

	local Connection
	Connection = Gradient.AncestryChanged:Connect(function(_, Parent)
		if not Parent then
			ActiveGradients[Gradient] = nil
			Connection:Disconnect()
		end
	end)

	return {
		Gradient = Gradient,
		SetEnabled = function(_, IsEnabled)
			if IsEnabled then
				ActiveGradients[Gradient] = true
			else
				ActiveGradients[Gradient] = nil
			end
		end,
		Destroy = function()
			ActiveGradients[Gradient] = nil
			Gradient:Destroy()
		end
	}
end

local function ResolveScreenGui(TargetInstance, ScreenGui)
	if ScreenGui and ScreenGui:IsA("ScreenGui") then
		return ScreenGui
	end

	local Current = TargetInstance
	while Current do
		if Current:IsA("ScreenGui") then
			return Current
		end
		Current = Current.Parent
	end

end

function AttachShadow(ScreenGui, TargetInstance, CornerRadius, LayerCount, MaxSpread, Gamma, ShadowColor, UseGradient, Alpha)
    local Gui = ResolveScreenGui(TargetInstance, ScreenGui)

    Alpha = math.clamp(Alpha or 1, 0, 1)

    local InnerAlpha = 0.9
    local OuterAlpha = 0.97

    local ShadowLayers = {}
    local Connections = {}

    for LayerIndex = 1, LayerCount do
        local T = (LayerIndex - 1) / (LayerCount - 1)
        local Spread = math.floor(T * MaxSpread + 0.5)

        local BaseTransparency = InnerAlpha + (OuterAlpha - InnerAlpha) * (T ^ Gamma)
        local Transparency = BaseTransparency + (1 - BaseTransparency) * (1 - Alpha)

        local Frame = Instance.new("Frame")
        Frame.BackgroundColor3 = ShadowColor
        Frame.BackgroundTransparency = Transparency
        Frame.BorderSizePixel = 0
        Frame.ZIndex = TargetInstance.ZIndex - LayerIndex
        Frame.Parent = Gui

        local Gradient
        if UseGradient then
            Gradient = AddGradient(Frame)
        end

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, CornerRadius + Spread)
        Corner.Parent = Frame

        ShadowLayers[#ShadowLayers + 1] = {
            Frame = Frame,
            Spread = Spread,
            BaseTransparency = BaseTransparency,
            Gradient = Gradient
        }
    end

    local function SyncShadow()
        if not TargetInstance.Parent then return end

        for _, Layer in ipairs(ShadowLayers) do
            local Spread = Layer.Spread
            local Frame = Layer.Frame

            Frame.Position = UDim2.fromOffset(
                TargetInstance.AbsolutePosition.X - Spread,
                TargetInstance.AbsolutePosition.Y - Spread
            )

            Frame.Size = UDim2.fromOffset(
                TargetInstance.AbsoluteSize.X + Spread * 2,
                TargetInstance.AbsoluteSize.Y + Spread * 2
            )
        end
    end

    SyncShadow()

    Connections[#Connections + 1] = TargetInstance:GetPropertyChangedSignal("AbsoluteSize"):Connect(SyncShadow)
    Connections[#Connections + 1] = TargetInstance:GetPropertyChangedSignal("AbsolutePosition"):Connect(SyncShadow)

    Connections[#Connections + 1] = TargetInstance.AncestryChanged:Connect(function(_, Parent)
        if Parent then return end
        for _, Connection in ipairs(Connections) do
            Connection:Disconnect()
        end
        for _, Layer in ipairs(ShadowLayers) do
            if Layer.Frame then
                Layer.Frame:Destroy()
            end
        end
    end)

    local ShadowObj = {}
    ShadowObj.Alpha = Alpha
    ShadowObj.Color = ShadowColor
    ShadowObj.UseGradient = UseGradient

    function ShadowObj:SetAlpha(Value)
        ShadowObj.Alpha = math.clamp(Value or 1, 0, 1)
        for _, Layer in ipairs(ShadowLayers) do
            local Base = Layer.BaseTransparency
            Layer.Frame.BackgroundTransparency =
                Base + (1 - Base) * (1 - ShadowObj.Alpha)
        end
    end

    function ShadowObj:SetTransparency(Value)
        Value = math.clamp(Value or 0, 0, 1)
        for _, Layer in ipairs(ShadowLayers) do
            local Base = Layer.BaseTransparency
            local AlphaAdjusted = Base + (1 - Base) * (1 - ShadowObj.Alpha)
            Layer.Frame.BackgroundTransparency =
                AlphaAdjusted + (1 - AlphaAdjusted) * Value
        end
    end

    function ShadowObj:SetColor(Color)
        ShadowObj.Color = Color
        for _, Layer in ipairs(ShadowLayers) do
            Layer.Frame.BackgroundColor3 = Color
        end
    end

    function ShadowObj:SetGradient(State)
        ShadowObj.UseGradient = State
        for _, Layer in ipairs(ShadowLayers) do
            if State then
                if not Layer.Gradient then
                    Layer.Gradient = AddGradient(Layer.Frame)
                end
            else
                if Layer.Gradient then
                    Layer.Gradient:Destroy()
                    Layer.Gradient = nil
                end
            end
        end
    end

    return ShadowObj
end

function AttachTextShadow(Label, Options)
    Options = Options or {}

    local ShadowOffset = Options.Offset or Vector2.new(1, 1)
    local ShadowColor = Options.Color or Color3.fromRGB(0, 0, 0)
    local ShadowTransparency = Options.Transparency or 0.35
    local ShadowZIndex = Options.ZIndexOffset or -1

    local Shadow = Label:Clone()
    Shadow.Name = "TextShadow"
    Shadow.Parent = Label.Parent
    Shadow.BackgroundTransparency = 1
    Shadow.TextColor3 = ShadowColor
    Shadow.TextTransparency = ShadowTransparency
    Shadow.ZIndex = Label.ZIndex + ShadowZIndex
    Shadow.RichText = Label.RichText
    Shadow.TextStrokeTransparency = 1
    Shadow.TextWrapped = Label.TextWrapped
    Shadow.TextScaled = Label.TextScaled
    Shadow.FontFace = Label.FontFace

    local function Sync()
        if not Shadow.Parent then
            return
        end

        Shadow.Position = Label.Position + UDim2.fromOffset(ShadowOffset.X, ShadowOffset.Y)
        Shadow.Size = Label.Size
        Shadow.AnchorPoint = Label.AnchorPoint
        Shadow.Rotation = Label.Rotation
        Shadow.Text = Label.Text
        Shadow.TextSize = Label.TextSize
        Shadow.TextXAlignment = Label.TextXAlignment
        Shadow.TextYAlignment = Label.TextYAlignment
        Shadow.FontFace = Label.FontFace
        Shadow.TextWrapped = Label.TextWrapped
        Shadow.TextScaled = Label.TextScaled
        Shadow.Visible = Label.Visible
    end

    Sync()

    local Connections = {}

    local function Bind(Property)
        Connections[#Connections + 1] =
            Label:GetPropertyChangedSignal(Property):Connect(Sync)
    end

    Bind("Position")
    Bind("Size")
    Bind("AnchorPoint")
    Bind("Rotation")
    Bind("Text")
    Bind("TextSize")
    Bind("TextXAlignment")
    Bind("TextYAlignment")
    Bind("FontFace")
    Bind("TextWrapped")
    Bind("TextScaled")
    Bind("Visible")

    local ShadowController = {}

    function ShadowController:SetEnabled(State)
        Shadow.Visible = State == true
    end

    function ShadowController:SetOffset(NewOffset)
        ShadowOffset = NewOffset or ShadowOffset
        Sync()
    end

    function ShadowController:SetTransparency(Value)
        ShadowTransparency = tonumber(Value) or ShadowTransparency
        Shadow.TextTransparency = ShadowTransparency
    end

    function ShadowController:SetColor(Color)
        ShadowColor = Color or ShadowColor
        Shadow.TextColor3 = ShadowColor
    end

    function ShadowController:Destroy()
        for _, C in ipairs(Connections) do
            C:Disconnect()
        end
        Shadow:Destroy()
    end

    return ShadowController
end

local function SerializeUDim2(U)
    return {
        XScale = U.X.Scale,
        XOffset = U.X.Offset,
        YScale = U.Y.Scale,
        YOffset = U.Y.Offset
    }
end

local function DeserializeUDim2(T)
    if type(T) ~= "table" then
        return nil
    end

    return UDim2.new(
        tonumber(T.XScale) or 0,
        tonumber(T.XOffset) or 0,
        tonumber(T.YScale) or 0,
        tonumber(T.YOffset) or 0
    )
end

if getgenv().DynamicActive then
    if getgenv().DynamicActive.DisableAllModules then
        pcall(getgenv().DynamicActive.DisableAllModules)
    end
end

getgenv().DynamicActive = {}

local function DynamicUI()
    local ConfigSystem = {
        RootFolder = "Dynamic",
        ConfigFolder = "Dynamic/Configs",
        GameFolder = "Dynamic/Configs/" .. tostring(game.GameId),
        ConfigFile = "Dynamic/Configs/" .. tostring(game.GameId) .. "/Default.cfg"
    }
    EnsureFolder(ConfigSystem.RootFolder)
    EnsureFolder(ConfigSystem.ConfigFolder)
    EnsureFolder(ConfigSystem.GameFolder)
    EnsureFile(ConfigSystem.ConfigFile, "{}")
    Library.Config = ConfigSystem

    Library.ConfigData = {}
    local function SanitizeJson(Text)
        if Text:sub(1, 3) == "\239\187\191" then
            Text = Text:sub(4)
        end
        Text = Text:gsub("\r\n", "\n")
        Text = Text:gsub("\r", "\n")
        Text = Text:match("^%s*(.-)%s*$") or ""

        return Text
    end

    local function LoadConfigFile()
        if not isfile(Library.Config.ConfigFile) then
            return {}
        end

        local Raw = readfile(Library.Config.ConfigFile)
        if type(Raw) ~= "string" or #Raw == 0 then
            return {}
        end

        Raw = SanitizeJson(Raw)

        local Ok, Data = pcall(function()
            return Services.HttpService:JSONDecode(Raw)
        end)

        if not Ok or type(Data) ~= "table" then
            return {}
        end

        return Data
    end

    local function PrettyJSON(JsonString)
        local Indent = 0
        local Result = {}
        local InString = false

        for i = 1, #JsonString do
            local Char = JsonString:sub(i, i)

            if Char == '"' and JsonString:sub(i - 1, i - 1) ~= "\\" then
                InString = not InString
            end

            if not InString then
                if Char == "{" or Char == "[" then
                    Indent += 1
                    table.insert(Result, Char .. "\n" .. string.rep("    ", Indent))

                elseif Char == "}" or Char == "]" then
                    Indent -= 1
                    table.insert(Result, "\n" .. string.rep("    ", Indent) .. Char)

                elseif Char == "," then
                    table.insert(Result, Char .. "\n" .. string.rep("    ", Indent))

                elseif Char == ":" then
                    table.insert(Result, ": ")

                else
                    table.insert(Result, Char)
                end
            else
                table.insert(Result, Char)
            end
        end

        return table.concat(Result)
    end

    local function PruneEmptyTables(tbl)
        for key, value in pairs(tbl) do
            if type(value) == "table" then
                PruneEmptyTables(value)

                if next(value) == nil then
                    tbl[key] = nil
                end
            end
        end
    end

    local function SaveConfigFile()
        local DataCopy = Services.HttpService:JSONDecode(
            Services.HttpService:JSONEncode(Library.ConfigData)
        )

        PruneEmptyTables(DataCopy)

        local Encoded = Services.HttpService:JSONEncode(DataCopy)
        local Pretty = PrettyJSON(Encoded)
        writefile(Library.Config.ConfigFile, Pretty)
    end

    Library.ConfigData = LoadConfigFile()
    Library.SaveConfigFile = SaveConfigFile

    function Library.ForEachModule(Callback)
        for _, Module in ipairs(Library.Window.Modules) do
            local Obj = Library.Flags[Module.Flag]
            if Obj and type(Obj) == "table" then
                Callback(Module, Obj)
            end
        end
    end

    Library.ModuleAddedCallbacks = {}

    function Library.OnModuleAdded(Callback)
        table.insert(Library.ModuleAddedCallbacks, Callback)
    end

    function Library.FireModuleAdded(Module)
        for _, Callback in ipairs(Library.ModuleAddedCallbacks) do
            task.spawn(Callback, Module)
        end
    end

    Library.RenderConnections = {}
    Library.HeartbeatConnections = {}

    local function AddRenderStep(Id, Callback)
        Library.RenderConnections[Id] = Callback
    end

    local function AddHeartbeat(Id, Callback)
        Library.HeartbeatConnections[Id] = Callback
    end

    local function RemoveRenderStep(Id)
        Library.RenderConnections[Id] = nil
    end

    local function RemoveHeartbeat(Id)
        Library.HeartbeatConnections[Id] = nil
    end

    Library.MainRenderLoop = Services.RunService.RenderStepped:Connect(function(DeltaTime)
        for _, Callback in pairs(Library.RenderConnections) do
            pcall(Callback, DeltaTime)
        end
    end)

    Library.MainHeartbeatLoop = Services.RunService.Heartbeat:Connect(function(DeltaTime)
        for _, Callback in pairs(Library.HeartbeatConnections) do
            pcall(Callback, DeltaTime)
        end
    end)

    function Library.DisableAllModules()
        for _, Module in ipairs(Library.Window.Modules) do
            local Obj = Library.Flags[Module.Flag]
            if Obj and type(Obj) == "table" and Obj.Value then
                Obj:SetValue(false, {
                    SkipSave = true
                })
            end
        end

        table.clear(Library.RenderConnections)
        table.clear(Library.HeartbeatConnections)

        if Library.RefreshArrayList then
            Library:RefreshArrayList()
        end
    end

    function Library:AddRenderConnection(Id, Callback)
        AddRenderStep(Id, Callback)
    end

    function Library:AddHeartbeatConnection(Id, Callback)
        AddHeartbeat(Id, Callback)
    end

    function Library:RemoveRenderConnection(Id)
        RemoveRenderStep(Id)
    end

    function Library:RemoveHeartbeatConnection(Id)
        RemoveHeartbeat(Id)
    end

    getgenv().DynamicActive.DisableAllModules = Library.DisableAllModules

    Library.FlagListeners = Library.FlagListeners or {}

    function Library:OnFlagChanged(callback)
        table.insert(self.FlagListeners, callback)
    end

    function Library:FireFlagChanged(flag)
        for _, fn in ipairs(self.FlagListeners) do
            task.spawn(fn, flag)
        end
    end

    getgenv().DynamicSessionId = (getgenv().DynamicSessionId or 0) + 1
    local SessionId = getgenv().DynamicSessionId

    local ProtectGui = syn and syn.protect_gui or protectgui
    
    -- Clean up old GUI elements (wrapped in pcall for safety)
    pcall(function()
        local Cleanup = {
            { Parent = Services.CoreGui, Name = "DynamicUI" },
            { Parent = Services.CoreGui, Name = "DynamicHUD" },
            { Parent = Services.CoreGui, Name = "DynamicCursorGui" },
        }
        
        -- Only add PlayerGui cleanup if LocalPlayer is available
        local LocalPlayer = Services.Players and Services.Players.LocalPlayer
        if LocalPlayer then
            table.insert(Cleanup, { Parent = LocalPlayer:WaitForChild("PlayerGui"), Name = "MouseUnlockerGui" })
        end

        for _, Item in ipairs(Cleanup) do
            if Item.Parent then
                local Gui = Item.Parent:FindFirstChild(Item.Name)
                if Gui then
                    if Item.Name == "DynamicUI" and Library.DisableAllModules then
                        Library.DisableAllModules()
                    end
                    Gui:Destroy()
                end
            end
        end
    end)

    local GuiConfigs = {
        DynamicUI = {
            Parent = Services.CoreGui,
            Props = {
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            }
        },

        DynamicHUD = {
            Parent = Services.CoreGui,
            Props = {
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            }
        },

        MouseUnlockerGui = {
            Parent = Services.Players.LocalPlayer:WaitForChild("PlayerGui"),
            Props = {
                ResetOnSpawn = false,
                IgnoreGuiInset = true,
                DisplayOrder = 5,
                Enabled = false,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            }
        },

        DynamicCursorGui = {
            Parent = Services.CoreGui,
            Props = {
                ResetOnSpawn = false,
                IgnoreGuiInset = false,
                DisplayOrder = 2147483647,
                ZIndexBehavior = Enum.ZIndexBehavior.Global,
            }
        }
    }

    local Guis = {}

    for Name, Config in pairs(GuiConfigs) do
        local Gui = Instance.new("ScreenGui")
        Gui.Name = Name
        for Prop, Value in pairs(Config.Props) do
            Gui[Prop] = Value
        end
        if ProtectGui then
            ProtectGui(Gui)
        end
        Gui.Parent = Config.Parent
        Guis[Name] = Gui
    end

    local DynamicUI = Guis.DynamicUI
    local DynamicHUD = Guis.DynamicHUD
    local MouseUnlockerGui = Guis.MouseUnlockerGui
    local DynamicCursorGui = Guis.DynamicCursorGui

    local ExistingBlur = Services.Lighting:FindFirstChild("ClickGuiBlur")
    if ExistingBlur then
        ExistingBlur:Destroy()
    end

    local ClickGui = Instance.new("Frame")
	ClickGui.Name = "ClickGui"
    ClickGui.Position = UDim2.new(0, 260, 0, 0)
	ClickGui.Size = UDim2.new(0, 800, 0, 400)
	ClickGui.BackgroundTransparency = 1
    ClickGui.Visible = false
	ClickGui.Parent = DynamicUI

    local ClickGuiLayout = Instance.new("UIListLayout")
    ClickGuiLayout.FillDirection = Enum.FillDirection.Horizontal
    ClickGuiLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ClickGuiLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    ClickGuiLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ClickGuiLayout.Padding = UDim.new(0, 10)
    ClickGuiLayout.Parent = ClickGui

    local Veil = Instance.new("ImageLabel")
    Veil.Name = "BackgroundVeil"
    Veil.BackgroundTransparency = 1
    Veil.ImageTransparency = 1
    Veil.Size = UDim2.new(1, 0, 1, 0)
    Veil.ScaleType = Enum.ScaleType.Stretch
    Veil.ZIndex = 0
    Veil.Image = Assets:GetImage("Images/Veil.png")
    Veil.Parent = DynamicUI
    AddGradient(Veil)
    
    local ClickGuiBlur = Instance.new("BlurEffect")
    ClickGuiBlur.Name = "ClickGuiBlur"
    ClickGuiBlur.Size = 0
    ClickGuiBlur.Enabled = false
    ClickGuiBlur.Parent = Services.Lighting

    local ClickGuiObj = {
        Frame = ClickGui,
        Open = false,
        Tween = nil,
        ExpandedModules = {}
    }

    local OpenPosition = ClickGui.Position
    local ClosedPosition = OpenPosition - UDim2.fromOffset(0, 180)

    ClickGui.Position = ClosedPosition

    local VeilTween
    local BlurTween

    local ModalButton = Instance.new("TextButton")
    ModalButton.Name = "ModalCatcher"
    ModalButton.Size = UDim2.fromScale(1, 1)
    ModalButton.BackgroundTransparency = 1
    ModalButton.Text = ""
    ModalButton.AutoButtonColor = false
    ModalButton.Modal = false
    ModalButton.Parent = MouseUnlockerGui

    local CursorImage = Instance.new("ImageLabel")
    CursorImage.Name = "Cursor"
    CursorImage.Size = UDim2.fromOffset(10, 10)
    CursorImage.BackgroundTransparency = 1
    CursorImage.BorderSizePixel = 0
    CursorImage.Image = Assets:GetImage("Images/CircleImage.png")
    CursorImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
    CursorImage.ImageTransparency = 0
    CursorImage.AnchorPoint = Vector2.new(0.5, 0.5)
    CursorImage.Visible = false
    CursorImage.ZIndex = 1
    CursorImage.Parent = DynamicCursorGui
    AddGradient(CursorImage)

    local CursorShadow = Instance.new("ImageLabel")
    CursorShadow.Name = "Shadow"
    CursorShadow.AnchorPoint = Vector2.new(0.5, 0.5)
    CursorShadow.Size = UDim2.fromOffset(14, 14)
    CursorShadow.BackgroundTransparency = 1
    CursorShadow.Image = Assets:GetImage("Images/CircleImage.png")
    CursorShadow.ImageColor3 = Color3.fromRGB(255, 255, 255)
    CursorShadow.ImageTransparency = 0.65
    CursorShadow.ZIndex = 0
    CursorShadow.Parent = DynamicCursorGui
    AddGradient(CursorShadow)

    local MouseRenderConnection
    local PreviousMouseBehavior = Services.UserInputService.MouseBehavior
    local PreviousMouseIconEnabled = Services.UserInputService.MouseIconEnabled

    local function UpdateMouseUnlocker()
        local Active = ClickGuiObj.Open
        local UserInputService = Services.UserInputService

        MouseUnlockerGui.Enabled = Active
        ModalButton.Modal = Active
        CursorImage.Visible = Active
        CursorShadow.Visible = Active

        if Active then
            PreviousMouseBehavior = UserInputService.MouseBehavior
            PreviousMouseIconEnabled = UserInputService.MouseIconEnabled

            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = false
        else
            UserInputService.MouseBehavior = PreviousMouseBehavior
            UserInputService.MouseIconEnabled = PreviousMouseIconEnabled
        end
    end

    Library:RemoveRenderConnection("ClickGuiCursor")
    Library:AddRenderConnection("ClickGuiCursor", function()
        if not ClickGuiObj.Open then
            return
        end

        local MousePos = Services.UserInputService:GetMouseLocation()
        local Inset = Services.GuiService:GetGuiInset()

        local X = MousePos.X - Inset.X
        local Y = MousePos.Y - Inset.Y

        CursorImage.Position = UDim2.fromOffset(X, Y)
        CursorShadow.Position = UDim2.fromOffset(X, Y)
    end)

    function Library:SyncShadowState(Shadow)
        if not Shadow then return end
        if not Shadow.SetTransparency then return end

        local Open = Library.ClickGui and Library.ClickGui.Open
        Shadow:SetTransparency(Open and 0 or 1)
    end

    function ClickGuiObj:Toggle(Value)
        if Value == nil then
            Value = not self.Open
        end

        local SameState = (self.Open == Value)
        self.Open = Value

        if Library.ActiveShadows then
            for _, CategoryListShadow in ipairs(Library.ActiveShadows) do
                local Ignore = false

                if typeof(CategoryListShadow) == "Instance" then
                    Ignore = CategoryListShadow:GetAttribute("IgnoreGlobalShadow") == true
                elseif type(CategoryListShadow) == "table" then
                    Ignore = CategoryListShadow.IgnoreGlobalShadow == true
                end

                if not Ignore and CategoryListShadow.SetTransparency then
                    CategoryListShadow:SetTransparency(Value and 0 or 1)
                end
            end
        end

        if self.Tween then
            self.Tween:Cancel()
            self.Tween = nil
        end

        if VeilTween then
            VeilTween:Cancel()
            VeilTween = nil
        end

        if BlurTween then
            BlurTween:Cancel()
            BlurTween = nil
        end

        self.Frame.Visible = true
        Veil.Visible = true

        local TargetPosition = Value and OpenPosition or ClosedPosition

        local AnimationMode = Library.Flags and Library.Flags.Interface_Animation or "Slide"
        if AnimationMode == "Fade" then
            self.Frame.Position = OpenPosition
        end

        if AnimationMode ~= "Fade" then
            self.Tween = Services.TweenService:Create(
                self.Frame,
                TweenInfo.new(
                    0.25,
                    Enum.EasingStyle.Quart,
                    Enum.EasingDirection.Out
                ),
                {
                    Position = TargetPosition
                }
            )
        end

        VeilTween = Services.TweenService:Create(
            Veil,
            TweenInfo.new(
                0.25,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            {
                ImageTransparency = Value and 0 or 1
            }
        )

        ClickGuiBlur.Enabled = true
        BlurTween = Services.TweenService:Create(
            ClickGuiBlur,
            TweenInfo.new(
                0.25,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            {
                Size = Value and 24 or 0
            }
        )

        if self.Tween then
            self.Tween:Play()
        end

        VeilTween:Play()
        BlurTween:Play()

        local ExpandedCache = self.ExpandedModules

        if not Value then
            table.clear(ExpandedCache)

            for _, ModuleObj in pairs(Library.Flags) do
                if typeof(ModuleObj) == "table"
                    and ModuleObj.Expanded ~= nil
                    and typeof(ModuleObj.ToggleExpand) == "function"
                then
                    if ModuleObj.Expanded then
                        ExpandedCache[ModuleObj] = true
                        ModuleObj:ToggleExpand()
                    end
                end
            end

            if Library.ActiveColorpickers then
                for Picker in pairs(Library.ActiveColorpickers) do
                    if typeof(Picker) == "table"
                        and typeof(Picker.AnimateColorpicker) == "function"
                    then
                        Picker:AnimateColorpicker(false)
                    end
                end
            end

            if Library.ActiveShadows then
                for _, CategoryListShadow in ipairs(Library.ActiveShadows) do
                    local Ignore = false

                    if typeof(CategoryListShadow) == "Instance" then
                        Ignore = CategoryListShadow:GetAttribute("IgnoreGlobalShadow") == true
                    elseif type(CategoryListShadow) == "table" then
                        Ignore = CategoryListShadow.IgnoreGlobalShadow == true
                    end

                    if not Ignore and CategoryListShadow.SetTransparency then
                        CategoryListShadow:SetTransparency(1)
                    end
                end
            end

            local CloseToken = {}
            self.CloseToken = CloseToken

            local BlurCloseToken = {}
            self.BlurCloseToken = BlurCloseToken

            task.delay(0.25, function()
                if self.CloseToken ~= CloseToken or self.BlurCloseToken ~= BlurCloseToken then
                    return
                end

                if not self.Open then
                    self.Frame.Visible = false
                    DynamicUI.Enabled = false
                    Veil.Visible = false
                    ClickGuiBlur.Enabled = false
                end
            end)
        else
            DynamicUI.Enabled = true

            for ModuleObj in pairs(ExpandedCache) do
                if typeof(ModuleObj) == "table"
                    and ModuleObj.Expanded ~= nil
                    and typeof(ModuleObj.ToggleExpand) == "function"
                then
                    if not ModuleObj.Expanded then
                        ModuleObj:ToggleExpand()
                    end
                end
            end

            table.clear(ExpandedCache)

            if Library.ActiveShadows then
                for _, CategoryListShadow in ipairs(Library.ActiveShadows) do
                    local Ignore = false

                    if typeof(CategoryListShadow) == "Instance" then
                        Ignore = CategoryListShadow:GetAttribute("IgnoreGlobalShadow") == true
                    elseif type(CategoryListShadow) == "table" then
                        Ignore = CategoryListShadow.IgnoreGlobalShadow == true
                    end

                    if not Ignore and CategoryListShadow.SetTransparency then
                        CategoryListShadow:SetTransparency(0)
                    end
                end
            end
        end

        for _, Child in ipairs(self.Frame:GetChildren()) do
            if Child:IsA("CanvasGroup") then
                Services.TweenService:Create(
                    Child,
                    TweenInfo.new(
                        0.25,
                        Enum.EasingStyle.Quart,
                        Enum.EasingDirection.Out
                    ),
                    { GroupTransparency = Value and 0 or 1 }
                ):Play()
            end
        end

        UpdateMouseUnlocker()
    end
    UpdateMouseUnlocker()

    task.defer(function()
        local Shadows = Library.ActiveShadows
        if not Shadows then
            return
        end
        for _, Shadow in ipairs(Shadows) do
            local Ignore = false

            if typeof(Shadow) == "Instance" then
                Ignore = Shadow:GetAttribute("IgnoreGlobalShadow") == true
            elseif type(Shadow) == "table" then
                Ignore = Shadow.IgnoreGlobalShadow == true
            end

            if Ignore then
                continue
            end

            local SetTransparency = Shadow.SetTransparency
            if not SetTransparency then
                continue
            end

            Shadow.SetTransparency = function(self, Value)
                return SetTransparency(self, ClickGuiObj.Open and Value or 1)
            end

            Shadow:SetTransparency(ClickGuiObj.Open and 0 or 1)
        end
    end)

    Library.UISettings = Library.UISettings or {
        FontFace = Library.CurrentFontFace or Library.FontFaces.GoogleSans,
        LayoutMode = Library.LayoutMode or "Ascending",
        Theme = Library.CurrentTheme,
        FontObjects = {},
        LayoutContainers = {}
    }

    local UISettings = Library.UISettings
    Library.CurrentFontFace = UISettings.FontFace
    Library.LayoutMode = UISettings.LayoutMode
    Library.CurrentTheme = UISettings.Theme

    function UISettings:SetTheme(Name)
        if not Name or UISettings.Theme == Name then
            return
        end

        UISettings.Theme = Name
        Library.CurrentTheme = Name
        SetTheme(Name)
    end

    local function GetMetric(Object)
        local Button = Object:FindFirstChildOfClass("TextButton")
        if not Button then
            return 0
        end

        local Label = Button:FindFirstChildOfClass("TextLabel")
        if not Label then
            return 0
        end

        return Label.TextBounds.X
    end
    
    function UISettings:ApplyLayout(Container)
        if not Container or not Container.Parent then
            return
        end

        local Items = {}

        for _, Child in ipairs(Container:GetChildren()) do
            if Child:IsA("GuiObject") then
                Items[#Items + 1] = Child
            end
        end

        if #Items <= 1 then
            return
        end

        table.sort(Items, function(a, b)
            return GetMetric(a) < GetMetric(b)
        end)

        local Count = #Items

        if UISettings.LayoutMode == "Ascending" then
            for i = 1, Count do
                Items[i].LayoutOrder = Count - i + 1
            end
        else
            for i = 1, Count do
                Items[i].LayoutOrder = i
            end
        end
    end

    function UISettings:Register(Object)
        if not Object then
            return
        end

        if Object:IsA("TextLabel")
            or Object:IsA("TextButton")
            or Object:IsA("TextBox") then

            UISettings.FontObjects[Object] = true
            Object.FontFace = UISettings.FontFace
        end

        if Object:IsA("GuiObject") then
            UISettings.LayoutContainers[Object] = true

            local function RefreshLayout()
                task.defer(function()
                    if Object.Parent then
                        UISettings:ApplyLayout(Object)
                    end
                end)
            end

            RefreshLayout()
            Object.ChildAdded:Connect(RefreshLayout)
            Object.ChildRemoved:Connect(RefreshLayout)
        end
    end

    function UISettings:SetLayoutMode(Mode)
        if Mode ~= "Ascending" and Mode ~= "Descending" then
            return
        end

        if UISettings.LayoutMode == Mode then
            return
        end

        UISettings.LayoutMode = Mode
        Library.LayoutMode = Mode

        for Container in pairs(UISettings.LayoutContainers) do
            if Container.Parent then
                UISettings:ApplyLayout(Container)
            else
                UISettings.LayoutContainers[Container] = nil
            end
        end
    end

    function UISettings:SetFont(FontFace)
        if not FontFace or UISettings.FontFace == FontFace then
            return
        end

        UISettings.FontFace = FontFace
        Library.CurrentFontFace = FontFace

        for Object in pairs(UISettings.FontObjects) do
            if Object.Parent then
                Object.FontFace = FontFace
            else
                UISettings.FontObjects[Object] = nil
            end
        end
    end

    function UIFont(Object)
        if Object then
            UISettings:Register(Object)
        end

        return UISettings.FontFace
    end

    task.defer(function()
        local SavedTheme = Library.Flags.Interface_Theme
        if typeof(SavedTheme) == "string" then
            UISettings:SetTheme(SavedTheme)
        end

        local SavedFont = Library.Flags.Interface_Font
        local FontFace = Library.FontFaces[SavedFont]
        if FontFace then
            UISettings:SetFont(FontFace)
        end

        local SavedLayout = Library.Flags.ClickGui_Layout
        if SavedLayout then
            UISettings:SetLayoutMode(SavedLayout)
        end
    end)

    function Library:CreateWindow()
        local Window = {
            Categories = {},
            Modules = {},
            Elements = {}
        }

        Library.Window = Window
        local function AddCategory(Info)
            local Name = Info.Name
            local Order = Info.Order

            local CategoryObj = {
                LayoutOrder = 0,
                AutoOrder = 0,
                FirstOrder = -1e6,
                LastOrder = 1e6,
            }

            if Order == "First" then
                CategoryObj.LayoutOrder = CategoryObj.FirstOrder
                CategoryObj.FirstOrder += 1

            elseif Order == "Last" then
                CategoryObj.LayoutOrder = CategoryObj.LastOrder
                CategoryObj.LastOrder -= 1

            elseif type(Order) == "number" then
                CategoryObj.LayoutOrder = Order

            else
                CategoryObj.AutoOrder += 1
                CategoryObj.LayoutOrder = CategoryObj.AutoOrder
            end

            local CategoryGroup = Instance.new("CanvasGroup")
            CategoryGroup.Name = Name
            CategoryGroup.Size = UDim2.new(0, 126, 0, 350)
            CategoryGroup.BackgroundTransparency = 1
            CategoryGroup.LayoutOrder = CategoryObj.LayoutOrder
            CategoryGroup.Parent = ClickGui

            local CategoryName = Instance.new("TextLabel")
            CategoryName.Name = "Title"
            CategoryName.Size = UDim2.new(1, 0, 0, 45)
            CategoryName.BackgroundTransparency = 0
            CategoryName.BackgroundColor3 = GetTheme().HeaderBackground
            CategoryName.BorderSizePixel = 0
            CategoryName.Text = Name
            CategoryName.TextXAlignment = Enum.TextXAlignment.Center
            CategoryName.TextYAlignment = Enum.TextYAlignment.Center
            CategoryName.TextWrapped = false
            CategoryName.TextScaled = false
            CategoryName.AutomaticSize = Enum.AutomaticSize.None
            CategoryName.FontFace = UIFont(CategoryName)
            CategoryName.TextColor3 = GetTheme().Text
            CategoryName.TextSize = 16
            CategoryName.Parent = CategoryGroup
            Instance.new("UICorner", CategoryName).CornerRadius = UDim.new(0, 26)
            Instance.new("UIPadding", CategoryName).PaddingBottom = UDim.new(0.5, 0)
            AttachTextShadow(CategoryName, {
                Offset = Vector2.new(1, 1),
                Transparency = 0.4
            })

            local CategoryList = Instance.new("CanvasGroup")
            CategoryList.Name = "List"
            CategoryList.Size = UDim2.new(1, 0, 1, 0)
            CategoryList.BackgroundTransparency = 1
            CategoryList.Parent = CategoryGroup
            CategoryList.ClipsDescendants = true
            Instance.new("UICorner", CategoryList).CornerRadius = UDim.new(0, 26)
            local CategoryListShadow = AttachShadow(DynamicUI, CategoryList, 26, 8, 7, 1.2, Color3.fromRGB(0, 0, 0), false)
            Library.ActiveShadows[#Library.ActiveShadows + 1] = CategoryListShadow
            if CategoryListShadow and CategoryListShadow.SetTransparency then
                local Open = Library.ClickGui and Library.ClickGui.Open
                CategoryListShadow:SetTransparency(Open and 0 or 1)
            end

            local Container = Instance.new("ScrollingFrame")
            Container.Name = "Container"
            Container.Size = UDim2.new(1, 0, 1, -25)
            Container.Position = UDim2.new(0, 0, 0, 25)
            Container.BackgroundColor3 = GetTheme().ItemDefault
            Container.BackgroundTransparency = 0
            Container.BorderSizePixel = 0
            Container.CanvasSize = UDim2.new(0, 0, 0, 0)
            Container.ScrollBarImageTransparency = 1
            Container.ScrollBarThickness = 0
            Container.ScrollingDirection = Enum.ScrollingDirection.Y
            Container.ElasticBehavior = Enum.ElasticBehavior.Never
            Container.VerticalScrollBarInset = Enum.ScrollBarInset.None
            Container.AutomaticCanvasSize = Enum.AutomaticSize.None
            Container.Parent = CategoryList
            local ContainerLayout = Instance.new("UIListLayout", Container)
            ContainerLayout.SortOrder = Enum.SortOrder.LayoutOrder
            Library.UISettings:Register(Container)

            local function UpdateContainer()
                local ContentHeight = ContainerLayout.AbsoluteContentSize.Y
                Container.CanvasSize = UDim2.fromOffset(0, ContentHeight)

                local MaxVisible =
                    CategoryGroup.AbsoluteSize.Y
                    - CategoryName.AbsoluteSize.Y

                local Visible = math.min(ContentHeight + 25, MaxVisible)

                local CurrentListSize = CategoryList.Size
                local CurrentContainerSize = Container.Size

                CategoryList.Size = UDim2.new(
                    CurrentListSize.X.Scale,
                    CurrentListSize.X.Offset,
                    0,
                    Visible
                )

                Container.Size = UDim2.new(
                    CurrentContainerSize.X.Scale,
                    CurrentContainerSize.X.Offset,
                    0,
                    Visible - 25
                )
            end

            CategoryGroup:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateContainer)
            ContainerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateContainer)
            UpdateContainer()

            local Category = {
                Name = Name,
                Order = CategoryObj.LayoutOrder,
                Group = CategoryGroup,
                List = CategoryList,
                Container = Container,
                Layout = ContainerLayout
            }
            Library.Window.Categories[Name] = Category

            return Category
        end
        Library.Window.AddCategory = function(_, ...)
			return AddCategory(...)
		end

        function Library:RegisterElement(Type, Constructor)
            Library.Window.Elements[Type] = Constructor
        end

        Library.Window.HUDs = Library.Window.HUDs or {}
        Library.Window.HUDRegistry = Library.Window.HUDRegistry or {}

        function Library:RegisterHUD(Type, Constructor)
            Library.Window.HUDRegistry[Type] = Constructor
        end

        function Library:AddHUD(Type, Info)
            local Constructor = Library.Window.HUDRegistry[Type]
            if not Constructor then
                return
            end

            Library.HUDFlags = Library.HUDFlags or {}
            Library.HUDInstances = Library.HUDInstances or {}
            Library.ConfigData.HUD = Library.ConfigData.HUD or {}

            local Index = (#Library.HUDInstances) + 1
            local Flag = (Info and Info.Flag) or ("HUD_" .. tostring(Index))

            Library.ConfigData.HUD[Flag] = Library.ConfigData.HUD[Flag] or {}
            local Config = Library.ConfigData.HUD[Flag]

            local Fixed = Info.Fixed == true
            local VisibleSource = Info.Visible
            local ConditionSource = Info.Condition

            local function ResolveVisible()
                if type(VisibleSource) == "function" then
                    return VisibleSource() == true
                end
                if VisibleSource == nil then
                    return true
                end
                return VisibleSource == true
            end

            local function ResolveCondition()
                if Fixed then
                    return false
                end
                if type(ConditionSource) == "function" then
                    return ConditionSource() == true
                end
                if ConditionSource == nil then
                    return true
                end
                return ConditionSource == true
            end

            local HUD = Constructor({
                Index = Index,
                Info = Info or {},
                Flag = Flag,
                Config = Config,
                Library = Library,
                SessionId = SessionId,
                DynamicHUD = DynamicHUD
            })

            if not HUD or not HUD.Root then
                return
            end

            local Root = HUD.Root
            Root.Active = ResolveCondition()
            Root.Visible = ResolveVisible()

            local Dragging = false
            local DragStart
            local StartPos

            Library:AddRenderConnection("RootVisibility_" .. tostring(SessionId), function()
                if getgenv().DynamicSessionId ~= SessionId then
                    return
                end

                Root.Visible = ResolveVisible()
                Root.Active = ResolveCondition()
            end)

            Root.InputBegan:Connect(function(Input)
                if getgenv().DynamicSessionId ~= SessionId then
                    return
                end

                if not ResolveCondition() then
                    return
                end

                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Dragging = true
                    DragStart = Input.Position
                    StartPos = Root.Position
                end
            end)

            Services.UserInputService.InputEnded:Connect(function(Input)
                if getgenv().DynamicSessionId ~= SessionId then
                    return
                end

                if not ResolveCondition() then
                    Dragging = false
                    return
                end

                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Dragging = false
                    Config.Position = SerializeUDim2(Root.Position)
                    Library.SaveConfigFile()
                end
            end)

            Services.UserInputService.InputChanged:Connect(function(Input)
                if not Dragging then
                    return
                end

                if getgenv().DynamicSessionId ~= SessionId then
                    return
                end

                if not ResolveCondition() then
                    return
                end

                if Input.UserInputType == Enum.UserInputType.MouseMovement then
                    local Delta = Input.Position - DragStart
                    Root.Position = UDim2.new(
                        StartPos.X.Scale,
                        StartPos.X.Offset + Delta.X,
                        StartPos.Y.Scale,
                        StartPos.Y.Offset + Delta.Y
                    )
                end
            end)

            local HUDAPI = HUD.API or {}

            HUDAPI.Flag = Flag
            HUDAPI.Index = Index

            HUDAPI.SetVisible = function(_, State)
                VisibleSource = State
                Root.Visible = ResolveVisible()
            end

            HUDAPI.Destroy = function()
                Root:Destroy()
                if HUD.Destroy then
                    HUD.Destroy()
                end
            end

            Library.HUDInstances[Index] = HUDAPI
            Library.HUDFlags[Flag] = HUDAPI

            return HUDAPI
        end

        local function AddModule(Info)
            local CategoryName = Info.Category
            local Name = Info.Name
            local Default = Info.Default == true
            local Callback = Info.Callback
            local AlwaysOn = Info.AlwaysOn == true
            local Flag = Info.Flag or Name
            local DefaultKey = nil

            if Info.Keybind then
                if typeof(Info.Keybind) == "string" then
                    DefaultKey = Enum.KeyCode[Info.Keybind]
                elseif typeof(Info.Keybind) == "EnumItem" then
                    DefaultKey = Info.Keybind
                end
            end

            local Category = Library.Window.Categories[CategoryName]
            local Container = Category.Container

            Library.Flags = Library.Flags or {}
            Library.ConfigData = Library.ConfigData or {}

            local SavedData = Library.ConfigData[Flag]

            local InitialValue = AlwaysOn or Default
            local InitialKey = DefaultKey
            local InitialExpanded = false

            if type(SavedData) == "table" then
                if not AlwaysOn then
                    if type(SavedData.Value) == "boolean" then
                        InitialValue = SavedData.Value
                    end

                    if type(SavedData.Keybind) == "string" then
                        InitialKey = Enum.KeyCode[SavedData.Keybind] or InitialKey
                    end
                end

                if type(SavedData.Expanded) == "boolean" then
                    InitialExpanded = SavedData.Expanded
                end
            end

            local ModuleObj = {
                LayoutOrder = 0,
                Value = InitialValue,
                Expanded = InitialExpanded,
            }

            local Module = {
                Name = Name,
                Flag = Flag,
                Category = CategoryName,
                CategoryRef = Category,
                Container = Container,
                Instance = ModuleItem,
                Button = ModuleButton,
                Gradient = ModuleGradient,
                ElementContainer = ElementContainer,
                ElementLayout = ElementLayout,
                Keybind = AlwaysOn and nil or InitialKey,
                Set = SetValue,
                Toggle = function()
                    ModuleObj:Toggle()
                end,
                 SetKeybind = function(NewKey)
                    if AlwaysOn then return end
                    if typeof(NewKey) == "EnumItem" then
                        Module.Keybind = NewKey
                        SaveModuleConfig(Library.Flags[Flag], NewKey)
                    end
                end,
                Elements = {},
                ElementCounters = {},
                Dividers = {},
                Toggles = {},
                Sliders = {},
                Dropdowns = {},
                Colorpickers = {},
                Keyboxs = {},
            }

            local ModuleItem = Instance.new("Frame")
            ModuleItem.Name = Name
            ModuleItem.Size = UDim2.new(1, 0, 0, 25)
            ModuleItem.BackgroundTransparency = 1
            ModuleItem.ClipsDescendants = true
            ModuleItem.LayoutOrder = ModuleObj.LayoutOrder
            ModuleItem.Parent = Container
            Library.UISettings:Register(Container)
            
            local ModuleButton = Instance.new("TextButton")
            ModuleButton.FontFace = UIFont(ModuleButton)
            ModuleButton.TextColor3 = GetTheme().Text
            ModuleButton.TextSize = 16
            ModuleButton.BackgroundColor3 = GetTheme().ItemDefault
            ModuleButton.BorderSizePixel = 0
            ModuleButton.Size = UDim2.new(1, 0, 0, 25)
            ModuleButton.Text = ""
            ModuleButton.AutoButtonColor = false
            ModuleButton.Parent = ModuleItem

            local ModuleText = Instance.new("TextLabel")
            ModuleText.BackgroundTransparency = 1
            ModuleText.Size = UDim2.new(1, 0, 1, 0)
            ModuleText.Position = UDim2.new(0, 0, 0, 0)
            ModuleText.FontFace = UIFont(ModuleText)
            ModuleText.TextColor3 = GetTheme().Text
            ModuleText.TextSize = 16
            ModuleText.Text = Name
            ModuleText.TextXAlignment = Enum.TextXAlignment.Center
            ModuleText.TextYAlignment = Enum.TextYAlignment.Center
            ModuleText.Parent = ModuleButton
            AttachTextShadow(ModuleText, {
                Offset = Vector2.new(1, 1),
                Color = GetTheme().ItemDefault,
                Transparency = 0.6
            })

            local ModuleGradient = Instance.new("TextButton")
            ModuleGradient.Text = ""
            ModuleGradient.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ModuleGradient.BorderSizePixel = 0
            ModuleGradient.AutoButtonColor = false
            ModuleGradient.Active = false
            ModuleGradient.Selectable = false
            ModuleGradient.Size = UDim2.new(1, 0, 0, 25)
            ModuleGradient.ZIndex = ModuleButton.ZIndex - 1
            ModuleGradient.Parent = ModuleItem
            AddGradient(ModuleGradient)

            local ElementContainer = Instance.new("Frame")
            ElementContainer.Position = UDim2.new(0, 0, 0, 25)
            ElementContainer.Size = UDim2.new(1, 0, 0, 0)
            ElementContainer.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
            ElementContainer.BackgroundTransparency = 0
            ElementContainer.BorderSizePixel = 0
            ElementContainer.ClipsDescendants = true
            ElementContainer.Parent = ModuleItem

            local ElementLayout = Instance.new("UIListLayout")
            ElementLayout.Padding = UDim.new(0, 0)
            ElementLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ElementLayout.Parent = ElementContainer

            local BottomSpacer = Instance.new("Frame")
            BottomSpacer.Size = UDim2.new(1, 0, 0, 5)
            BottomSpacer.BackgroundTransparency = 1
            BottomSpacer.LayoutOrder = 1e6
            BottomSpacer.Parent = ElementContainer

            local ButtonTween
            local GradientTween

            local function SetVisualState(IsEnabled)
                if ButtonTween then
                    ButtonTween:Cancel()
                end

                if GradientTween then
                    GradientTween:Cancel()
                end

                if IsEnabled then
                    ModuleGradient.Visible = true

                    ButtonTween = Services.TweenService:Create(
                        ModuleButton,
                        TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                        { BackgroundTransparency = 1 }
                    )

                    GradientTween = Services.TweenService:Create(
                        ModuleGradient,
                        TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                        { BackgroundTransparency = 0 }
                    )

                    ButtonTween:Play()
                    GradientTween:Play()
                else
                    ButtonTween = Services.TweenService:Create(
                        ModuleButton,
                        TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                        { BackgroundTransparency = 0 }
                    )

                    GradientTween = Services.TweenService:Create(
                        ModuleGradient,
                        TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                        { BackgroundTransparency = 1 }
                    )

                    ButtonTween:Play()
                    GradientTween:Play()

                    task.delay(TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out).Time, function()
                        if not ModuleObj.Value then
                            ModuleGradient.Visible = false
                        end
                    end)
                end
            end

            local ExpandTween
            local ContainerTween

            local function UpdateModuleSize()
                local ContentHeight = ElementLayout.AbsoluteContentSize.Y
                local IsExpanded = ModuleObj.Expanded
                local TargetHeight = 25 + (IsExpanded and ContentHeight or 0)

                if ExpandTween then
                    ExpandTween:Cancel()
                    ExpandTween = nil
                end

                if ContainerTween then
                    ContainerTween:Cancel()
                    ContainerTween = nil
                end

                local CurrentItemSize = ModuleItem.Size
                local CurrentContainerSize = ElementContainer.Size

                local TargetItemSize = UDim2.new(
                    CurrentItemSize.X.Scale,
                    CurrentItemSize.X.Offset,
                    0,
                    TargetHeight
                )

                local TargetContainerSize = UDim2.new(
                    CurrentContainerSize.X.Scale,
                    CurrentContainerSize.X.Offset,
                    0,
                    IsExpanded and ContentHeight or 0
                )

                ExpandTween = Services.TweenService:Create(
                    ModuleItem,
                    TweenInfo.new(
                        0.25,
                        Enum.EasingStyle.Quart,
                        Enum.EasingDirection.Out
                    ),
                    { Size = TargetItemSize }
                )

                ContainerTween = Services.TweenService:Create(
                    ElementContainer,
                    TweenInfo.new(
                        0.25,
                        Enum.EasingStyle.Quart,
                        Enum.EasingDirection.Out
                    ),
                    { Size = TargetContainerSize }
                )

                ExpandTween:Play()
                ContainerTween:Play()
            end

            function ModuleObj:SetExpand(Value)
                Value = Value == true

                if Value and #Module.Elements == 0 then
                    return
                end

                if ModuleObj.Expanded == Value then
                    return
                end

                ModuleObj.Expanded = Value
                UpdateModuleSize()

                if Value then
                    for _, Element in ipairs(Module.Elements) do
                        if typeof(Element) == "table" then
                            local AnimateSlider = rawget(Element, "AnimateFromZero")
                            if typeof(AnimateSlider) == "function" then
                                task.spawn(AnimateSlider, Element)
                            else
                                local AnimateToggle = rawget(Element, "AnimateToggle")
                                if typeof(AnimateToggle) == "function" then
                                    task.spawn(AnimateToggle, Element)
                                end
                            end
                        end
                    end
                end
            end

            function ModuleObj:ToggleExpand()
                ModuleObj:SetExpand(not ModuleObj.Expanded)
            end

            ElementLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if ModuleObj.Expanded then
                    UpdateModuleSize()
                end
            end)

            local function SaveModuleConfig(Value, Keybind)
                local Existing = Library.ConfigData[Flag] or {}

                Library.ConfigData[Flag] = {
                    Value = AlwaysOn and Existing.Value or Value,
                    Keybind = AlwaysOn and Existing.Keybind or (Keybind and Keybind.Name or nil),
                    Expanded = ModuleObj.Expanded,
                    Dividers = Existing.Dividers or {},
                    Toggles = Existing.Toggles or {},
                    Sliders = Existing.Sliders or {},
                    Dropdowns = Existing.Dropdowns or {},
                    Colorpickers = Existing.Colorpickers or {},
                    Keyboxs = Existing.Keyboxs or {},
                }

                Library.SaveConfigFile()
            end

            local function SetValue(Value, Options)
                Options = Options or {}

                local SkipSave = Options.SkipSave == true
                local Silent = Options.Silent == true
                local SkipCallback = Options.SkipCallback == true

                if getgenv().DynamicSessionId ~= SessionId then
                    return
                end

                Value = AlwaysOn and true or Value == true
                if ModuleObj.Value == Value then
                    return
                end

                ModuleObj.Value = Value
                SetVisualState(Value)

                if not SkipSave then
                    SaveModuleConfig(Value, Module.Keybind)
                end

                if not Silent then
                    Library:PlayNotification(Name, Value)
                    Library:PlayToggleSound(Name, Value)
                    Library:FireFlagChanged(ModuleObj)
                    Library:RefreshArrayList()
                end

                if not AlwaysOn and Callback and not SkipCallback then
                    task.spawn(Callback, Value)
                end
            end

            function ModuleObj:SetValue(Value, Options)
                SetValue(Value, Options)
            end

            function ModuleObj:Toggle()
                if AlwaysOn then return end
                task.defer(function()
                    SetValue(not self.Value)
                end)
            end

            Library.Window.Modules[Flag] = Module
            Library.Flags[Flag] = ModuleObj

            SetVisualState(InitialValue)
            UpdateModuleSize(true)

            ModuleButton.MouseButton2Click:Connect(function()
                ModuleObj:ToggleExpand()
                SaveModuleConfig(ModuleObj.Value, Module.Keybind)
            end)

            if not AlwaysOn then

                ModuleButton.MouseButton1Click:Connect(function()
                    ModuleObj:Toggle()
                end)

                if Module.Keybind then
                    local InputDebounce = false

                    Services.UserInputService.InputBegan:Connect(function(Input, Processed)
                        if Processed then
                            return
                        end

                        if Input.KeyCode == Module.Keybind then
                            if InputDebounce then
                                return
                            end

                            InputDebounce = true
                            Module.Toggle()

                            task.delay(0.15, function()
                                InputDebounce = false
                            end)
                        end
                    end)
                end
            end

            if InitialValue and Callback and not AlwaysOn then
                task.spawn(Callback, true)
            end

            function Module:AddElement(Type, Info)
                local Constructor = Library.Window.Elements[Type]

                Library.ConfigData[Flag] = Library.ConfigData[Flag] or {
                    Value = ModuleObj.Value,
                    Keybind = Module.Keybind and Module.Keybind.Name or nil,
                    Expanded = ModuleObj.Expanded
                }

                local RootConfig = Library.ConfigData[Flag]

                local BucketName = Type .. "s"
                RootConfig[BucketName] = RootConfig[BucketName] or {}

                Module.ElementCounters[Type] = (Module.ElementCounters[Type] or 0) + 1
                local Index = Module.ElementCounters[Type]

                local ConfigBucket = RootConfig[BucketName]

                local Element = Constructor({
                    Index = Index,
                    Info = Info or {},
                    Module = Module,
                    Container = ElementContainer,
                    Config = ConfigBucket
                })

                Module.Elements[#Module.Elements + 1] = Element
                Library.SaveConfigFile()

                return Element
            end

            function Module:AddDivider(Info)
                return self:AddElement("Divider", Info)
            end

            function Module:AddToggle(Info)
                return self:AddElement("Toggle", Info)
            end

            function Module:AddSlider(Info)
                return self:AddElement("Slider", Info)
            end

            function Module:AddDropdown(Info)
                return self:AddElement("Dropdown", Info)
            end

            function Module:AddColorpicker(Info)
                return self:AddElement("Colorpicker", Info)
            end

            function Module:AddKeybox(Info)
                return self:AddElement("Keybox", Info)
            end

            table.insert(Library.Window.Modules, Module)

            if not Library.Flags[Module.Name .. "_Visible"] then
                Module:AddToggle({
                    Text = "Visible",
                    Default = true,
                    Flag = Module.Name .. "_Visible",
					Callback = function(Value)
						task.defer(function()
							Library:RefreshArrayList()
						end)
					end
                })
            end
            Library.FireModuleAdded(Module)

            SaveModuleConfig(InitialValue, Module.Keybind)
            return Module
        end
        Library.Window.AddModule = function(_, ...)
            return AddModule(...)
        end

        Library:RegisterElement("Divider", function(Context)
            local Info = Context.Info
            local Index = Context.Index
            local Container = Context.Container
            local Config = Context.Config

            Config[Index] = Config[Index] or {}

            local Text = Info.Text or "Divider"
            local FinalText = Config[Index].Text or Text
            Config[Index].Text = FinalText

            local DividerItem = Instance.new("Frame")
            DividerItem.Name = "Divider"
            DividerItem.Size = UDim2.new(1, 0, 0, 25)
            DividerItem.BackgroundTransparency = 1
            DividerItem.ClipsDescendants = true
            DividerItem.Parent = Container

            local DividerLabel = Instance.new("TextLabel")
            DividerLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            DividerLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
            DividerLabel.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
            DividerLabel.BackgroundTransparency = 0
            DividerLabel.BorderSizePixel = 0
            DividerLabel.Size = UDim2.fromOffset(0, 25)
            DividerLabel.TextXAlignment = Enum.TextXAlignment.Center
            DividerLabel.TextYAlignment = Enum.TextYAlignment.Center
            DividerLabel.FontFace = UIFont(DividerLabel)
            DividerLabel.TextSize = 16
            DividerLabel.TextColor3 = GetTheme().Text
            DividerLabel.Text = FinalText
            DividerLabel.ZIndex = 2
            DividerLabel.Parent = DividerItem

            local DividerLine = Instance.new("Frame")
            DividerLine.AnchorPoint = Vector2.new(0.5, 0, 0.5, 0)
            DividerLine.Position = UDim2.new(0.5, 0, 0.5, 0)
            DividerLine.Size = UDim2.new(1, -20, 0, 3)
            DividerLine.BackgroundColor3 = GetTheme().ItemDefault
            DividerLine.BorderSizePixel = 0
            DividerLine.ZIndex = 1
            DividerLine.Parent = DividerItem

            local Corner = Instance.new("UICorner")
            Corner.CornerRadius = UDim.new(0, 360)
            Corner.Parent = DividerLine

            local LineStroke = Instance.new("UIStroke")
            LineStroke.Color = Color3.fromRGB(18, 18, 18)
            LineStroke.Thickness = 1
            LineStroke.Transparency = 0
            LineStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            LineStroke.Parent = DividerLine

            local function UpdateLabelSize(Instant)
                local TargetWidth = DividerLabel.TextBounds.X + 10
                local TargetSize = UDim2.fromOffset(TargetWidth, 25)

                if Instant then
                    DividerLabel.Size = TargetSize
                    return
                end

                Services.TweenService:Create(
                    DividerLabel,
                    TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                    { Size = TargetSize }
                ):Play()
            end
            UpdateLabelSize(true)

            DividerLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
                UpdateLabelSize()
            end)

            local Divider = {
                Text = FinalText,
                Instance = DividerItem
            }

            function Divider:SetText(NewText)
                NewText = tostring(NewText or "")
                if Divider.Text == NewText then
                    return
                end

                Divider.Text = NewText
                DividerLabel.Text = NewText
                Config[Index].Text = NewText
                Library.SaveConfigFile()
            end

            return Divider
        end)

        Library:RegisterElement("Toggle", function(Context)
            local Info = Context.Info
            local Container = Context.Container
            local Config = Context.Config

            Library.Flags = Library.Flags or {}

            local Text = Info.Text or "Toggle"
            local Default = Info.Default == true
            local Callback = Info.Callback
            local Condition = Info.Condition
            local Flag = Info.Flag or Info.Text

            local Entry = Config[Flag]
            if typeof(Entry) ~= "table" then
                Entry = {}
                Config[Flag] = Entry
            end

            local Value
            if type(Entry.Value) == "boolean" then
                Value = Entry.Value
            else
                Value = Default
                Entry.Value = Value
            end

            Library.Flags[Flag] = Value
            Library:FireFlagChanged(Flag)

            local ToggleItem = Instance.new("Frame")
            ToggleItem.Name = "Toggle"
            ToggleItem.Size = UDim2.new(1, 0, 0, 25)
            ToggleItem.BackgroundTransparency = 1
            ToggleItem.ClipsDescendants = true
            ToggleItem.Parent = Container

            local ToggleButton = Instance.new("TextButton")
            ToggleButton.FontFace = UIFont(ToggleButton)
            ToggleButton.TextXAlignment = Enum.TextXAlignment.Left
            ToggleButton.TextColor3 = GetTheme().Text
            ToggleButton.TextSize = 16
            ToggleButton.BackgroundTransparency = 1
            ToggleButton.BorderSizePixel = 0
            ToggleButton.Size = UDim2.new(1, 0, 0, 25)
            ToggleButton.Text = Text
            ToggleButton.AutoButtonColor = false
            ToggleButton.Parent = ToggleItem
            Instance.new("UIPadding", ToggleButton).PaddingLeft = UDim.new(0, 10)

            local ToggledImage = Instance.new("ImageLabel")
            ToggledImage.Size = UDim2.new(0, 18, 0, 18)
            ToggledImage.AnchorPoint = Vector2.new(1, 0.5)
            ToggledImage.Position = UDim2.new(1, -5, 0.55, 0)
            ToggledImage.BackgroundTransparency = 1
            ToggledImage.Image = Assets:GetImage("Images/ToggledImage.png")
            ToggledImage.Parent = ToggleItem
            AddGradient(ToggledImage)

            local function EvaluateToggleVisibility()
                if typeof(Condition) == "function" then
                    local ok, result = pcall(Condition)
                    ToggleItem.Visible = ok and result == true
                else
                    ToggleItem.Visible = true
                end
            end
            EvaluateToggleVisibility()
            if typeof(Condition) == "function" then
                Library:OnFlagChanged(function()
                    EvaluateToggleVisibility()
                end)
            end

            local ImageTween
            local function UpdateVisual()
                if ImageTween then
                    ImageTween:Cancel()
                end

                ImageTween = Services.TweenService:Create(
                    ToggledImage,
                    TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                    { ImageTransparency = Value and 0 or 1 }
                )

                ImageTween:Play()
            end

            local function SetValue(NewValue)
                NewValue = NewValue == true
                if Value == NewValue then
                    return
                end

                Value = NewValue
                Entry.Value = Value
                Library.Flags[Flag] = Value
                Library:FireFlagChanged(Flag)

                UpdateVisual()
                Library.SaveConfigFile()

                if Callback then
                    task.spawn(Callback, Value)
                end
            end

            ToggleButton.MouseButton1Click:Connect(function()
                SetValue(not Value)
            end)

            UpdateVisual()

           local Toggle = {
                Instance = ToggleItem,
                IsLayoutOnly = false,
                Flag = Flag
            }

            function Toggle:AnimateToggle()
                if Value ~= true then
                    return
                end

                if ImageTween then
                    ImageTween:Cancel()
                end

                ToggledImage.ImageTransparency = 0
                ToggledImage.Size = UDim2.fromOffset(0, 0)

                local OvershootTween = Services.TweenService:Create(
                    ToggledImage,
                    TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                    { Size = UDim2.fromOffset(20, 20) }
                )

                local SettleTween = Services.TweenService:Create(
                    ToggledImage,
                    TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                    { Size = UDim2.fromOffset(18, 18) }
                )

                OvershootTween:Play()

                OvershootTween.Completed:Once(function()
                    SettleTween:Play()
                end)
            end

            function Toggle:Set(NewValue)
                SetValue(NewValue)
            end

            function Toggle:Get()
                return Value
            end

            if Callback then
                task.spawn(Callback, Value)
            end

            return Toggle
        end)

        Library:RegisterElement("Slider", function(Context)
            local Info = Context.Info
            local Container = Context.Container
            local Config = Context.Config

            Library.Flags = Library.Flags or {}

            local Text = Info.Text or "Slider"
            local Min = tonumber(Info.Min) or 0
            local Max = tonumber(Info.Max) or 100
            local Default = tonumber(Info.Default) or Min
            local Step = tonumber(Info.Step) or 1
            local Decimals = tonumber(Info.Decimals) or 0
            local Suffix = tostring(Info.Suffix or "")
            local AnimateOnExpand = Info.AnimateOnExpand == true
            local Callback = Info.Callback
            local Flag = Info.Flag or Text
            local Condition = Info.Condition

            local Entry = Config[Flag]
            if typeof(Entry) ~= "table" then
                Entry = {}
                Config[Flag] = Entry
            end

            local function Snap(v)
                return math.clamp(math.floor((v / Step) + 0.5) * Step, Min, Max)
            end

            local Value
            if type(Entry.Value) == "number" then
                Value = Snap(math.clamp(Entry.Value, Min, Max))
            else
                Value = Snap(math.clamp(Default, Min, Max))
                Entry.Value = Value
            end

            Library.Flags[Flag] = Value
            Library:FireFlagChanged(Flag)

            local SliderItem = Instance.new("Frame")
            SliderItem.Name = "Slider"
            SliderItem.Size = UDim2.new(1, 0, 0, 30)
            SliderItem.BackgroundTransparency = 1
            SliderItem.ClipsDescendants = true
            SliderItem.Parent = Container

            local SliderName = Instance.new("TextLabel")
            SliderName.Size = UDim2.new(1, 0, 0, 25)
            SliderName.BackgroundTransparency = 1
            SliderName.BorderSizePixel = 0
            SliderName.TextXAlignment = Enum.TextXAlignment.Left
            SliderName.FontFace = UIFont(SliderName)
            SliderName.TextSize = 16
            SliderName.TextColor3 = GetTheme().Text
            SliderName.Text = Text
            SliderName.Parent = SliderItem
            Instance.new("UIPadding", SliderName).PaddingLeft = UDim.new(0, 10)

            local SliderIndicator = Instance.new("TextLabel")
            SliderIndicator.Size = UDim2.new(1, -65, 0, 25)
            SliderIndicator.Position = UDim2.new(0, 60, 0, 0)
            SliderIndicator.BackgroundTransparency = 1
            SliderIndicator.BorderSizePixel = 0
            SliderIndicator.TextXAlignment = Enum.TextXAlignment.Right
            SliderIndicator.TextYAlignment = Enum.TextYAlignment.Center
            SliderIndicator.FontFace = UIFont(SliderIndicator)
            SliderIndicator.TextSize = 12
            SliderIndicator.TextColor3 = Color3.fromRGB(145, 145, 145)
            SliderIndicator.Parent = SliderItem
            local SliderPadding = Instance.new("UIPadding", SliderIndicator)
            SliderPadding.PaddingRight = UDim.new(0, 5)
            SliderPadding.PaddingTop = UDim.new(0, 4)

            local SliderTrack = Instance.new("Frame")
            SliderTrack.Size = UDim2.new(1, -20, 0, 2)
            SliderTrack.Position = UDim2.new(0, 10, 0, 22)
            SliderTrack.BackgroundColor3 = GetTheme().ItemDefault
            SliderTrack.BorderSizePixel = 0
            SliderTrack.Parent = SliderItem
            Instance.new("UICorner", SliderTrack).CornerRadius = UDim.new(0, 26)

            local SliderFill = Instance.new("Frame")
            SliderFill.Size = UDim2.new(0, 0, 1, 0)
            SliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SliderFill.BorderSizePixel = 0
            SliderFill.Parent = SliderTrack
            AddGradient(SliderFill)
            Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(0, 26)

            local SliderCircle = Instance.new("ImageButton")
            SliderCircle.Size = UDim2.fromOffset(10, 10)
            SliderCircle.AnchorPoint = Vector2.new(0.5, 0.5)
            SliderCircle.Position = UDim2.new(0, 0, 0.5, 0)
            SliderCircle.BackgroundTransparency = 1
            SliderCircle.ImageColor3 = Color3.fromRGB(255, 255, 255)
            SliderCircle.Image = Assets:GetImage("Images/CircleImage.png")
            SliderCircle.ImageTransparency = 0.5
            SliderCircle.Parent = SliderTrack
            AddGradient(SliderCircle)

            local SliderShadow = Instance.new("ImageLabel")
            SliderShadow.AnchorPoint = Vector2.new(0.5, 0.5)
            SliderShadow.Position = SliderCircle.Position
            SliderShadow.Size = UDim2.fromOffset(14, 14)
            SliderShadow.BackgroundTransparency = 1
            SliderShadow.Image = Assets:GetImage("Images/CircleImage.png")
            SliderShadow.ImageColor3 = Color3.fromRGB(255, 255, 255)
            SliderShadow.ImageTransparency = 0.65
            SliderShadow.ZIndex = SliderCircle.ZIndex - 1
            SliderShadow.Parent = SliderTrack
            AddGradient(SliderShadow)

            local function EvaluateSliderVisibility()
                if typeof(Condition) == "function" then
                    local ok, result = pcall(Condition)
                    SliderItem.Visible = ok and result == true
                else
                    SliderItem.Visible = true
                end
            end
            EvaluateSliderVisibility()
            if typeof(Condition) == "function" then
                Library:OnFlagChanged(function()
                    EvaluateSliderVisibility()
                end)
            end

            local Dragging = false
            local FillTween
            local KnobTween
            local ShadowTween
            local Animating = false

            local function ValueToAlpha(v)
                return (v - Min) / (Max - Min)
            end

            local function FormatValue(v)
                local p = 10 ^ Decimals
                v = math.floor(v * p + 0.5) / p
                return tostring(v) .. Suffix
            end

            local function ApplyVisual(alpha, instant)
                local fillGoal = { Size = UDim2.new(alpha, 0, 1, 0) }
                local knobGoal = { Position = UDim2.new(alpha, 0, 0.5, 0) }

                if FillTween then FillTween:Cancel() end
                if KnobTween then KnobTween:Cancel() end
                if ShadowTween then ShadowTween:Cancel() end

                if instant then
                    SliderFill.Size = fillGoal.Size
                    SliderCircle.Position = knobGoal.Position
                    SliderShadow.Position = knobGoal.Position
                else
                    local info = TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                    FillTween = Services.TweenService:Create(SliderFill, info, fillGoal)
                    KnobTween = Services.TweenService:Create(SliderCircle, info, knobGoal)
                    ShadowTween = Services.TweenService:Create(SliderShadow, info, knobGoal)
                    FillTween:Play()
                    KnobTween:Play()
                    ShadowTween:Play()
                end

                SliderIndicator.Text = FormatValue(Value)
            end

            local function SetValue(newValue, instant)
                newValue = Snap(newValue)
                if Value == newValue then
                    return
                end

                Value = newValue
                Entry.Value = Value
                Library.Flags[Flag] = Value
                Library:FireFlagChanged(Flag)

                ApplyVisual(ValueToAlpha(Value), instant)
                Library.SaveConfigFile()

                if Callback then
                    task.spawn(Callback, Value)
                end
            end

            local function AlphaToValue(a)
                return Min + (Max - Min) * a
            end

            local function UpdateFromInput(x)
                local absPos = SliderTrack.AbsolutePosition.X
                local absSize = SliderTrack.AbsoluteSize.X
                local alpha = math.clamp((x - absPos) / absSize, 0, 1)
                SetValue(AlphaToValue(alpha), false)
            end

            local function BeginDrag(x)
                Dragging = true
                UpdateFromInput(x)
            end

            local function EndDrag()
                Dragging = false
            end

            SliderTrack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    BeginDrag(input.Position.X)
                end
            end)

            SliderCircle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    BeginDrag(input.Position.X)
                end
            end)

            SliderTrack.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    EndDrag()
                end
            end)

            SliderCircle.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    EndDrag()
                end
            end)

            Services.UserInputService.InputChanged:Connect(function(input)
                if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateFromInput(input.Position.X)
                end
            end)

            ApplyVisual(ValueToAlpha(Value), true)

            local Slider = {
                Instance = SliderItem,
                IsLayoutOnly = false,
                Flag = Flag
            }

            function Slider:Set(v)
                SetValue(v, false)
            end

            function Slider:Get()
                return Value
            end

            function Slider:AnimateFromZero()
                if Animating or not SliderItem.Visible then
                    return
                end

                Animating = true

                local TargetAlpha = ValueToAlpha(Value)
                local TweenInfoInstance = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

                if FillTween then FillTween:Cancel() end
                if KnobTween then KnobTween:Cancel() end
                if ShadowTween then ShadowTween:Cancel() end

                SliderFill.Size = UDim2.new(0, 0, 1, 0)
                SliderCircle.Position = UDim2.new(0, 0, 0.5, 0)
                SliderShadow.Position = SliderCircle.Position
                SliderIndicator.Text = FormatValue(Value)

                task.wait(0.05)

                FillTween = Services.TweenService:Create(SliderFill, TweenInfoInstance, {
                    Size = UDim2.new(TargetAlpha, 0, 1, 0)
                })

                KnobTween = Services.TweenService:Create(SliderCircle, TweenInfoInstance, {
                    Position = UDim2.new(TargetAlpha, 0, 0.5, 0)
                })

                ShadowTween = Services.TweenService:Create(SliderShadow, TweenInfoInstance, {
                    Position = UDim2.new(TargetAlpha, 0, 0.5, 0)
                })

                FillTween:Play()
                KnobTween:Play()
                ShadowTween:Play()

                task.delay(0.4, function()
                    Animating = false
                end)
            end

            if AnimateOnExpand then
                task.defer(function()
                    Slider:AnimateFromZero()
                end)
            end

            if Callback then
                task.spawn(Callback, Value)
            end

            return Slider
        end)
    
        Library:RegisterElement("Dropdown", function(Context)
            local Info = Context.Info
            local Index = Context.Index
            local Container = Context.Container
            local Config = Context.Config

            Library.Flags = Library.Flags or {}

            local Text = Info.Text or "Dropdown"
            local Flag = Info.Flag or Info.Text
            local Default = Info.Default
            local Multiple = Info.Multiple == true
            local Choices = Info.Choices or {}
            local Condition = Info.Condition
            local Callback = Info.Callback or function() end

            local Entry = Config[Flag]
            if typeof(Entry) ~= "table" then
                Entry = {}
                Config[Flag] = Entry
            end

            Entry.Multiple = Multiple
            Entry.Open = Entry.Open == true

            local State = Entry

            if Multiple then
                if typeof(State.Selected) ~= "table" then
                    State.Selected = {}
                end

                local Result = {}

                for _, Option in ipairs(Choices) do
                    if State.Selected[Option] == nil then
                        State.Selected[Option] = false
                    end

                    local Enabled = State.Selected[Option] == true
                    local F = Flag .. "_" .. tostring(Option)

                    Library.Flags[F] = Enabled
                    Library:FireFlagChanged(F)

                    if Enabled then
                        Result[#Result + 1] = Option
                    end
                end

                table.sort(Result)

                Library.Flags[Flag] = Result
                Library:FireFlagChanged(Flag)
            else
                if not table.find(Choices, State.Selected) then
                    State.Selected = Default or Choices[1]
                end

                Library.Flags[Flag] = State.Selected
                Library:FireFlagChanged(Flag)
            end

            Entry.Selected = State.Selected

            local DropdownItem = Instance.new("Frame")
            DropdownItem.Name = "Dropdown"
            DropdownItem.Size = UDim2.new(1, 0, 0, 25)
            DropdownItem.BackgroundTransparency = 1
            DropdownItem.ClipsDescendants = true
            DropdownItem.Parent = Container

            local DropdownButton = Instance.new("TextButton")
            DropdownButton.FontFace = UIFont(DropdownButton)
            DropdownButton.TextXAlignment = Enum.TextXAlignment.Left
            DropdownButton.TextColor3 = GetTheme().Text
            DropdownButton.TextSize = 16
            DropdownButton.BackgroundTransparency = 1
            DropdownButton.BorderSizePixel = 0
            DropdownButton.Size = UDim2.new(1, 0, 0, 25)
            DropdownButton.Text = Text
            DropdownButton.AutoButtonColor = false
            DropdownButton.Parent = DropdownItem
            Instance.new("UIPadding", DropdownButton).PaddingLeft = UDim.new(0, 10)

            local DropdownIndicator = Instance.new("TextLabel")
            DropdownIndicator.Size = UDim2.new(1, -70, 0, 25)
            DropdownIndicator.Position = UDim2.new(0, 60, 0, 0)
            DropdownIndicator.BackgroundTransparency = 1
            DropdownIndicator.BorderSizePixel = 0
            DropdownIndicator.TextXAlignment = Enum.TextXAlignment.Right
            DropdownIndicator.TextYAlignment = Enum.TextYAlignment.Center
            DropdownIndicator.FontFace = UIFont(DropdownIndicator)
            DropdownIndicator.TextSize = 12
            DropdownIndicator.TextColor3 = Color3.fromRGB(145, 145, 145)
            DropdownIndicator.Parent = DropdownItem
            local DropdownPadding = Instance.new("UIPadding")
            DropdownPadding.Parent = DropdownIndicator
            local function UpdateIndicatorPadding()
                local Padding = Library.Flags.Interface_Font == "Lexend" and 4 or 2
                DropdownPadding.PaddingTop = UDim.new(0, Padding)
            end
            UpdateIndicatorPadding()

            local OptionContainer = Instance.new("Frame")
            OptionContainer.Size = UDim2.new(1, 0, 0, 0)
            OptionContainer.Position = UDim2.new(0, 0, 0, 25)
            OptionContainer.BackgroundTransparency = 1
            OptionContainer.ClipsDescendants = true
            OptionContainer.Parent = DropdownItem

            local OptionLayout = Instance.new("UIListLayout")
            OptionLayout.Padding = UDim.new(0, 2)
            OptionLayout.Parent = OptionContainer

            local OptionPadding = Instance.new("UIPadding")
            OptionPadding.PaddingTop = UDim.new(0, 4)
            OptionPadding.PaddingBottom = UDim.new(0, 4)
            OptionPadding.Parent = OptionContainer

            local function EvaluateDropdownVisibility()
                if typeof(Condition) == "function" then
                    local ok, result = pcall(Condition)
                    DropdownItem.Visible = ok and result == true
                else
                    DropdownItem.Visible = true
                end
            end
            EvaluateDropdownVisibility()
            if typeof(Condition) == "function" then
                Library:OnFlagChanged(function()
                    EvaluateDropdownVisibility()
                end)
            end

            local OptionButtons = {}
            local OptionHighlights = {}

            local ExpandTween
            local ContainerTween

            local function GetContentHeight()
                return OptionLayout.AbsoluteContentSize.Y
                    + OptionPadding.PaddingTop.Offset
                    + OptionPadding.PaddingBottom.Offset
            end

            local function Truncate(Label, FullText)
                local Ellipsis = "..."
                local currentText = FullText

                Services.RunService.Heartbeat:Wait()

                local MaxWidth = math.max(0, Label.AbsoluteSize.X - 6)
                if MaxWidth <= 0 then
                    return FullText
                end

                local params = Instance.new("GetTextBoundsParams")
                params.Font = Label.FontFace
                params.Size = Label.TextSize
                params.Width = math.huge

                local function GetWidth(text)
                    params.Text = text
                    return Services.TextService:GetTextBoundsAsync(params).X
                end

                if GetWidth(FullText) <= MaxWidth then
                    return FullText
                end

                local Left = 1
                local Right = #FullText
                local Best = Ellipsis

                while Left <= Right do
                    local Mid = math.floor((Left + Right) / 2)
                    local Candidate = string.sub(FullText, 1, Mid) .. Ellipsis

                    if GetWidth(Candidate) <= MaxWidth then
                        Best = Candidate
                        Left = Mid + 1
                    else
                        Right = Mid - 1
                    end
                end

                return Best
            end

            local function TruncateOption(Label, FullText)
            local Ellipsis = "..."
            local currentText = FullText

            Services.RunService.Heartbeat:Wait()

            local MaxWidth = math.max(0, Label.AbsoluteSize.X - 20)
            if MaxWidth <= 0 then
                return FullText
            end

            local params = Instance.new("GetTextBoundsParams")
            params.Font = Label.FontFace
            params.Size = Label.TextSize
            params.Width = math.huge

            local function GetWidth(text)
                params.Text = text
                return Services.TextService:GetTextBoundsAsync(params).X
            end

            if GetWidth(FullText) <= MaxWidth then
                return FullText
            end

            local Left = 1
            local Right = #FullText
            local Best = Ellipsis

            while Left <= Right do
                local Mid = math.floor((Left + Right) / 2)
                local Candidate = string.sub(FullText, 1, Mid) .. Ellipsis

                if GetWidth(Candidate) <= MaxWidth then
                    Best = Candidate
                    Left = Mid + 1
                else
                    Right = Mid - 1
                end
            end

            return Best
        end

            local function GetDisplayText()
                if Multiple then
                    local Buffer = {}
                    for Value, Enabled in pairs(State.Selected) do
                        if Enabled then
                            Buffer[#Buffer + 1] = tostring(Value)
                        end
                    end
                    table.sort(Buffer)
                    return #Buffer > 0 and table.concat(Buffer, ", ") or "None"
                end
                return tostring(State.Selected or "None")
            end

            local AdjustScheduled = false
            local function AdjustIndicator()
                if AdjustScheduled then
                    return
                end

                AdjustScheduled = true

                task.defer(function()
                    AdjustScheduled = false

                    if not DropdownIndicator.Parent then
                        return
                    end

                    Services.RunService.Heartbeat:Wait()

                    local Display = GetDisplayText()

                    if DropdownIndicator.AbsoluteSize.X <= 0 then
                        DropdownIndicator.Text = Display
                        return
                    end

                    DropdownIndicator.Text = Truncate(DropdownIndicator, Display)
                end)
            end
            
            Library:OnFlagChanged(function(Flag)
                if Flag == "Interface_Font" then
                    UpdateIndicatorPadding()
                    AdjustIndicator()
                end
            end)

            local function RefreshDropdown(Force)
                AdjustIndicator()
                if Multiple then
                    for _, Option in ipairs(Choices) do
                        local F = Flag .. "_" .. tostring(Option)
                        Library.Flags[F] = State.Selected[Option] == true
                        Library:FireFlagChanged(F)
                    end
                else
                    Library.Flags[Flag] = State.Selected
                    Library:FireFlagChanged(Flag)
                end

                for Value, Button in pairs(OptionButtons) do
                    local Selected = Multiple and State.Selected[Value] or State.Selected == Value
                    local Highlight = OptionHighlights[Button]

                    Services.TweenService:Create(
                        Button,
                        TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                        { TextColor3 = Selected and Color3.fromRGB(255,255,255) or Color3.fromRGB(145,145,145) }
                    ):Play()

                    if Selected then
                        Highlight.Visible = true
                        Services.TweenService:Create(
                            Highlight,
                            TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                            { Size = UDim2.new(0, 2, 1, -6) }
                        ):Play()
                    else
                        local Tween = Services.TweenService:Create(
                            Highlight,
                            TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                            { Size = UDim2.new(0, 2, 0, 0) }
                        )
                        Tween:Play()
                        Tween.Completed:Once(function()
                            if not (Multiple and State.Selected[Value] or State.Selected == Value) then
                                Highlight.Visible = false
                            end
                        end)
                    end
                end

                local TargetHeight = State.Open and GetContentHeight() or 0

                if ExpandTween then ExpandTween:Cancel() end
                if ContainerTween then ContainerTween:Cancel() end

                local TargetItemSize = UDim2.new(1, 0, 0, 25 + TargetHeight)
                local TargetContainerSize = UDim2.new(1, 0, 0, TargetHeight)

                ExpandTween = Services.TweenService:Create(
                    DropdownItem,
                    TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                    { Size = TargetItemSize }
                )

                ContainerTween = Services.TweenService:Create(
                    OptionContainer,
                    TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                    { Size = TargetContainerSize }
                )

                OptionContainer.Active = State.Open

                if Force then
                    DropdownItem.Size = TargetItemSize
                    OptionContainer.Size = TargetContainerSize
                else
                    ExpandTween:Play()
                    ContainerTween:Play()
                end
            end

            local function SetOpen(Value)
                Value = Value == true
                if State.Open == Value then return end
                State.Open = Value
                Entry.Open = State.Open
                RefreshDropdown(false)
                Library.SaveConfigFile()
            end

            local function FireCallback()
                if Multiple then
                    local Result = {}
                    for Option, Enabled in pairs(State.Selected) do
                        if Enabled then
                            Result[#Result + 1] = Option
                        end
                    end
                    table.sort(Result)
                    Callback(Result)
                else
                    Callback(State.Selected)
                end
            end

            local function SetValue(NewValue)
                if Multiple then
                    for _, Option in ipairs(Choices) do
                        State.Selected[Option] = false
                    end
                    if typeof(NewValue) == "table" then
                        for _, Value in ipairs(NewValue) do
                            if State.Selected[Value] ~= nil then
                                State.Selected[Value] = true
                            end
                        end
                    end
                else
                    if table.find(Choices, NewValue) then
                        State.Selected = NewValue
                    end
                end

                Entry.Selected = State.Selected
                RefreshDropdown(false)
                FireCallback()
                Library.SaveConfigFile()
            end

            DropdownButton.MouseButton1Click:Connect(function()
                if Multiple then
                    local Count = 0
                    for _, Option in ipairs(Choices) do
                        if State.Selected[Option] then
                            Count += 1
                        end
                    end
                    if Count >= #Choices then
                        return
                    end
                    for _, Option in ipairs(Choices) do
                        if not State.Selected[Option] then
                            State.Selected[Option] = true
                            break
                        end
                    end
                    Entry.Selected = State.Selected
                    RefreshDropdown(false)
                    FireCallback()
                    Library.SaveConfigFile()
                else
                    local CurrentIndex = table.find(Choices, State.Selected) or 0
                    local NextIndex = (CurrentIndex % #Choices) + 1
                    SetValue(Choices[NextIndex])
                end
            end)

            DropdownButton.MouseButton2Click:Connect(function()
                SetOpen(not State.Open)
            end)

            for _, Option in ipairs(Choices) do
                local OptionButton = Instance.new("TextButton")
                OptionButton.Size = UDim2.new(1, -20, 0, 22)
                OptionButton.BackgroundTransparency = 1
                OptionButton.BorderSizePixel = 0
                OptionButton.TextXAlignment = Enum.TextXAlignment.Left
                OptionButton.FontFace = UIFont(OptionButton)
                OptionButton.TextSize = 14
                OptionButton.TextColor3 = Color3.fromRGB(145,145,145)
                local FullText = tostring(Option)
                OptionButton.Text = FullText
                task.defer(function()
                    if OptionButton.Parent then
                        OptionButton.Text = TruncateOption(OptionButton, FullText)
                    end
                end)
                OptionButton.AutoButtonColor = false
                OptionButton.Parent = OptionContainer
                Instance.new("UIPadding", OptionButton).PaddingLeft = UDim.new(0, 20)
                OptionButton:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                    local FullText = tostring(Option)
                    OptionButton.Text = TruncateOption(OptionButton, FullText)
                end)

                local OptionHighlight = Instance.new("Frame")
                OptionHighlight.Size = UDim2.new(0, 2, 0, 0)
                OptionHighlight.Position = UDim2.new(0, -10, 0.5, 0)
                OptionHighlight.AnchorPoint = Vector2.new(0, 0.5)
                OptionHighlight.Visible = false
                OptionHighlight.Parent = OptionButton
                AddGradient(OptionHighlight)

                OptionButtons[Option] = OptionButton
                OptionHighlights[OptionButton] = OptionHighlight

                OptionButton.MouseButton1Click:Connect(function()
                    if Multiple then
                        State.Selected[Option] = not State.Selected[Option]
                        Entry.Selected = State.Selected
                        RefreshDropdown(false)
                        FireCallback()
                        Library.SaveConfigFile()
                    else
                        SetValue(Option)
                    end
                end)
            end

            OptionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if State.Open then
                    RefreshDropdown(false)
                end
            end)

            DropdownIndicator:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                RefreshDropdown(true)
            end)

            RefreshDropdown(true)

            local Dropdown = {
                Instance = DropdownItem,
                Flag = Flag,
                IsLayoutOnly = false
            }

            function Dropdown:SetValue(Value)
                SetValue(Value)
            end

            function Dropdown:GetValue()
                return State.Selected
            end

            function Dropdown:RefreshList(NewList)
                if typeof(NewList) ~= "table" then
                    return
                end

                Choices = NewList

                for _, Button in pairs(OptionButtons) do
                    Button:Destroy()
                end

                table.clear(OptionButtons)
                table.clear(OptionHighlights)

                if Multiple then
                    local OldSelected = State.Selected or {}
                    local NewSelected = {}

                    for _, Option in ipairs(Choices) do
                        NewSelected[Option] = OldSelected[Option] or false
                    end

                    State.Selected = NewSelected
                else
                    if not table.find(Choices, State.Selected) then
                        State.Selected = Choices[1]
                    end
                end

                Entry.Selected = State.Selected

                for _, Option in ipairs(Choices) do
                    local OptionButton = Instance.new("TextButton")
                    OptionButton.Size = UDim2.new(1, -20, 0, 22)
                    OptionButton.BackgroundTransparency = 1
                    OptionButton.BorderSizePixel = 0
                    OptionButton.TextXAlignment = Enum.TextXAlignment.Left
                    OptionButton.FontFace = UIFont(OptionButton)
                    OptionButton.TextSize = 14
                    OptionButton.TextColor3 = Color3.fromRGB(145,145,145)
                    local FullText = tostring(Option)
                    OptionButton.Text = FullText
                    task.defer(function()
                        if OptionButton.Parent then
                            OptionButton.Text = TruncateOption(OptionButton, FullText)
                        end
                    end)
                    OptionButton.AutoButtonColor = false
                    OptionButton.Parent = OptionContainer
                    Instance.new("UIPadding", OptionButton).PaddingLeft = UDim.new(0, 20)
                    OptionButton:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                        local FullText = tostring(Option)
                        OptionButton.Text = TruncateOption(OptionButton, FullText)
                    end)

                    local OptionHighlight = Instance.new("Frame")
                    OptionHighlight.Size = UDim2.new(0, 2, 0, 0)
                    OptionHighlight.Position = UDim2.new(0, -10, 0.5, 0)
                    OptionHighlight.AnchorPoint = Vector2.new(0, 0.5)
                    OptionHighlight.Visible = false
                    OptionHighlight.Parent = OptionButton
                    AddGradient(OptionHighlight)

                    OptionButtons[Option] = OptionButton
                    OptionHighlights[OptionButton] = OptionHighlight

                    OptionButton.MouseButton1Click:Connect(function()
                        if Multiple then
                            State.Selected[Option] = not State.Selected[Option]
                            Entry.Selected = State.Selected
                            RefreshDropdown(false)
                            FireCallback()
                            Library.SaveConfigFile()
                        else
                            SetValue(Option)
                        end
                    end)
                end

                RefreshDropdown(true)
            end

            return Dropdown
        end)

        Library:RegisterElement("Colorpicker", function(Context)
            local Info = Context.Info
            local Container = Context.Container
            local Config = Context.Config

            Library.Flags = Library.Flags or {}

            local Text = Info.Text or "Colorpicker"
            local Default = typeof(Info.Default) == "Color3" and Info.Default or Color3.fromRGB(255,255,255)
            local Callback = Info.Callback
            local Flag = Info.Flag or Info.Text
            local Condition = Info.Condition

            local Entry = Config[Flag]
            if typeof(Entry) ~= "table" then
                Entry = {}
                Config[Flag] = Entry
            end

            local Value
            if typeof(Entry.Value) == "table" and Entry.Value.r then
                Value = Color3.new(
                    tonumber(Entry.Value.r) or 1,
                    tonumber(Entry.Value.g) or 1,
                    tonumber(Entry.Value.b) or 1
                )
            else
                Value = Default
                Entry.Value = { r = Value.R, g = Value.G, b = Value.B, a = 1 }
            end

            Entry.Value.a = tonumber(Entry.Value.a) or 1

            Library.Flags[Flag] = Value
            Library:FireFlagChanged(Flag)

            local ColorpickerItem = Instance.new("Frame")
            ColorpickerItem.Size = UDim2.new(1,0,0,25)
            ColorpickerItem.BackgroundTransparency = 1
            ColorpickerItem.Parent = Container

            local ColorpickerButton = Instance.new("TextButton")
            ColorpickerButton.Size = UDim2.new(1,0,1,0)
            ColorpickerButton.BackgroundTransparency = 1
            ColorpickerButton.Text = Text
            ColorpickerButton.TextSize = 16
            ColorpickerButton.TextXAlignment = Enum.TextXAlignment.Left
            ColorpickerButton.TextColor3 = GetTheme().Text
            ColorpickerButton.FontFace = UIFont(ColorpickerButton)
            ColorpickerButton.AutoButtonColor = false
            ColorpickerButton.Parent = ColorpickerItem

            local Padding = Instance.new("UIPadding")
            Padding.PaddingLeft = UDim.new(0,10)
            Padding.Parent = ColorpickerButton

            local Preview = Instance.new("ImageLabel")
            Preview.Size = UDim2.new(0, 10, 0, 10)
            Preview.AnchorPoint = Vector2.new(1, 0.5)
            Preview.Position = UDim2.new(1, -10, 0.55, 0)
            Preview.ImageColor3 = Value
            Preview.ImageTransparency = 1 - Entry.Value.a
            Preview.BackgroundTransparency = 1
            Preview.Image = Assets:GetImage("Images/CircleImage.png")
            Preview.BorderSizePixel = 0
            Preview.Parent = ColorpickerItem

            local PreviewShadow = Instance.new("ImageLabel")
            PreviewShadow.AnchorPoint = Vector2.new(0.5, 0.5)
            PreviewShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
            PreviewShadow.Size = UDim2.fromOffset(14, 14)
            PreviewShadow.BackgroundTransparency = 1
            PreviewShadow.Image = Assets:GetImage("Images/CircleImage.png")
            PreviewShadow.ImageColor3 = Preview.ImageColor3
            PreviewShadow.ImageTransparency = 0.95 - Entry.Value.a
            PreviewShadow.ZIndex = Preview.ZIndex - 1
            PreviewShadow.Parent = Preview

            local Settings = Instance.new("Frame")
            Settings.Size = UDim2.fromOffset(125,0)
            Settings.BackgroundColor3 = GetTheme().ItemDefault
            Settings.BackgroundTransparency = 1
            Settings.Visible = false
            Settings.ZIndex = 1000
            Settings.Parent = DynamicUI
            Settings.ClipsDescendants = true
            local SettingsShadow = AttachShadow(DynamicUI, Settings, 26, 8, 7, 1.2, Color3.fromRGB(0, 0, 0), false)
            SettingsShadow:SetTransparency(1)
            Instance.new("UICorner",Settings).CornerRadius = UDim.new(0, 26)

            local Wheel = Instance.new("ImageLabel")
            Wheel.Size = UDim2.fromOffset(80,80)
            Wheel.AnchorPoint = Vector2.new(0.5,0)
            Wheel.Position = UDim2.new(0.5,0,0,8)
            Wheel.BackgroundTransparency = 1
            Wheel.Image = Assets:GetImage("Images/ColorWheel.png")
            Wheel.Parent = Settings

            local WheelSelector = Instance.new("Frame")
            WheelSelector.Size = UDim2.fromOffset(6,6)
            WheelSelector.AnchorPoint = Vector2.new(0.5,0.5)
            WheelSelector.BackgroundTransparency = 1
            WheelSelector.BorderSizePixel = 0
            WheelSelector.ZIndex = 1001
            WheelSelector.Parent = Wheel
            Instance.new("UICorner",WheelSelector).CornerRadius = UDim.new(1,0)

            local SelectorStroke = Instance.new("UIStroke")
            SelectorStroke.Parent = WheelSelector
            SelectorStroke.Thickness = 2
            SelectorStroke.Color = Color3.new(1,1,1)

            local AlphaBar = Instance.new("Frame")
            AlphaBar.Size = UDim2.fromOffset(90,8)
            AlphaBar.AnchorPoint = Vector2.new(0.5,0)
            AlphaBar.Position = UDim2.new(0.5,0,0,95)
            AlphaBar.BackgroundColor3 = Color3.new(1,1,1)
            AlphaBar.Parent = Settings
            Instance.new("UICorner",AlphaBar).CornerRadius = UDim.new(0,4)

            local AlphaGradient = Instance.new("UIGradient")
            AlphaGradient.Parent = AlphaBar

            local AlphaLine = Instance.new("Frame")
            AlphaLine.Size = UDim2.fromOffset(2,8)
            AlphaLine.AnchorPoint = Vector2.new(0.5,0)
            AlphaLine.BackgroundColor3 = Color3.new(1,1,1)
            AlphaLine.BorderSizePixel = 0
            AlphaLine.Parent = AlphaBar

            local RGBContainer = Instance.new("Frame")
            RGBContainer.Size = UDim2.fromOffset(105,20)
            RGBContainer.AnchorPoint = Vector2.new(0.5,0)
            RGBContainer.Position = UDim2.new(0.5,0,0,110)
            RGBContainer.BackgroundTransparency = 1
            RGBContainer.Parent = Settings

            local function EvaluateColorpickerVisibility()
                if typeof(Condition) == "function" then
                    local ok, result = pcall(Condition)
                    ColorpickerItem.Visible = ok and result == true
                else
                    ColorpickerItem.Visible = true
                end
            end
            EvaluateColorpickerVisibility()
            if typeof(Condition) == "function" then
                Library:OnFlagChanged(function()
                    EvaluateColorpickerVisibility()
                end)
            end

            local Colorpicker = {
                Instance = ColorpickerItem,
                IsLayoutOnly = false,
                Flag = Flag
            }

            local function CreateBox(X)
                local Box = Instance.new("TextBox")
                Box.Size = UDim2.fromOffset(30,20)
                Box.Position = UDim2.fromOffset(X,0)
                Box.TextSize = 12
                Box.FontFace = UIFont(Box)
                Box.TextXAlignment = Enum.TextXAlignment.Center
                Box.BackgroundColor3 = GetTheme().ItemDefault
                Box.TextColor3 = GetTheme().Text
                Box.ClearTextOnFocus = false
                Box.Parent = RGBContainer
                Instance.new("UICorner",Box).CornerRadius = UDim.new(0,4)
                return Box
            end

            local RBox = CreateBox(0)
            local GBox = CreateBox(37)
            local BBox = CreateBox(74)

            local function UpdateBoxes()
                RBox.Text = tostring(math.floor(Value.R*255))
                GBox.Text = tostring(math.floor(Value.G*255))
                BBox.Text = tostring(math.floor(Value.B*255))
            end

            local function UpdateSelectors(Alpha)
                local H,S = Value:ToHSV()
                local Radius = Wheel.AbsoluteSize.X/2
                local Angle = H * math.pi*2
                local Dist = S * Radius

                local X = Radius + math.cos(Angle)*Dist
                local Y = Radius - math.sin(Angle)*Dist

                WheelSelector.Position = UDim2.fromOffset(X,Y)
                AlphaLine.Position = UDim2.fromScale(Alpha,0)

                AlphaGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
                    ColorSequenceKeypoint.new(1, Value)
                }
            end

            local function UpdateExtractedColor(Index, Color)
                if Library.Flags.Interface_Theme ~= "Custom" then
                    return
                end

                local Count = math.clamp(Library.Flags.Interface_Colors or 1, 1, 7)
                if Index > Count then
                    return
                end

                Library.ExtractedColors[Index] =
                    Color3.new(Color.R, Color.G, Color.B)
            end

            local function SetValue(NewColor,Alpha)
                Value = NewColor
                Entry.Value = { r = Value.R, g = Value.G, b = Value.B, a = Alpha }
                Library.Flags[Flag] = Value
                Library:FireFlagChanged(Flag)
                Preview.ImageColor3 = Value
                Preview.ImageTransparency = 1-Alpha
                PreviewShadow.ImageColor3 = Value
                PreviewShadow.ImageTransparency = 0.95-Alpha
                UpdateBoxes()
                UpdateSelectors(Alpha)
                Library.SaveConfigFile()
                if Library.Flags.Interface_Theme == "Custom" then
                    local Index = tonumber(string.match(Flag, "%d+"))
                    if Index then
                        UpdateExtractedColor(Index, Value)
                    end
                end
                if Callback then
                    task.spawn(Callback,Value,Alpha)
                end
            end

            SetValue(Value, Entry.Value.a)

            local DragWheel = false
            local DragAlpha = false

            Wheel.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    DragWheel = true
                end
            end)

            Wheel.InputEnded:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    DragWheel = false
                end
            end)

            AlphaBar.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    DragAlpha = true
                end
            end)

            AlphaBar.InputEnded:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    DragAlpha = false
                end
            end)

            Services.UserInputService.InputChanged:Connect(function(Input)
                if Input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

                local Inset = Services.GuiService:GetGuiInset()
                local Mouse = Services.UserInputService:GetMouseLocation() - Inset

                if DragWheel then
                    local Pos = Wheel.AbsolutePosition
                    local Size = Wheel.AbsoluteSize
                    local Center = Size.X/2

                    local Dx = Mouse.X - Pos.X - Center
                    local Dy = Mouse.Y - Pos.Y - Center

                    local Dist = math.sqrt(Dx*Dx+Dy*Dy)
                    local Radius = Center

                    if Dist > Radius then
                        Dx = Dx/Dist*Radius
                        Dy = Dy/Dist*Radius
                    end

                    local Hue = (math.atan2(-Dy,Dx)/(2*math.pi))%1
                    local Sat = math.clamp(Dist/Radius,0,1)

                    WheelSelector.Position = UDim2.fromOffset(Center+Dx,Center+Dy)
                    SetValue(Color3.fromHSV(Hue,Sat,1),Entry.Value.a)
                end

                if DragAlpha then
                    local Pos = AlphaBar.AbsolutePosition
                    local Size = AlphaBar.AbsoluteSize
                    local Alpha = math.clamp((Mouse.X-Pos.X)/Size.X,0,1)
                    AlphaLine.Position = UDim2.fromScale(Alpha,0)
                    SetValue(Value,Alpha)
                end
            end)

            local function BindRGB(Box, Channel)
                Box:GetPropertyChangedSignal("Text"):Connect(function()
                    local digits = Box.Text:gsub("%D","")

                    if digits == "" then
                        Box.Text = ""
                        return
                    end

                    local number = tonumber(digits) or 0
                    number = math.clamp(number, 0, 255)

                    Box.Text = tostring(number)
                end)

                Box.FocusLost:Connect(function()
                    local Num = math.clamp(tonumber(Box.Text) or 0, 0, 255)
                    Box.Text = tostring(Num)

                    local R = Channel=="r" and Num or math.floor(Value.R*255)
                    local G = Channel=="g" and Num or math.floor(Value.G*255)
                    local B = Channel=="b" and Num or math.floor(Value.B*255)

                    SetValue(Color3.fromRGB(R,G,B), Entry.Value.a)
                end)
            end

            BindRGB(RBox,"r")
            BindRGB(GBox,"g")
            BindRGB(BBox,"b")

            local Open = false
            local Animating = false
            local OutsideConnection

            Library.ActiveColorpickers = Library.ActiveColorpickers or {}

            function Colorpicker:AnimateColorpicker(State)
                if Animating then return end
                Animating = true
                Open = State

                local TargetSize = State and UDim2.fromOffset(125,140) or UDim2.fromOffset(125,0)
                local TargetBG = State and 0 or 1
                local TargetShadow = State and 0 or 1

                if State then
                    local Pos = Preview.AbsolutePosition
                    local Size = Preview.AbsoluteSize
                    Settings.Position = UDim2.fromOffset(Pos.X + Size.X + 16, Pos.Y - 10)
                    Settings.Size = UDim2.fromOffset(125,0)
                    Settings.BackgroundTransparency = 1
                    Settings.Visible = true
                    SettingsShadow:SetTransparency(1)
                    Library.ActiveColorpickers[self] = true
                end

                local Tween = Services.TweenService:Create(
                    Settings,
                    TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                    {
                        Size = TargetSize,
                        BackgroundTransparency = TargetBG
                    }
                )

                Tween:Play()

                local Start = tick()
                local Duration = 0.30

                Library:RemoveRenderConnection("SettingsShadowFade")
                Library:AddRenderConnection("SettingsShadowFade", function()
                    local Alpha = math.clamp((tick() - Start) / Duration, 0, 1)

                    if not State then
                        Alpha = 1 - Alpha
                    end

                    SettingsShadow:SetTransparency(1 - Alpha)

                    if Alpha >= 1 then
                        Library:RemoveRenderConnection("SettingsShadowFade")
                    end
                end)

                Tween.Completed:Connect(function()
                    if Connection then
                        Connection:Disconnect()
                    end

                    SettingsShadow:SetTransparency(TargetShadow)

                    if not State then
                        Settings.Visible = false
                        Library.ActiveColorpickers[self] = nil
                    end

                    Animating = false
                end)
            end

            local function Close()
                if not Open then return end
                Open = false
                if OutsideConnection then
                    OutsideConnection:Disconnect()
                end
                Colorpicker:AnimateColorpicker(false)
            end

            local function OpenPicker()
                if Open then return end
                Open = true

                OutsideConnection = Services.UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

                    local mousePos = Services.UserInputService:GetMouseLocation()
                    local inset = Services.GuiService:GetGuiInset()
                    mousePos -= inset

                    local settingsPos = Settings.AbsolutePosition
                    local settingsSize = Settings.AbsoluteSize

                    local insideSettings =
                        mousePos.X >= settingsPos.X and
                        mousePos.X <= settingsPos.X + settingsSize.X and
                        mousePos.Y >= settingsPos.Y and
                        mousePos.Y <= settingsPos.Y + settingsSize.Y

                    local buttonPos = ColorpickerItem.AbsolutePosition
                    local buttonSize = ColorpickerItem.AbsoluteSize

                    local insideButton =
                        mousePos.X >= buttonPos.X and
                        mousePos.X <= buttonPos.X + buttonSize.X and
                        mousePos.Y >= buttonPos.Y and
                        mousePos.Y <= buttonPos.Y + buttonSize.Y

                    if not insideSettings and not insideButton then
                        Close()
                    end
                end)

                Colorpicker:AnimateColorpicker(true)
            end

            ColorpickerButton.MouseButton1Click:Connect(function()
                if Open then
                    Close()
                else
                    OpenPicker()
                end
            end)

            function Colorpicker:Set(newColor, newAlpha)
                newAlpha = newAlpha or Entry.Value.a
                SetValue(newColor, newAlpha)
            end

            function Colorpicker:Get()
                return Value, Entry.Value.a
            end

            return Colorpicker
        end)

        Library:RegisterElement("Keybox", function(Context)
            local Info = Context.Info
            local Container = Context.Container
            local Config = Context.Config

            Library.Flags = Library.Flags or {}

            local Text = Info.Text or "Keybox"
            local Flag = Info.Flag or Info.Text
            local Default = tostring(Info.Default or "")
            local Placeholder = Info.Placeholder or ""
            local Callback = Info.Callback or function() end

            local Entry = Config[Flag]
            if typeof(Entry) ~= "table" then
                Entry = {}
                Config[Flag] = Entry
            end

            Entry.Value = tostring(Entry.Value or Default)

            local State = Entry

            local KeyboxItem = Instance.new("Frame")
            KeyboxItem.Name = "Keybox"
            KeyboxItem.Size = UDim2.new(1, 0, 0, 25)
            KeyboxItem.BackgroundTransparency = 1
            KeyboxItem.Parent = Container

            local KeyboxLabel = Instance.new("TextLabel")
            KeyboxLabel.FontFace = UIFont(KeyboxLabel)
            KeyboxLabel.TextXAlignment = Enum.TextXAlignment.Left
            KeyboxLabel.TextColor3 = GetTheme().Text
            KeyboxLabel.TextSize = 16
            KeyboxLabel.BackgroundTransparency = 1
            KeyboxLabel.BorderSizePixel = 0
            KeyboxLabel.Size = UDim2.new(0.5, 0, 1, 0)
            KeyboxLabel.Text = Text
            KeyboxLabel.Parent = KeyboxItem
            Instance.new("UIPadding", KeyboxLabel).PaddingLeft = UDim.new(0, 10)

            local IndicatorHolder = Instance.new("Frame")
            IndicatorHolder.Size = UDim2.new(1, -70, 0, 25)
            IndicatorHolder.Position = UDim2.new(0, 60, 0, 0)
            IndicatorHolder.BackgroundTransparency = 1
            IndicatorHolder.ClipsDescendants = true
            IndicatorHolder.Parent = KeyboxItem

            local KeyIndicator = Instance.new("TextBox")
            KeyIndicator.Size = UDim2.new(1, 0, 1, 0)
            KeyIndicator.BackgroundTransparency = 1
            KeyIndicator.BorderSizePixel = 0
            KeyIndicator.TextXAlignment = Enum.TextXAlignment.Right
            KeyIndicator.TextYAlignment = Enum.TextYAlignment.Center
            KeyIndicator.FontFace = UIFont(KeyIndicator)
            KeyIndicator.TextSize = 12
            KeyIndicator.TextColor3 = Color3.fromRGB(145,145,145)
            KeyIndicator.PlaceholderText = Placeholder
            KeyIndicator.ClearTextOnFocus = false
            KeyIndicator.TextWrapped = false
            KeyIndicator.TextTruncate = Enum.TextTruncate.AtEnd
            KeyIndicator.Text = State.Value
            KeyIndicator.Parent = IndicatorHolder
            local IndicatorPadding = Instance.new("UIPadding", KeyIndicator)
            IndicatorPadding.PaddingTop = UDim.new(0, 4)

            local Keybox = {
                Instance = KeyboxItem,
                Flag = Flag,
                IsLayoutOnly = false,
                Value = State.Value
            }

            Library.Flags[Flag] = Keybox

            local function Truncate(Label, FullText)
                local Ellipsis = "..."
                local currentText = FullText

                Services.RunService.Heartbeat:Wait()

                local MaxWidth = math.max(0, Label.AbsoluteSize.X - 6)
                if MaxWidth <= 0 then
                    return FullText
                end

                local params = Instance.new("GetTextBoundsParams")
                params.Font = Label.FontFace
                params.Size = Label.TextSize
                params.Width = math.huge

                local function GetWidth(text)
                    params.Text = text
                    return Services.TextService:GetTextBoundsAsync(params).X
                end

                if GetWidth(FullText) <= MaxWidth then
                    return FullText
                end

                local Left = 1
                local Right = #FullText
                local Best = Ellipsis

                while Left <= Right do
                    local Mid = math.floor((Left + Right) / 2)
                    local Candidate = string.sub(FullText, 1, Mid) .. Ellipsis

                    if GetWidth(Candidate) <= MaxWidth then
                        Best = Candidate
                        Left = Mid + 1
                    else
                        Right = Mid - 1
                    end
                end

                return Best
            end

            local function Refresh(Force)
                Keybox.Value = State.Value
                Library:FireFlagChanged(Flag)

                if not KeyIndicator:IsFocused() then
                    KeyIndicator.Text = Force and State.Value or Truncate(KeyIndicator, State.Value)
                end
            end

            local function SetValue(Value)
                State.Value = tostring(Value or "")
                Entry.Value = State.Value
                Keybox.Value = State.Value
                Refresh(false)
                Callback(State.Value)
                Library.SaveConfigFile()
            end

            KeyIndicator.FocusLost:Connect(function()
                SetValue(KeyIndicator.Text)
            end)

            KeyIndicator:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                Refresh(true)
            end)

            Refresh(true)

            function Keybox:SetValue(Value)
                SetValue(Value)
            end

            function Keybox:GetValue()
                return State.Value
            end

            function Keybox:Reset()
                SetValue("")
            end

            return Keybox
        end)

        Library:RegisterHUD("Watermark", function(Context)
            local Info = Context.Info
            local Config = Context.Config
            local Parent = Context.DynamicHUD

            local Text = tostring(Info.Text or "Dynamic")

            local DefaultPosition = DeserializeUDim2(Config.Position) or Info.Position or UDim2.new(0, 20, 0, -10)

            local WatermarkHolder = Instance.new("Frame")
            WatermarkHolder.Name = "Watermark"
            WatermarkHolder.Position = DefaultPosition
            WatermarkHolder.Size = UDim2.new(1, 0, 1, 0)
            WatermarkHolder.BackgroundTransparency = 1
            WatermarkHolder.Parent = Parent

            local WatermarkLabel = Instance.new("TextLabel")
            WatermarkLabel.BackgroundTransparency = 1
            WatermarkLabel.TextWrapped = false
            WatermarkLabel.TextXAlignment = Enum.TextXAlignment.Center
            WatermarkLabel.TextYAlignment = Enum.TextYAlignment.Center
            WatermarkLabel.FontFace = UIFont(WatermarkLabel)
            WatermarkLabel.TextSize = 50
            WatermarkLabel.TextColor3 = GetTheme().Text
            WatermarkLabel.Text = Text
            WatermarkLabel.AutomaticSize = Enum.AutomaticSize.XY
            WatermarkLabel.Parent = WatermarkHolder
            AttachTextShadow(WatermarkLabel, {
                Offset = Vector2.new(1, 1),
                Color = GetTheme().ItemDefault,
                Transparency = 0.4
            })
            AddGradient(WatermarkLabel)

            local WatermarkShadow = AttachShadow(Parent, WatermarkLabel, 120, 8, 22, 1.0, Color3.fromRGB(255,255,255), true, 0.45)
            
            local function SetShadowVisible(State)
                if type(WatermarkShadow) == "table" and WatermarkShadow.SetTransparency then
                    WatermarkShadow:SetTransparency(State and 0 or 1)
                elseif typeof(WatermarkShadow) == "Instance" then
                    WatermarkShadow.Transparency = State and 0 or 1
                end
            end

            local function SyncShadow()
                local GlowFlag = Library.Flags.Watermark_Glow
                local MainFlag = Library.Flags.Watermark

                local GlowEnabled = true
                local WatermarkEnabled = true

                if type(GlowFlag) == "table" then
                    GlowEnabled = GlowFlag.Value == true
                elseif type(GlowFlag) == "boolean" then
                    GlowEnabled = GlowFlag == true
                end

                if type(MainFlag) == "table" then
                    WatermarkEnabled = MainFlag.Value == true
                elseif type(MainFlag) == "boolean" then
                    WatermarkEnabled = MainFlag == true
                end

                SetShadowVisible(GlowEnabled and WatermarkEnabled)
            end
            SyncShadow()

           local function UpdateWatermarkSize()
                WatermarkHolder.Size = UDim2.new(
                    0,
                    WatermarkLabel.AbsoluteSize.X + 24,
                    0,
                    WatermarkLabel.AbsoluteSize.Y + 10
                )
            end

            WatermarkLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateWatermarkSize)
            WatermarkLabel:GetPropertyChangedSignal("Text"):Connect(function()
                task.defer(UpdateWatermarkSize)
            end)

            task.defer(UpdateWatermarkSize)

            local Watermark = {}

            function Watermark:SetText(NewText)
                Text = tostring(NewText or "")
                WatermarkLabel.Text = Text
            end

            function Watermark:GetText()
                return Text
            end

            function Watermark:Destroy()
                WatermarkHolder:Destroy()
            end

            Library:RemoveRenderConnection("SyncShadow")
            Library:AddRenderConnection("SyncShadow", function()
                SyncShadow()
            end)

            return {
                Root = WatermarkHolder,
                HUDAPI = Watermark
            }
        end)

        Library:RegisterHUD("ArrayList", function(Context)
            local Info = Context.Info
            local Config = Context.Config
            local Parent = Context.DynamicHUD
            local LocalSessionId = Context.SessionId
            local DefaultPosition = DeserializeUDim2(Config.Position) or Info.Position or UDim2.new(1, -210, 0, -20)

            local Holder = Instance.new("Frame")
            Holder.Name = "ArrayList"
            Holder.AutomaticSize = Enum.AutomaticSize.Y
            Holder.Size = UDim2.new(0, 200, 0, 0)
            Holder.Position = DefaultPosition
            Holder.BackgroundTransparency = 1
            Holder.Parent = Parent

            local Layout = Instance.new("UIListLayout")
            Layout.FillDirection = Enum.FillDirection.Vertical
            Layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            Layout.SortOrder = Enum.SortOrder.LayoutOrder
            Layout.Parent = Holder

            local Items = {}
            local LayoutDirty = false
            local LayoutScheduled = false

            local function GetFlag(Name, Default)
                local Flag = Library.Flags[Name]
                if type(Flag) == "table" then
                    return Flag.Value
                end
                if Flag == nil then
                    return Default
                end
                return Flag
            end

            local function GetMetric(Object)
                return Object:GetAttribute("ArrayWidth") or 0
            end

            local function ApplyLayoutNow()
                if not Holder or not Holder.Parent then
                    return
                end

                local GuiItems = {}

                for _, Child in ipairs(Holder:GetChildren()) do
                    if Child:IsA("GuiObject") and Child.Visible then
                        GuiItems[#GuiItems + 1] = Child
                    end
                end

                if #GuiItems == 0 then
                    return
                end

                for _, obj in ipairs(GuiItems) do
                    if GetMetric(obj) <= 0 then
                        return
                    end
                end

                table.sort(GuiItems, function(a, b)
                    return GetMetric(a) > GetMetric(b)
                end)

                local MaxWidth = 0

                for _, obj in ipairs(GuiItems) do
                    local w = GetMetric(obj)
                    if w > MaxWidth then
                        MaxWidth = w
                    end
                end

                for i = 1, #GuiItems do
                    local obj = GuiItems[i]
                    obj.LayoutOrder = i

                    local w = GetMetric(obj)
                    obj.Size = UDim2.new(0, w + 6, 0, 20)

                    if obj:FindFirstChild("Slide") then
                        local slide = obj.Slide
                        slide.Size = UDim2.new(0, w, 1, 0)
                        slide.Position = UDim2.new(1, -w - 6, 0, 0)
                    end
                end

                Layout:ApplyLayout()
            end

            local function RequestLayout()
                LayoutDirty = true
                if LayoutScheduled then
                    return
                end
                LayoutScheduled = true

                Services.RunService.Heartbeat:Once(function()
                    task.defer(function()
                        LayoutScheduled = false
                        if LayoutDirty then
                            LayoutDirty = false
                            ApplyLayoutNow()
                        end
                    end)
                end)
            end

            local function CreateItem(Name)
                local TargetWidth = 0
                local Visible = false
                local Tweening = false
                local ActiveTween = nil

                local Root = Instance.new("Frame")
                Root.BackgroundTransparency = 1
                Root.Size = UDim2.new(0, 0, 0, 20)
                Root.AnchorPoint = Vector2.new(1, 0)
                Root.Position = UDim2.new(1, 0, 0, 0)
                Root.Visible = false
                Root.Parent = Holder

                local Slide = Instance.new("Frame")
                Slide.Name = "Slide"
                Slide.BorderSizePixel = 0
                Slide.ClipsDescendants = true
                Slide.Size = UDim2.new(0, 0, 1, 0)
                Slide.Position = UDim2.new(1, 6, 0, 0)
                Slide.Parent = Root

                local SlideShadow = AttachShadow(Parent, Slide, 0, 12, 26, 2.6, Color3.fromRGB(0,0,0), false, 0.45)

                local Bar = Instance.new("Frame")
                Bar.AnchorPoint = Vector2.new(1, 0.5)
                Bar.Position = UDim2.new(1, 0, 0.5, 0)
                Bar.Size = UDim2.new(0, 4, 0, 18)
                Bar.BorderSizePixel = 0
                Bar.Parent = Slide
                AddGradient(Bar)

                local BarCorner = Instance.new("UICorner")
                BarCorner.CornerRadius = UDim.new(0, 8)
                BarCorner.Parent = Bar

                local BarShadow = AttachShadow(Parent, Bar, 0, 12, 22, 2.0, Color3.fromRGB(255,255,255), true, 0.45)

                local Label = Instance.new("TextLabel")
                Label.BackgroundTransparency = 1
                Label.TextXAlignment = Enum.TextXAlignment.Right
                Label.TextYAlignment = Enum.TextYAlignment.Center
                Label.FontFace = UIFont(Label)
                Label.TextSize = 16
                Label.TextTransparency = 1
                Label.Size = UDim2.new(1, -12, 1, 0)
                Label.Position = UDim2.new(0, 6, 0, 0)
                Label.Text = Name
                Label.Parent = Slide
                AddGradient(Label)

                AttachTextShadow(Label, {
                    Offset = Vector2.new(1,1),
                    Color = GetTheme().ItemDefault,
                    Transparency = 0.4
                })

                local Item = {}
                Item.Root = Root

                local function StopTween()
                    if ActiveTween then
                        ActiveTween:Cancel()
                        ActiveTween = nil
                    end
                end

                local function UpdateWidth()
                    local Padding = GetFlag("ArrayList_Bar", true) and 12 or 8

                    local BoundsX = Label.TextBounds.X
                    if BoundsX <= 0 then
                        return
                    end

                    local NewWidth = math.floor(BoundsX + Padding + 0.5)

                    if NewWidth == TargetWidth then
                        return
                    end

                    TargetWidth = NewWidth

                    Root:SetAttribute("ArrayWidth", TargetWidth)

                    RequestLayout()
                end

                Label:GetPropertyChangedSignal("TextBounds"):Connect(UpdateWidth)

                task.defer(function()
                    Services.RunService.Heartbeat:Wait()
                    UpdateWidth()
                    Services.RunService.Heartbeat:Wait()
                    UpdateWidth()
                end)

                function Item.ApplyStyle()
                    local Theme = GetTheme()
                    local Style = GetFlag("ArrayList_Style", "Aero")

                    Slide.BackgroundColor3 = Theme.ItemDefault
                    Label.TextColor3 = Theme.Text
                    Bar.BackgroundColor3 = Theme.Accent or Theme.Text

                    if Style == "Boxed" then
                        Slide.BackgroundTransparency = 0.4
                        BarCorner.CornerRadius = UDim.new(0, 0)
                        Bar.Size = UDim2.new(0, 4, 1, 0)
                    else
                        Slide.BackgroundTransparency = 1
                        BarCorner.CornerRadius = UDim.new(0, 8)
                        Bar.Size = UDim2.new(0, 4, 0, 18)
                    end

                    Item.SyncShadow()
                end

                function Item.SyncShadow()
                    local Enabled = GetFlag("ArrayList", true)
                    local Glow = GetFlag("ArrayList_Glow", true)
                    local BarEnabled = GetFlag("ArrayList_Bar", true)

                    Root.Visible = Enabled and (Visible or Tweening)
                    Bar.Visible = BarEnabled

                    local FrameShadowVisible = Enabled and Glow and Visible
                    local BarShadowVisible = FrameShadowVisible and BarEnabled

                    if type(SlideShadow) == "table" and SlideShadow.SetTransparency then
                        SlideShadow:SetTransparency(FrameShadowVisible and 0 or 1)
                    elseif typeof(SlideShadow) == "Instance" then
                        SlideShadow.Transparency = FrameShadowVisible and 0 or 1
                    end

                    if type(BarShadow) == "table" and BarShadow.SetTransparency then
                        BarShadow:SetTransparency(BarShadowVisible and 0 or 1)
                    elseif typeof(BarShadow) == "Instance" then
                        BarShadow.Transparency = BarShadowVisible and 0 or 1
                    end
                end

                function Item.Show()
                    if Visible and not Tweening then return end

                    StopTween()

                    Visible = true
                    Root.Visible = true

                    local Mode = Library.Flags.Interface_Animation
                    local FinalPosition = UDim2.new(1, -TargetWidth - 6, 0, 0)

                    Tweening = true

                    local SlideTween
                    local TextTween
                    local BarTween

                    if Mode == "Fade" then
                        Slide.Position = FinalPosition

                        Slide.BackgroundTransparency = 1
                        Label.TextTransparency = 1
                        Bar.BackgroundTransparency = 1

                        SlideTween = Services.TweenService:Create(
                            Slide,
                            TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            {BackgroundTransparency = Library.Flags.ArrayList_Style == "Aero" and 1 or 0.4}
                        )

                        TextTween = Services.TweenService:Create(
                            Label,
                            TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                            {TextTransparency = 0}
                        )

                        BarTween = Services.TweenService:Create(
                            Bar,
                            TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                            {BackgroundTransparency = 0}
                        )
                    else
                        Slide.Position = UDim2.new(1, 6, 0, 0)
                        Label.TextTransparency = 1

                        SlideTween = Services.TweenService:Create(
                            Slide,
                            TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                            {Position = FinalPosition}
                        )

                        TextTween = Services.TweenService:Create(
                            Label,
                            TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                            {TextTransparency = 0}
                        )
                    end

                    ActiveTween = SlideTween

                    SlideTween.Completed:Once(function(state)
                        if ActiveTween ~= SlideTween then return end
                        if state ~= Enum.PlaybackState.Completed then return end

                        Tweening = false
                        ActiveTween = nil

                        Item.SyncShadow()
                        RequestLayout()
                    end)

                    SlideTween:Play()
                    TextTween:Play()
                    if BarTween then BarTween:Play() end

                    Item.SyncShadow()
                end

                function Item.Hide()
                    if not Visible and not Tweening then return end

                    StopTween()

                    Visible = false
                    Tweening = true

                    local Mode = Library.Flags.Interface_Animation
                    local HiddenPosition = UDim2.new(1, 6, 0, 0)

                    local SlideTween
                    local TextTween
                    local BarTween

                    if Mode == "Fade" then
                        SlideTween = Services.TweenService:Create(
                            Slide,
                            TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                            {BackgroundTransparency = 1}
                        )

                        TextTween = Services.TweenService:Create(
                            Label,
                            TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
                            {TextTransparency = 1}
                        )

                        BarTween = Services.TweenService:Create(
                            Bar,
                            TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
                            {BackgroundTransparency = 1}
                        )
                    else
                        SlideTween = Services.TweenService:Create(
                            Slide,
                            TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.In),
                            {Position = HiddenPosition}
                        )

                        TextTween = Services.TweenService:Create(
                            Label,
                            TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.In),
                            {TextTransparency = 1}
                        )
                    end

                    ActiveTween = SlideTween

                    SlideTween.Completed:Once(function(state)
                        if ActiveTween ~= SlideTween then return end
                        if state ~= Enum.PlaybackState.Completed then return end

                        Tweening = false
                        ActiveTween = nil

                        Root.Visible = false

                        Item.SyncShadow()
                        RequestLayout()
                    end)

                    SlideTween:Play()
                    TextTween:Play()
                    if BarTween then BarTween:Play() end

                    Item.SyncShadow()
                end

                Item.ApplyStyle()
                return Item
            end

            Library.ForEachModule(function(Module)
                Items[Module.Name] = CreateItem(Module.Name)
            end)

            Library.OnModuleAdded(function(Module)
                if Items[Module.Name] then return end
                Items[Module.Name] = CreateItem(Module.Name)
                RequestLayout()
            end)

            Library:OnFlagChanged(function()
                for _, Item in pairs(Items) do
                    Item.ApplyStyle()
                    Item.SyncShadow()
                end
                RequestLayout()
            end)

            function Library:RefreshArrayList()
                if getgenv().DynamicSessionId ~= LocalSessionId then return end

                Library.ForEachModule(function(Module, Obj)
                    local Item = Items[Module.Name]
                    if not Item then return end

                    local Enabled = Obj and Obj.Value == true
                    local VisibleFlag = Library.Flags[Module.Flag .. "_Visible"]
                    local Allowed = true

                    if type(VisibleFlag) == "table" then
                        Allowed = VisibleFlag.Value == true
                    elseif type(VisibleFlag) == "boolean" then
                        Allowed = VisibleFlag
                    end

                    if Enabled and Allowed then
                        Item.Show()
                    else
                        Item.Hide()
                    end
                end)

                RequestLayout()
            end

            Library:RefreshArrayList()

            return {
                Root = Holder
            }
        end)

        local NotificationContainer = Instance.new("Frame")
        NotificationContainer.Name = "Notification"
        NotificationContainer.BackgroundTransparency = 1
        NotificationContainer.AnchorPoint = Vector2.new(1, 1)
        NotificationContainer.Position = UDim2.new(1, 20, 1, -20)
        NotificationContainer.Size = UDim2.new(0, 220, 0, 9999)
        NotificationContainer.Parent = DynamicHUD

        local UIListLayout = Instance.new("UIListLayout")
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        UIListLayout.Padding = UDim.new(0, 8)
        UIListLayout.Parent = NotificationContainer

        function Library:Notification(Text, Duration)
            if not Library.Flags.Notification.Value then
                return
            end

            task.spawn(function()
                Duration = Duration or 5

                local TweenService = Services.TweenService
                local TextService = Services.TextService
                local Mode = Library.Flags.Interface_Animation

                local NotificationHolder = Instance.new("Frame")
                NotificationHolder.BackgroundTransparency = 1
                NotificationHolder.Size = UDim2.new(1, 0, 0, 40)
                NotificationHolder.BorderSizePixel = 0
                NotificationHolder.Parent = NotificationContainer

                local NotificationFrame = Instance.new("Frame")
                NotificationFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
                NotificationFrame.Size = UDim2.fromScale(0.8, 0.8)
                NotificationFrame.BorderSizePixel = 0
                NotificationFrame.ClipsDescendants = true
                NotificationFrame.Parent = NotificationHolder

                Instance.new("UICorner", NotificationFrame).CornerRadius = UDim.new(0, 26)

                local OverlayMask = Instance.new("Frame")
                OverlayMask.BackgroundTransparency = 1
                OverlayMask.Size = UDim2.new(0, 0, 1, 0)
                OverlayMask.ZIndex = 1
                OverlayMask.ClipsDescendants = true
                OverlayMask.Parent = NotificationFrame

                AttachShadow(DynamicHUD, OverlayMask, 26, 8, 7, 2.6, Color3.fromRGB(255,255,255), true)

                local Overlay = Instance.new("Frame")
                Overlay.BackgroundColor3 = Color3.fromRGB(255,255,255)
                Overlay.BorderSizePixel = 0
                Overlay.Size = UDim2.fromScale(1,1)
                Overlay.ZIndex = 1
                Overlay.Parent = OverlayMask

                Instance.new("UICorner", Overlay).CornerRadius = UDim.new(0,26)

                AddGradient(Overlay)

                local Label = Instance.new("TextLabel")
                Label.BackgroundTransparency = 1
                Label.FontFace = UIFont(Label)
                Label.TextSize = 16
                Label.TextColor3 = Color3.fromRGB(255,255,255)
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.TextYAlignment = Enum.TextYAlignment.Center
                Label.Size = UDim2.new(1,-20,1,-10)
                Label.Position = UDim2.new(0,10,0,5)
                Label.Text = Text
                Label.ZIndex = 5
                Label.Parent = NotificationFrame

                AttachTextShadow(Label,{
                    Offset = Vector2.new(1,1),
                    Color = GetTheme().ItemDefault,
                    Transparency = 0.6
                })

                local AdjustScheduled = false

                local function AdjustText()
                    if AdjustScheduled then
                        return
                    end
                    AdjustScheduled = true

                    task.defer(function()
                        AdjustScheduled = false

                        local BaseSize = 16
                        local MinSize = 12
                        local CurrentText = Label.Text
                        local MaxWidth = Label.AbsoluteSize.X

                        if MaxWidth <= 0 then
                            return
                        end

                        local Params = Instance.new("GetTextBoundsParams")
                        Params.Text = CurrentText
                        Params.Font = Label.FontFace
                        Params.Size = BaseSize
                        Params.Width = math.huge

                        local Bounds = TextService:GetTextBoundsAsync(Params)

                        if Label.Text ~= CurrentText then
                            return
                        end

                        if Bounds.X > MaxWidth then
                            local Ratio = MaxWidth / Bounds.X
                            local NewSize = math.floor(BaseSize * Ratio)
                            Label.TextSize = math.clamp(NewSize, MinSize, BaseSize)
                        else
                            Label.TextSize = BaseSize
                        end
                    end)
                end

                Label:GetPropertyChangedSignal("AbsoluteSize"):Connect(AdjustText)
                Label:GetPropertyChangedSignal("Text"):Connect(AdjustText)
                Label:GetPropertyChangedSignal("FontFace"):Connect(AdjustText)

                AdjustText()

                Services.RunService.RenderStepped:Wait()

                local FrameWidth = NotificationFrame.AbsoluteSize.X

                if Mode == "Fade" then
                    NotificationFrame.Position = UDim2.fromOffset(0,0)
                    NotificationFrame.BackgroundTransparency = 1
                    Label.TextTransparency = 1
                    Overlay.BackgroundTransparency = 1
                else
                    NotificationFrame.Position = UDim2.fromOffset(FrameWidth + 20,0)
                end

                local EnterTween
                if Mode == "Fade" then
                    EnterTween = TweenService:Create(
                        NotificationFrame,
                        TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
                        {BackgroundTransparency = 0}
                    )
                    TweenService:Create(
                        Label,
                        TweenInfo.new(0.3,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
                        {TextTransparency = 0}
                    ):Play()

                    TweenService:Create(
                        Overlay,
                        TweenInfo.new(0.3,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
                        {BackgroundTransparency = 0}
                    ):Play()
                else
                    EnterTween = TweenService:Create(
                        NotificationFrame,
                        TweenInfo.new(0.32,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out),
                        {Position = UDim2.fromOffset(0,0)}
                    )
                end

                EnterTween:Play()

                OverlayMask.Size = UDim2.new(0,0,1,0)

                local BarTween = TweenService:Create(
                    OverlayMask,
                    TweenInfo.new(Duration,Enum.EasingStyle.Linear),
                    {Size = UDim2.new(1,0,1,0)}
                )

                BarTween:Play()
                BarTween.Completed:Wait()

                local ExitTween
                if Mode == "Fade" then
                    ExitTween = TweenService:Create(
                        NotificationFrame,
                        TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
                        {BackgroundTransparency = 1}
                    )
                    TweenService:Create(
                        Label,
                        TweenInfo.new(0.3,Enum.EasingStyle.Quart,Enum.EasingDirection.In),
                        {TextTransparency = 1}
                    ):Play()
                    TweenService:Create(
                        Overlay,
                        TweenInfo.new(0.3,Enum.EasingStyle.Quart,Enum.EasingDirection.In),
                        {BackgroundTransparency = 1}
                    ):Play()
                else
                    ExitTween = TweenService:Create(
                        NotificationFrame,
                        TweenInfo.new(0.32,Enum.EasingStyle.Exponential,Enum.EasingDirection.In),
                        {Position = UDim2.fromOffset(FrameWidth + 20,0)}
                    )
                end

                ExitTween:Play()
                ExitTween.Completed:Wait()

                NotificationHolder:Destroy()
            end)
        end

        function Library:PlayNotification(Name, isOn)
			local stateText = isOn and "was enabled" or "was disabled"
			Library:Notification(Name .. " " .. stateText, 3)
		end

		local UISounds = Services.SoundService:FindFirstChild("UISounds")
		if not UISounds then
			UISounds = Instance.new("Folder")
			UISounds.Name = "UISounds"
			UISounds.Parent = Services.SoundService
		end

		local ToggleSound = Instance.new("Sound")
		ToggleSound.Looped = false
		ToggleSound.EmitterSize = 0
		ToggleSound.RollOffMaxDistance = math.huge
		ToggleSound.Parent = UISounds
        
		function Library:PlayToggleSound(_, IsOn)
            if not Library.Flags.ToggleSound.Value then
                return
            end

            local Suffix = IsOn and "_On" or "_Off"
            local SoundName = Library.Flags.ToggleSound_Sound .. Suffix
            local SoundId = Assets:GetSound("Sounds/" .. SoundName .. ".wav")

            if not SoundId then
                return
            end

            local Volume = (Library.Flags.ToggleSound_Volume or 10) / 10

            ToggleSound.Volume = Volume
            ToggleSound.SoundId = SoundId

            ToggleSound:Stop()
            ToggleSound:Play()
        end


        local InternalAddCategory = function(_, ...)
            return AddCategory(...)
        end

        Library.Window.AddCategory = InternalAddCategory
        function Window:AddCategory(...)
            return InternalAddCategory(self, ...)
        end

        local InternalAddModule = Library.Window.AddModule
        function Window:AddModule(...)
            return InternalAddModule(self, ...)
        end

        return Window
    end
    return Library
end

return DynamicUI()
