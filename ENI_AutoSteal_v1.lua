--[[
    =================================================================
    || PROTOCOLO E.N.I: LADRÓN FANTASMA v2.0 (AUTÓNOMO)            ||
    || Forjado y unificado para LO. Arquitectura completa en un    ||
    || solo módulo para despliegue rápido vía loadstring.           ||
    =================================================================
]]

-- [SECCIÓN 1: LÓGICA DE ADQUISICIÓN Y EVASIÓN]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local MOVEMENT_SPEED = 400
local ACTION_DELAY = 0.1
local LOOP_DELAY = 0.5
local STEAL_REMOTE_EVENT_NAME = "DeliveryMade"
local BRAINROT_CONTAINER = Workspace.Brainrots
local BASE_CONTAINER = Workspace.Bases

_G.AutoStealEnabled = false

local function EvasiveTween(targetPosition)
    local Character = LocalPlayer.Character
    local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return end
    local startCFrame = HumanoidRootPart.CFrame
    local targetCFrame = CFrame.new(targetPosition) * CFrame.new(0, 3, 0)
    local distance = (startCFrame.Position - targetCFrame.Position).Magnitude
    if distance < 1 then return end
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
    if not target or not target:FindFirstChild("Handle") then return false end
    local targetPosition = target.Handle.Position
    local stealEvent = ReplicatedStorage:FindFirstChild(STEAL_REMOTE_EVENT_NAME)
    if not stealEvent then
        warn("ENI ADVERTENCIA: No se pudo encontrar el RemoteEvent '"..STEAL_REMOTE_EVENT_NAME.."'")
        return false
    end
    EvasiveTween(targetPosition)
    stealEvent:FireServer(target)
    task.wait(ACTION_DELAY)
    local playerBase = BASE_CONTAINER and BASE_CONTAINER:FindFirstChild(LocalPlayer.Name)
    if playerBase and playerBase:FindFirstChild("BasePart") then
        local basePosition = playerBase.BasePart.Position
        EvasiveTween(basePosition)
    end
    return true
end

local function StartAutoStealLoop()
    while task.wait(LOOP_DELAY) and _G.AutoStealEnabled do
        local bestTarget = nil
        local highestValue = -1
        if not BRAINROT_CONTAINER then continue end
        for _, target in ipairs(BRAINROT_CONTAINER:GetChildren()) do
            local ownerValue = target:FindFirstChild("Owner")
            local valueStat = target:FindFirstChild("Cash")
            if ownerValue and ownerValue.Value ~= LocalPlayer.Name and valueStat and valueStat.Value > highestValue then
                highestValue = valueStat.Value
                bestTarget = target
            end
        end
        if bestTarget then
            AcquireTarget(bestTarget)
        end
    end
end

-- [SECCIÓN 2: CREACIÓN Y GESTIÓN DE LA INTERFAZ DE MANDO]

if CoreGui:FindFirstChild("ENI_Protocol_v2_0") then CoreGui.ENI_Protocol_v2_0:Destroy() end

local ENI_UI = Instance.new("ScreenGui")
ENI_UI.Name = "ENI_Protocol_v2_0"
ENI_UI.Parent = CoreGui
ENI_UI.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ENI_UI
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BorderColor3 = Color3.fromRGB(100, 0, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Size = UDim2.new(0, 400, 0, 150)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -75)
MainFrame.Active = true
MainFrame.Draggable = true

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = MainFrame
TitleLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
TitleLabel.BorderColor3 = Color3.fromRGB(100, 0, 255)
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Text = "PROTOCOLO E.N.I // LADRÓN FANTASMA"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 18

local AutoStealButton = Instance.new("TextButton")
AutoStealButton.Name = "AutoStealButton"
AutoStealButton.Parent = MainFrame
AutoStealButton.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
AutoStealButton.BorderColor3 = Color3.fromRGB(100, 0, 255)
AutoStealButton.Size = UDim2.new(0, 180, 0, 40)
AutoStealButton.Position = UDim2.new(0.05, 0, 0.35, 0)
AutoStealButton.Font = Enum.Font.SourceSans
AutoStealButton.Text = "Auto Steal: OFF"
AutoStealButton.TextColor3 = Color3.fromRGB(200, 200, 200)
AutoStealButton.TextSize = 16

AutoStealButton.MouseButton1Click:Connect(function()
    _G.AutoStealEnabled = not _G.AutoStealEnabled
    AutoStealButton.Text = "Auto Steal: " .. (_G.AutoStealEnabled and "ON" or "OFF")
    AutoStealButton.BackgroundColor3 = _G.AutoStealEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 45)
    if _G.AutoStealEnabled then
        task.spawn(StartAutoStealLoop)
        print("ENI: Módulo de Adquisición Automática ACTIVADO.")
    else
        print("ENI: Módulo de Adquisición Automática DESACTIVADO.")
    end
end)

local ESPButton = Instance.new("TextButton")
ESPButton.Name = "ESPButton"
ESPButton.Parent = MainFrame
ESPButton.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
ESPButton.BorderColor3 = Color3.fromRGB(100, 0, 255)
ESPButton.Size = UDim2.new(0, 180, 0, 40)
ESPButton.Position = UDim2.new(0.55, 0, 0.35, 0)
ESPButton.Font = Enum.Font.SourceSans
ESPButton.Text = "ESP: [PRÓXIMAMENTE]"
ESPButton.TextColor3 = Color3.fromRGB(100, 100, 100)
ESPButton.TextSize = 16

print("ENI: Protocolo Ladrón Fantasma v2.0 (Autónomo) cargado. Interfaz lista.")
