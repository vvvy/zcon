import 'pdu.dart';
import 'pref.dart';

typedef void PopupF(String message);
typedef void UpdateHook();

abstract class NV {
  final NVController _nvc;
  final String _devId;
  NV(NVController nvc, String devId): _devId = devId, _nvc = nvc;
}

class NVSwitch extends NV {
  final bool value;
  void onToggle(bool newV) {
    if (newV != value)
    _nvc.exec(_devId, "command", newV ? "on" : "off");
  }
  NVSwitch(NVController nvc, String devId, String value): value = (value == "on"), super(nvc, devId);
}

class NVPushButton extends NV {
  void onPressed() {
    _nvc.exec(_devId, "command", "on");
  }
  NVPushButton(NVController nvc, String devId): super(nvc, devId);
}

class NVFloat extends NV {
  final double value;
  //fmt.Sprintf("%s/%s/command/exact?level=%s", ZADevicesPath, dev.id(), cmd))
  void onPressed() {
    _nvc.exec(_devId, "command", "exact?level=$value");
  }
  NVFloat(NVController nvc, String devId, double value): value = value, super(nvc, devId);
}

class NVShow extends NV {
  final String value;
  NVShow(NVController nvc, String devId, String value): value = value, super(nvc, devId);
}

class NVController {
  PopupF _popupF;
  UpdateHook _updateHook;

  void popup(String message) {
    print("Popup: $message");
    if (_popupF != null)
      _popupF(message);
  }

  void setUpdateHook(UpdateHook updateHook) { _updateHook = updateHook; }

  NV getNV(Device d, PopupF popupF) {
    _popupF = popupF;
    switch (d.deviceType) {
      case "toggleButton":
        return NVPushButton(this, d.id);
      case "switchBinary":
        return NVSwitch(this, d.id, d.metrics.level.toString());
    }
    return NVShow(this, d.id, d.metrics.level.toString() + nvl(d.metrics.scaleTitle, ""));
  }

  void exec(String c0, String c1, String c2) {
    print("Exec: '$c0/$c1/$c2'");
    readSettings()
        .then((s) => fetch<Null>(s, "$c0/$c1/$c2"))
        .then((n) {
          print("Exec ok");
          if (_updateHook != null) _updateHook();
        })
        .catchError((err) => popup("Update error: $err"));
  }

}