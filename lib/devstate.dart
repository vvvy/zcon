import 'dart:async';

import 'package:zcon/i18n.dart';
import 'package:zcon/pdu.dart';
import 'package:zcon/pref.dart';
import 'package:zcon/devlist.dart';
import 'package:zcon/constants.dart';
import 'package:zcon/model.dart';

//------------------------------------------------------------------------------
enum PopupType {
  CommErrorTransient
}

typedef void PopupF(PopupType type, dynamic detail);

abstract class DevView { }

class DevViewFull extends DevView {
  final DevList devices;
  final bool isLoading;
  DevViewFull(this.devices, this.isLoading);
}

class DevViewEmpty extends DevView {
  final AppError error;
  final bool isLoading;
  DevViewEmpty(this.error, this.isLoading);
}

//------------------------------------------------------------------------------
enum AlertType { Temperature, Battery, Failed }

class Alert {
  final AlertType type;
  final int count;
  final int filterId;
  Alert(this.type, this.count, [this.filterId = -1]);
}

class AlertBuilder {
  List<Alert> _alerts;
  final int _failedFilterId;
  final int _batteryFilterId;
  final int _temperatureFilterId;
  AlertBuilder({int failedFilterId, int batteryFilterId, int temperatureFilterId}):
        _alerts = [],
        _batteryFilterId = batteryFilterId,
        _failedFilterId = failedFilterId,
        _temperatureFilterId = temperatureFilterId;

  void processDevices(List<Device> devices) {
    int failedCount = 0;
    int batteryCount = 0;
    int temperatureCount = 0;
    for (Device device in devices) {
      if (device.deviceType == "battery" && device.metrics.level < Constants.batteryAlertLevel)
        batteryCount += 1;

      if (device.deviceType == "sensorMultilevel" && device.probeType == "temperature") {
        if (device.metrics.level < Constants.tempLoBound || device.metrics.level > Constants.tempHiBound)
          temperatureCount += 1;
      }

      if (device.metrics != null && device.metrics.isFailed != null && device.metrics.isFailed)
        failedCount += 1;
    }
    _alerts = [];
    if (temperatureCount > 0)
      _alerts.add(Alert(AlertType.Temperature, temperatureCount, _temperatureFilterId));
    if (failedCount > 0)
      _alerts.add(Alert(AlertType.Failed, failedCount, _failedFilterId));
    if (batteryCount > 0)
      _alerts.add(Alert(AlertType.Battery,batteryCount, _batteryFilterId));
  }

  List<Alert> get alertList => _alerts;
}

abstract class DevStateNest {
  void setDevState(DevState state);
}

abstract class DevState {
  final MainModel _model;
  final DevListController _dlc;
  final AlertBuilder _alertBuilder;
  bool _isLoading;
  bool _updateNeeded;

  bool get isLoading => _isLoading;
  int getFilter() => _dlc.current;
  List<IdName<int>> getAvailableFilters(ViewNameTranslator vnt) => _dlc.getMaster(vnt);
  void setFilter(int current) {
    _dlc.current = current;
    //TODO move _current under separate persistence key
    // (so we don't write entire config when moving between views)
    _model.submit(ViewConfigUpdate(_dlc.makeConfig()));
    //writeConfig(_dlc.makeConfig()).then((_) => parent.setDevState(this));
  }
  bool get listsOnline => _dlc.isOnline;
  bool get isListEditable => _dlc.isListEditable;
  List<ReorderListItem<String>> startEditList() => _dlc.startEditList();
  void endEditList(List<ReorderListItem<String>> result) {
    _dlc.endEditList(result);
    _model.submit(ViewConfigUpdate(_dlc.makeConfig()));
    //writeConfig(_dlc.makeConfig()).then((_) => parent.setDevState(this));
  }
  List<ReorderListItem<int>> startEditMaster(ViewNameTranslator vnt) => _dlc.startEditMaster(vnt);
  void endEditMaster(List<ReorderListItem<int>> result) {
    _dlc.endEditMaster(result);
    _model.submit(ViewConfigUpdate(_dlc.makeConfig()));
    //writeConfig(_dlc.makeConfig()).then((_) => parent.setDevState(this));
  }
  DevView getDeviceView(PopupF popupF);
  List<Alert> get alerts => _alertBuilder.alertList;
  void flagNeedsUpdate() {
    _updateNeeded = true;
    tryUpdateNow();
  }
  void tryUpdateNow();
  void cleanup();
  DevState(this._model, this._isLoading, this._updateNeeded):
        _alertBuilder = AlertBuilder(
            failedFilterId: DevListController.getViewId(View.Failed),
            batteryFilterId: DevListController.getViewId(View.Battery),
            temperatureFilterId: DevListController.getViewId(View.Temperature)
        ),
        _dlc = new DevListController();

