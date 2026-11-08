-- ZEEKK PRO MAX | Roblox Studio Loader
-- Bunu StarterPlayer > StarterPlayerScripts altina LocalScript olarak ekle.
-- ReplicatedStorage icindeki ModuleScript'in adi ZeekkProMax olmalidir.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local moduleScript = ReplicatedStorage:WaitForChild("ZeekkProMax", 15)

if not moduleScript or not moduleScript:IsA("ModuleScript") then
    warn("[ZEEKK PRO MAX] ReplicatedStorage icinde ZeekkProMax ModuleScript bulunamadi.")
    return
end

local success, startPanel = pcall(require, moduleScript)
if not success then
    warn("[ZEEKK PRO MAX] Modul yuklenemedi: " .. tostring(startPanel))
    return
end

if type(startPanel) ~= "function" then
    warn("[ZEEKK PRO MAX] Modul beklenen baslatma fonksiyonunu dondurmedi.")
    return
end

local started, err = pcall(startPanel)
if not started then
    warn("[ZEEKK PRO MAX] Panel baslatilamadi: " .. tostring(err))
end
