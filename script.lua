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

-- Variables
local LocalPlayer = Players.LocalPlayer
local MainGui = LocalPlayer.PlayerGui:WaitForChild("MainGui", 10) -- Ajout d'un wait pour la sécurité
local identified = identifyexecutor and identifyexecutor() or "Unknown"

local Brushes = {"Normal", "Star", "Circle", "Diamond", "Moon", "Asterisk", "Stripes", "Plus", "Triangle", "Water", "Chain", "Heart", "Checkerboard", "Hexagon", "Spray Paint", "Sticker", "Random"}

-- --- FONCTIONS LOGIQUES (Inchangées) ---
function GetGrid()
    if not MainGui then return nil end
    local Grid = MainGui:FindFirstChild("PaintFrame"):FindFirstChild("Grid")

    if not Grid then
        Grid = MainGui:FindFirstChild("PaintFrame"):FindFirstChild("GridHolder"):FindFirstChild("Grid")
    end

    return Grid
end

function SendNotify(title, text)
    -- Utilisation du système de notif d'Orion si possible, sinon Roblox
    game.StarterGui:SetCore("SendNotification", {
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
        SendNotify("Erreur API", "Impossible de contacter ton serveur Vercel ou URL invalide.")
        return {}
    end

    return HttpService:JSONDecode(Response)
end

function Import(url)
    if Settings.IsDrawing then return end
    if url == "" then SendNotify("Erreur", "Mets une URL d'abord !") return end

    local pixels = GetJson(url)
    if #pixels == 0 then return end
    
    local usedIndices = {}

    -- Rafraichir la grid si elle a changé
    Grid = GetGrid()
    if not Grid then SendNotify("Erreur", "Grid introuvable. Ouvre le tableau !") return end

    Settings.IsDrawing = true

    for i = 1, #pixels do
        -- Check si le joueur a arrêté le script ou fermé l'ui (optionnel)
        if not Settings.IsDrawing then break end

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
        
        -- Protection contre les erreurs d'index
        local pixelPart = Grid:FindFirstChild(tostring(pixelIndex))

        if pixelPart then
            if Settings.Brush == "Normal" then
                pixelPart.BackgroundColor3 = Color3.fromRGB(r, g, b)
            else
                local Brush
                if Settings.Brush == "Random" then
                    Brush = ReplicatedStorage.Brushes[Brushes[math.random(2, 16)]]:Clone()
                elseif ReplicatedStorage.Brushes:FindFirstChild(Settings.Brush) then
                    Brush = ReplicatedStorage.Brushes[Settings.Brush]:Clone()
                end

                if Brush then
                    Brush.ImageColor3 = Color3.fromRGB(r, g, b)
                    Brush.Size = UDim2.new(Settings.Size, 0, Settings.Size, 0)
                    Brush.Parent = pixelPart
                end
            end
        end

        task.wait(0.375) -- Vitesse de dessin
    end

    Settings.IsDrawing = false
    SendNotify("Terminé", "Dessin fini !")
end

-- --- NOUVELLE INTERFACE (Orion Library) ---

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

local Window = OrionLib:MakeWindow({
    Name = "Starving Arts | Lunamoon", 
    HidePremium = false, 
    SaveConfig = false, 
    Config = {
        Watermark = false -- C'est ici qu'on retire le watermark !
    },
    IntroEnabled = true,
    IntroText = "Lunamoon Script"
})

-- Onglet Principal
local MainTab = Window:MakeTab({
    Name = "Dessin",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

MainTab:AddSection({
    Name = "Configuration de l'image"
})

MainTab:AddTextbox({
    Name = "Image URL",
    Default = "",
    TextDisappear = false,
    Callback = function(Value)
        Settings.Image = Value
    end
})

MainTab:AddButton({
    Name = "Lancer le Dessin",
    Callback = function()
        task.spawn(function()
            Import(Settings.Image)
        end)
    end
})

MainTab:AddToggle({
    Name = "Arrêt d'urgence",
    Default = false,
    Callback = function(Value)
        if Value then
            Settings.IsDrawing = false
        end
    end
})

MainTab:AddSection({
    Name = "Paramètres du Pinceau"
})

MainTab:AddDropdown({
    Name = "Mode de dessin",
    Default = "Randomize",
    Options = {"Randomize", "By Step"},
    Callback = function(Value)
        Settings.Mode = Value
    end
})

MainTab:AddDropdown({
    Name = "Style de Pinceau (Brush)",
    Default = "Stripes",
    Options = Brushes,
    Callback = function(Value)
        Settings.Brush = Value
    end
})

MainTab:AddSlider({
    Name = "Taille du Pinceau",
    Min = 1,
    Max = 5,
    Default = 1,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "scale",
    Callback = function(Value)
        Settings.Size = Value
    end
})

-- Onglet Crédits / Extra
local ExtraTab = Window:MakeTab({
    Name = "Extras",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

ExtraTab:AddButton({
    Name = "Copier Lien YouTube",
    Callback = function()
        if setclipboard then
            setclipboard("https://www.youtube.com")
            OrionLib:MakeNotification({
                Name = "Succès",
                Content = "Lien copié dans le presse-papier !",
                Image = "rbxassetid://4483345998",
                Time = 5
            })
        end
    end
})

ExtraTab:AddLabel("Wait few min before submit")

-- Initialisation
OrionLib:Init()
