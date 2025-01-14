-- script taken (and heavily modified) from here: https://www.domoticz.com/forum/viewtopic.php?f=59&t=18566&start=20
--[[
WHAT DOES THE SCRIPTS?:
It looks to the LAST SEEN date/time of a device. When threshold runs out, you get a notification to check the device.
Be sure you are adding devices that are updated in a normal situation. 
For example, devices connected to a Xiaomi gateway are not updated, unless activated. When you add a smoke detector tru Xiaomi gateway, then the smoke detector has to give a smoke-alarm before the threshold runs out. Otherwise you get a notification. 
Advice for Xiaomi smoke-detectors is to use Zigbee2MQTT, this gateway does update the LAST SEEN date/time of Xiaomi smoke-detectors.

The script sends notifications to the email address defined in user variable "user_email", so it must be defined in Domoticz.
Domoticz email configuration should also be working.
]]--

local NOTIFY_TIME = 'at 11:30'        -- reminder notification time
local TIMEOUT_SEC_DEFAULT = 2*60*60   -- timeout in seconds
local TIMEOUT_SEC_TUYA    = 5*60*60   -- timeout in seconds for Tuya devices
local TIMEOUT_SEC_CONTACT = 2*60*60   -- timeout in seconds for door/window sensors
local TIMEOUT_SEC_ROUTER  = 2*60*60   -- timeout in seconds for Zigbee routers
local TIMEOUT_SEC_LONG    = 6*60*60   -- timeout in seconds for sensors not reporting often
local TIMEOUT_SEC_TEMP    = 2*60*60   -- timeout in seconds for temp sensors
local TIMEOUT_SEC_WATER   = 24*60*60  -- timeout in seconds for water meter
local TIMEOUT_SEC_SHORT   = 2*60      -- timeout in seconds for devices updated frequently
local LOG_LEVEL = domoticz.LOG_INFO   -- Can be domoticz.LOG_INFO, domoticz.LOG_MODULE_EXEC_INFO, domoticz.LOG_DEBUG or domoticz.LOG_ERROR

local HTTPCallback = 'CheckLastSeen'
local Time = require('Time')

local function count_items(table)
    local nb = 0
    for key, value in pairs(table)
    do
        nb = nb + 1
    end

    return nb
end

local function human_time(sec)
    local ti
    sec = tonumber(sec)
    if(sec == nil)       then ti = 'NIL'
    elseif(sec >= 86400) then ti = string.sub(tostring(sec/24/3600),1,4) .. ' days'  
    elseif(sec >= 3600)  then ti = string.sub(tostring(sec/3600),1,4) .. ' hours' 
    elseif(sec >= 60)    then ti = string.sub(tostring(sec/60),1,4) .. ' minutes'
    else ti = sec .. ' seconds'
    end
    return ti 
end

local function build_notified_list(domoticz)
    local msg = "Reminder: Signal lost for:\\n\n"
    local nb = 0

    for key, value in pairs(domoticz.data.notified)
    do
        local lastUpdate = Time(value).secondsAgo
        local device = domoticz.devices(key)
        if(device == nil)
        then
            msg = msg .. " - " .. key .. "(DEVICE NOT FOUND) (last update " .. human_time(lastUpdate) .. " ago / " .. value .. ")\\n\n"
            domoticz.data.notified[key] = nil
        else
            msg = msg .. " - " .. device.name .. " (last update " .. human_time(lastUpdate) .. " ago / " .. value .. ")\\n\n"
        end
        nb = nb + 1
    end

    if(nb > 0)
    then
        return msg
    else
        return nil
    end
end

local function send_notification(domoticz, subject, msg, notified_msg)
    if(msg ~= "")
    then
        if(notified_msg ~= nil)
        then
            msg = msg .. "\\n\n" .. notified_msg
        end

        if(string.len(subject) > 100)
        then
            subject = string.sub(subject, 1, 100) .. "..."
        end

        domoticz.log(msg, domoticz.LOG_INFO)
        domoticz.email(subject, msg, domoticz.variables("user_email").value)
    end
