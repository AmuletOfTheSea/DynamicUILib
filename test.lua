-- DynamicUILib - Full UI Library for DynamicSource2
-- This library contains all UI components, helpers, and styling utilities

-- Loading Screen UI Components
local UILib = {}

function UILib.CreateLoadingScreen(CoreGui)
    local LoadingScreenGui = Instance.new("ScreenGui")
    LoadingScreenGui.Name = "DynamicLoadingScreen"
    LoadingScreenGui.ResetOnSpawn = false
    LoadingScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    LoadingScreenGui.Parent = CoreGui

    local LoadingContainer = Instance.new("Frame")
    LoadingContainer.Name = "LoadingContainer"
    LoadingContainer.Size = UDim2.new(0, 450, 0, 280)
    LoadingContainer.Position = UDim2.new(0.5, -225, 0.5, -140)
    LoadingContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    LoadingContainer.BorderSizePixel = 0
    LoadingContainer.Parent = LoadingScreenGui

    local LoadingCorner = Instance.new("UICorner")
    LoadingCorner.CornerRadius = UDim.new(0, 16)
    LoadingCorner.Parent = LoadingContainer

    local BorderStroke = Instance.new("UIStroke")
    BorderStroke.Color = Color3.fromRGB(50, 50, 50)
    BorderStroke.Thickness = 1
    BorderStroke.Parent = LoadingContainer

    local LoadingTitle = Instance.new("TextLabel")
    LoadingTitle.Name = "LoadingTitle"
    LoadingTitle.Size = UDim2.new(1, -40, 0, 70)
    LoadingTitle.Position = UDim2.new(0, 20, 0, 15)
    LoadingTitle.BackgroundTransparency = 1
    LoadingTitle.TextColor3 = Color3.fromRGB(100, 220, 230)
    LoadingTitle.TextSize = 32
    LoadingTitle.Font = Enum.Font.GothamBold
    LoadingTitle.Text = "Dynamic"
    LoadingTitle.TextXAlignment = Enum.TextXAlignment.Left
    LoadingTitle.Parent = LoadingContainer

    local LoadingSubtitle = Instance.new("TextLabel")
    LoadingSubtitle.Name = "LoadingSubtitle"
    LoadingSubtitle.Size = UDim2.new(1, -40, 0, 25)
    LoadingSubtitle.Position = UDim2.new(0, 20, 0, 70)
    LoadingSubtitle.BackgroundTransparency = 1
    LoadingSubtitle.TextColor3 = Color3.fromRGB(180, 180, 180)
    LoadingSubtitle.TextSize = 13
    LoadingSubtitle.Font = Enum.Font.Gotham
    LoadingSubtitle.Text = "Initializing Script"
    LoadingSubtitle.TextXAlignment = Enum.TextXAlignment.Left
    LoadingSubtitle.Parent = LoadingContainer

    local LoadingProgressBg = Instance.new("Frame")
    LoadingProgressBg.Name = "ProgressBackground"
    LoadingProgressBg.Size = UDim2.new(1, -40, 0, 6)
    LoadingProgressBg.Position = UDim2.new(0, 20, 0, 110)
    LoadingProgressBg.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    LoadingProgressBg.BorderSizePixel = 0
    LoadingProgressBg.Parent = LoadingContainer

    local ProgressCorner = Instance.new("UICorner")
    ProgressCorner.CornerRadius = UDim.new(0, 3)
    ProgressCorner.Parent = LoadingProgressBg

    local LoadingProgress = Instance.new("Frame")
    LoadingProgress.Name = "ProgressBar"
    LoadingProgress.Size = UDim2.new(0, 0, 1, 0)
    LoadingProgress.BackgroundColor3 = Color3.fromRGB(100, 220, 230)
    LoadingProgress.BorderSizePixel = 0
    LoadingProgress.Parent = LoadingProgressBg

    local ProgressCorner2 = Instance.new("UICorner")
    ProgressCorner2.CornerRadius = UDim.new(0, 3)
    ProgressCorner2.Parent = LoadingProgress

    local LoadingText = Instance.new("TextLabel")
    LoadingText.Name = "LoadingText"
    LoadingText.Size = UDim2.new(1, -40, 0, 120)
    LoadingText.Position = UDim2.new(0, 20, 0, 140)
    LoadingText.BackgroundTransparency = 1
    LoadingText.TextColor3 = Color3.fromRGB(150, 150, 150)
    LoadingText.TextSize = 12
    LoadingText.Font = Enum.Font.Gotham
    LoadingText.Text = "Loading modules..."
    LoadingText.TextWrapped = true
    LoadingText.TextYAlignment = Enum.TextYAlignment.Top
    LoadingText.TextXAlignment = Enum.TextXAlignment.Left
    LoadingText.Parent = LoadingContainer

    return {
        Gui = LoadingScreenGui,
        Container = LoadingContainer,
        Title = LoadingTitle,
        Subtitle = LoadingSubtitle,
        Progress = LoadingProgress,
        ProgressBg = LoadingProgressBg,
        Text = LoadingText,
        Close = function(self)
            self.Gui:Destroy()
        end,
        UpdateProgress = function(self, percent)
            self.Progress.Size = UDim2.new(math.clamp(percent / 100, 0, 1), 0, 1, 0)
        end,
        UpdateText = function(self, text)
            self.Text.Text = text
        end,
        UpdateSubtitle = function(self, text)
            self.Subtitle.Text = text
        end
    }
