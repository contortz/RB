-- Replace the entire CreateSlider function with this:
function CreateSlider(parent, yPos, min, max, default)
    -- Main slider frame
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(0.8, 0, 0, 20)
    sliderFrame.Position = UDim2.new(0, 0, 0, yPos)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = parent

    -- Background track
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0.4, 0)
    track.Position = UDim2.new(0, 0, 0.3, 0)
    track.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    track.BorderSizePixel = 0
    track.Parent = sliderFrame

    -- Fill bar
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0.5, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track

    -- Draggable button
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 16, 0, 16)
    button.Position = UDim2.new(0.5, -8, 0.5, -8)
    button.BackgroundColor3 = Color3.fromRGB(200, 200, 255)
    button.BorderSizePixel = 0
    button.Text = ""
    button.Parent = sliderFrame

    -- Value display label
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.2, 0, 1, 0)
    valueLabel.Position = UDim2.new(1.05, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    valueLabel.TextSize = 12
    valueLabel.Parent = sliderFrame

    -- Internal state and event
    local currentValue = default
    sliderFrame.ValueChanged = Instance.new("BindableEvent")

    local function updateSlider(input)
        local mousePos = input.Position.X
        local framePos = sliderFrame.AbsolutePosition.X
        local frameWidth = sliderFrame.AbsoluteSize.X
        if frameWidth <= 0 then return end -- Avoid division by zero

        local percent = math.clamp((mousePos - framePos) / frameWidth, 0, 1)
        currentValue = min + (max - min) * percent
        currentValue = math.round(currentValue * 10) / 10 -- Round to 1 decimal

        fill.Size = UDim2.new(percent, 0, 1, 0)
        button.Position = UDim2.new(percent, -8, 0.5, -8)
        valueLabel.Text = tostring(currentValue)
        sliderFrame.ValueChanged:Fire(currentValue)
    end

    -- Button drag logic
    button.MouseButton1Down:Connect(function()
        local connection
        connection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider(input)
            end
        end)
        local endedConnection = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                connection:Disconnect()
                endedConnection:Disconnect()
            end
        end)
    end)

    -- Click on track to jump to position
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateSlider(input)
        end
    end)

    -- Set initial value
    local defaultPercent = (default - min) / (max - min)
    fill.Size = UDim2.new(defaultPercent, 0, 1, 0)
    button.Position = UDim2.new(defaultPercent, -8, 0.5, -8)
    valueLabel.Text = tostring(default)

    return sliderFrame
end

-- Replace the entire CreateToggle function with this:
function CreateToggle(parent, text, yPos)
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0.8, 0, 0, 25)
    toggle.Position = UDim2.new(0, 0, 0, yPos)
    toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    toggle.BackgroundTransparency = 0.5
    toggle.BorderSizePixel = 0
    toggle.Text = "❌ Disabled"
    toggle.TextColor3 = Color3.fromRGB(200, 200, 200)
    toggle.TextSize = 13
    toggle.TextXAlignment = Enum.TextXAlignment.Left
    toggle.Parent = parent

    -- Use a simple boolean state and MouseButton1Click for reliable toggling
    local enabled = false
    toggle.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            toggle.Text = "✅ Enabled"
            toggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        else
            toggle.Text = "❌ Disabled"
            toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        end
        -- Fire the custom event we'll attach to the button
        if toggle.OnToggle then
            toggle.OnToggle:Fire(enabled)
        end
    end)

    -- Add a custom event for state changes
    toggle.OnToggle = Instance.new("BindableEvent")
    return toggle
end
