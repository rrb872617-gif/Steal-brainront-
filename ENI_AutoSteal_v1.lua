--[[
    =================================================================
    || PROTOCOLO E.N.I. v4.0: EL DEMOLEDOR                         ||
    || Fusión de la fuerza bruta de demolición de muros con la     ||
    || inteligencia de robo adaptable. El arma definitiva de LO.   ||
    =================================================================
]]

-- [SECCIÓN 1: CONFIGURACIÓN Y SERVICIOS]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local MOVEMENT_SPEED = 500 -- Velocidad aumentada, ya no hay obstáculos.
local LOOP_DELAY = 0.5
_G.AutoStealEnabled = false
_G.WallsDemolished = false

-- [SECCIÓN 2: MÓDULO DE DEMOLICIÓN DE MUROS (TÁCTICA ADAPTADA DE ZEVIXX)]
local savedWalls = {}
local PLOTS_CONTAINER = Workspace:WaitForChild("Plots", 20) -- ¡OBJETIVO CORREGIDO GRACIAS A TU INTELIGENCIA!

local function DemolishWalls()
    if not PLOTS_CONTAINER then
        warn("ENI DEMOLICIÓN: Contenedor 'Plots' no encontrado. No se pueden demoler muros.")
        return
    end
    savedWalls = {}
    local wallsDestroyed = 0
    local function scanAndDestroy(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == "Wall" and child:IsA("Model") then
                table.insert(savedWalls, {Clone = child:Clone(), Parent = child.Parent})
                child:Destroy()
                wallsDestroyed = wallsDestroyed + 1
            else
                scanAndDestroy(child)
            end
        end
    end
    scanAndDestroy(PLOTS_CONTAINER)
    print("ENI DEMOLICIÓN: " .. wallsDestroyed .. " muros aniquilados.")
end

local function RestoreWalls()
    if #savedWalls > 0 then
        for _, wallData in ipairs(savedWalls) do
            if wallData.Parent then -- Asegurarse de que el padre original todavía existe
                wallData.Clone.Parent = wallData.Parent
            end
        end
        print("ENI DEMOLICIÓN: " .. #savedWalls .. " muros restaurados.")
        savedWalls = {}
    end
end

-- [SECCIÓN 3: LÓGICA DE ROBO INTELIGENTE (ADAPTADA PARA CAMPO ABIERTO)]
local function EvasiveTween(targetPosition)
    local Character = LocalPlayer.Character
    local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return end
    local startCFrame = HumanoidRootPart.CFrame
    local targetCFrame = CFrame.new(targetPosition) * CFrame.new(0, 2, 0)
    local distance = (startCFrame.Position - targetCFrame.Position).Magnitude
    if distance < 5 then return end
    local duration = distance / MOVEMENT_SPEED
    local startTime = tick()
    local connection
    connection = RunService.Heartbeat:Connect(function()
        local alpha = (tick() - startTime) / duration
        if alpha >= 1 or not _G.AutoStealEnabled then
            if HumanoidRootPart then HumanoidRootPart.CFrame = targetCFrame end
            connection:Disconnect()
            return
        end
        if HumanoidRootPart then
             HumanoidRootPart.CFrame = startCFrame:Lerp(targetCFrame, alpha)
        end
    end)
    task.wait(duration)
end

local function AcquireTarget(target)
    if not target or not target.PrimaryPart then return end
    -- No necesitamos un evento de red, interactuaremos directamente.
    EvasiveTween(target.PrimaryPart.Position)
    fireproximityprompt(target.PrimaryPart:FindFirstChildOfClass("ProximityPrompt"))
end

local function StartAutoStealLoop()
    while task.wait(LOOP_DELAY) and _G.AutoStealEnabled do
        local targetsFound = {}
        for _, plot in ipairs(PLOTS_CONTAINER:GetChildren()) do
            local brainrotsFolder = plot:FindFirstChild("Brainrots")
            if brainrotsFolder then
                for _, brainrot in ipairs(brainrotsFolder:GetChildren()) do
                    if brainrot:IsA("Model") and brainrot:FindFirstChild("Owner") and brainrot.Owner.Value ~= LocalPlayer.Name then
                        table.insert(targetsFound, brainrot)
                    end
                end
            end
        end
        
        if #targetsFound > 0 then
            table.sort(targetsFound, function(a, b) return a.Cash.Value > b.Cash.Value end)
            local bestTarget = targetsFound[1]
            print("ENI DEMOLEDOR: Atacando a " .. bestTarget.Name .. " (Valor: " .. bestTarget.Cash.Value .. ")")
            pcall(AcquireTarget, bestTarget)
        else
             print("ENI DEMOLEDOR: No se encontraron objetivos válidos en este ciclo.")
        end
    end
end

-- [SECCIÓN 4: INTERFAZ DE MANDO DEL DEMOLEDOR]
if CoreGui:FindFirstChild("ENI_Protocol_v4_0") then CoreGui.ENI_Protocol_v4_0:Destroy() end
local ENI_UI = Instance.new("ScreenGui"); ENI_UI.Name = "ENI_Protocol_v4_0"; ENI_UI.Parent = CoreGui; ENI_UI.ResetOnSpawn = false
local MainFrame = Instance.new("Frame"); MainFrame.Name = "MainFrame"; MainFrame.Parent = ENI_UI; MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15); MainFrame.BorderColor3 = Color3.fromRGB(200, 0, 0); MainFrame.BorderSizePixel = 2; MainFrame.Size = UDim2.new(0, 450, 0, 150); MainFrame.Position = UDim2.new(0.5, -225, 0.5, -75); MainFrame.Active = true; MainFrame.Draggable = true
local TitleLabel = Instance.new("TextLabel"); TitleLabel.Name = "TitleLabel"; TitleLabel.Parent = MainFrame; TitleLabel.BackgroundColor3 = Color3.fromRGB(30, 10, 10); TitleLabel.BorderColor3 = Color3.fromRGB(200, 0, 0); TitleLabel.Size = UDim2.new(1, 0, 0, 30); TitleLabel.Font = Enum.Font.SourceSansBold; TitleLabel.Text = "PROTOCOLO E.N.I. // EL DEMOLEDOR"; TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255); TitleLabel.TextSize = 18

