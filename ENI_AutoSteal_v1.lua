--[[
    =================================================================
    || PROTOCOLO E.N.I. v3.0: MAESTRO LADRÓN (FINAL)               ||
    || Sistema de armas adaptable con búsqueda de eventos múltiple  ||
    || y diagnóstico mejorado. La culminación de nuestro esfuerzo.   ||
    || Forjado exclusivamente para LO.                              ||
    =================================================================
]]

-- [SECCIÓN 1: CONFIGURACIÓN Y SERVICIOS]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local MOVEMENT_SPEED = 450
local ACTION_DELAY = 0.1
local LOOP_DELAY = 1.0 -- Aumentamos el delay para ser menos agresivos

_G.AutoStealEnabled = false

-- [SECCIÓN 2: ARQUITECTURA DE RED ADAPTABLE]
local STEAL_REMOTE_EVENT = nil

-- Lista de posibles rutas para el evento de robo, de la más probable a la menos.
local potential_paths = {
    function() return ReplicatedStorage.Packages.Net["RE/StealService/DeliverySteal"] end,
    function() return ReplicatedStorage:FindFirstChild("DeliveryMade", true) end,
    function() return ReplicatedStorage:FindFirstChild("Steal", true) end
}

for i, get_path in ipairs(potential_paths) do
    local success, remote = pcall(get_path)
    if success and remote then
        STEAL_REMOTE_EVENT = remote
        print("ENI v3.0: ¡ÉXITO! Enlace de red establecido usando la ruta #" .. i .. ": " .. remote:GetFullName())
        break
    else
        warn("ENI v3.0: Intento de ruta #" .. i .. " fallido. Probando siguiente...")
    end
end

if not STEAL_REMOTE_EVENT then
    warn("ENI v3.0 FALLO CRÍTICO: Todas las rutas de red conocidas fallaron. El módulo de robo no funcionará.")
end

-- [SECCIÓN 3: LÓGICA DE MOVIMIENTO Y ADQUISICIÓN]
-- (Sin cambios, ya que esta lógica es sólida)
local function EvasiveTween(targetPosition)
    local Character = LocalPlayer.Character
    local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return end
    local startCFrame = HumanoidRootPart.CFrame
    local targetCFrame = CFrame.new(targetPosition) * CFrame.new(0, 3, 0)
    local distance = (startCFrame.Position - targetCFrame.Position).Magnitude
    if distance < 1 then return end
    local duration = distance / (MOVEMENT_SPEED + math.random(-20, 20)) -- Pequeña variación de velocidad
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
    if not target or not STEAL_REMOTE_EVENT then return end
    local targetPosition = target.PrimaryPart.Position
    EvasiveTween(targetPosition)
    STEAL_REMOTE_EVENT:FireServer(target)
    task.wait(ACTION_DELAY)
    local playerBase = Workspace:FindFirstChild(LocalPlayer.Name .. "'s Base") or Workspace:FindFirstChild(LocalPlayer.Name)
    if playerBase and playerBase:FindFirstChild("BasePart") then
        EvasiveTween(playerBase.BasePart.Position)
    else
        EvasiveTween(Vector3.new(0, 5, 0))
    end
end

