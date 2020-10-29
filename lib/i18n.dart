
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:zcon/devlist.dart';
import 'package:zcon/devstate.dart';

class L10ns {
  L10ns(Locale locale): _offset = locale.languageCode == 'ru' ? 1 : 0;
  final int _offset;

  static L10ns of(BuildContext context) => Localizations.of<L10ns>(context, L10ns);

  final/*static*/ Map<String, List<String>> _localizedValues = {
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
    //'': ['', ''],
    //'': ['', ''],
    //'': ['', ''],
    //'': ['', ''],

    'url': ['URL', 'URL'],
    'userName': ['User name', 'Имя пользователя'],
    'password': ['Password', 'Пароль'],
  };
  final List<String Function(String)> _error =
    [(msg) => "Error: $msg", (msg) => "Ошибка: $msg"];
  final List<String Function(String)> _errorNL =
    [(msg) => "ERROR:\n$msg", (msg) => "ОШИБКА:\n$msg"];
  final List<String Function(String)> _activating =
    [(title) => "Activating $title", (title) => "Активация: $title"];
  final List<String Function(String)> _updating =
    [(title) => "Updating $title", (title) => "Обновление: $title"];
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

  //String get ZZZ => _localizedValues['ZZZ'][_offset];
  //String get ZZZ => _localizedValues['ZZZ'][_offset];
  //String get ZZZ => _localizedValues['ZZZ'][_offset];

  String Function(String) get error => _error[_offset];
  String Function(String) get errorNL => _errorNL[_offset];
  String Function(String) get activating => _activating[_offset];
  String Function(String) get updating => _updating[_offset];
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

/// Helper function to extract MaterialLocalizations from the context
MaterialLocalizations matLoc(BuildContext context) =>
    Localizations.of<MaterialLocalizations>(context, MaterialLocalizations);