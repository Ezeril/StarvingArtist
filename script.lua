-- Settings
local Settings = {
    Image = "",
    Mode = "Randomize",
    IsDrawing = false,
    Size = 1,
    Brush = "Stripes"
}

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Varriables
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

Window:Section("Lunamoon")

Window:Button("Draw", function()
    task.spawn(function()
        Import(Settings.Image)
    end)
end)

Window:Box("Image URL", {}, function(value) 
    task.spawn(function()
        Settings.Image = value
    end)
end) 

Window:Dropdown("Draw Mode", {list = { "Randomize", "By Step" } }, function(var) 
    task.spawn(function()
        Settings.Mode = var
    end)
end)

Window:Dropdown("Brushes", {list = Brushes }, function(var) 
    task.spawn(function()
        Settings.Brush = var
    end)
end)

Window:Slider("Brush Size", {min = 1, max = 5}, function(value)
    task.spawn(function()
        Settings.Size = value
    end)
  end)

Window:Section("Wait few min before submit")

Window:Button("YouTube: Lunamoon", function()
    task.spawn(function()
        if setclipboard then
            setclipboard("https://www.youtube.com")
        end
    end)
end)
