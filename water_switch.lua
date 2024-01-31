local LOG_LEVEL = domoticz.LOG_DEBUG -- Can be domoticz.LOG_INFO, domoticz.LOG_MODULE_EXEC_INFO, domoticz.LOG_DEBUG or domoticz.LOG_ERROR
local SENSOR_CLOSE_IDX = 359         -- Closed: Water closed
local SENSOR_OPEN_IDX = 358          -- Closed: Water opened
local WATER_DIR_SWITCH_IDX = 355     -- Switch off to close water / Switch on to open water
local WATER_ON_OFF_SWITCH_IDX = 354  -- Switch on to open/close water depending on WATER_DIR_SWITCH_IDX state
local WATER_SWITCH_IDX = 236         -- Switch to open/close water (selector switch: 0 -> close / 10 -> middle / 20 -> open )

local listen_devices = {
    SENSOR_CLOSE_IDX,
    SENSOR_OPEN_IDX,
    WATER_DIR_SWITCH_IDX,
    WATER_ON_OFF_SWITCH_IDX,
    WATER_SWITCH_IDX
}

local function resetSwitchState(domoticz)
    if(domoticz.devices(SENSOR_CLOSE_IDX).active == false)
    then
        domoticz.log("Water switch: Closed", domoticz.LOG_DEBUG)
        domoticz.devices(WATER_SWITCH_IDX).switchSelector(0).silent()
        domoticz.devices(WATER_ON_OFF_SWITCH_IDX).switchOff().silent()
        domoticz.devices(WATER_DIR_SWITCH_IDX).switchOff().silent()
    end
    if(domoticz.devices(SENSOR_CLOSE_IDX).active == true and domoticz.devices(SENSOR_OPEN_IDX).active == true)
    then
        domoticz.log("Water switch: Middle", domoticz.LOG_DEBUG)
        domoticz.devices(WATER_SWITCH_IDX).switchSelector(10).silent()
    end
    if(domoticz.devices(SENSOR_OPEN_IDX).active == false)
    then
        domoticz.log("Water switch: Opened", domoticz.LOG_DEBUG)
        domoticz.devices(WATER_SWITCH_IDX).switchSelector(20).silent()
        domoticz.devices(WATER_ON_OFF_SWITCH_IDX).switchOff().silent()
        domoticz.devices(WATER_DIR_SWITCH_IDX).switchOff().silent()
    end
end

return {
    on = { devices = listen_devices },
    logging = { level = LOG_LEVEL, marker  = "Water" },
    execute = function(domoticz, item)
        if(item.isDevice)
        then
            if(item.id == WATER_SWITCH_IDX)
            then
                domoticz.log("Water switch changed state " .. item.state, domoticz.LOG_INFO)
                if(item.level == 0)
                then
                    domoticz.devices(WATER_SWITCH_IDX).switchSelector(10).silent()
                    domoticz.devices(WATER_DIR_SWITCH_IDX).switchOff()
                    domoticz.devices(WATER_ON_OFF_SWITCH_IDX).switchOn()
                elseif(item.level == 20)
                then
                    domoticz.devices(WATER_SWITCH_IDX).switchSelector(10).silent()
                    domoticz.devices(WATER_DIR_SWITCH_IDX).switchOn()
                    domoticz.devices(WATER_ON_OFF_SWITCH_IDX).switchOn()
                else
                    resetSwitchState(domoticz)
                end
            elseif(item.id == SENSOR_CLOSE_IDX)
            then
                resetSwitchState(domoticz)
            elseif(item.id == SENSOR_OPEN_IDX)
            then
                resetSwitchState(domoticz)
            end
        end
    end
}
