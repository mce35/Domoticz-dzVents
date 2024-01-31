local LOG_LEVEL = domoticz.LOG_INFO -- Can be domoticz.LOG_INFO, domoticz.LOG_MODULE_EXEC_INFO, domoticz.LOG_DEBUG or domoticz.LOG_ERROR

local devices_rdc = {
    171,    -- ZG - °/% Bureau
    168,    -- ZG - °/% Salon
    163,    -- ZG - °/%/B Cuisine
    333     -- ZG - °/% Sonoff Frigo
}

local devices_sous_sol = {
    153,    -- ZG - °/% buanderie
    179,    -- ZG - °/% Cave
    148     -- ZG - °/%/B sous-sol
}
local devices_up = {
    198,    -- ZG - °/% Chambre Tim
    195,    -- ZG - °/% Salle de jeu
    176,    -- ZG - °/% Ch Noam/Mahé
    339     -- ZG - °/%/B Chambre parents
}
local devices_ext = {
    192,    -- ZG - ZG - °/% Extérieur
    345     -- ZG - °/% Extérieur arrière
}
local devices_all = {
    171,    -- ZG - °/% Bureau
    168,    -- ZG - °/% Salon
    163,    -- ZG - °/%/B Cuisine
    333,    -- ZG - °/% Sonoff Frigo
    153,    -- ZG - °/% buanderie
    179,    -- ZG - °/% Cave
    148,    -- ZG - °/%/B sous-sol
    198,    -- ZG - °/% Chambre Tim
    195,    -- ZG - °/% Salle de jeu
    176,    -- ZG - °/% Ch Noam/Mahé
    339,    -- ZG - °/%/B Chambre parents
    192,    -- ZG - ZG - °/% Extérieur
    345     -- ZG - °/% Extérieur arrière
}

function update_avg(domoticz, avg_dev_idx, devices)
    local avg_temp = 0
    local avg_hum = 0
    local nb_devices = 0
    for idx, device in ipairs(devices)
    do
        local temp = domoticz.devices(device).temperature
        local humidity = domoticz.devices(device).humidity
        local last_seen = domoticz.devices(device).lastUpdate.secondsAgo
        domoticz.log("update dev " .. device, domoticz.LOG_DEBUG)
        domoticz.log("update dev temp " .. device .. " " .. temp, domoticz.LOG_DEBUG)
        domoticz.log("update dev humidity " .. device .. " " .. humidity, domoticz.LOG_DEBUG)
        domoticz.log("update dev last_seen " .. device .. " " .. last_seen, domoticz.LOG_DEBUG)
        if(last_seen ~= nil and last_seen < 7200)
        then
            if(temp ~= nil and humidity ~= nil)
            then
                avg_temp = avg_temp + temp
                avg_hum = avg_hum + humidity
                nb_devices = nb_devices + 1
            end
        end
    end
    domoticz.log("found " .. nb_devices .. " devices", domoticz.LOG_DEBUG)
    if(nb_devices > 0)
    then
        avg_temp = avg_temp / nb_devices
        avg_hum = avg_hum / nb_devices
        domoticz.log("Update device " .. avg_dev_idx .. " with temp " .. avg_temp .. "°C / " .. avg_hum .. "%", domoticz.LOG_INFO)
        domoticz.devices(avg_dev_idx).updateTempHum(avg_temp, avg_hum)
    end
end

return {
    on = { devices =  devices_all },
    logging = { level = LOG_LEVEL, marker  = 'avg_temp' },

    execute = function(domoticz, item)
        domoticz.log("Update average temperatures", domoticz.LOG_DEBUG)
        if(item.isDevice)
        then
            update_avg(domoticz, 268, devices_rdc)
            update_avg(domoticz, 269, devices_sous_sol)
            update_avg(domoticz, 270, devices_up)
            update_avg(domoticz, 349, devices_ext)
        end
    end
}
