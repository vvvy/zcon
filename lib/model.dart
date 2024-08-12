import 'package:flutter/cupertino.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:zcon/devstate.dart';
import 'package:zcon/i18n.dart';
import 'package:zcon/nv.dart';
import 'package:zcon/pdu.dart';
import 'package:zcon/pref.dart';
import 'package:zcon/nio.dart';


enum CommonModelEvents {
  AppPaused,
  AppResumed,
  RemoteReloadRequest,
  Reload,
  UpdateUI,
}

class ViewConfigUpdate { final ViewConfig viewConfig; ViewConfigUpdate(this.viewConfig); }
//class SettingsUpdate { final Settings settings; SettingsUpdate(this.settings); }

class L10nModel extends Model {
  final locales = LocaleSupport();

  void setLocale(OverriddenLocaleCode localeCode) {
    if (locales.setLocale(localeCode)) notifyListeners();
  }

  void rebuild() { notifyListeners(); }
}

class MainModel extends Model implements NetworkListener {
  DevState? devState;
  NVController? nvc;
  Settings? _settings;
  ViewConfig? _viewConfig;
  NioSender? _nioSender;
  FetchConfig? _fetchConfig;

  bool _networkIoActive = false;

  MainModel() {
    nvc = NVController(this);
  }

  static MainModel of(BuildContext context, {rebuildOnChange = false}) =>
      ScopedModel.of<MainModel>(context, rebuildOnChange: rebuildOnChange);

  Widget scoped(Widget child) => ScopedModel<MainModel>(model: this, child: child);

  Settings? get settings => _settings;
  ViewConfig? get viewConfig => _viewConfig;
  FetchConfig? get fetchConfig => _fetchConfig;

  NV? getNVbyLink(DeviceLink link, L10ns l10ns) {
    final device = devState!.getDeviceByLink(link);
    return (device != null) ? nvc!.getNV(device, l10ns) : null;
  }

  void setDevState(DevState newDevState) {
    if (devState != newDevState && devState != null) devState!.cleanup();
    devState = newDevState;
    notifyListeners();
  }

  void reload() {
    setDevState(DevStateEmpty.init(this));
  }

  void onNetworkEvent(NetworkIndication ind) {
    print("main thread received ni: ${ind}");
    switch (ind) {
      case FetchStart(isFull: final isFull):
        _networkIoActive = true;
        //devState?.isLoading = true;
        break;
      case FetchResult(isFull: final isFull, devices: final devices, error: final error):
        _networkIoActive = false;
        break;
      case CommandStart(id: final id):
        _networkIoActive = true;
        break;
      case CommandResult(id: final id, error: final error):
        _networkIoActive = false;
        break;
    }
    notifyListeners();
  }

  void init(L10nModel l10nModel) {
    _nioSender = startNio(this);
    reload();
    Future.microtask(() async {
      _settings = await readSettings();
      _fetchConfig = FetchConfig(url: _settings!.url,
          username: _settings!.username,
          password: _settings!.password
      );
      _nioSender!.submit(Configure(NioConfig(
          fetchConfig: _fetchConfig!,
          intervalMainS: _settings!.intervalMainS,
          intervalUpdateS: _settings!.intervalUpdateS,
          intervalErrorRetryS: _settings!.intervalErrorRetryS
      )));
      _viewConfig = await readViewConfig();
      l10nModel.setLocale(_settings!.localeCode);
      reload();
    });
  }

  void submit(dynamic event) {
    print("submit $event");
    if (event == CommonModelEvents.AppPaused) {
      _nioSender?.submit(Pause());
      setDevState(DevStateEmpty(devState!, error: AppError.appPaused()));
    } else if (event == CommonModelEvents.AppResumed) {
      _nioSender?.submit(Resume());
      setDevState(DevStateEmpty.init(this));
    } else if (event == CommonModelEvents.RemoteReloadRequest) {
      if (devState != null) devState!.flagNeedsUpdate();
    } else if (event == CommonModelEvents.UpdateUI) {
      notifyListeners();
    } else if (event == CommonModelEvents.Reload) {
      reload();
    } else if (event is DevState) {
      setDevState(event);
    } else if (event is ViewConfigUpdate) {
      _viewConfig = event.viewConfig;
      Future.microtask(() async { await writeViewConfig(event.viewConfig); });
      notifyListeners();
    } else if (event is Settings) {
      _settings = event;
      Future.microtask(() async { await writeSettings(event); });
      reload();
    } else {
      print("WARNING: Unhandled event: $event");
    }
  }
}
