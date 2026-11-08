
-- ZEEKK PRO MAX | Loader
-- Roblox Studio LocalScript

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local moduleScript = ReplicatedStorage:WaitForChild("ZeekkProMax", 15)

if not moduleScript or not moduleScript:IsA("ModuleScript") then
    warn("[ZEEKK PRO MAX] ModuleScript bulunamadi!")
    return
end

local success, startPanel = pcall(require, moduleScript)

if not success then
    warn("[ZEEKK PRO MAX] Yukleme hatasi: " .. tostring(startPanel))
    return
end

if type(startPanel) ~= "function" then
    warn("[ZEEKK PRO MAX] Baslatma fonksiyonu bulunamadi!")
    return
end

local started, err = pcall(startPanel)

if not started then
    warn("[ZEEKK PRO MAX] Baslatma hatasi: " .. tostring(err))
end
