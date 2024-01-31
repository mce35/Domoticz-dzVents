--[[
Script that check that the door does not stay open for more than XX seconds
]]--

local LOG_LEVEL = domoticz.LOG_INFO -- Can be domoticz.LOG_INFO, domoticz.LOG_MODULE_EXEC_INFO, domoticz.LOG_DEBUG or domoticz.LOG_ERROR
local MAX_OPEN_TIME = 30 -- time after which an alarm is triggered
local GW_ALARM_IDX = 26  -- index of the gateway alarm ringtone
local GW_VOLUME_IDX = 30 -- index of the gateway volume

return {
    on = { devices = { 204 --[[ ZG Port frigo ]] } },
    logging = { level = LOG_LEVEL, marker  = 'CheckDoor' },
    execute = function(domoticz, device)
        local door_state = device.state
        domoticz.log("Door state:  '" .. door_state .. "'", domoticz.LOG_DEBUG)
        if(door_state == "Open")
        then
            domoticz.devices(GW_ALARM_IDX).cancelQueuedCommands()                          -- Gateway alarm ringtone
            domoticz.devices(GW_VOLUME_IDX).setLevel(20)                                   -- Gateway volume
            domoticz.devices(GW_ALARM_IDX).switchSelector(30).afterSec(MAX_OPEN_TIME)      -- Gateway alarm ringtone
            domoticz.devices(GW_ALARM_IDX).switchSelector(0).afterSec(MAX_OPEN_TIME + 10)  -- Gateway alarm ringtone
            domoticz.devices(GW_ALARM_IDX).switchSelector(30).afterSec(MAX_OPEN_TIME + 20) -- Gateway alarm ringtone
            domoticz.devices(GW_ALARM_IDX).switchSelector(0).afterSec(MAX_OPEN_TIME + 30)  -- Gateway alarm ringtone
            domoticz.devices(GW_ALARM_IDX).switchSelector(30).afterSec(MAX_OPEN_TIME + 40) -- Gateway alarm ringtone
            domoticz.devices(GW_ALARM_IDX).switchSelector(0).afterSec(MAX_OPEN_TIME + 50)  -- Gateway alarm ringtone
            domoticz.devices(GW_ALARM_IDX).switchSelector(30).afterSec(MAX_OPEN_TIME + 60) -- Gateway alarm ringtone
            domoticz.devices(GW_ALARM_IDX).switchSelector(0).afterSec(MAX_OPEN_TIME + 70)  -- Gateway alarm ringtone
        else
            domoticz.devices(GW_ALARM_IDX).cancelQueuedCommands() -- Gateway alarm ringtone
            domoticz.devices(GW_ALARM_IDX).switchSelector(0)      -- Gateway alarm ringtone
        end
    end
}
