import 'pdu.dart';

typedef void ErrorF(String message);
typedef void UpdateHook();

abstract class NV {
  final NVController _nvc;
  final String _devId;
  NV(NVController nvc, String devId): _devId = devId, _nvc = nvc;
}

abstract class NVUpdate extends NV {
  NVUpdate(NVController nvc, String devId): super(nvc, devId);
  void onUpdate(ErrorF errorF) => _nvc.exec(_devId, "command", "update", errorF);
}

class NVSwitch extends NVUpdate {
  final bool value;
  void onToggle(bool newV, ErrorF errorF) {
    if (newV != value) {
      String cStr =  newV ? "on" : "off";
      _nvc.exec(_devId, "command", cStr, errorF);
    }
  }
  NVSwitch(NVController nvc, String devId, String value): value = (value == "on"), super(nvc, devId);
  static NV fromDev(NVController nvc, Device d) { return NVSwitch(nvc, d.id, d.metrics.level.toString()); }
}

class NVPushButton extends NV {
  void onPressed(ErrorF errorF) {
    _nvc.exec(_devId, "command", "on", errorF);
  }
  NVPushButton(NVController nvc, String devId): super(nvc, devId);
  static NV fromDev(NVController nvc, Device d) => NVPushButton(nvc, d.id);
}

class NVThermostatSetPoint extends NVUpdate {
  final double value;
  final String title;
  void onSet(double newV, ErrorF errorF) {
    _nvc.exec(_devId, "command", "exact?level=$newV", errorF);
  }
  NVThermostatSetPoint(NVController nvc, String devId, String title, double value): title = title, value = value, super(nvc, devId);
  static NV fromDev(NVController nvc, Device d) { return NVThermostatSetPoint(nvc,
      d.id,
      d.metrics.level.toString() + nvl(d.metrics.scaleTitle, ""),
      asDouble(d.metrics.level));
  }
}

class NVSwitchMultilevel extends NVUpdate {
  final int value;
  final String title;
  void onSet(int newV, ErrorF errorF) {
    _nvc.exec(_devId, "command", "exact?level=${_nv(newV)}", errorF);
  }
  static int _nv(int v) {
    if (v > 99) v = 99;
    if (v < 0) v = 0;
    return v;
  }
  static String nvText(int v) {
    return { 0: "Closed", 99: "Open" }[v] ?? (v.toString() + "%");
  }

  NVSwitchMultilevel(NVController nvc, String devId, String title, int value): title = title, value = value, super(nvc, devId);
  static NV fromDev(NVController nvc, Device d) {
   int v = _nv(asInt(d.metrics.level));
   return NVSwitchMultilevel(nvc, d.id, nvText(v), v);
  }
}

class NVShow extends NVUpdate {
  final String value;
  NVShow(NVController nvc, String devId, String value): value = value, super(nvc, devId);
  static NV fromDev(NVController nvc, Device d) { return NVShow(nvc, d.id, d.metrics.level.toString() + nvl(d.metrics.scaleTitle, "")); }
}

double asDouble(dynamic v) {
  if (v is double)
    return v;
  else if (v is int)
    return v.toDouble();
  else if (v is String)
    return double.tryParse(v);
  else
    return null;
}

int asInt(dynamic v) {
  if (v is int)
    return v;
  else if (v is double)
    return v.toInt();
  else if (v is String)
    return int.tryParse(v);
  else
    return null;
}

typedef NV NVGen(NVController nvc, Device d);

final Map<String, NVGen> nvForType  = {
  "toggleButton": NVPushButton.fromDev,
  "switchBinary": NVSwitch.fromDev,
  "thermostat": NVThermostatSetPoint.fromDev,
  "switchMultilevel": NVSwitchMultilevel.fromDev,
  "*": NVShow.fromDev
};

class NVController {
  UpdateHook _updateHook;

  void setUpdateHook(UpdateHook updateHook) { _updateHook = updateHook; }

  NV getNV(Device d) {
    NVGen f = nvForType[d.deviceType];
    if (f == null) f = nvForType["*"];
    return f(this, d);
  }

  void exec(String c0, String c1, String c2, ErrorF errorF) {
    print("Exec: '$c0/$c1/$c2'");
    fetch<Null>("$c0/$c1/$c2")
      .then((n) {
        print("Exec ok");
        if (_updateHook != null) _updateHook();
      })
      .catchError((err) => errorF("$err"));
  }
}