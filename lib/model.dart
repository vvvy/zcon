import 'package:flutter/cupertino.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:zcon/devstate.dart';
import 'package:zcon/i18n.dart';
import 'package:zcon/nv.dart';
import 'package:zcon/pdu.dart';
import 'package:zcon/pref.dart';
import 'package:zcon/nio.dart';

import 'devlist.dart';

sealed class ModelEvent { }

class AppPaused extends ModelEvent { }
class AppResumed extends ModelEvent { }
class ViewConfigUpdate extends ModelEvent { final ViewConfig viewConfig; ViewConfigUpdate(this.viewConfig); }
class SettingsUpdate extends ModelEvent { final Settings settings; SettingsUpdate(this.settings); }

class L10nModel extends Model {
  final locales = LocaleSupport();

  void setLocale(OverriddenLocaleCode localeCode) {
    if (locales.setLocale(localeCode)) notifyListeners();
  }

  void rebuild() { notifyListeners(); }
}

mixin DevListControllerMixin {
  MainModel get _model;
  final DevListController _dlc = DevListController();

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

  void refreshDLC({bool rebuildHint = true}) {
    if (_model.settings != null)
      _dlc.applyDevices(_model._devState.devices, _model.settings!.visLevel, rebuildHint: rebuildHint);
  }

  DevView getDeviceView() {
    return _dlc.isOnline ? DevViewFull(_dlc.list) : DevViewEmpty(_model._devState.error);
  }
}

class MainModel extends Model with DevListControllerMixin implements NetworkListener {
  L10nModel? _l10nModel;
  Settings? _settings;
  ViewConfig? _viewConfig;
  NioSender? _nioSender;
  bool _isNetworkIoActive = false;
  final AlertBuilder _alertBuilder  = AlertBuilder(
      failedFilterId: DevListController.getViewId(AppView.Failed),
      batteryFilterId: DevListController.getViewId(AppView.Battery),
      temperatureFilterId: DevListController.getViewId(AppView.Temperature)
  );
  int _commandN = 0;

  DevState _devState = DevState.initial();

  void Function(Popup popup) popupFn = (p) => print("default popup fn invoked on ${p}");

  MainModel get _model => this;
  List<Alert> get alerts => _alertBuilder.alertList;

  static MainModel of(BuildContext context, {rebuildOnChange = false}) =>
      ScopedModel.of<MainModel>(context, rebuildOnChange: rebuildOnChange);

  Widget scoped(Widget child) => ScopedModel<MainModel>(model: this, child: child);

  Settings? get settings => _settings;
  ViewConfig? get viewConfig => _viewConfig;
  bool get isNetworkIoActive => _isNetworkIoActive;

  void showPopup(Popup popup) => popupFn(popup);

  NV? getNVbyLink(DeviceLink link, L10ns l10ns) {
    final device = _devState.getDeviceByLink(link);
    return (device != null) ? getNV(device, l10ns) : null;
  }

  void exec(Command cmd, [String? title]) {
    _nioSender?.submit(ExecCommand(_commandN, cmd.c0, cmd.c1, cmd.c2, title: title));
    _commandN += 1;
  }

  void execCond(Command? cmd, [String? title]) {
    if (cmd != null) exec(cmd, title);
  }

  void reloadDevices() {
    _nioSender?.submit(Reload());
  }

  void handleEvent(DevStateEvent event) {
    final (devState, action) = _devState.handleEvent(event);
    _devState = devState;
    switch (action) {
      case null:
        break;
      case ErrorPopup(error: final error):
        showPopup(CommErrorPopup(error));
        break;
    }
  }

  void onNetworkEvent(NetworkIndication ind) {
    print("main thread received ni: ${ind}");
    switch (ind) {
      case FetchStart(/*isFull: final isFull*/):
        _isNetworkIoActive = true;
        break;
      case FetchResult(isFull: final isFull, devices: final devices, error: final error):
        _isNetworkIoActive = false;
        if (devices != null) {
          handleEvent(DevicesUpdate(isFull, devices));
          if (_settings !=null)
            _alertBuilder.processDevices(_devState.devices, _model.settings!);
          refreshDLC(rebuildHint: devices.structureChanged ?? false);
        } else if (error != null) {
          handleEvent(DevicesUpdateError(error));
          refreshDLC(rebuildHint: true);
          showPopup(CommErrorPopup(error));
        }
        break;
      case CommandStart(id: final id, title: final title):
        _isNetworkIoActive = true;
        showPopup(GenericPopup("Executing command[#${id}] ${title ?? ''}"));
        break;
      case CommandResult(id: final id, error: final error):
        _isNetworkIoActive = false;
        if (error != null) showPopup(GenericPopup("command[#${id}] error: ${error}"));
        break;
    }
    notifyListeners();
  }

  void onSettingsAvailable(Settings settings) {
    _settings = settings;
    _l10nModel?.setLocale(settings.localeCode);
    final fetchConfig = FetchConfig(url: _settings!.url,
        username: settings.username,
        password: settings.password
    );
    _nioSender!.submit(Configure(NioConfig(
        fetchConfig: fetchConfig,
        intervalMainS: settings.intervalMainS,
        intervalUpdateS: settings.intervalUpdateS,
        intervalErrorRetryS: settings.intervalErrorRetryS
    )));
  }

  void onViewConfigAvailable(ViewConfig viewConfig) {
    _viewConfig = viewConfig;
    _dlc.parseConfig(viewConfig);
  }

  void onInitializationError(AppError error) {
    print("InitializationError: ${error}");
    showPopup(CommErrorPopup(error));
  }

  void onAppError(AppError error) {
    print("AppError: ${error}");
    showPopup(CommErrorPopup(error));
  }

  void init(L10nModel l10nModel) {

    _nioSender = startNio(this);
    _l10nModel = l10nModel;

    Future.microtask(() async {
      try {
        onSettingsAvailable(await readSettings());
        onViewConfigAvailable(await readViewConfig());
        notifyListeners();
        print("init complete");
      } catch(err) {
        onInitializationError(AppError.convert(err));
      }
    });

  }

  void submit(ModelEvent event) {
    print("submit $event");
    switch (event) {
      case AppPaused():
        _nioSender?.submit(Pause());
        break;
      case AppResumed():
        _nioSender?.submit(Resume());
        break;
      case ViewConfigUpdate(viewConfig: final viewConfig):
        onViewConfigAvailable(viewConfig);
        notifyListeners();
        Future.microtask(() async {
          try {
            await writeViewConfig(viewConfig);
          } catch(err) {
            onAppError(AppError.convert(err));
          }
        });
        break;
      case SettingsUpdate(settings: final settings):
        onSettingsAvailable(settings);
        notifyListeners();
        Future.microtask(() async {
          try {
            await writeSettings(settings);
          } catch(err) {
            onAppError(AppError.convert(err));
          }
        });
        break;
    }
  }
}
