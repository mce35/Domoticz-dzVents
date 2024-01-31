local LOG_LEVEL = domoticz.LOG_DEBUG -- Can be domoticz.LOG_INFO, domoticz.LOG_MODULE_EXEC_INFO, domoticz.LOG_DEBUG or domoticz.LOG_ERROR
local BTN_IDX = 156        -- ZG button
local GW_ALARM_IDX = 26    -- index of the gateway alarm ringtone
local GW_VOLUME_IDX = 30   -- index of the gateway volume
local GW_DOORBELL_IDX = 28 -- index of the gateway doorbell
local SECURITY_IDX = 79    -- index of the security device
local GW_LIGHT_IDX = 25
local SIREN_IDX = 352

local devices_armed_away = {
    BTN_IDX,
    216, -- ZG porte bureau
    205, -- ZG porte entrée
    208, -- ZG porte cuisine
    207, -- ZG porte salon
    206, -- ZG fenêtre salon
    146, -- ZG porte buanderie
    147, -- ZG porte garage
    209, -- ZG motion entrée
    144, -- ZG motion sous-sol
    174  -- ZG motion bureau
    }
local devices_armed_home = {
    216, -- ZG porte bureau
    205, -- ZG porte entrée
    208, -- ZG porte cuisine
    207, -- ZG porte salon
    206, -- ZG fenêtre salon
    146, -- ZG porte buanderie
    147  -- ZG porte garage
    }

local devices_trigger_time_sec = {
    ["default"] = 0,
    [205] = 30, -- ZG porte entrée
    [209] = 30, -- ZG motion entrée
    [174] = 30, -- ZG motion bureau
    [146] = 60, -- ZG porte buanderie
    [144] = 60, -- ZG motion sous-sol
    [147] = 300 -- ZG porte garage
    }

local function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function check_doors(domoticz)
    for idx, device in ipairs(devices_armed_away)
    do
        if(domoticz.devices(device).state == "Open")
        then
            domoticz.notify("Alarm warning", "The door '" .. domoticz.devices(device).name .. "' is opened when alarm is activated!", domoticz.PRIORITY_HIGH, nil, nil, nil)
            domoticz.devices(GW_DOORBELL_IDX).cancelQueuedCommands()
            domoticz.devices(GW_VOLUME_IDX).setLevel(20) -- Gateway volume
            domoticz.devices(GW_DOORBELL_IDX).switchSelector(20) -- Gateway doorbell
            domoticz.devices(GW_DOORBELL_IDX).switchSelector(0).afterSec(30) -- Gateway doorbell
        end
    end
end

local function sound_alarm(domoticz)
    domoticz.devices(SIREN_IDX).switchOn()
    domoticz.devices(GW_ALARM_IDX).cancelQueuedCommands()
    domoticz.devices(GW_VOLUME_IDX).setLevel(100) -- Gateway volume
    domoticz.devices(GW_ALARM_IDX).switchSelector(20) -- Gateway alarm ringtone
    domoticz.devices(GW_ALARM_IDX).switchSelector(20).afterSec(30) -- Gateway alarm ringtone
    domoticz.devices(GW_ALARM_IDX).switchSelector(20).afterSec(60) -- Gateway alarm ringtone
    domoticz.devices(GW_ALARM_IDX).switchSelector(20).afterSec(90) -- Gateway alarm ringtone
    domoticz.devices(GW_ALARM_IDX).switchSelector(20).afterSec(120) -- Gateway alarm ringtone
    domoticz.devices(GW_ALARM_IDX).switchSelector(20).afterSec(150) -- Gateway alarm ringtone
    domoticz.devices(GW_ALARM_IDX).switchSelector(20).afterSec(180) -- Gateway alarm ringtone
    domoticz.devices(GW_ALARM_IDX).switchSelector(20).afterSec(210) -- Gateway alarm ringtone
end

local function clear_alarm(domoticz)
    domoticz.devices(SIREN_IDX).switchOff()
    domoticz.devices(GW_ALARM_IDX).cancelQueuedCommands() -- Gateway alarm ringtone
    domoticz.devices(GW_ALARM_IDX).switchSelector(0) -- Gateway alarm ringtone
end

local function on_armed_home(domoticz)
    clear_alarm(domoticz)
    check_doors(domoticz)
    domoticz.devices(GW_LIGHT_IDX).setRGB(0, 0, 255)
    domoticz.variables("alarm_trigger").cancelQueuedCommands()
    domoticz.data.state = 0;
end