  DevState.clone(DevState prev):
        _model = prev._model,
        _isLoading = prev._isLoading,
        _updateNeeded = prev._updateNeeded,
        _alertBuilder = prev._alertBuilder,
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
        super.clone(origin)
  {
    _dlc.applyDevices(devices.devices, _model.settings.visLevel, rebuildHint: true);
    Future.microtask(() => _init());
  }

  @override
  DevView getDeviceView(PopupF popupF) {
    _popupF = popupF;
    return _dlc.isOnline ? DevViewFull(_dlc.list, _isLoading) : DevViewEmpty(null, _isLoading);
  }

  void popup(PopupType type, [AppError error]) {
    print("Popup: $type $error");
    if (_popupF != null) _popupF(type, error);
  }

  void _devUpdate() async {
    print("Starting incremental update");
    _isLoading = true;
    //parent.setDevState(this);
    _model.submit(CommonModelEvents.UpdateUI);

    try {
      final ds = await fetch<Devices>("?since=${_devices.updateTime}", _model.settings);
      print("Incremental update ok, n=${ds.devices.length}");
      _isLoading = false;
      _errorCount = 0;
      _devices = _devices.merge(ds);
      _alertBuilder.processDevices(_devices.devices);
      _dlc.applyDevices(
          _devices.devices, _model.settings.visLevel, rebuildHint: _devices.structureChanged
      );
      _model.submit(CommonModelEvents.UpdateUI);
      _setTimer();
    } catch(err) {
      print("Incremental update failed, err=$err");
      _isLoading = false;
      if (_errorCount == Constants.maxErrorRetries) {
        _model.submit(DevStateEmpty(this, error: AppError.convert(err)));
      } else {
        if (_errorCount == 0)
          popup(PopupType.CommErrorTransient, AppError.convert(err));
        _errorCount += 1;
        _setTimer();
      }
    }
  }

  void _setTimer() async {
    if (_devRefreshT != null)
      _devRefreshT.cancel();
    //Settings settings = await readSettings();
    final settings = _model.settings;
    if (settings == null) {
      print("ERROR: DevStateNonEmpty: unable to update, settings == null (in _setTimer())");
      return;
    }
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
  }
}

class DevStateEmpty extends DevState {
  AppError error;
  Future<void> devicesF;

  DevStateEmpty(DevState origin, {AppError error}):
        error = error,
        super.clone(origin) {
    _dlc.applyDevices(null, _model.settings.visLevel, rebuildHint: true);
    initCond();
  }

  DevStateEmpty.init(MainModel model):
        error = null,
        super(model, false, false) {
    initCond();
  }

  DevStateEmpty.init2(DevState origin):
        error = null,
        super.clone(origin) {
    initCond();
  }

  void initCond() {
    if (_model.settings != null && _model.viewConfig != null && error == null)
      Future.microtask(() => _init(_model.settings, _model.viewConfig));
  }

  void _init(Settings settings, ViewConfig viewConfig) async {
    print("Starting full update");
    _isLoading = true;
    _model.submit(CommonModelEvents.UpdateUI);
    _dlc.parseConfig(viewConfig);

    devicesF = () async {
      try {
        final ds = await fetch<Devices>("", settings);
        print("Full update ok, n=${ds.devices.length}");
        _isLoading = false;
        error = null;
        _alertBuilder.processDevices(ds.devices);
        _model.submit(DevStateNonEmpty(this, devices: ds));
      } catch(err) {
        print("Full update failed, err=$err");
        _isLoading = false;
        error = AppError.convert(err);
        _model.submit(CommonModelEvents.UpdateUI);
      }
    }();
  }

  @override
  DevView getDeviceView(PopupF _popupF) {
    return DevViewEmpty(error, _isLoading);
  }

  void tryUpdateNow() { }

  void cleanup() {
    devicesF = null;
  }
}

