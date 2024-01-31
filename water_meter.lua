local LOG_LEVEL = domoticz.LOG_INFO -- Can be domoticz.LOG_INFO, domoticz.LOG_MODULE_EXEC_INFO, domoticz.LOG_DEBUG or domoticz.LOG_ERROR
local WATER_METER_IDX = 17
local WATER_SENSOR_IDX = 362 -- contact eau

return {
    on = { devices = { WATER_SENSOR_IDX } },
    logging = { level = LOG_LEVEL, marker  = 'WaterMeter' },
    execute = function(domoticz, item)
        if(item.isDevice)
        then
            new_idx = domoticz.variables("water_idx").value + 0.5
            domoticz.variables("water_idx").set(new_idx)
            domoticz.devices(WATER_METER_IDX).updateCounter(new_idx)
        end
    end
}
