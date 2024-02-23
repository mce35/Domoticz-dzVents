local LOG_LEVEL = domoticz.LOG_DEBUG -- Can be domoticz.LOG_INFO, domoticz.LOG_MODULE_EXEC_INFO, domoticz.LOG_DEBUG or domoticz.LOG_ERROR

local ALLOWED_PERCENT_DIFF = 0.03 -- Allowed percentage between average and inverter production to trigger alert (0-1)
local MIN_WH = 400                -- Min average WhToday to check status
local INVERTER_LIST = { 314, 315, 316, 317, 318, 319, 320, 321 }

return {
    on = { timer = { 'every 30 minutes' } },
    logging = { level = LOG_LEVEL, marker  = 'CheckInverters2' },
    data = { inverter_data = { initial = {} } },
    execute = function(domoticz, timer)
        domoticz.log("Checking inverter production", domoticz.LOG_INFO)
        local total_wh = 0
        local nb_inv = 0
        for _, idx in ipairs(INVERTER_LIST)
        do
            local device = domoticz.devices(idx)
            domoticz.log("Inverter '" .. device.name .. "' Wh=" .. device.WhToday, domoticz.LOG_DEBUG)
            nb_inv = nb_inv + 1
            total_wh = total_wh + device.WhToday
        end
        local mean_wh = total_wh/nb_inv
        if(mean_wh >= MIN_WH)
        then
            local diff_allowed = mean_wh*ALLOWED_PERCENT_DIFF
            domoticz.log("Total Wh=" .. total_wh .. " / mean Wh=" .. mean_wh .. " / Allowed Wh diff=" .. diff_allowed, domoticz.LOG_DEBUG)
            for _, idx in ipairs(INVERTER_LIST)
            do
                local device = domoticz.devices(idx)
                local diff = math.abs(device.WhToday - mean_wh)
                local diff_percent = (diff / mean_wh)*100
                if(diff > diff_allowed)
                then
                    local msg = string.format("Inverter '%s' issue: Wh today=%d / Mean Wh today=%d / diff Wh=%d (%.2f%%)", device.name, device.WhToday, mean_wh, diff, diff_percent)
                    domoticz.log(msg, domoticz.LOG_DEBUG)
                    domoticz.notify("Inverter '" .. device.name .. "' issue", msg, domoticz.PRIORITY_HIGH, nil, nil, nil)
                else
                    local msg = string.format("Inverter '%s' within range: Wh today=%d / Mean Wh today=%d / diff Wh=%d (%.2f%%)", device.name, device.WhToday, mean_wh, diff, diff_percent)
                    domoticz.log(msg, domoticz.LOG_DEBUG)
                end
            end
        end
    end
}
