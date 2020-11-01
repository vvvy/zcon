# Changes and TODO

## TODO

* Fix request abort on view change
* Better multilevel switch support (level change)
* Make up Reorder view: fast scroll top/bottom, scrollbar(?), better organize content
* Custom names for custom views
* Handle rooms (http://zway-server:8083/ZAutomation/api/v1/locations) and dashboard
* Better Reload icon in appbar (animated)
* Add FCM support (compatible with ZWay)
* Add Status to Drawer (?)

 
## Version 1.0.4+5

* Added support for window blinds (SwitchMultilevel + motor)
* Add Drawer
* Add Alarms to Drawer view
 - Battery low
 - Failed devices
 - T below 5C and above 30C
* Add Edit config (via JSON)
* i18n, Russian strings
* Handle visibility and permanently_hidden device attributes (via settings)
* Added splash screen
* Changed app title to ZConsole

Under the hood: moved to [scoped_model package](https://pub.dev/packages/scoped_model)
 
## Version 1.0.3+4

* Avatars and icons in the list view
* Thermostat setpoint editor

## Version 1.0.2+3

* New application icon (lamp)
* View configuration buttons moved to the Settings dialog from the appbar
* The app now handles application lifecycle events. Controller polling is now paused when the app is paused
* Long pressing on a list item performs device update
* Popup messages on device operations (sets and updates)
* Help text in Reorder editor 

## Version 1.0.1+2

* Many changes