end

function UILib.CreateWatermark(CoreGui)
    local WatermarkGui = Instance.new("ScreenGui")
    WatermarkGui.Name = "DynamicWatermark"
    WatermarkGui.ResetOnSpawn = false
    WatermarkGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    WatermarkGui.Parent = CoreGui

    local WatermarkLabel = Instance.new("TextLabel")
    WatermarkLabel.Name = "WatermarkLabel"
    WatermarkLabel.Size = UDim2.new(0, 200, 0, 30)
    WatermarkLabel.Position = UDim2.new(0, 10, 0, 10)
    WatermarkLabel.BackgroundTransparency = 0.3
    WatermarkLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    WatermarkLabel.TextColor3 = Color3.fromRGB(100, 220, 230)
    WatermarkLabel.TextSize = 14
    WatermarkLabel.Font = Enum.Font.GothamBold
    WatermarkLabel.Text = "Dynamic [DEV BUILD]"
    WatermarkLabel.TextXAlignment = Enum.TextXAlignment.Center
    WatermarkLabel.Parent = WatermarkGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = WatermarkLabel

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(100, 220, 230)
    Stroke.Thickness = 1.5
    Stroke.Parent = WatermarkLabel

    return {
        Gui = WatermarkGui,
        Label = WatermarkLabel,
        SetText = function(self, text)
            self.Label.Text = text
        end,
        Remove = function(self)
            self.Gui:Destroy()
        end
    }
end

function UILib.CreateNotification(CoreGui, title, message, duration)
    duration = duration or 5
    
    local NotificationGui = Instance.new("ScreenGui")
    NotificationGui.Name = "DynamicNotification"
    NotificationGui.ResetOnSpawn = false
    NotificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    NotificationGui.Parent = CoreGui

    local NotificationFrame = Instance.new("Frame")
    NotificationFrame.Name = "NotificationFrame"
    NotificationFrame.Size = UDim2.new(0, 300, 0, 80)
    NotificationFrame.Position = UDim2.new(1, -320, 1, -100)
    NotificationFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    NotificationFrame.BorderSizePixel = 0
    NotificationFrame.Parent = NotificationGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = NotificationFrame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(100, 220, 230)
    Stroke.Thickness = 1
    Stroke.Parent = NotificationFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(1, -20, 0, 30)
    TitleLabel.Position = UDim2.new(0, 10, 0, 5)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.TextColor3 = Color3.fromRGB(100, 220, 230)
    TitleLabel.TextSize = 14
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = title
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = NotificationFrame

    local MessageLabel = Instance.new("TextLabel")
    MessageLabel.Name = "Message"
    MessageLabel.Size = UDim2.new(1, -20, 0, 40)
    MessageLabel.Position = UDim2.new(0, 10, 0, 35)
    MessageLabel.BackgroundTransparency = 1
    MessageLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    MessageLabel.TextSize = 12
    MessageLabel.Font = Enum.Font.Gotham
    MessageLabel.Text = message
    MessageLabel.TextWrapped = true
    MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
    MessageLabel.TextYAlignment = Enum.TextYAlignment.Top
    MessageLabel.Parent = NotificationFrame

    task.delay(duration, function()
        NotificationGui:Destroy()
    end)

    return NotificationGui
