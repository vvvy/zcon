
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:zcon/devlist.dart';
import 'package:zcon/devstate.dart';

class L10ns {
  L10ns(Locale locale): _offset = locale.languageCode == 'ru' ? 1 : 0;
  final int _offset;

  static L10ns of(BuildContext context) => Localizations.of<L10ns>(context, L10ns);

  static final Map<String, List<String>> _localizedValues = {
    'reload': ['Reload', 'Перезагрузить'],
    'english': ['English', 'Английский'],
    'russian': ['Russian', 'Русский'],
    'systemDefined': ['<Defined by OS>', '<Задан системой>'],
    'language': ['Language', 'Язык приложения'],
    'advanced': ['Advanced', 'Для продвинутых'],
    'viewSettings': ['View settings', 'Настойки представлений'],
    'editViewList': ['Edit view list', 'Редактировать список представлений'],
    'editCurrentView': ['Edit current view', 'Редактировать текущее представление'],
    'updateIntervalSeconds': ['Update interval, seconds', 'Интервал обновления (сек)'],
    'visLevel': ['Device visibility level', 'Уровень видимости устройств'],
    'visVisible': ['Visible', 'Видимые'],
    'visHidden': ['Hidden', 'Скрытые'],
    'visAll': ['All', 'Все'],
    'intGt5': ['Must be an int >= 5', 'Должно быть целым >= 5'],
    'int0to100': ['Must be an integer between 0 and 100', 'Должно быть целым в диапазоне от 0 до 100'],
    'double': ['Must be a double', 'Должно быть вещественным числом'],
    'inputRequired': ['Please enter value', 'Обязательное поле'],
    'jsonConfig': ['JSON config', 'Конфигурация (JSON)'],
    'invalidJson': ['Invalid JSON', 'Невалидный JSON'],
    'settings': ['Settings', 'Настройки'],
    'editConfigAdvanced': ['Edit config (advanced)', 'Конфигурация (для продвинутых)'],
    'alerts': ['Alerts', 'Оповещения'],
    'reorderHint': [
      'Drag and drop to reorder. Long press on an item to start dragging. '+
        'Drop below the separator to hide and vice versa. Drop to panels to move to top/bottom.',
      'Схватить и перетащить для изменения порядка. Долгое нажатие на объект для начала перетаскивания. ' +
        'Перетащить под разделитель, чтобы скрыть, и наоборот. Перетащить на панели для передвижения в начало/в конец.'
    ],
    'toTop': ['To top', 'В начало'],
    'toBottom': ['To bottom', 'В конец'],
    'open': ['Open', 'ОТКР'],
    'closed': ['Closed', 'ЗАКР'],

    'goToPosition': ['Go to position', 'Перейти'],
    'increase': ['Increase', 'Шаг вверх'],
    'startUp': ['Start up', 'Начать движение вверх'],
    'stop': ['Stop', 'Остановить'],
    'startDown': ['Start down', 'Начать движение вниз'],
    'decrease': ['Decrease', 'Шаг вниз'],


    //Error messages
    AppError.k_urlNeeded: ['URL not set - please set it via settings', 'URL не установлена - необходимо установить через Настройки'],
    AppError.k_urlInvalid: ['Invalid URL', 'URL не валиден'],
    AppError.k_appPaused: ['Application paused', 'Приложение приостановлено'],
    //'': ['', ''],
    //'': ['', ''],
    //'': ['', ''],
    //'': ['', ''],
    //'': ['', ''],
    //'': ['', ''],

    'url': ['URL', 'URL'],
    'userName': ['User name', 'Имя пользователя'],
    'password': ['Password', 'Пароль'],

    'batteryAlertLevel': ['Low battery level, %', 'Низкий уровень батареи, %' ],
    'tempLoBound': ['Low temperature, C/F', 'Низкая температура, C/F'],
    'tempHiBound': ['High temperature, C/F', 'Высокая температура, C/F'],

    'visualThresholds': ['Color circle thresholds', 'Пороги цветовой окраски'],
    'setPointBlueCircleThreshold': ['Set point: blue, C/F', 'Термостат: голубой, C/F'],
    'batteryYellowCircleThreshold': ['Battery: yellow, %', 'Батарея: желтый, %'],
    'tempYellowCircleThreshold': ['Temperature: yellow, C/F', 'Температура: желтый, C/F'],
  };

