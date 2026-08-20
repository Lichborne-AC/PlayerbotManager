local addonName, PBM = ...

-- Taula global de localització per a l'addon
PBM.L = PBM.L or {}
local L = PBM.L

-- Metataula per retornar la clau original si no hi ha traducció
setmetatable(L, {
    __index = function(t, key)
        return key
    end
})

-- Alias global per accedir-hi fàcilment des de qualsevol fitxer
PBM_L = L