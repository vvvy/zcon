import 'package:scoped_model/scoped_model.dart';
import 'devstate.dart';
import 'i18n.dart';
import 'nv.dart';
import 'pref.dart';


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

class MainModel extends Model {
  DevState devState;
  NVController nvc;
  Settings _settings;
  ViewConfig _viewConfig;

  MainModel() {
    this.nvc = NVController(this);
  }

  Settings get settings => _settings;
  ViewConfig get viewConfig => _viewConfig;

  void setDevState(DevState newDevState) {
    if (devState != newDevState && devState != null) devState.cleanup();
    devState = newDevState;
    notifyListeners();
  }

  void reload() {
    setDevState(DevStateEmpty.init(this));
  }

  void init(L10nModel l10nModel) {
    reload();
    Future.microtask(() async {
      _settings = await readSettings();
      _viewConfig = await readViewConfig();
      l10nModel.setLocale(_settings.localeCode);
      reload();
    });
  }

  void submit(dynamic event) {
    print("submit $event");
    if (event == CommonModelEvents.AppPaused) {
      setDevState(DevStateEmpty(devState, error: "Application paused"));
    } else if (event == CommonModelEvents.AppResumed) {
      setDevState(DevStateEmpty.init(this));
    } else if (event == CommonModelEvents.RemoteReloadRequest) {
      if (devState != null) devState.flagNeedsUpdate();
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
