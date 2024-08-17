import 'package:zcon/i18n.dart';
import 'package:zcon/pdu.dart';
import 'package:zcon/pref.dart';
import 'package:zcon/devlist.dart';
import 'package:zcon/constants.dart';

//------------------------------------------------------------------------------

sealed class Popup { }
class GenericPopup implements Popup { String text; GenericPopup(this.text); }
class CommErrorPopup implements Popup { AppError error; CommErrorPopup(this.error); }


//typedef void PopupF(PopupType type, dynamic detail);

sealed class DevView { }

class DevViewFull extends DevView {
  final DevList devices;
  //final bool isLoading;
  DevViewFull(this.devices);
}

class DevViewEmpty extends DevView {
  final AppError? error;
  //final bool isLoading;
  DevViewEmpty(this.error);
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
  AlertBuilder({
    required int failedFilterId,
    required int batteryFilterId,
    required int temperatureFilterId}):
        _alerts = [],
        _batteryFilterId = batteryFilterId,
        _failedFilterId = failedFilterId,
        _temperatureFilterId = temperatureFilterId;

  void processDevices(List<Device>? devices, Settings settings) {
    int failedCount = 0;
    int batteryCount = 0;
    int temperatureCount = 0;
    if (devices != null)
      for (Device device in devices) {
        if (device.deviceType == "battery" && device.metrics!.level < settings.batteryAlertLevel)
          batteryCount += 1;

        if (device.deviceType == "sensorMultilevel" && device.probeType == "temperature") {
          if (device.metrics!.level! < settings.tempLoBound || device.metrics!.level! > settings.tempHiBound)
            temperatureCount += 1;
        }

        if (device.metrics?.isFailed ?? false) failedCount += 1;
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

sealed class DevStateEvent { }

class DevicesUpdate implements DevStateEvent {
  final bool isFull;
  final Devices devices;
  DevicesUpdate(this.isFull, this.devices);
}

class DevicesUpdateError implements DevStateEvent {
  AppError error;
  DevicesUpdateError(this.error);
}

sealed class DevStateAction { }

class ErrorPopup implements DevStateAction {
  AppError error;
  ErrorPopup(this.error);
}

sealed class DevState {
  Device? getDeviceByLink(DeviceLink link);
  List<Device>? get devices;
  AppError? get error;

  static DevState initial() => DevStateEmpty._internal();

  (DevState, DevStateAction?) handleEvent(DevStateEvent event);
}

class DevStateNonEmpty extends DevState {
  Devices _devices;
  int _errorCount;

  DevStateNonEmpty._internal(Devices devices):
        _devices = devices,
        _errorCount = 0;

  @override
  List<Device>? get devices => _devices.devices;

  AppError? get error => null;

  @override
  Device? getDeviceByLink(DeviceLink link) {
    final d =_devices.devices;
    if (d != null) return link.getDevice(d);
    return null;
  }

  @override
  (DevState, DevStateAction?) handleEvent(DevStateEvent event) {
    switch (event) {
      case DevicesUpdate(isFull: final isFull, devices: final devices):
        if (isFull)
          _devices = devices;
        else
          _devices = _devices.merge(devices);
        _errorCount = 0;
        return (this, null);

      case DevicesUpdateError(error: final error):
        if (_errorCount >= Constants.maxErrorRetries) {
          return (DevStateEmpty._internal(error: AppError.convert(error)), null);
        } else {
          _errorCount += 1;
          return (this, (_errorCount == 1) ? ErrorPopup(AppError.convert(error)) : null);
        }
    }
  }
}

class DevStateEmpty extends DevState {
  AppError? _error;

  @override
  AppError? get error => _error;

  DevStateEmpty._internal({AppError? error}): _error = error;

  @override
  Device? getDeviceByLink(DeviceLink link) => null;

  @override
  List<Device>? get devices => null;

  @override
  (DevState, DevStateAction?) handleEvent(DevStateEvent event) {
    switch (event) {
      case DevicesUpdate(devices: final devices /*isFull: final isFull*/):
        return (DevStateNonEmpty._internal(devices), null);
      case DevicesUpdateError(error: final error):
        _error = error;
        return (this, null);
    }
  }
}