  static final Map<String, List<String Function(String)>> _localizedValuesFSS = {
    'error': [(msg) => "Error: $msg", (msg) => "Ошибка: $msg"],
    'errorNL': [(msg) => "ERROR:\n$msg", (msg) => "ОШИБКА:\n$msg"],
    'commErrorTransient': [(msg) => "Communications error (will retry soon): $msg", (msg) => "Ошибка коммуникаций: $msg"],
    'activating': [(title) => "Activating $title", (title) => "Активация: $title"],
    'updating': [(title) => "Updating $title", (title) => "Обновление: $title"],
    AppError.k_zaHttpError: [(msg) => "Z-Way API: HTTP $msg", (msg) => "API Z-Way: HTTP $msg"],
    AppError.k_zaAppError: [(msg) => "Z-Way API: [Application] $msg", (msg) => "API Z-Way: [Приложение] $msg"],
  };

  final List<String Function(String, bool)> _settingOnOff =
    [(title, isOn) => "Setting $title ${isOn?'on':'off'}", (title, isOn) => "$title => ${isOn?'ВКЛ':'выкл'}"];
  final List<String Function(String, dynamic)> _settingLevel =
    [(title, level) => "Setting level of $title to $level", (title, level) => "Уровень $title => $level"];
  final List<String Function(Duration)> _elapsed = [
    (diff) {
      final diffSec = diff.inSeconds;
      if (diffSec >= 3600 * 24) return "${diff.inDays}d ago";
      if (diffSec >= 3600) return "${diff.inHours}h ago";
      if (diffSec >= 60) return "${diff.inMinutes}min ago";
      return "${diffSec}s ago";
    },
    (diff) {
      final diffSec = diff.inSeconds;
      if (diffSec >= 3600 * 24) return "${diff.inDays}дн назад";
      if (diffSec >= 3600) return "${diff.inHours}ч назад";
      if (diffSec >= 60) return "${diff.inMinutes}мин назад";
      return "$diffSecсек назад";
    }
  ];

  final Map<AlertType, List<String>> _alertTypes = {
    AlertType.Temperature: ['temperature', 'температура'],
    AlertType.Battery: ['battery', 'батарея'],
    AlertType.Failed: ['failed', 'отказ'],
  };

  final List<Map<View, String>> _viewNames = [
    {
      View.All: "All",
      View.Temperature: "Temperature",
      View.Thermostats: "Thermostats",
      View.Scene: "Scene",
      View.Switches: "Switches",
      View.Blinds: "Blinds",
      View.Battery: "Battery",
      View.Failed: "Failed",
      View.Custom1: "Custom1",
      View.Custom2: "Custom2",
      View.Custom3: "Custom3",
      View.Custom4: "Custom4",
      View.Custom5: "Custom5",
    },{
      View.All: "Все",
      View.Temperature: "Температура",
      View.Thermostats: "Термостаты",
      View.Scene: "Сценарии",
      View.Switches: "Выключатели",
      View.Blinds: "Жалюзи",
      View.Battery: "Батареи",
      View.Failed: "Отказы",
      View.Custom1: "Коллекция1",
      View.Custom2: "Коллекция2",
      View.Custom3: "Коллекция3",
      View.Custom4: "Коллекция4",
      View.Custom5: "Коллекция5",
    }
  ];

//  String get ok => _localizedValues['ok'][_offset];
//  String get cancel => _localizedValues['cancel'][_offset];
  String get reload => _localizedValues['reload'][_offset];
  String get url => _localizedValues['url'][_offset];
  String get userName => _localizedValues['userName'][_offset];
  String get password => _localizedValues['password'][_offset];
  String get english => _localizedValues['english'][_offset];
  String get russian => _localizedValues['russian'][_offset];
  String get systemDefined => _localizedValues['systemDefined'][_offset];
  String get language => _localizedValues['language'][_offset];
  String get advanced => _localizedValues['advanced'][_offset];
  String get viewSettings => _localizedValues['viewSettings'][_offset];
  String get editViewList => _localizedValues['editViewList'][_offset];
  String get editCurrentView => _localizedValues['editCurrentView'][_offset];
  String get updateIntervalSeconds => _localizedValues['updateIntervalSeconds'][_offset];
  String get intGt5 => _localizedValues['intGt5'][_offset];
  String get inputRequired => _localizedValues['inputRequired'][_offset];

  String get jsonConfig => _localizedValues['jsonConfig'][_offset];
  String get invalidJson => _localizedValues['invalidJson'][_offset];
  String get settings => _localizedValues['settings'][_offset];
  String get editConfigAdvanced => _localizedValues['editConfigAdvanced'][_offset];
  String get alerts => _localizedValues['alerts'][_offset];
  String get reorderHint => _localizedValues['reorderHint'][_offset];
  String get toTop => _localizedValues['toTop'][_offset];
  String get toBottom => _localizedValues['toBottom'][_offset];

