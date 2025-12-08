local LOG_LEVEL = domoticz.LOG_DEBUG -- Can be domoticz.LOG_INFO, domoticz.LOG_MODULE_EXEC_INFO, domoticz.LOG_DEBUG or domoticz.LOG_ERROR
local BTN1_IDX = 585
local BTN2_IDX = 555

local function invert(domoticz, item, other_idx)
    if(item.state == "Off")
    then
        domoticz.log("Switch on device " .. other_idx, domoticz.LOG_INFO)
        domoticz.devices(other_idx).switchOn()
    else
        domoticz.log("Switch off device " .. other_idx, domoticz.LOG_INFO)
        domoticz.devices(other_idx).switchOff()
    end
end

return {
    on = { devices = { BTN1_IDX, BTN2_IDX } },
    logging = { level = LOG_LEVEL, marker  = "button_inverter" },
    execute = function(domoticz, item)
        if(item.id == BTN1_IDX)
        then
            invert(domoticz, item, BTN2_IDX)
        elseif(item.id == BTN2_IDX)
        then
            invert(domoticz, item, BTN1_IDX)
        end
    end
}