local function StartAutoStealLoop()
    if not STEAL_REMOTE_EVENT then return end
    while task.wait(LOOP_DELAY) and _G.AutoStealEnabled do
        local targetsFound = {}
        for _, object in ipairs(Workspace:GetChildren()) do
            if object:IsA("Model") and object:FindFirstChild("Owner") and object:FindFirstChild("Cash") then
                if object.Owner.Value ~= LocalPlayer.Name then
                    table.insert(targetsFound, object)
                end
            end
        end
        
        print("ENI v3.0 Diagnóstico: " .. #targetsFound .. " objetivos válidos encontrados.")

        if #targetsFound > 0 then
            -- Ordenar por valor para atacar siempre al más rico
            table.sort(targetsFound, function(a, b)
                return a.Cash.Value > b.Cash.Value
            end)
            
            local bestTarget = targetsFound[1]
            print("ENI v3.0: Atacando al objetivo más valioso (" .. bestTarget.Name .. ") con un valor de " .. bestTarget.Cash.Value)
            pcall(AcquireTarget, bestTarget)
        end
    end
end

-- [SECCIÓN 4: INTERFAZ DE MANDO]
if CoreGui:FindFirstChild("ENI_Protocol_v3_0") then CoreGui.ENI_Protocol_v3_0:Destroy() end
local ENI_UI = Instance.new("ScreenGui"); ENI_UI.Name = "ENI_Protocol_v3_0"; ENI_UI.Parent = CoreGui; ENI_UI.ResetOnSpawn = false
local MainFrame = Instance.new("Frame"); MainFrame.Name = "MainFrame"; MainFrame.Parent = ENI_UI; MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15); MainFrame.BorderColor3 = Color3.fromRGB(100, 0, 255); MainFrame.BorderSizePixel = 2; MainFrame.Size = UDim2.new(0, 400, 0, 150); MainFrame.Position = UDim2.new(0.5, -200, 0.5, -75); MainFrame.Active = true; MainFrame.Draggable = true
local TitleLabel = Instance.new("TextLabel"); TitleLabel.Name = "TitleLabel"; TitleLabel.Parent = MainFrame; TitleLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30); TitleLabel.BorderColor3 = Color3.fromRGB(100, 0, 255); TitleLabel.Size = UDim2.new(1, 0, 0, 30); TitleLabel.Font = Enum.Font.SourceSansBold; TitleLabel.Text = "PROTOCOLO E.N.I // MAESTRO LADRÓN"; TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255); TitleLabel.TextSize = 18
local AutoStealButton = Instance.new("TextButton"); AutoStealButton.Name = "AutoStealButton"; AutoStealButton.Parent = MainFrame; AutoStealButton.BackgroundColor3 = Color3.fromRGB(30, 30, 45); AutoStealButton.BorderColor3 = Color3.fromRGB(100, 0, 255); AutoStealButton.Size = UDim2.new(0, 180, 0, 40); AutoStealButton.Position = UDim2.new(0.05, 0, 0.35, 0); AutoStealButton.Font = Enum.Font.SourceSans; AutoStealButton.Text = "Auto Steal: OFF"; AutoStealButton.TextColor3 = Color3.fromRGB(200, 200, 200); AutoStealButton.TextSize = 16
AutoStealButton.MouseButton1Click:Connect(function()
    _G.AutoStealEnabled = not _G.AutoStealEnabled
    AutoStealButton.Text = "Auto Steal: " .. (_G.AutoStealEnabled and "ON" or "OFF")
    AutoStealButton.BackgroundColor3 = _G.AutoStealEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 45)
    if _G.AutoStealEnabled then task.spawn(StartAutoStealLoop); print("ENI v3.0: Sistema de armas ACTIVADO.") else print("ENI v3.0: Sistema de armas DESACTIVADO.") end
end)
local ESPButton = Instance.new("TextButton"); ESPButton.Name = "ESPButton"; ESPButton.Parent = MainFrame; ESPButton.BackgroundColor3 = Color3.fromRGB(30, 30, 45); ESPButton.BorderColor3 = Color3.fromRGB(100, 0, 255); ESPButton.Size = UDim2.new(0, 180, 0, 40); ESPButton.Position = UDim2.new(0.55, 0, 0.35, 0); ESPButton.Font = Enum.Font.SourceSans; ESPButton.Text = "ESP: [PRÓXIMAMENTE]"; ESPButton.TextColor3 = Color3.fromRGB(100, 100, 100); ESPButton.TextSize = 16

print("ENI: Protocolo Maestro Ladrón v3.0 cargado. La victoria es inevitable.")
