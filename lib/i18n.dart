
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter_localizations/flutter_localizations.dart';
//import 'package:flutter_localizations/flutter_localizations.dart';

class L10ns {
  L10ns(Locale locale): _offset = locale.languageCode == 'ru' ? 1 : 0;
  final int _offset;

  static L10ns of(BuildContext context) => Localizations.of<L10ns>(context, L10ns);

  static Map<String, List<String>> _localizedValues = {
//    'ok': ['Ok', 'Есть'],
//    'cancel': ['Cancel', 'Отставить'],
    'reload': ['Reload', 'Перезагрузить'],
    'english': ['English', 'Английский'],
    'russian': ['Russian', 'Русский'],
    'systemDefined': ['<Defined by OS>', '<Задан системой>'],

    'userName': ['User name', 'Имя пользователя'],
    'password': ['Password', 'Пароль'],
  };

//  String get ok => _localizedValues['ok'][_offset];
//  String get cancel => _localizedValues['cancel'][_offset];
  String get reload => _localizedValues['reload'][_offset];
  String get english => _localizedValues['english'][_offset];
  String get russian => _localizedValues['russian'][_offset];
  String get systemDefined => _localizedValues['systemDefined'][_offset];

  String get userName => _localizedValues['userName'][_offset];
  String get password => _localizedValues['password'][_offset];
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