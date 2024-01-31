# Domoticz-dzVents

This repository contains a collection of LUA scripts to use with Domoticz.

> [!WARNING]
> These scripts are made available to serve as examples, they are not meant to be used as-is.

| Script             | Function |
|:------------------:|:---------|
| `alarm.lua`        | Triggers a siren when a door is opened or motion is detected. |
| `avg_temp.lua`     | Aggregates multiple temperature sensors to a single dummy sensor |
| `check_alive.lua`  | Checks last seen status of a list of devices. When a threshold is reached, it sends a notification through email. It can be used to check when devices are out of battery. |
| `check_door.lua`   | Sounds an alarm when a door stays open for too long |
| `leak_detect.lua`  | Tries to detect water leak. Based on a leaky bucket. Needs a switch sensor to count water consumption. |
| `lights_on.lua`    | Switch on lights on motion detection (depending on a lux sensor) or button press. |
| `rain_meter.lua`   | Tries to count rain based on a pluviometer - Work in progress |
| `water_flow.lua`   | Updates a water flow sensor (in L/minute), based on a variable updated by water_meter.lua |
| `water_meter.lua`  | Measure the water consumption, based on a switch to indicate water consumption |
| `water_switch.lua` | Allows to control a water valve controlled by 2 on/off switches (one for direction, one to open/close the valves) and 2 sensors (stop sensors) using a simple on/off switch. |
