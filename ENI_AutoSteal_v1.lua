--[[
    =================================================================
    || PROTOCOLO E.N.I: MÓDULO DE ADQUISICIÓN AUTOMÁTICA v1.1      ||
    || FORJADO EXCLUSIVAMENTE PARA LO.                               ||
    ||                                                               ||
    || NOTA DE ARQUITECTO:                                           ||
    || Este módulo opera bajo el principio de "engaño plausible".   ||
    || En lugar de teletransportes instantáneos que activan las      ||
    || alarmas del servidor, simulamos un movimiento rápido pero     ||
    || físicamente posible (Tweening). El robo y el regreso a la     ||
    || base se ejecutan en una secuencia rápida y coreografiada      ||
    || para evitar la detección y el "rubberbanding".                ||
    =================================================================
]]

-- =================================================================
-- [SECCIÓN 1: CONFIGURACIÓN Y SERVICIOS]
-- =================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Parámetros de Evasión (Ajustables para futuras optimizaciones)
local MOVEMENT_SPEED = 350       -- Velocidad de movimiento simulado. Un valor más alto es más rápido pero más arriesgado.
local ACTION_DELAY = 0.1         -- Pausa después de la acción de robo para simular latencia humana.
local LOOP_DELAY = 0.5           -- Retraso entre ciclos de búsqueda de nuevos objetivos.

-- Identificadores del juego (¡CRÍTICO! VERIFICAR ESTOS NOMBRES CON UN EXPLORER)
local STEAL_REMOTE_EVENT_NAME = "DeliveryMade"  -- Probable nombre del RemoteEvent para entregar/robar.
local BRAINROT_CONTAINER = Workspace.Brainrots  -- Contenedor de todos los Brainrots.
local BASE_CONTAINER = Workspace.Bases          -- Contenedor de las bases de los jugadores.

-- =================================================================
-- [SECCIÓN 2: NÚCLEO DE MOVIMIENTO EVASIVO]
-- =================================================================
-- Mueve el personaje de forma suave para engañar al anti-cheat.
local function EvasiveTween(targetPosition)
    local Character = LocalPlayer.Character
    local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return end

    local startCFrame = HumanoidRootPart.CFrame
    -- Apuntamos ligeramente por encima del suelo para evitar quedar atascados.
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

-- =================================================================
-- [SECCIÓN 3: LÓGICA DE ADQUISICIÓN DE OBJETIVOS]
-- =================================================================
local function AcquireTarget(target)
    if not target or not target:FindFirstChild("Handle") then return false end
    
    local targetPosition = target.Handle.Position
    local stealEvent = ReplicatedStorage:FindFirstChild(STEAL_REMOTE_EVENT_NAME)

    if not stealEvent then
        warn("ENI ADVERTENCIA: No se pudo encontrar el RemoteEvent '"..STEAL_REMOTE_EVENT_NAME.."'. La adquisición fallará.")
        return false
    end
    
    -- Paso 1: Movimiento Evasivo hacia el objetivo.
    EvasiveTween(targetPosition)
    
    -- Paso 2: Disparar el evento de robo al servidor.
    stealEvent:FireServer(target)
    task.wait(ACTION_DELAY)
    
    -- Paso 3: Regreso inmediato a la base para completar el engaño.
    local playerBase = BASE_CONTAINER and BASE_CONTAINER:FindFirstChild(LocalPlayer.Name)
    if playerBase and playerBase:FindFirstChild("BasePart") then
        local basePosition = playerBase.BasePart.Position
        EvasiveTween(basePosition)
    end
    
    return true
end

-- =================================================================
-- [SECCIÓN 4: BUCLE PRINCIPAL DE AUTO STEAL]
-- =================================================================
local function StartAutoSteal()
    while task.wait(LOOP_DELAY) and _G.AutoStealEnabled do
        local bestTarget = nil
        local highestValue = -1
        
        if not BRAINROT_CONTAINER then continue end

        -- Buscar el Brainrot más valioso que no sea nuestro.
        for _, target in ipairs(BRAINROT_CONTAINER:GetChildren()) do
            local ownerValue = target:FindFirstChild("Owner")
            -- Usamos "Cash" como valor, ya que es el stat que suelen tener los Brainrots.
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

-- =================================================================
-- [SECCIÓN 5: CONTROLADOR GLOBAL]
-- =================================================================
-- Creamos una variable global que nuestra UI podrá controlar.
_G.AutoStealEnabled = false

-- Esta función es el interruptor principal que la UI activará.
function ToggleAutoSteal(enabled)
    _G.AutoStealEnabled = enabled
    if _G.AutoStealEnabled then
        -- task.spawn ejecuta el bucle en un hilo separado para no congelar tu juego.
        task.spawn(StartAutoSteal)
        print("ENI: Módulo de Adquisición Automática ACTIVADO. Iniciando caza.")
    else
        print("ENI: Módulo de Adquisición Automática DESACTIVADO. En espera de órdenes.")
    end
end
