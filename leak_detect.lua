--[[
Script that detects water leaks
]]--

local INTERVAL_CHECK = 60           -- delay between leak checks in minutes
local NB_INTERVALS_NOTIF = 20       -- number of consecutive intervals with consumption to trigger the notification
local WATER_CONTACT_IDX = 8         -- index of the device for the water sensor
local WATER_TICK_CAPACITY = 0.5     -- number of water liters for each water sensor tick
local LEAKY_BUCKET_MAX_VALUE = 200  -- leaky bucket burst count allowed (number of liters allowed at once)
local LEAKY_BUCKET_AVG_LEAK = 0.5   -- leaky bucket average rate allowed (number of liters average allowed per minute)
local LEAKY_BUCKET_DEVICE_IDX = 211 -- widget index to log bucket counter
local LOG_LEVEL = domoticz.LOG_INFO -- Can be domoticz.LOG_INFO, domoticz.LOG_MODULE_EXEC_INFO, domoticz.LOG_DEBUG or domoticz.LOG_ERROR
local WATER_SWITCH_IDX = 236        -- Switch to close water (selector switch -> switchSelector(0) to close)

return {
    on = { devices = { WATER_CONTACT_IDX --[[ Contact eau ]],
                       157 --[[ Leak chauffe-eau ]],
                       230 --[[ Leak buanderie ]],
                       231 --[[ Leak cuisine ]] ,
                       253 --[[ Leak chaudière ]] ,
                       254 --[[ Leak atelier ]] },
        timer = { 'every minute' } },
    logging = { level = LOG_LEVEL, marker  = 'LeakDetect' },
    data = { consecutive_changes = { initial = 0 },
        has_changed = { initial = false},
        interval_check_count = { initial = 0 } },
    execute = function(domoticz, item)
        if(item.isDevice)
        then
            if(item.id == WATER_CONTACT_IDX)
            then
                local new_value = domoticz.variables("water_leak_counter").value - WATER_TICK_CAPACITY
                if(new_value >= 0)
                then
                    domoticz.variables("water_leak_counter").set(new_value)
                    domoticz.devices(LEAKY_BUCKET_DEVICE_IDX).updateCustomSensor(new_value)
                else
                    domoticz.log("Water leak detected!", domoticz.LOG_INFO)
                    domoticz.notify("Water leak detected!", "Water leak detected!", domoticz.PRIORITY_HIGH, nil, nil, nil)
                    domoticz.variables("water_leak_counter").set(LEAKY_BUCKET_MAX_VALUE) -- reset to max value to avoid a storm of notifications
                    domoticz.devices(LEAKY_BUCKET_DEVICE_IDX).updateCustomSensor(LEAKY_BUCKET_MAX_VALUE)
                    domoticz.devices(WATER_SWITCH_IDX).switchSelector(0)
                end
                domoticz.data.has_changed = true
            else
                if(item.active == true)
                then
                    domoticz.log("Water leak detected! (sensor " .. item.name .. ")", domoticz.LOG_INFO)
                    domoticz.notify("Water leak detected! (sensor " .. item.name .. ")", "Water leak detected! (sensor " .. item.name .. ")", domoticz.PRIORITY_HIGH, nil, nil, nil)
                    domoticz.devices(WATER_SWITCH_IDX).switchSelector(0)
                end
            end
        elseif(item.isTimer)
        then
            -- small leak check (to detect small continuous consumption)
            -- check that in each time interval of INTERVAL_CHECK minutes
            -- consumption was detected for NB_INTERVALS_NOTIF consecutive intervals and trigger a notification 
            domoticz.data.interval_check_count = domoticz.data.interval_check_count + 1
            domoticz.log("timer interval count " .. domoticz.data.interval_check_count, domoticz.LOG_DEBUG)
            if(domoticz.data.interval_check_count >= INTERVAL_CHECK)
            then
                if(domoticz.data.has_changed == true)
                then
                    domoticz.data.has_changed = false
                    domoticz.data.consecutive_changes = domoticz.data.consecutive_changes + 1
                    domoticz.log("change detected (nb_consecutive_changes=" .. domoticz.data.consecutive_changes .. ")", domoticz.LOG_DEBUG)
                    if(domoticz.data.consecutive_changes > NB_INTERVALS_NOTIF)
                    then
                        domoticz.notify("Small water leak detected!", "Small water leak detected!", domoticz.PRIORITY_HIGH, nil, nil, nil)
                        domoticz.data.consecutive_changes = 0
                        domoticz.devices(WATER_SWITCH_IDX).switchSelector(0)
                    end
                else
                    domoticz.data.consecutive_changes = 0
                    domoticz.log("no change detected", domoticz.LOG_DEBUG)
                end
                domoticz.data.interval_check_count = 0
            end
            
            -- leak detect using leaky bucket algorithm
            local new_value = domoticz.variables("water_leak_counter").value + LEAKY_BUCKET_AVG_LEAK
            if(new_value <= LEAKY_BUCKET_MAX_VALUE)
            then
                domoticz.variables("water_leak_counter").set(new_value)
                domoticz.devices(LEAKY_BUCKET_DEVICE_IDX).updateCustomSensor(new_value)
            else
                domoticz.devices(LEAKY_BUCKET_DEVICE_IDX).updateCustomSensor(LEAKY_BUCKET_MAX_VALUE)
            end
        end
    end
}
