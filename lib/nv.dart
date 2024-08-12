import 'package:zcon/pdu.dart';
import 'package:zcon/model.dart';
import 'package:zcon/i18n.dart';

typedef void ErrorF(AppError error);
typedef void UpdateHook();

abstract class NV {
  final NVController _nvc;
  final String _devId;
  NV(this._nvc, this._devId);
  DeviceLink getLink() => DeviceLink(_devId);
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
  static NV fromDev(NVController nvc, Device d, L10ns _l10ns) =>
      NVSwitch(nvc, d.id!, (d.metrics?.level).toString());
}

class NVPushButton extends NV {
  void onPressed(ErrorF errorF) {
    _nvc.exec(_devId, "command", "on", errorF);
  }
  NVPushButton(NVController nvc, String devId): super(nvc, devId);
  static NV fromDev(NVController nvc, Device d, L10ns _l10ns) => NVPushButton(nvc, d.id!);
}

class NVThermostatSetPoint extends NV {
  final double? value;
  final String title;
  void onSet(double newV, ErrorF errorF) {
    _nvc.exec(_devId, "command", "exact?level=$newV", errorF);
  }
  NVThermostatSetPoint(NVController nvc, String devId, this.title, this.value): super(nvc, devId);
  static NV fromDev(NVController nvc, Device d, L10ns _l10ns) =>
      NVThermostatSetPoint(nvc,
        d.id!,
        (d.metrics?.level).toString() + nvl(d.metrics?.scaleTitle, ""),
        asDouble(d.metrics?.level)
      );
}

class NVSwitchMultilevel extends NVUpdate {
  final int? value;
  final String title;
  void onSetLevel(int newV, ErrorF errorF) =>
      _nvc.exec(_devId, "command", "exact?level=${_nv(newV)}", errorF);

  void onStartUp(ErrorF errorF) => _nvc.exec(_devId, "command", "startUp", errorF);
  void onStartDown(ErrorF errorF) => _nvc.exec(_devId, "command", "startDown", errorF);
  void onStop(ErrorF errorF) => _nvc.exec(_devId, "command", "stop", errorF);
  void onIncrease(ErrorF errorF) => _nvc.exec(_devId, "command", "increase", errorF);
  void onDecrease(ErrorF errorF) => _nvc.exec(_devId, "command", "decrease", errorF);

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

  NVSwitchMultilevel(NVController nvc, String devId, this.title, this.value): super(nvc, devId);

  static NV fromDev(NVController nvc, Device d, L10ns l10ns) {
   int? v = _nv(asInt(d.metrics?.level));
   return NVSwitchMultilevel(nvc, d.id!, nvText(v, l10ns), v);
  }
}

class NVShow extends NVUpdate {
  final String value;
  NVShow(NVController nvc, String devId, String value): value = value, super(nvc, devId);
  static NV fromDev(NVController nvc, Device d, L10ns _l10ns) =>
      NVShow(nvc, d.id!, (d.metrics?.level).toString() + nvl(d.metrics?.scaleTitle, ""));
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

typedef NV NVGen(NVController nvc, Device d, L10ns l10ns);

final Map<String, NVGen> nvForType  = {
  "toggleButton": NVPushButton.fromDev,
  "switchBinary": NVSwitch.fromDev,
  "thermostat": NVThermostatSetPoint.fromDev,
  "switchMultilevel": NVSwitchMultilevel.fromDev,
  "*": NVShow.fromDev
};

class NVController {
  NVController(this.model);
  final MainModel model;

  NV getNV(Device d, L10ns l10ns) {
    NVGen? f = nvForType[d.deviceType];
    if (f == null) f = nvForType["*"]!;
    return f(this, d, l10ns);
  }

  void exec(String c0, String c1, String c2, ErrorF errorF) async {
    print("Exec: '$c0/$c1/$c2'");
    try {
      final _ = await fetch<Null>("$c0/$c1/$c2", model.fetchConfig!);
      print("Exec ok");
      model.submit(CommonModelEvents.RemoteReloadRequest);
    } catch (err) { errorF(AppError.convert(err)); }
  }
}