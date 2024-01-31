local LOG_LEVEL = domoticz.LOG_INFO -- Can be domoticz.LOG_INFO, domoticz.LOG_MODULE_EXEC_INFO, domoticz.LOG_DEBUG or domoticz.LOG_ERROR
local WATER_FLOW_IDX = 18

return {
    on = { timer = { 'every minute' } },
    logging = { level = LOG_LEVEL, marker  = 'WaterFlow' },
    execute = function(domoticz, timer)
        local current_idx = domoticz.variables("water_idx").value
        local last_idx = domoticz.variables("last_water_idx").value
        local difference = domoticz.time.compare(domoticz.variables("last_water_idx").lastUpdate).secs
        local waterflow = (current_idx - last_idx) * 60 / difference
        domoticz.devices(WATER_FLOW_IDX).updateWaterflow(waterflow)
        domoticz.variables("last_water_idx").set(current_idx)
    end
}
