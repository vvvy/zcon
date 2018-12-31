import 'pdu.dart';

typedef void ErrorF(String message);
typedef void UpdateHook();

abstract class NV {
  final NVController _nvc;
  final String _devId;
  NV(NVController nvc, String devId): _devId = devId, _nvc = nvc;
}

//Commented out due to the bug https://github.com/dart-lang/sdk/issues/35011
/*
mixin NVUpdate on NV {
  void onUpdate() {
    _nvc.exec(_devId, "command", "update");
  }
}
*/

abstract class NVUpdate extends NV {
  NVUpdate(NVController nvc, String devId): super(nvc, devId);
  void onUpdate(ErrorF errorF) {
    _nvc.exec(_devId, "command", "update", errorF);
  }
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
}

class NVPushButton extends NV {
  void onPressed(ErrorF errorF) {
    _nvc.exec(_devId, "command", "on", errorF);
  }
  NVPushButton(NVController nvc, String devId): super(nvc, devId);
}

class NVFloat extends NVUpdate {
  final double value;
  void onSet(double newV, ErrorF errorF) {
    _nvc.exec(_devId, "command", "exact?level=$newV", errorF);
  }
  NVFloat(NVController nvc, String devId, double value): value = value, super(nvc, devId);
}

class NVShow extends NVUpdate {
  final String value;
  NVShow(NVController nvc, String devId, String value): value = value, super(nvc, devId);
}

class NVController {
  UpdateHook _updateHook;

  void setUpdateHook(UpdateHook updateHook) { _updateHook = updateHook; }

  NV getNV(Device d) {
    switch (d.deviceType) {
      case "toggleButton":
        return NVPushButton(this, d.id);
      case "switchBinary":
        return NVSwitch(this, d.id, d.metrics.level.toString());
      default:
        return NVShow(this, d.id, d.metrics.level.toString() + nvl(d.metrics.scaleTitle, ""));
    }
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