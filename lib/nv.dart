import 'package:zcon/pdu.dart';
import 'package:zcon/i18n.dart';

typedef void ErrorF(AppError error);
typedef void UpdateHook();

abstract class NV {
  final String _devId;
  NV(this._devId);
  DeviceLink getLink() => DeviceLink(_devId);
}

abstract class NVUpdate extends NV {
  NVUpdate(String devId): super(devId);
  Command get updateCmd => Command(_devId, "command", "update");
}

class NVSwitch extends NVUpdate {
  final bool value;
  Command? toggleCmd(bool newV) {
    if (newV != value) {
      String cStr =  newV ? "on" : "off";
      return Command(_devId, "command", cStr);
    }
    return null;
  }
  NVSwitch(String devId, String value): value = (value == "on"), super(devId);
  static NV fromDev(Device d, L10ns _l10ns) =>
      NVSwitch(d.id!, (d.metrics?.level).toString());
}

class NVPushButton extends NV {
  Command get pressedCmd => Command(_devId, "command", "on");

  NVPushButton(String devId): super(devId);
  static NV fromDev(Device d, L10ns _l10ns) => NVPushButton(d.id!);
}

class NVThermostatSetPoint extends NV {
  final double? value;
  final String title;
  Command setCmd(double newV) => Command(_devId, "command", "exact?level=$newV");

  NVThermostatSetPoint(String devId, this.title, this.value): super(devId);
  static NV fromDev(Device d, L10ns _l10ns) =>
      NVThermostatSetPoint(
        d.id!,
        (d.metrics?.level).toString() + nvl(d.metrics?.scaleTitle, ""),
        asDouble(d.metrics?.level)
      );
}

class NVSwitchMultilevel extends NVUpdate {
  final int? value;
  final String title;
  Command setLevelCmd(int newV) => Command(_devId, "command", "exact?level=${_nv(newV)}");

  Command startUpCmd() => Command(_devId, "command", "startUp");
  Command startDownCmd() => Command(_devId, "command", "startDown");
  Command stopCmd() => Command(_devId, "command", "stop");
  Command increaseCmd() => Command(_devId, "command", "increase");
  Command decreaseCmd() => Command(_devId, "command", "decrease");

  static int? _nv(int? v) {
    if (v == null) return v;
    if (v > 99) v = 99;
    if (v < 0) v = 0;
    return v;
  }

  //TODO localize
  static String nvText(int? v, L10ns l10ns) {
    return { 0: l10ns.closed, 99: l10ns.open }[v] ?? (v.toString() + "%");
  }

  NVSwitchMultilevel(String devId, this.title, this.value): super(devId);

  static NV fromDev(Device d, L10ns l10ns) {
   int? v = _nv(asInt(d.metrics?.level));
   return NVSwitchMultilevel(d.id!, nvText(v, l10ns), v);
  }
}

class NVShow extends NVUpdate {
  final String value;
  NVShow(String devId, String value): value = value, super(devId);
  static NV fromDev(Device d, L10ns _l10ns) =>
      NVShow(d.id!, (d.metrics?.level).toString() + nvl(d.metrics?.scaleTitle, ""));
}

double? asDouble(dynamic v) {
  if (v is double)
    return v;
  else if (v is int)
    return v.toDouble();
  else if (v is String)
    return double.tryParse(v);
  else
    return null;
}

int? asInt(dynamic v) {
  if (v is int)
    return v;
  else if (v is double)
    return v.toInt();
  else if (v is String)
    return int.tryParse(v);
  else
    return null;
}

typedef NV NVGen(Device d, L10ns l10ns);

final Map<String, NVGen> nvForType  = {
  "toggleButton": NVPushButton.fromDev,
  "switchBinary": NVSwitch.fromDev,
  "thermostat": NVThermostatSetPoint.fromDev,
  "switchMultilevel": NVSwitchMultilevel.fromDev,
  "*": NVShow.fromDev
};

NV getNV(Device d, L10ns l10ns) {
  NVGen? f = nvForType[d.deviceType];
  if (f == null) f = nvForType["*"]!;
  return f(d, l10ns);
}


class Command {
  final String c0;
  final String c1;
  final String c2;
  Command(this.c0, this.c1, this.c2);
}