end

local function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end
 

return {
    on = { timer =  { 'every 15 minutes' }, httpResponses = { HTTPCallback } },
    logging = { level = LOG_LEVEL, marker  = 'CheckLastSeen' },

    data = { notified = { initial = {} } },

    execute = function(domoticz, item)
        -- devices to check (indexes), timeout in seconds
        local devices = {
            ['153'] = TIMEOUT_SEC_TEMP,    -- ZG - °/% buanderie
            ['171'] = TIMEOUT_SEC_TEMP,    -- ZG - °/% Bureau
            ['179'] = TIMEOUT_SEC_TEMP,    -- ZG - °/% Cave
            ['198'] = TIMEOUT_SEC_TEMP,    -- ZG - °/% Chambre Tim
            ['192'] = TIMEOUT_SEC_TEMP,    -- ZG - °/% Extérieur
            ['345'] = TIMEOUT_SEC_TEMP,    -- ZG - °/% Extérieur arrière
            ['195'] = TIMEOUT_SEC_TEMP,    -- ZG - °/% Salle de jeu
            ['176'] = TIMEOUT_SEC_TEMP,    -- ZG - °/% Ch Noam/Mahé
            ['168'] = TIMEOUT_SEC_TEMP,    -- ZG - °/% Salon
            ['148'] = TIMEOUT_SEC_TEMP,    -- ZG - °/%/B sous-sol
            ['163'] = TIMEOUT_SEC_TEMP,    -- ZG - °/%/B Cuisine
            ['255'] = TIMEOUT_SEC_TEMP,    -- ZG - °/% Frigo
            ['333'] = TIMEOUT_SEC_TEMP,    -- ZG - °/% Sonoff 1
            ['336'] = TIMEOUT_SEC_TEMP,    -- ZG - °/% Sonoff 2
            ['339'] = TIMEOUT_SEC_TEMP,    -- ZG - °/%/B Chambre parents

            ['146'] = TIMEOUT_SEC_CONTACT, -- ZG - Porte buanderie
            ['216'] = TIMEOUT_SEC_CONTACT, -- ZG - Porte bureau
            ['208'] = TIMEOUT_SEC_CONTACT, -- ZG - Porte cuisine
            ['205'] = TIMEOUT_SEC_CONTACT, -- ZG - Porte d'entrée
            ['204'] = TIMEOUT_SEC_CONTACT, -- ZG - Porte frigo
            ['147'] = TIMEOUT_SEC_CONTACT, -- ZG - Porte garage
            ['207'] = TIMEOUT_SEC_CONTACT, -- ZG - Porte salon
            ['206'] = TIMEOUT_SEC_CONTACT, -- ZG - Fenêtre salon

            ['157'] = TIMEOUT_SEC_DEFAULT, -- ZG - Leak chauffe-eau
            ['230'] = TIMEOUT_SEC_DEFAULT, -- ZG - Leak buanderie
            ['231'] = TIMEOUT_SEC_DEFAULT, -- ZG - Leak cuisine
            ['253'] = TIMEOUT_SEC_TUYA,    -- ZG - Water leak Tuya 1
            ['254'] = TIMEOUT_SEC_TUYA,    -- ZG - Water leak Tuya 2

            ['144'] = TIMEOUT_SEC_DEFAULT, -- ZG - Motion cave
            ['174'] = TIMEOUT_SEC_DEFAULT, -- ZG - Motion bureau
            ['209'] = TIMEOUT_SEC_DEFAULT, -- ZG - Motion entrée

            ['215'] = TIMEOUT_SEC_CONTACT, -- ZG - Chatière
            ['210'] = TIMEOUT_SEC_CONTACT, -- ZG - Boîte à lettre
            ['244'] = TIMEOUT_SEC_CONTACT, -- ZG - Rain sensor
            ['297'] = TIMEOUT_SEC_LONG,    -- ZG - Portail
            ['175'] = TIMEOUT_SEC_DEFAULT, -- ZG - Lux bureau
            ['156'] = TIMEOUT_SEC_DEFAULT, -- ZG - btn cuisine
            ['145'] = TIMEOUT_SEC_DEFAULT, -- ZG - btn bureau
            ['323'] = TIMEOUT_SEC_DEFAULT, -- ZG - Hue remote

            ['237'] = TIMEOUT_SEC_DEFAULT, -- ZG - Smoke detector
            ['242'] = TIMEOUT_SEC_LONG,    -- ZG - Heiman Smoke detector
            ['322'] = TIMEOUT_SEC_LONG,    -- ZG - Heiman Smoke detector 2

            ['238'] = TIMEOUT_SEC_ROUTER,  -- ZG - Light cuisine
            -- ['247'] = TIMEOUT_SEC_ROUTER,  -- ZG - Light bureau old
            ['249'] = TIMEOUT_SEC_ROUTER,  -- ZG - Light cave 1
            ['250'] = TIMEOUT_SEC_ROUTER,  -- ZG - Light cave 2
            ['332'] = TIMEOUT_SEC_ROUTER,  -- ZG - Light bureau

            ['245'] = TIMEOUT_SEC_DEFAULT, -- ZG - Router Ext
            ['248'] = TIMEOUT_SEC_ROUTER,  -- ZG - Router RDC
            -- ['258'] = TIMEOUT_SEC_ROUTER,  -- ZG - Micromodule chauffe-eau

            -- ['302'] = TIMEOUT_SEC_ROUTER,  -- ZG - Switch1
            -- ['303'] = TIMEOUT_SEC_ROUTER,  -- ZG - Switch2
            -- ['304'] = TIMEOUT_SEC_ROUTER,  -- ZG - Switch3
            -- ['305'] = TIMEOUT_SEC_ROUTER,  -- ZG - Switch4

            ['182'] = TIMEOUT_SEC_DEFAULT, -- PM2.5 sensor
            ['190'] = TIMEOUT_SEC_DEFAULT, -- PM10
            ['547'] = TIMEOUT_SEC_DEFAULT, -- PM2.5 sensor indoor
            ['548'] = TIMEOUT_SEC_DEFAULT, -- PM10 sensor indoor

            ['287'] = TIMEOUT_SEC_DEFAULT, -- PZEM1
            ['274'] = TIMEOUT_SEC_DEFAULT, -- PZEM2

            -- ['68']  = TIMEOUT_SEC_DEFAULT, -- Xiaomi Gateway Lux
            ['17']  = TIMEOUT_SEC_WATER,   -- Water - 1 day
            ['363'] = TIMEOUT_SEC_SHORT,   -- Arduino analog input 0
            ['4']   = TIMEOUT_SEC_DEFAULT, -- Teleinfo Courant
            ['221'] = TIMEOUT_SEC_DEFAULT, -- Palazzetti - Room Temperature

            -- ['277'] = TIMEOUT_SEC_DEFAULT, -- Enphase kWh Production
            ['279'] = TIMEOUT_SEC_DEFAULT, -- Enphase kWh Consumption
            ['281'] = TIMEOUT_SEC_DEFAULT, -- Enphase kWh Net Consumption

            ['314'] = TIMEOUT_SEC_DEFAULT, -- Inv 122138073676
            ['315'] = TIMEOUT_SEC_DEFAULT, -- Inv 122134049595
            ['316'] = TIMEOUT_SEC_DEFAULT, -- Inv 122134052922
            ['317'] = TIMEOUT_SEC_DEFAULT, -- Inv 122134051631
            ['318'] = TIMEOUT_SEC_DEFAULT, -- Inv 122134051700
            ['319'] = TIMEOUT_SEC_DEFAULT, -- Inv 122134052139
            ['320'] = TIMEOUT_SEC_DEFAULT, -- Inv 122134052445
            ['321'] = TIMEOUT_SEC_DEFAULT, -- Inv 122134052356

            ['467'] = TIMEOUT_SEC_SHORT, -- esp-mh-z19-1
            ['473'] = TIMEOUT_SEC_SHORT, -- alarm box MH-Z19
        }

        local notified = domoticz.data.notified -- short reference

        if(not (item.isHTTPResponse))
        then
            if(domoticz.time.matchesRule(NOTIFY_TIME))
            then
                local msg = build_notified_list(domoticz)
                if(msg ~= nil)
                then
                    domoticz.email("Reminder: Signal lost for " .. count_items(notified) .. " device(s)", msg, domoticz.variables("user_email").value)
                end
            end

            domoticz.openURL({ 
                url = domoticz.settings['Domoticz url'] .. '/json.htm?type=command&param=getdevices&used=true',
                callback = HTTPCallback })
        else
            local back_devices_msg = ""
            local lost_devices_msg = ""
            local lost_devices_subject = "Signal lost for | "
            local back_devices_subject = "Signal back for | "
            local to_be_notified = {}

            -- domoticz.log("HTTP response '" .. dump(item), domoticz.LOG_DEBUG)

            if(not item.ok)
            then
                domoticz.log("HTTP request failed, status code=" .. item.statusCode, domoticz.LOG_ERROR)
                domoticz.email("Check alive failed", "HTTP request failed, status code=" .. item.statusCode, domoticz.variables("user_email").value)
                return
            end
            if(not item.isJSON)
            then
                domoticz.log("HTTP request failed, didn't return a JSON object " .. dump(item), domoticz.LOG_ERROR)
                domoticz.email("Check alive failed", "HTTP request failed, didn't return a JSON object " .. dump(item), domoticz.variables("user_email").value)
                return
            end

            for _, node in pairs(item.json.result)
            do
                local toCheck = devices[node.idx]
                if(toCheck)
                then
                    local lastUpdate = Time(node.LastUpdate).secondsAgo
                    local deviceName = (node.Name or node.idx)
                    local deviceID = tonumber(node.idx)
                    local threshold = toCheck

                    domoticz.log("device '" .. deviceName .. "': last seen=" .. lastUpdate .. "seconds ago / threshold=" .. human_time(threshold) .. ")", domoticz.LOG_DEBUG)
                    if(lastUpdate < threshold)
                    then
                        --device is alive
                        if(notified[deviceID] == nil)
                        then
                            domoticz.log("device '" .. deviceName .. "' still alive", domoticz.LOG_DEBUG)
                        else
                            back_devices_msg = "Signal back from sensor '" .. deviceName .. "'" .. "\\n\n" .. back_devices_msg
                            back_devices_subject = back_devices_subject .. deviceName .. " | "

                            notified[deviceID] = nil  --remove from notified list
                        end
                    else 
                        --lost signal
                        if(notified[deviceID] == nil)
                        then
                            lost_devices_msg = "Signal lost: '" .. deviceName .. "' last seen " .. human_time(lastUpdate) .. " ago (" .. node.LastUpdate .. "), threshold=" .. human_time(threshold) .. ". Battery empty?" .. "\\n\n" .. lost_devices_msg
                            lost_devices_subject = lost_devices_subject .. deviceName .. " | "
                            to_be_notified[deviceID] = node.LastUpdate
                        else
                            domoticz.log("Device '" .. deviceName .. "' already notifed (last seen " .. human_time(lastUpdate) .. " ago, threshold=" .. human_time(threshold) .. ". Battery empty?)", domoticz.LOG_DEBUG)
                        end
                    end
                end
            end
            local notified_msg = build_notified_list(domoticz) --build list of still unreachable devices
            for key, value in pairs(to_be_notified)
            do
                notified[key] = value
            end
            send_notification(domoticz, lost_devices_subject, lost_devices_msg, notified_msg)
            send_notification(domoticz, back_devices_subject, back_devices_msg, notified_msg)
        end
    end
}
