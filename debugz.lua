-- ==== Add near your other state/consts ====
local lastConfirmAt = 0
local CONFIRM_COOLDOWN = 1.2

-- ==== Add once (top-level, after frame is created): helper banner UI ====
local confirmBanner = Instance.new("TextLabel")
confirmBanner.Size = UDim2.new(1, -12, 0, 24)
confirmBanner.Position = UDim2.new(0, 6, 0, 8)
confirmBanner.BackgroundColor3 = Color3.fromRGB(60, 60, 20)
confirmBanner.TextColor3 = Color3.fromRGB(255, 255, 180)
confirmBanner.TextScaled = true
confirmBanner.Font = Enum.Font.GothamBold
confirmBanner.Text = ""
confirmBanner.Visible = false
confirmBanner.Parent = frame

-- ==== Helpers (reuse your looksLikeOK, etc.) ====
local function looksLikeOK(s)
    if typeof(s) ~= "string" then return false end
    s = s:lower():gsub("%s+", "")
    return (s == "ok" or s == "okay" or s == "ok!")
end

local function findNumberNodeIn(root, minV, maxV)
    for _, d in ipairs(root:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and typeof(d.Text) == "string" then
            local num = d.Text:match("(%d+)")
            if num then
                local val = tonumber(num)
                if val and val >= minV and val <= maxV then
                    return d, val
                end
            end
        end
    end
    return nil
end

local function findOKLabelIn(root)
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("TextLabel") and looksLikeOK(d.Text) then
            return d
        end
    end
    return nil
end

local function clickableAncestor(node, stopAt)
    local cur = node
    while cur and cur ~= stopAt do
        if cur:IsA("TextButton") or cur:IsA("ImageButton") then
            return cur
        end
        cur = cur.Parent
    end
    if stopAt then
        return stopAt:FindFirstChildWhichIsA("TextButton", true)
            or stopAt:FindFirstChildWhichIsA("ImageButton", true)
    end
    return nil
end

local function pressButton(btn)
    if not btn then return false end
    local ok = false
    -- 1) Native activation (most reliable when allowed)
    if btn.Activate then
        ok = pcall(function() btn:Activate() end)
    end
    -- 2) Fall back to firesignal
    if not ok and typeof(firesignal) == "function" then
        pcall(function()
            if btn.MouseButton1Down then firesignal(btn.MouseButton1Down) end
            if btn.MouseButton1Click then firesignal(btn.MouseButton1Click) end
            if btn.MouseButton1Up then firesignal(btn.MouseButton1Up) end
            if btn.Activated then firesignal(btn.Activated) end
        end)
        ok = true
    end
    return ok
end

-- ==== REPLACE your tryConfirmPurchase() with this ====
local GuiService = game:GetService("GuiService")

local function tryConfirmPurchase()
    if not autoConfirmUnlock then return end
    if os.clock() - lastConfirmAt < CONFIRM_COOLDOWN then return end

    local root = CoreGui:FindFirstChild("PurchasePromptApp"); if not root then return end
    local container = root:FindFirstChild("ProductPurchaseContainer"); if not container then return end
    local animator = container:FindFirstChild("Animator"); if not animator then return end
    local prompt = animator:FindFirstChild("Prompt"); if not prompt then return end
    local controls = prompt:FindFirstChild("AlertControls"); if not controls then return end
    local footer = controls:FindFirstChild("Footer"); if not footer then return end
    local buttons = footer:FindFirstChild("Buttons"); if not buttons then return end

    -- Target FIRST holder (the one with the 39 etc.)
    local holder1 = buttons:FindFirstChild("1"); if not holder1 then return end

    -- Require OK text and price 30..50 inside the same holder
    local okLabel = findOKLabelIn(holder1); if not okLabel then return end
    local numberNode, price = findNumberNodeIn(holder1, 30, 50); if not numberNode then return end

    -- Find the clickable ancestor in that exact region
    local okBtn = clickableAncestor(numberNode, holder1); if not okBtn then return end

    -- Try to activate programmatically
    local pressed = pressButton(okBtn)

    -- If CoreGui blocks programmatic activation, focus + banner so user can press Enter/Click
    if not pressed then
        confirmBanner.Text = ("Press OK to confirm (%d)"):format(price)
        confirmBanner.Visible = true
        pcall(function() GuiService.SelectedObject = okBtn end)
        -- Hide the banner shortly after to avoid sticking
        task.delay(2.0, function()
            if confirmBanner then confirmBanner.Visible = false end
        end)
    end

    lastConfirmAt = os.clock()
end
