//Note on custom icons:
//1. Go to https://www.fluttericon.com/
//2. Upload either config.json (recommended) or svg sources from assets/custom_icons
//3. Specify CustomIcons as a class name
//4. Download
//5. move fonts/CustomIcons.ttf from the downloaded archive to fonts/
//6. move config.json from the downloaded archive to assets/custom_icons
//7. move custom_icons_icons.dart from the downloaded archive to lib/
//8. edit custom_icons_icons.dart, add String type annotation to _kFontPkg
//9. use icons as e.g. CustomIcons.wb_25

import 'package:flutter/material.dart';
import 'package:zcon/pdu.dart';
import 'package:zcon/custom_icons_icons.dart';

enum AColor { neutral, green, yellow, red }

Widget _colorAvatar(Widget child, AColor color) {
  switch (color) {
    case AColor.green:
      return CircleAvatar(child: child, foregroundColor: Colors.yellow, backgroundColor: Colors.green);
    case AColor.yellow:
      return CircleAvatar(child: child, foregroundColor: Colors.green, backgroundColor: Colors.yellow);
    case AColor.red:
      return CircleAvatar(child: child, backgroundColor: Colors.red);
    case AColor.neutral:
    default:
      return CircleAvatar(child: child, backgroundColor: Colors.blue);
  }
}

AColor _fromRange(dynamic l, double lo, double hi, AColor c0, AColor c1, AColor c2) {
  if (l is double || l is int) {
    if (l < lo) return c0;
    else if (l >= hi) return c2;
    else return c1;
  } else return AColor.neutral;
}

AColor _fromValues(dynamic l, String v0, AColor c0, String v1, AColor c1) {
  if (l is String && l == v0)
    return c0;
  else if (l is String && l == v1)
    return c1;
  else return AColor.neutral;
}

Widget _battery(dynamic level) {
  if (level is double || level is int) {
    if (level < 25)
      return _colorAvatar(Icon(Icons.battery_alert), AColor.red);
    else if (level < 50)
      return _colorAvatar(Icon(Icons.battery_std), AColor.yellow);
    else
      return _colorAvatar(Icon(Icons.battery_std), AColor.green);
  }
  return _colorAvatar(Icon(Icons.battery_unknown), AColor.neutral);
}

Widget _windowBlind(dynamic level) {
  //return _colorAvatar(Icon(CustomIcons.wb_unknown), AColor.red);
  if (!(level is double || level is int))
    return _colorAvatar(Icon(CustomIcons.wb_unknown), AColor.red);
  level = level.toInt();
  if (level == 0)
    return _colorAvatar(Icon(CustomIcons.wb_00), AColor.neutral);
  if (level <= 25)
    return _colorAvatar(Icon(CustomIcons.wb_25), AColor.yellow);
  if (level <= 50)
    return _colorAvatar(Icon(CustomIcons.wb_50), AColor.yellow);
  if (level <= 75)
    return _colorAvatar(Icon(CustomIcons.wb_75), AColor.yellow);
  if (level <= 100 || level == 255)
    return _colorAvatar(Icon(CustomIcons.wb_99), AColor.yellow);
  return _colorAvatar(Icon(CustomIcons.wb_unknown), AColor.red);
}


final _avatarMap = {
  "battery": _battery,
  "switchBinary":[Icon(Icons.lightbulb_outline)],
  "thermostat/thermostat_set_point":[Text("T"), (l) => _fromRange(l, 18, 18, AColor.neutral, AColor.neutral, AColor.green)],

  "sensorMultilevel/temperature":[Text("t"), (l) => _fromRange(l, 5, 18, AColor.red, AColor.yellow, AColor.green)],
  "sensorMultilevel/meterElectric_ampere":[Text("A")],
  "sensorMultilevel/meterElectric_kilowatt_hour":[Text("kWh")],
  "sensorMultilevel/meterElectric_power_factor":[Text("P")],
  "sensorMultilevel/meterElectric_voltage":[Text("V")],
  "sensorMultilevel/meterElectric_watt":[Text("W")],
  "sensorMultilevel":[Icon(Icons.av_timer)],

  "toggleButton/notification_email":[Icon(Icons.email)],
  "toggleButton/notification_push":[Icon(Icons.notifications)],
  "toggleButton":[Icon(Icons.launch)],

  "sensorBinary/flood":[Icon(Icons.invert_colors), (l) => _fromValues(l, "on", AColor.red, "off", AColor.green)],
  "sensorBinary":[Icon(Icons.hdr_strong)],

  "sensorDiscrete":[Icon(Icons.menu)],

  "switchMultilevel/motor": _windowBlind,

  /*
  "sensorBinary/alarm_heat":[Text("sensorBinary/alarm_heat"), AColor.neutral],
  "sensorBinary/alarm_power":[Text("sensorBinary/alarm_power"), AColor.neutral],
  "sensorBinary/general_purpose":[Text("sensorBinary/general_purpose"), AColor.neutral],
  "sensorBinary/tamper":[Text("sensorBinary/tamper"), AColor.neutral],
  "sensorDiscrete/":[Text("sensorDiscrete/"), AColor.neutral],
  "sensorDiscrete/control":[Text("sensorDiscrete/control"), AColor.neutral],
  "sensorMultiline/":[Text("sensorMultiline/"), AColor.neutral],
  "text/":[Text("text/"), AColor.neutral],
  */

  "*": [Icon(Icons.blur_circular), AColor.neutral]
};





Widget avatar(Device d) {
  var spec = _avatarMap[d.deviceType + "/" + d.probeType];
  if (spec == null) spec = _avatarMap[d.deviceType];
  if (spec == null) spec = _avatarMap["*"];

  if (spec is Function) {
    return spec(d.metrics.level);
  } else if (spec is List) {
    AColor aColor;
    if (spec.length > 1) {
      if (spec[1] is AColor)
        aColor = spec[1];
      else if (spec[1] is Function)
        aColor = spec[1](d.metrics.level);
      else
        aColor = AColor.neutral;
    } else
      aColor = AColor.neutral;
    return _colorAvatar(spec[0], aColor);
  } else {
    //default
    return _colorAvatar(Icon(Icons.blur_circular), AColor.neutral);
  }
}