end

function UILib.CreateTooltip(parent, text)
    local TooltipLabel = Instance.new("TextLabel")
    TooltipLabel.Name = "Tooltip"
    TooltipLabel.Size = UDim2.new(0, 200, 0, 0)
    TooltipLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    TooltipLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    TooltipLabel.TextSize = 11
    TooltipLabel.Font = Enum.Font.Gotham
    TooltipLabel.Text = text
    TooltipLabel.TextWrapped = true
    TooltipLabel.BorderSizePixel = 0
    TooltipLabel.Visible = false
    TooltipLabel.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = TooltipLabel

    local Padding = Instance.new("UIPadding")
    Padding.PaddingLeft = UDim.new(0, 8)
    Padding.PaddingRight = UDim.new(0, 8)
    Padding.PaddingTop = UDim.new(0, 6)
    Padding.PaddingBottom = UDim.new(0, 6)
    Padding.Parent = TooltipLabel

    return TooltipLabel
end

function UILib.FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.2f", num / 1000000) .. "M"
    elseif num >= 1000 then
        return string.format("%.2f", num / 1000) .. "K"
    else
        return tostring(num)
    end
end

function UILib.FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    if hours > 0 then
        return string.format("%dh %dm %ds", hours, minutes, secs)
    elseif minutes > 0 then
        return string.format("%dm %ds", minutes, secs)
    else
        return string.format("%ds", secs)
    end
end

function UILib.CreateCustomButton(parent, text, callback)
    local Button = Instance.new("TextButton")
    Button.Name = "CustomButton"
    Button.Size = UDim2.new(1, 0, 0, 36)
    Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 14
    Button.Font = Enum.Font.GothamBold
    Button.Text = text
    Button.BorderSizePixel = 0
    Button.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Button

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(100, 220, 230)
    Stroke.Thickness = 1
    Stroke.Parent = Button

    Button.MouseButton1Click:Connect(callback)

    Button.MouseEnter:Connect(function()
        Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end)

    Button.MouseLeave:Connect(function()
        Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end)

    return Button
end

function UILib.CreateColorPicker(parent, initialColor)
    local Picker = Instance.new("Frame")
    Picker.Name = "ColorPicker"
    Picker.Size = UDim2.new(1, 0, 0, 150)
    Picker.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Picker.BorderSizePixel = 0
    Picker.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Picker

    local currentColor = initialColor or Color3.fromRGB(100, 220, 230)

    local function updateDisplay()
        local display = Instance.new("Frame")
        display.Name = "ColorDisplay"
        display.Size = UDim2.new(0, 60, 0, 60)
        display.Position = UDim2.new(0, 10, 0, 10)
        display.BackgroundColor3 = currentColor
        display.BorderSizePixel = 0
        display.Parent = Picker

        local DisplayCorner = Instance.new("UICorner")
        DisplayCorner.CornerRadius = UDim.new(0, 6)
        DisplayCorner.Parent = display
    end

    updateDisplay()

    return {
        Instance = Picker,
        GetColor = function() return currentColor end,
        SetColor = function(color) currentColor = color; updateDisplay() end
    }
