local LOG_LEVEL = domoticz.LOG_DEBUG -- Can be domoticz.LOG_INFO, domoticz.LOG_MODULE_EXEC_INFO, domoticz.LOG_DEBUG or domoticz.LOG_ERROR
-- propagates changes from BTN1 to BTN2 (not the opposite)
local BTN1_IDX = 585
local BTN2_IDX = 963

local function invert(domoticz, item, other_idx)
    if(item.state == "Off")
    then
        domoticz.log("Switch on device " .. other_idx, domoticz.LOG_INFO)
        domoticz.devices(other_idx).switchOn().silent()
    else
        domoticz.log("Switch off device " .. other_idx, domoticz.LOG_INFO)
        domoticz.devices(other_idx).switchOff().silent()
    end
end

return {
    on = { devices = { BTN1_IDX } },
    logging = { level = LOG_LEVEL, marker  = "button_inverter" },
    execute = function(domoticz, item)
        if(item.id == BTN1_IDX)
        then
            invert(domoticz, item, BTN2_IDX)
        end
    end
}