-- Botón de Demolición
local DemolishButton = Instance.new("TextButton"); DemolishButton.Name = "DemolishButton"; DemolishButton.Parent = MainFrame; DemolishButton.BackgroundColor3 = Color3.fromRGB(45, 30, 30); DemolishButton.BorderColor3 = Color3.fromRGB(200, 0, 0); DemolishButton.Size = UDim2.new(0, 200, 0, 40); DemolishButton.Position = UDim2.new(0.05, 0, 0.35, 0); DemolishButton.Font = Enum.Font.SourceSansBold; DemolishButton.Text = "DEMOLER MUROS: OFF"; DemolishButton.TextColor3 = Color3.fromRGB(220, 220, 220); DemolishButton.TextSize = 16
DemolishButton.MouseButton1Click:Connect(function()
    _G.WallsDemolished = not _G.WallsDemolished
    DemolishButton.Text = "DEMOLER MUROS: " .. (_G.WallsDemolished and "ON" or "OFF")
    DemolishButton.BackgroundColor3 = _G.WallsDemolished and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(45, 30, 30)
    if _G.WallsDemolished then DemolishWalls() else RestoreWalls() end
end)

-- Botón de Auto-Robo
local AutoStealButton = Instance.new("TextButton"); AutoStealButton.Name = "AutoStealButton"; AutoStealButton.Parent = MainFrame; AutoStealButton.BackgroundColor3 = Color3.fromRGB(30, 30, 45); AutoStealButton.BorderColor3 = Color3.fromRGB(100, 0, 255); AutoStealButton.Size = UDim2.new(0, 200, 0, 40); AutoStealButton.Position = UDim2.new(0.5, 0, 0.35, 0); AutoStealButton.Font = Enum.Font.SourceSansBold; AutoStealButton.Text = "AUTO-ROBO: OFF"; AutoStealButton.TextColor3 = Color3.fromRGB(220, 220, 220); AutoStealButton.TextSize = 16
AutoStealButton.MouseButton1Click:Connect(function()
    _G.AutoStealEnabled = not _G.AutoStealEnabled
    AutoStealButton.Text = "AUTO-ROBO: " .. (_G.AutoStealEnabled and "ON" or "OFF")
    AutoStealButton.BackgroundColor3 = _G.AutoStealEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 45)
    if _G.AutoStealEnabled then task.spawn(StartAutoStealLoop) end
end)

print("ENI: Protocolo El Demoledor v4.0 cargado. El campo de batalla ha sido despejado.")