  String get open => _localizedValues['open'][_offset];
  String get closed => _localizedValues['closed'][_offset];
  String get visLevel => _localizedValues['visLevel'][_offset];
  String get visVisible => _localizedValues['visVisible'][_offset];
  String get visHidden => _localizedValues['visHidden'][_offset];
  String get visAll => _localizedValues['visAll'][_offset];

  String get goToPosition => _localizedValues['goToPosition'][_offset];
  String get increase => _localizedValues['increase'][_offset];
  String get startUp => _localizedValues['startUp'][_offset];
  String get stop => _localizedValues['stop'][_offset];
  String get startDown => _localizedValues['startDown'][_offset];
  String get decrease => _localizedValues['decrease'][_offset];

  String get batteryAlertLevel => _localizedValues['batteryAlertLevel'][_offset];
  String get tempLoBound => _localizedValues['tempLoBound'][_offset];
  String get tempHiBound => _localizedValues['tempHiBound'][_offset];

  String get int0to100 => _localizedValues['int0to100'][_offset];
  String get double => _localizedValues['double'][_offset];

  String get visualThresholds => _localizedValues['visualThresholds'][_offset];
  String get setPointBlueCircleThreshold => _localizedValues['setPointBlueCircleThreshold'][_offset];
  String get tempYellowCircleThreshold => _localizedValues['tempYellowCircleThreshold'][_offset];
  String get batteryYellowCircleThreshold => _localizedValues['batteryYellowCircleThreshold'][_offset];

  //String get ZZZ => _localizedValues['ZZZ'][_offset];
  //String get ZZZ => _localizedValues['ZZZ'][_offset];
  //String get ZZZ => _localizedValues['ZZZ'][_offset];

  String _errorString(String Function(String) envelope, AppError err) {
    if (_localizedValues.containsKey(err.errCode))
      return envelope(_localizedValues[err.errCode][_offset]);
    else if (_localizedValuesFSS.containsKey(err.errCode))
      return envelope(_localizedValuesFSS[err.errCode][_offset](err.extraMessage));
    else
      return envelope(err.extraMessage);
  }
  String Function(AppError err) get error =>
          (err) => _errorString(_localizedValuesFSS['error'][_offset], err);
  String Function(AppError err) get errorNL =>
          (err) => _errorString(_localizedValuesFSS['errorNL'][_offset], err);
  //String Function(String) get error => _error[_offset];
  //String Function(String) get errorNL => _localizedValuesFSS['errorNL'][_offset];

  String Function(PopupType type, dynamic detail) get popup => (type, detail) {
    switch(type) {
      case PopupType.CommErrorTransient:
        return _errorString(_localizedValuesFSS['commErrorTransient'][_offset], detail as AppError);
      default:
        print("ERROR: Unhandled PopupType in L10ns: $type");
        return "[$type]";
    }
  };

  String Function(String) get activating => _localizedValuesFSS['activating'][_offset];
  String Function(String) get updating => _localizedValuesFSS['updating'][_offset];
  //String Function(String) get errorNL => _errorNL[_offset];
  //String Function(String) get activating => _activating[_offset];
  //String Function(String) get updating => _updating[_offset];
  String Function(String, bool) get settingOnOff => _settingOnOff[_offset];
  String Function(String, dynamic) get settingLevel => _settingLevel[_offset];
  String Function(Duration) get elapsed => _elapsed[_offset];
  String Function(Alert) get alertText => (a) => "${a.count}: ${_alertTypes[a.type][_offset]}";
  ViewNameTranslator get viewNameOf => (id) =>_viewNames[_offset][id];
}

class L10nsDelegate extends LocalizationsDelegate<L10ns> {
  const L10nsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ru'].contains(locale.languageCode);

  @override
  Future<L10ns> load(Locale locale) {
    return SynchronousFuture<L10ns>(L10ns(locale));
  }

  @override
  bool shouldReload(L10nsDelegate old) => false;

  static const L10nsDelegate delegate = L10nsDelegate();
}

enum OverriddenLocaleCode { None, EN, RU }

class OverriddenLocaleCodeSerDe  {
  static OverriddenLocaleCode de(String input) {
    switch (input) {
      case 'EN':
        return OverriddenLocaleCode.EN;
      case 'RU':
        return OverriddenLocaleCode.RU;
      default:
        return OverriddenLocaleCode.None;
    }
  }

  static String ser(OverriddenLocaleCode lc) {
    switch (lc) {
      case OverriddenLocaleCode.EN:
        return 'EN';
      case OverriddenLocaleCode.RU:
        return 'RU';
      default:
        return '-';
    }
  }
}

const localeEN = Locale('en', '');
const localeRU = Locale('ru', '');
const supportedLocales = [localeEN, localeRU];

Locale _localeFromCode(OverriddenLocaleCode lc) {
  switch(lc) {
    case OverriddenLocaleCode.EN: return localeEN;
    case OverriddenLocaleCode.RU: return localeRU;
    default: return null;
  }
}

