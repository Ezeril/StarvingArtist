-- Settings
local Settings = {
    Image = "",
    Mode = "Randomize",
    IsDrawing = false,
    Size = 1,
    Brush = "Normal"
}

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local LocalPlayer = Players.LocalPlayer
local MainGui = LocalPlayer.PlayerGui.MainGui
local identified = identifyexecutor()

local Brushes = {"Normal", "Star", "Circle", "Diamond", "Moon", "Asterisk", "Stripes", "Plus", "Triangle", "Water", "Chain", "Heart", "Checkerboard", "Hexagon", "Spray Paint", "Sticker", "Random"}

function GetGrid()
    local Grid = MainGui:FindFirstChild("PaintFrame"):FindFirstChild("Grid")
    if not Grid then
        Grid = MainGui:FindFirstChild("PaintFrame"):FindFirstChild("GridHolder"):FindFirstChild("Grid")
    end
    return Grid
end

function SendNotify(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text
    })
end

local Grid = GetGrid()

function GetJson(url)
    local Response = game:HttpGet(string.format("https://images.esohasl.net" .. "/?url=%s&executor=%s", url, string.gsub(identified, "%s+", "")))

    if string.find(Response, "502") then
        SendNotify("Server Error | 502", "The server may have gone down unexpectedly. Report to discord.gg/HjKDVu2rAH - I'll fix it as soon as possible.")
        return {}
    elseif string.find(Response, "Bad Request") or string.find(Response, "undefined is not an object") then
        SendNotify("Invalid URL", "The link provided is incorrect. discord.gg/HjKDVu2rAH to get help on how to get correct links.")
        return {}
    end

    return HttpService:JSONDecode(Response)
end

function Import(url)
    if Settings.IsDrawing then return end

    local pixels = GetJson(url)
    local usedIndices = {}

    if not Grid then Grid = GetGrid() end

    Settings.IsDrawing = true

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

        if Settings.Brush == "Normal" then
            Grid[tostring(pixelIndex)].BackgroundColor3 = Color3.fromRGB(r, g, b)
        else
            local Brush
            if Settings.Brush == "Random" then
                Brush = ReplicatedStorage.Brushes[Brushes[math.random(2, 16)]]:Clone()
            else
                Brush = ReplicatedStorage.Brushes[Settings.Brush]:Clone()
            end

            Brush.ImageColor3 = Color3.fromRGB(r, g, b)
            Brush.Size = UDim2.new(Settings.Size, 0, Settings.Size, 0)
            Brush.Parent = Grid[tostring(pixelIndex)]
        end

        task.wait(0.375)
    end

    Settings.IsDrawing = false
end

-- User Interface
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wally2", true))()
local Window = Library:CreateWindow("Starving Arts")

-- UI Section for Image Settings
Window:Section("🎨 Image Settings", {icon = "rbxassetid://1234567890"})  -- Remplacez l'ID par un vrai pour l'icône
Window:Box("Image URL", {}, function(value) 
    task.spawn(function()
        Settings.Image = value
    end)
end)

Window:Dropdown("🖌️ Draw Mode", {list = { "Randomize", "By Step" } }, function(var) 
    task.spawn(function()
        Settings.Mode = var
    end)
end)

Window:Dropdown("🔲 Brushes", {list = Brushes }, function(var) 
    task.spawn(function()
        Settings.Brush = var
    end)
end)

Window:Slider("📏 Brush Size", {min = 1, max = 5}, function(value)
    task.spawn(function()
        Settings.Size = value
    end)
end)

-- Section for Actions with some stylized buttons
Window:Section("🔧 Actions", {icon = "rbxassetid://1234567890"})  -- Remplacez l'ID par un vrai pour l'icône
Window:Button("✨ Draw Image", {color = Color3.fromRGB(34, 34, 34)}, function()
    task.spawn(function()
        Import(Settings.Image)
    end)
end)

Window:Button("🎨 Change Brush", {color = Color3.fromRGB(42, 87, 179)}, function()
    Window:Dropdown("Select Brush", {list = Brushes}, function(selectedBrush)
        Settings.Brush = selectedBrush
        SendNotify("Brush Changed", "Your brush has been changed to: " .. selectedBrush)
    end)
end)

Window:Button("🎥 YouTube: EsohaSL", {color = Color3.fromRGB(255, 87, 34)}, function()
    task.spawn(function()
        if setclipboard then
            setclipboard("https://www.youtube.com/@esohasl")
        end
    end)
end)

-- Section for Important Info
Window:Section("⚠️ Important Information")
Window:Label("Please wait a few minutes before submitting.")
Window:Label("Ensure the image URL is valid before drawing.")
