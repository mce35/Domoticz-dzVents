--[[
Script that mesure rain
]]--

local RAIN_SENSOR_IDX = 244          -- index of the rain sensor
local RAIN_METER_IDX = 214           -- index of the rain meter
local RAIN_TICK_CAPACITY = 0.5       -- number of mm for each rain sensor change
local LOG_LEVEL = domoticz.LOG_DEBUG -- Can be domoticz.LOG_INFO, domoticz.LOG_MODULE_EXEC_INFO, domoticz.LOG_DEBUG or domoticz.LOG_ERROR

return {
    on = { devices = { RAIN_SENSOR_IDX --[[ Pluviomètre ]] },
        timer = { "at 00:01" } },
    logging = { level = LOG_LEVEL, marker  = "RainMeter" },
    execute = function(domoticz, item)
        if(item.isDevice)
        then
            local last_rain_total  = domoticz.devices(RAIN_METER_IDX).rain
            local new_rain_total   = RAIN_TICK_CAPACITY + last_rain_total
            local last_update      = math.max(domoticz.devices(RAIN_METER_IDX).lastUpdate.secondsAgo, 1)
            local rain_amount_hour = domoticz.utils.round(RAIN_TICK_CAPACITY * 3600 * 100 / last_update, 0)

            domoticz.log("Last/New rain index: " .. last_rain_total .. "/" .. new_rain_total .. " / " .. (rain_amount_hour / 100) .. "mm/h / last update: " .. last_update .. "s ago", domoticz.LOG_DEBUG)
            domoticz.devices(RAIN_METER_IDX).updateRain(domoticz.utils.round(rain_amount_hour, 1), domoticz.utils.round(new_rain_total, 1))
        elseif(item.isTimer)
        then
            domoticz.log("Reset rain meter", domoticz.LOG_DEBUG)
            domoticz.devices(RAIN_METER_IDX).updateRain(domoticz.utils.round(domoticz.devices(RAIN_METER_IDX).rainRate, 0), 0) -- reset rainTotal
        end
    end
}
