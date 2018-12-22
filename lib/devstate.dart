import 'dart:async';
import 'pdu.dart';
import 'pref.dart';
import 'devlist.dart';

//------------------------------------------------------------------------------

typedef void PopupF(String message);

abstract class DevView { }

class DevViewFull extends DevView {
  final DevList devices;
  final bool isLoading;
  DevViewFull(DevList devices, bool isLoading): devices = devices, isLoading = isLoading;
}

class DevViewEmpty extends DevView {
  final String error;
  final bool isLoading;
  DevViewEmpty(String error, bool isLoading): error = error, isLoading = isLoading;
}

//------------------------------------------------------------------------------
//TODO move these to settings

const maxErrorRetries = 5;

abstract class DevStateNest {
  void setDevState(DevState state);
}

abstract class DevState {
  final DevStateNest parent;
  bool _isLoading;
  bool _updateNeeded;
  DevListController _dlc;

  bool get isLoading => _isLoading;
  int getFilter() => _dlc.current;
  List<IdName<int>> getAvailableFilters() => _dlc.master;
  void setFilter(int current) {
    _dlc.current = current;
    //TODO move _current under separate persistence key
    // (so we don't write entire config when moving between views)
    writeConfig(_dlc.makeConfig()).then((_) => parent.setDevState(this));
  }
  bool get listsOnline => _dlc.isOnline;
  bool get isListEditable => _dlc.isListEditable;
  List<ReorderListItem<String>> startEditList() => _dlc.startEditList();
  void endEditList(List<ReorderListItem<String>> result) {
    _dlc.endEditList(result);
    writeConfig(_dlc.makeConfig()).then((_) => parent.setDevState(this));
  }
  List<ReorderListItem<int>> startEditMaster() => _dlc.startEditMaster();
  void endEditMaster(List<ReorderListItem<int>> result) {
    _dlc.endEditMaster(result);
    writeConfig(_dlc.makeConfig()).then((_) => parent.setDevState(this));
  }
  DevView getDeviceView(PopupF popupF);
  void flagNeedsUpdate() {
    _updateNeeded = true;
    tryUpdateNow();
  }
  void tryUpdateNow();
  void cleanup();
  DevState({DevStateNest parent, bool isLoading, bool updateNeeded}):
        parent = parent,
        _isLoading = isLoading,
        _updateNeeded = updateNeeded,
        _dlc = new DevListController();

  DevState.clone(DevState prev):
        parent = prev.parent,
        _isLoading = prev._isLoading,
        _updateNeeded = prev._updateNeeded,
        _dlc = prev._dlc;
}

class DevStateNonEmpty extends DevState {
  //Future<void> _devicesF;
  Timer _devRefreshT;
  Devices _devices;
  int _errorCount;
  PopupF _popupF;

  DevStateNonEmpty(DevState origin, {Devices devices}):
        _devices = devices,
        super.clone(origin) {
    _dlc.applyDevices(devices.devices, rebuildHint: true);
    Future.microtask(() => _init());
  }

  @override
  DevView getDeviceView(PopupF popupF) {
    _popupF = popupF;
    return _dlc.isOnline ? DevViewFull(_dlc.list, _isLoading) : DevViewEmpty(null, _isLoading);
  }

  void popup(String message) {
    print("Popup: $message");
    if (_popupF != null)
      _popupF(message);
  }

  void _devUpdate() {
    print("Starting incremental update");
    _isLoading = true;
    parent.setDevState(this);

    fetch<Devices>("?since=${_devices.updateTime}")
      .then((ds) {
        print("Incremental update ok, n=${ds.devices.length}");
        _isLoading = false;
        _errorCount = 0;
        _devices = _devices.merge(ds);
        _dlc.applyDevices(_devices.devices, rebuildHint: _devices.structureChanged);
        parent.setDevState(this);
        _setTimer();
      }).catchError((err) {
        print("Incremental update failed, err=$err");
        _isLoading = false;
        if (_errorCount == maxErrorRetries) {
          parent.setDevState(DevStateEmpty(this, error: err.toString()));
        } else {
          if (_errorCount == 0)
            popup("Communications error (will retry soon): $err");
          _errorCount += 1;
          _setTimer();
        }
      });
  }

  void _setTimer() async {
    if (_devRefreshT != null)
      _devRefreshT.cancel();
    Settings settings = await readSettings();
    int s;
    if (_updateNeeded)
      s = settings.intervalUpdateS;
    else if (_errorCount == 0)
      s = settings.intervalMainS;
    else
      s = settings.intervalErrorRetryS;
    _updateNeeded = false;
    _devRefreshT = new Timer(Duration(seconds: s), () => _devUpdate());
  }

  void _init() {
    _setTimer();
  }

  void tryUpdateNow() {
    if (!_isLoading) _setTimer();
  }

  void cleanup() {
    if (_devRefreshT != null)
      _devRefreshT.cancel();
    //_devicesF = null;
  }
}

class DevStateEmpty extends DevState {
  String error;
  Future<void> devicesF;

  DevStateEmpty(DevState origin, {String error}):
        error = error,
        super.clone(origin) {
    _dlc.applyDevices(null, rebuildHint: true);
    Future.microtask(() => _init());
  }

  DevStateEmpty.init(DevStateNest parent):
        error = null,
        super(parent: parent, isLoading: false, updateNeeded: false) {
    Future.microtask(() => _init());
  }

  void _init() {
    if (error == null) {
      print("Starting full update");
      _isLoading = true;
      parent.setDevState(this);
      readConfig().then((ls) => _dlc.parseConfig(ls));
      devicesF = fetch<Devices>("")
        .then((ds) {
          print("Full update ok, n=${ds.devices.length}");
          _isLoading = false;
          error = null;
          parent.setDevState(DevStateNonEmpty(this, devices: ds));
        }).catchError((err) {
          print("Full update failed, err=$err");
          _isLoading = false;
          error = err.toString();
          parent.setDevState(this);
        });
    }
  }

  @override
  DevView getDeviceView(PopupF popupF) {
    return DevViewEmpty(error, _isLoading);
  }

  void tryUpdateNow() { }

  void cleanup() {
    devicesF = null;
  }
}

