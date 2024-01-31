local LOG_LEVEL = domoticz.LOG_DEBUG -- Can be domoticz.LOG_INFO, domoticz.LOG_MODULE_EXEC_INFO, domoticz.LOG_DEBUG or domoticz.LOG_ERROR
local LIGHT_IDX = 238
local BTN_IDX = 145


return {
    on = { devices = { 209 --[[ ZG motion entrée ]],
                       174 --[[ ZG motion bureau ]],
                       144 --[[ ZG motion cave ]],
                       BTN_IDX --[[ ZG btn bureau ]],
                       323 --[[ ZG Hue remote ]] } },
    logging = { level = LOG_LEVEL, marker  = "Lights" },
    execute = function(domoticz, item)
        if(item.isDevice)
        then
            if(item.id == 323) -- Hue remote
            then
                domoticz.log("Light button pressed: level " .. item.state .. " level " .. item.level, domoticz.LOG_INFO)
                if(item.state == "Off")
                then
                    domoticz.devices(LIGHT_IDX).switchOff()
                else
                    domoticz.devices(LIGHT_IDX).switchOn()
                    domoticz.devices(LIGHT_IDX).dimTo(item.level)
                end
            elseif(item.id == BTN_IDX) -- button
            then
                domoticz.log("Light button pressed: level " .. item.state, domoticz.LOG_INFO)
                if(item.level == 0 or item.level == nil) -- 1 click
                then
                    if(domoticz.devices(LIGHT_IDX).state == "Off")
                    then
                        domoticz.devices(LIGHT_IDX).switchOn()
                        domoticz.devices(LIGHT_IDX).dimTo(100)
                    else
                        domoticz.devices(LIGHT_IDX).switchOff()
                    end
                elseif(item.level == 10) -- 2 clicks
                then
                    domoticz.devices(LIGHT_IDX).switchOn()
                    domoticz.devices(LIGHT_IDX).dimTo(50)
                elseif(item.level == 20) -- 3 clicks
                then
                    domoticz.devices(LIGHT_IDX).switchOn()
                    domoticz.devices(LIGHT_IDX).dimTo(75)
                end
            elseif(item.id == 174) -- motion bureau
            then
                if(item.state == "On")
                then
                    domoticz.devices(332).cancelQueuedCommands()
                    if(domoticz.devices(175 --[[ ZG lux bureau ]]).lux < 100)
                    then
                        domoticz.log("Switch on light bureau (Lux: " .. domoticz.devices(175 --[[ ZG lux bureau ]]).lux .. ")", domoticz.LOG_INFO)
                        domoticz.devices(332).switchOn()
                        domoticz.devices(332).dimTo(100)
                    else
                        domoticz.log("Do not switch on light bureau (Lux: " .. domoticz.devices(175 --[[ ZG lux bureau ]]).lux .. " / state " .. item.state .. ")", domoticz.LOG_INFO)
                    end
                    domoticz.devices(332).switchOff().afterSec(300)
                end
            elseif(item.id == 144) -- motion cave
            then
                if(item.state == "On")
                then
                    domoticz.log("Switch on light cave", domoticz.LOG_INFO)
                    domoticz.devices(249).cancelQueuedCommands()
                    domoticz.devices(249).switchOn()
                    domoticz.devices(249).dimTo(100)
                    domoticz.devices(249).switchOff().afterSec(120)
                    domoticz.devices(250).cancelQueuedCommands()
                    domoticz.devices(250).switchOn()
                    domoticz.devices(250).dimTo(100)
                    domoticz.devices(250).switchOff().afterSec(120)
                end
            elseif(item.id == 209) -- motion entrée
            then
                if(item.state == "On" and domoticz.devices(68 --[[ lux gateway ]]).lux < 900)
                then
                    domoticz.devices(25).dimTo(100)
                    domoticz.devices(25).switchOff().afterSec(120)
                end
            end
        end
    end
}