end


function UILib.CreateWindow(windowName, windowTitle)
    local WindowGui = Instance.new("ScreenGui")
    WindowGui.Name = windowName
    WindowGui.ResetOnSpawn = false
    WindowGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local WindowFrame = Instance.new("Frame")
    WindowFrame.Name = "MainWindow"
    WindowFrame.Size = UDim2.new(0, 500, 0, 600)
    WindowFrame.Position = UDim2.new(0.5, -250, 0.5, -300)
    WindowFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    WindowFrame.BorderSizePixel = 0
    WindowFrame.Parent = WindowGui

    local WindowCorner = Instance.new("UICorner")
    WindowCorner.CornerRadius = UDim.new(0, 12)
    WindowCorner.Parent = WindowFrame

    local WindowStroke = Instance.new("UIStroke")
    WindowStroke.Color = Color3.fromRGB(50, 50, 50)
    WindowStroke.Thickness = 2
    WindowStroke.Parent = WindowFrame

    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = WindowFrame

    local TitleBarCorner = Instance.new("UICorner")
    TitleBarCorner.CornerRadius = UDim.new(0, 12)
    TitleBarCorner.Parent = TitleBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(1, -20, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.TextColor3 = Color3.fromRGB(100, 220, 230)
    TitleLabel.TextSize = 18
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = windowTitle
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar

    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "Content"
    ContentFrame.Size = UDim2.new(1, 0, 1, -40)
    ContentFrame.Position = UDim2.new(0, 0, 0, 40)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.BorderSizePixel = 0
    ContentFrame.Parent = WindowFrame

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Padding = UDim.new(0, 8)
    ListLayout.Parent = ContentFrame

    local ScrollingFrame = Instance.new("ScrollingFrame")
    ScrollingFrame.Name = "ScrollContainer"
    ScrollingFrame.Size = UDim2.new(1, -10, 1, -10)
    ScrollingFrame.Position = UDim2.new(0, 5, 0, 5)
    ScrollingFrame.BackgroundTransparency = 1
    ScrollingFrame.BorderSizePixel = 0
    ScrollingFrame.ScrollBarThickness = 4
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollingFrame.Parent = ContentFrame

    local function MakeDraggable()
        local isDragging = false
        local dragInput, dragStart, startPos

        TitleBar.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = true
                dragStart = input.Position
                startPos = WindowFrame.Position
            end
        end)

        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                WindowFrame.Position = startPos + UDim2.new(0, delta.X, 0, delta.Y)
            end
        end)

        game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = false
            end
        end)
    end

    MakeDraggable()

    return {
        Gui = WindowGui,
        MainFrame = WindowFrame,
        Content = ScrollingFrame,
        AddButton = function(self, text, callback)
            return UILib.CreateCustomButton(ScrollingFrame, text, callback)
        end,
        AddLabel = function(self, text)
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 0, 25)
            Label.BackgroundTransparency = 1
            Label.TextColor3 = Color3.fromRGB(200, 200, 200)
            Label.TextSize = 12
            Label.Font = Enum.Font.Gotham
            Label.Text = text
            Label.Parent = ScrollingFrame
            return Label
        end,
        Show = function(self)
            self.Gui.Parent = game:GetService("CoreGui")
        end,
        Hide = function(self)
            self.Gui.Parent = nil
        end,
        Close = function(self)
            self.Gui:Destroy()
        end
    }
end

function UILib.CreateTab(parent, tabName)
    local TabButton = Instance.new("TextButton")
    TabButton.Name = tabName
    TabButton.Size = UDim2.new(0, 100, 0, 30)
    TabButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    TabButton.TextColor3 = Color3.fromRGB(180, 180, 180)
    TabButton.TextSize = 12
    TabButton.Font = Enum.Font.Gotham
    TabButton.Text = tabName
    TabButton.BorderSizePixel = 0
    TabButton.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = TabButton

    return TabButton
end

return UILib