class OverriddenL10nsDelegate extends L10nsDelegate {
  final Locale _overriddenLocale;
  const OverriddenL10nsDelegate(this._overriddenLocale);

  @override
  bool isSupported(Locale locale) => _overriddenLocale != null;

  @override
  Future<L10ns> load(Locale locale) => super.load(_overriddenLocale);

  @override
  bool shouldReload(L10nsDelegate old) => true;

  OverriddenL10nsDelegate fromCode(OverriddenLocaleCode lc) {
    final loc = _localeFromCode(lc);
    return (_overriddenLocale != loc) ? OverriddenL10nsDelegate(loc) : this;
  }
}

class OverriddenMaterialDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  final Locale _overriddenLocale;
  final LocalizationsDelegate<MaterialLocalizations> _super =
      GlobalMaterialLocalizations.delegate;
  const OverriddenMaterialDelegate(this._overriddenLocale);

  @override
  bool isSupported(Locale locale) => _overriddenLocale != null;

  @override
  Future<MaterialLocalizations> load(Locale locale) => _super.load(_overriddenLocale);

  @override
  bool shouldReload(LocalizationsDelegate<MaterialLocalizations> old) => true;

  OverriddenMaterialDelegate fromCode(OverriddenLocaleCode lc) {
    final loc = _localeFromCode(lc);
    return (_overriddenLocale != loc) ? OverriddenMaterialDelegate(loc) : this;
  }
}

class OverriddenWidgetsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  final Locale _overriddenLocale;
  final LocalizationsDelegate<WidgetsLocalizations> _super =
      GlobalWidgetsLocalizations.delegate;
  const OverriddenWidgetsDelegate(this._overriddenLocale);

  @override
  bool isSupported(Locale locale) => _overriddenLocale != null;

  @override
  Future<WidgetsLocalizations> load(Locale locale) => _super.load(_overriddenLocale);

  @override
  bool shouldReload(LocalizationsDelegate<WidgetsLocalizations> old) => true;

  OverriddenWidgetsDelegate fromCode(OverriddenLocaleCode lc) {
    final loc = _localeFromCode(lc);
    return (_overriddenLocale != loc) ? OverriddenWidgetsDelegate(loc) : this;
  }
}


class LocaleSupport {
  var l10nsDelegate = OverriddenL10nsDelegate(null);
  var materialsDelegate = OverriddenMaterialDelegate(null);
  var widgetsDelegate = OverriddenWidgetsDelegate(null);

  List<LocalizationsDelegate<dynamic>> get list =>
      [l10nsDelegate, materialsDelegate, widgetsDelegate, L10nsDelegate.delegate];

  /// Handle possible locale change after settings dialog
  ///
  /// returns true if notifyListeners needed
  bool setLocale(OverriddenLocaleCode localeCode) {
    var nl = false;
    {
      final newDelegate = l10nsDelegate.fromCode(localeCode);
      if (newDelegate != l10nsDelegate) {
        l10nsDelegate = newDelegate;
        nl = true;
      }
    }{
      final newDelegate = materialsDelegate.fromCode(localeCode);
      if (newDelegate != materialsDelegate) {
        materialsDelegate = newDelegate;
        nl = true;
      }
    }{
      final newDelegate = widgetsDelegate.fromCode(localeCode);
      if (newDelegate != widgetsDelegate) {
        widgetsDelegate = newDelegate;
        nl = true;
      }
    }
    return nl;
  }
}

class AppError {
  final String errCode;
  final String extraMessage;

  static const k_urlNeeded = 'urlNeeded';
  static const k_urlInvalid = 'urlInvalid';
  static const k_appPaused = 'appPaused';
  static const k_zaHttpError = 'zaHttpError';
  static const k_zaAppError = 'zaAppError';

//  static const k_ = '';
//  static const k_ = '';
//  static const k_ = '';

  AppError(this.errCode, this.extraMessage);

  AppError.urlNeeded(): this(k_urlNeeded, '');
  AppError.urlInvalid(): this(k_urlInvalid, '');
  AppError.appPaused(): this(k_appPaused, '');
  AppError.zaHttpError(int statusCode, String reasonPhrase): this(k_zaHttpError, "$statusCode $reasonPhrase");
  AppError.zaAppError(int code, String message): this(k_zaAppError, "$code $message");

  factory AppError.convert(dynamic source) {
    if (source is AppError) return source;
    return AppError("unknown", source.toString());
  }
}

/// Helper function to extract MaterialLocalizations from the context
MaterialLocalizations matLoc(BuildContext context) =>
    Localizations.of<MaterialLocalizations>(context, MaterialLocalizations);