return {
    on = { devices = devices_armed_away,
        variables = { "alarm_trigger" },
        security = { domoticz.SECURITY_ARMEDAWAY, domoticz.SECURITY_ARMEDHOME, domoticz.SECURITY_DISARMED } },
    logging = { level = LOG_LEVEL, marker  = "Alarm" },
    data = { current_detection = { initial = "" },
        state = { initial = 0 } -- 0 -> not triggered / 1 -> will be triggered / 2 -> triggered
        },
    execute = function(domoticz, item)
        if(item.isDevice)
        then
            if(item.id == BTN_IDX) -- button
            then
                domoticz.log("button=" ..  item.state, domoticz.LOG_DEBUG)
                if(item.state == "4 Click")
                then
                    domoticz.devices(SECURITY_IDX).cancelQueuedCommands() -- security
                    domoticz.devices(SECURITY_IDX).disarm()
                elseif(item.state == "1 Click")
                then
                    if(domoticz.security == "Armed Home")
                    then
                        domoticz.devices(SECURITY_IDX).disarm().silent()
                    end
                    domoticz.devices(SECURITY_IDX).cancelQueuedCommands()
                    domoticz.devices(SECURITY_IDX).armAway().afterSec(300)
                    domoticz.devices(GW_LIGHT_IDX).setRGB(255, 0, 0)
                    domoticz.variables("alarm_trigger").cancelQueuedCommands()
                    domoticz.data.state = 0;
                    check_doors(domoticz)
                elseif(item.state == "2 Click")
                then
                    domoticz.devices(SECURITY_IDX).cancelQueuedCommands() -- security
                    domoticz.devices(SECURITY_IDX).armHome().silent()
                    on_armed_home(domoticz)
                end
            else
                local device = item
                if(device.state ~= "Off" and ((domoticz.security == "Armed Home" and has_value(devices_armed_home, device.id)) or domoticz.security == "Armed Away"))
                then
                    domoticz.data.current_detection = domoticz.data.current_detection .. "The device '" .. device.name .. "' has changed (" .. device.state .. ") while alarm status is '" .. domoticz.security .. "'!<br/>\n"
                    if(domoticz.security == "Armed Home" or domoticz.data.state == 2)
                    then
                        domoticz.variables("alarm_trigger").set(1)
                    else
                        domoticz.devices(GW_DOORBELL_IDX).cancelQueuedCommands()
                        domoticz.devices(GW_VOLUME_IDX).setLevel(10) -- Gateway volume
                        domoticz.devices(GW_DOORBELL_IDX).switchSelector(10) -- Gateway doorbell
                        domoticz.devices(GW_DOORBELL_IDX).switchSelector(0).afterSec(32) -- Gateway doorbell
                        domoticz.devices(GW_LIGHT_IDX).setRGB(0, 255, 255)
                        if(domoticz.data.state == 0)
                        then
                            local timeout = devices_trigger_time_sec["default"]
                            if(devices_trigger_time_sec[device.id] ~= nil)
                            then
                                timeout = devices_trigger_time_sec[device.id]
                            end
                            domoticz.log("alarm: alarm will be triggered in " .. timeout .. " seconds (trigger device: " .. device.name .. ")", domoticz.LOG_INFO)
                            domoticz.variables("alarm_trigger").set(1).afterSec(timeout)
                            domoticz.data.state = 1;
                        end
                    end
                end
            end
        elseif(item.isVariable)
        then
            local variable = item
            if (variable.value ~= 0)
            then
                domoticz.notify("[Domoticz] Intrusion detected", domoticz.data.current_detection, domoticz.PRIORITY_HIGH, nil, nil, nil)
                domoticz.data.current_detection = ""
                domoticz.variables("alarm_trigger").set(0)
                domoticz.data.state = 2;
                sound_alarm(domoticz)
            end
        elseif(item.isSecurity)
        then
            domoticz.log("alarm: status=" .. domoticz.security, domoticz.LOG_DEBUG)
            if(domoticz.security == "Armed Away")
            then
                check_doors(domoticz)
                domoticz.data.state = 0;
            elseif(domoticz.security == "Armed Home")
            then
                on_armed_home(domoticz)
            else -- disarmed
                domoticz.devices(GW_LIGHT_IDX).setRGB(0, 255, 0)
                clear_alarm(domoticz)
                domoticz.variables("alarm_trigger").cancelQueuedCommands()
                domoticz.data.state = 0;
                domoticz.data.current_detection = ""
                domoticz.variables("alarm_trigger").set(0)
            end
        end
    end
}
