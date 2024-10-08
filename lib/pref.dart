import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zcon/constants.dart';
import 'package:zcon/devlist.dart';
import 'package:zcon/i18n.dart';

const
  k_url = 'url',
  k_username = 'username',
  k_password = 'password',
  k_intervalMainS = 'intervalMainS',
  k_intervalErrorRetryS = 'intervalErrorRetryS',
  k_intervalUpdateS = 'intervalUpdateS',
  k_localeCode = 'localeCode',
  k_visLevel = 'visLevel',
  k_config = 'config',
  k_batteryAlertLevel = 'batteryAlertLevel',
  k_tempLoBound = 'tempLoBound',
  k_tempHiBound = 'tempHiBound',
  k_setPointBlueCircleThreshold = 'setPointBlueCircleThreshold',
  k_batteryYellowCircleThreshold = 'batteryYellowCircleThreshold',
  k_tempYellowCircleThreshold = 'tempYellowCircleThreshold'
;

class ViewConfig {
  final List<String>? views;
  ViewConfig(this.views);
}

Future<ViewConfig> readViewConfig() async {
  print("readViewConfig");
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return ViewConfig(prefs.getStringList(k_config));
}

Future<void> writeViewConfig(ViewConfig viewConfig) async {
  print("writeViewConfig");
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setStringList(k_config, viewConfig.views!);
}

/// Returns the app config as a json-serialized string.
///
/// Password and locale fields are not included in the string.
Future<String> configToJson() async {
  Map<String, dynamic> m = Map();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  for (String k in prefs.getKeys())
    if (!{k_password, k_localeCode}.contains(k))
      m[k] = prefs.get(k);
  return jsonEncode(m);
}

/// Parses and stores the app config from a json-serialized string.
///
/// Password and locale fields are ignored.
Future<void> configFromJson(String configJson) async {
  Map<String, dynamic> m = jsonDecode(configJson);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  for(String key in {k_url, k_username})
    if (m.containsKey(key)) prefs.setString(key, m[key]);
  for(String key in {k_intervalMainS, k_intervalErrorRetryS, k_intervalUpdateS})
    if (m.containsKey(key)) prefs.setInt(key, m[key]);
  if (m.containsKey(k_config)) prefs.setStringList(k_config, <String>[for(var s in m[k_config]) s]);
}



class Settings {
  final String url;
  final String username;
  final String password;

  /// Interval between successive incremental updates
  final int intervalMainS;
  /// Interval between retries during error
  final int intervalErrorRetryS;
  /// Interval between a device command and the update (refresh) that follows it
  final int intervalUpdateS;
  /// Language setting
  final OverriddenLocaleCode localeCode;
  /// Device visibility setting
  final VisLevel visLevel;
  /// battery level alert threshold, in %%
  final int batteryAlertLevel;
  /// temperature normal range low bound (outside triggers alert)
  final double tempLoBound;
  /// temperature normal range high bound (outside triggers alert)
  final double tempHiBound;
  /// Thermostat set point blue circle indication threshold
  final double setPointBlueCircleThreshold;
  /// Battery yellow circle indication threshold
  final int batteryYellowCircleThreshold;
  /// Temperature yellow circle indication threshold
  final double tempYellowCircleThreshold;

  Settings({
    required this.url, required this.username, required this.password,
    this.intervalMainS = Constants.defaultIntervalMainS,
    this.intervalErrorRetryS = Constants.defaultIntervalErrorRetryS,
    this.intervalUpdateS = Constants.defaultIntervalUpdateS,
    this.localeCode = OverriddenLocaleCode.None,
    this.visLevel = VisLevel.All,
    this.batteryAlertLevel = Constants.defaultBatteryAlertLevel,
    this.tempLoBound = Constants.defaultTempLoBound,
    this.tempHiBound = Constants.defaultTempHiBound,
    this.setPointBlueCircleThreshold = Constants.defaultSetPointBlueCircleThreshold,
    this.batteryYellowCircleThreshold = Constants.defaultBatteryYellowCircleThreshold,
    this.tempYellowCircleThreshold = Constants.defaultTempYellowCircleThreshold,
  });
}

Future<Settings> readSettings() async {
  print("readSettings");
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return Settings(
      url: prefs.getString(k_url) ?? "",
      username: prefs.getString(k_username) ?? "",
      password: prefs.getString(k_password) ?? "",
      intervalMainS: prefs.getInt(k_intervalMainS) ?? Constants.defaultIntervalMainS,
      intervalErrorRetryS: prefs.getInt(k_intervalErrorRetryS) ?? Constants.defaultIntervalErrorRetryS,
      intervalUpdateS: prefs.getInt(k_intervalUpdateS) ?? Constants.defaultIntervalUpdateS,
      localeCode: OverriddenLocaleCodeSerDe.de(prefs.getString(k_localeCode)),
      visLevel: () {
        final l = prefs.getInt(k_visLevel) ?? 0;
        return VisLevel.values[(l >= 0 && l < VisLevel.values.length) ? l : 0];
      }(),
      batteryAlertLevel: prefs.getInt(k_batteryAlertLevel) ?? Constants.defaultBatteryAlertLevel,
      tempLoBound: prefs.getDouble(k_tempLoBound) ?? Constants.defaultTempLoBound,
      tempHiBound: prefs.getDouble(k_tempHiBound) ?? Constants.defaultTempHiBound,
      setPointBlueCircleThreshold: prefs.getDouble(k_setPointBlueCircleThreshold) ?? Constants.defaultSetPointBlueCircleThreshold,
      batteryYellowCircleThreshold: prefs.getInt(k_batteryYellowCircleThreshold) ?? Constants.defaultBatteryYellowCircleThreshold,
      tempYellowCircleThreshold: prefs.getDouble(k_tempYellowCircleThreshold) ?? Constants.defaultTempYellowCircleThreshold,
  );
}

Future<void> writeSettings(Settings settings) async {
  print("writeSettings");
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(k_url, settings.url);
  await prefs.setString(k_username, settings.username);
  await prefs.setString(k_password, settings.password);
  await prefs.setInt(k_intervalMainS, settings.intervalMainS);
  await prefs.setInt(k_intervalErrorRetryS, settings.intervalErrorRetryS);
  await prefs.setInt(k_intervalUpdateS, settings.intervalUpdateS);
  await prefs.setString(k_localeCode, OverriddenLocaleCodeSerDe.ser(settings.localeCode));
  await prefs.setInt(k_visLevel, settings.visLevel.index);
  await prefs.setInt(k_batteryAlertLevel, settings.batteryAlertLevel);
  await prefs.setDouble(k_tempLoBound, settings.tempLoBound);
  await prefs.setDouble(k_tempHiBound, settings.tempHiBound);
  await prefs.setDouble(k_setPointBlueCircleThreshold, settings.setPointBlueCircleThreshold);
  await prefs.setInt(k_batteryYellowCircleThreshold, settings.batteryYellowCircleThreshold);
  await prefs.setDouble(k_tempYellowCircleThreshold, settings.tempYellowCircleThreshold);
}

typedef Future<void> FVC(BuildContext context);

class Preferences extends StatefulWidget {
  final Settings _initSettings;
  final FVC? _masterEditor, _viewEditor;

  @override
  PreferencesState createState() {
    return PreferencesState(_initSettings, _masterEditor, _viewEditor);
  }

  Preferences(this._initSettings, this._masterEditor, this._viewEditor);
}

class PreferencesState extends State<Preferences> {
  final Settings initSettings;
  final FVC? _masterEditor, _viewEditor;
  OverriddenLocaleCode _localeCode;
  VisLevel _visLevel;

  final
      cUsername = TextEditingController(),
      cPassword = TextEditingController(),
      cUrl = TextEditingController(),
      cIntervalMainS = TextEditingController(),
      cBatteryAlertLevel = TextEditingController(),
      cTempLoBound = TextEditingController(),
      cTempHiBound = TextEditingController(),
      cSetPointBlueCircleThreshold = TextEditingController(),
      cBatteryYellowCircleThreshold = TextEditingController(),
      cTempYellowCircleThreshold = TextEditingController()
  ;

  final _formKey = GlobalKey<FormState>();

  PreferencesState(this.initSettings, this._masterEditor, this._viewEditor) :
        _localeCode = initSettings.localeCode,
        _visLevel = initSettings.visLevel
  {
    cUrl.text = initSettings.url;
    cUsername.text = initSettings.username;
    cPassword.text = initSettings.password;
    cIntervalMainS.text = initSettings.intervalMainS.toString();
    cBatteryAlertLevel.text = initSettings.batteryAlertLevel.toString();
    cTempLoBound.text = initSettings.tempLoBound.toString();
    cTempHiBound.text = initSettings.tempHiBound.toString();
    cSetPointBlueCircleThreshold.text = initSettings.setPointBlueCircleThreshold.toString();
    cBatteryYellowCircleThreshold.text = initSettings.batteryYellowCircleThreshold.toString();
    cTempYellowCircleThreshold.text = initSettings.tempYellowCircleThreshold.toString();
  }

  @override
  void initState() {
    super.initState();
  }

  static const _boldFont = TextStyle(fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    final materialLoc = matLoc(context);
    final myLoc = L10ns.of(context);
    final vrGeneric = (String? value) =>
      (value != null && value.isEmpty) ? myLoc.inputRequired : null;
    final vrDouble = (String? value) {
      if (value == null) return null;
      var iv = double.tryParse(value);
      var t = iv != null;
      if (!t) {
        return myLoc.double;
      }
      return null;
    };
    final vrPercent = (String? value) {
      if (value == null) return null;
      var iv = int.tryParse(value);
      var t = iv != null;
      t = t && iv >= 0;
      t = t && iv <= 100;
      if (!t) {
        return myLoc.int0to100;
      }
      return null;
    };

    return Form(
        key: _formKey,
        child: SingleChildScrollView(child: Dialog(
          child:
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(myLoc.url),
                  TextFormField(
                    controller: cUrl,
                    autocorrect: false,
                    validator: vrGeneric,
                  ),
                  Text(myLoc.userName),
                  TextFormField(
                    controller: cUsername,
                    autocorrect: false,
                    validator: vrGeneric,
                  ),
                  Text(myLoc.password),
                  TextFormField(
                    controller: cPassword,
                    autocorrect: false,
                    validator: vrGeneric,
                    obscureText: true,
                  ),
                  Text(myLoc.language),
                  DropdownButtonFormField(items: <DropdownMenuItem<OverriddenLocaleCode>>[
                    DropdownMenuItem<OverriddenLocaleCode>(value: OverriddenLocaleCode.None, child: Text(myLoc.systemDefined)),
                    DropdownMenuItem<OverriddenLocaleCode>(value: OverriddenLocaleCode.EN, child: Text(myLoc.english)),
                    DropdownMenuItem<OverriddenLocaleCode>(value: OverriddenLocaleCode.RU, child: Text(myLoc.russian)),
                  ],
                      value: _localeCode,
                      onChanged: (value) => setState(() { if (value != null) _localeCode = value; })
                  ),
                  if (_masterEditor != null || _viewEditor != null) ...(
                      <Widget>[
                        Divider(),
                        Text(myLoc.viewSettings, style: _boldFont),
                        Column(children: <Widget>[
                          if (_masterEditor != null)
                            ElevatedButton(child: Text(myLoc.editViewList), onPressed: () => _masterEditor(context)),
                          if(_viewEditor != null)
                            ElevatedButton(child: Text(myLoc.editCurrentView), onPressed: () => _viewEditor(context))
                        ])
                      ]
                  ),
                  Divider(),
                  Text(myLoc.advanced, style: _boldFont),
                  Text(myLoc.visLevel),
                  DropdownButtonFormField(items: <DropdownMenuItem<VisLevel>>[
                    DropdownMenuItem<VisLevel>(value: VisLevel.Visible, child: Text(myLoc.visVisible)),
                    DropdownMenuItem<VisLevel>(value: VisLevel.Invisible, child: Text(myLoc.visHidden)),
                    DropdownMenuItem<VisLevel>(value: VisLevel.All, child: Text(myLoc.visAll)),
                  ],
                      value:  _visLevel,
                      onChanged: (value) => { if (value != null) setState(() { _visLevel = value; }) }
                  ),
                  Text(myLoc.updateIntervalSeconds),
                  TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: cIntervalMainS,
                    validator: (value) {
                      if (value == null) return null;
                      var iv = int.tryParse(value);
                      var t = iv != null;
                      t = t && iv >= 5;
                      if (!t) {
                        return myLoc.intGt5;
                      }
                      return null;
                    },
                  ),
                  Divider(),
                  Text(myLoc.alerts, style: _boldFont),
                  Text(myLoc.batteryAlertLevel),
                  TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: cBatteryAlertLevel,
                    validator: vrPercent,
                  ),
                  Text(myLoc.tempLoBound),
                  TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: cTempLoBound,
                    validator: vrDouble,
                  ),
                  Text(myLoc.tempHiBound),
                  TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: cTempHiBound,
                    validator: vrDouble,
                  ),
                  Text(myLoc.visualThresholds, style: _boldFont),
                  Text(myLoc.batteryYellowCircleThreshold),
                  TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: cBatteryYellowCircleThreshold,
                    validator: vrPercent,
                  ),
                  Text(myLoc.setPointBlueCircleThreshold),
                  TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: cSetPointBlueCircleThreshold,
                    validator: vrDouble,
                  ),
                  Text(myLoc.tempYellowCircleThreshold),
                  TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: cTempYellowCircleThreshold,
                    validator: vrDouble,
                  ),
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              child: Text(materialLoc.cancelButtonLabel),
                              onPressed: () => Navigator.pop(context, null),
                            ),
                            TextButton(
                              child: Text(materialLoc.okButtonLabel),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  Navigator.pop(context, Settings(
                                    url: cUrl.text,
                                    username: cUsername.text,
                                    password: cPassword.text,
                                    intervalMainS: int.tryParse(cIntervalMainS.text) ?? Constants.defaultIntervalMainS,
                                    localeCode: _localeCode,
                                    visLevel: _visLevel,
                                    batteryAlertLevel: int.tryParse(cBatteryAlertLevel.text) ?? Constants.defaultBatteryAlertLevel,
                                    tempLoBound: double.tryParse(cTempLoBound.text) ?? Constants.defaultTempLoBound,
                                    tempHiBound: double.tryParse(cTempHiBound.text) ?? Constants.defaultTempHiBound,
                                    setPointBlueCircleThreshold: double.tryParse(cSetPointBlueCircleThreshold.text) ?? Constants.defaultSetPointBlueCircleThreshold,
                                    batteryYellowCircleThreshold: int.tryParse(cBatteryYellowCircleThreshold.text) ?? Constants.defaultBatteryYellowCircleThreshold,
                                    tempYellowCircleThreshold: double.tryParse(cTempYellowCircleThreshold.text) ?? Constants.defaultTempYellowCircleThreshold,
                                  ));
                                }
                              },
                            ),
                          ]
                      )
                  ),
                ]
              )
            ),
        ))
    );
  }
}

class JSONState extends State<JSON> {
  String _json;
  final cJSON = TextEditingController();
  JSONState(String json): _json = json;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    cJSON.text = _json;
  }

  @override
  Widget build(BuildContext context) {
    final materialLoc = matLoc(context);
    final myLoc = L10ns.of(context);

    // Build a Form widget using the _formKey we created above
    return Form(
      key: _formKey,
      child: SingleChildScrollView(child: Dialog(
        child:
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(myLoc.jsonConfig),
              TextFormField(
                controller: cJSON,
                minLines: 3,
                maxLines: 6,
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null) { return null; }
                  try { jsonDecode(value); return null; }
                  catch(_) { return myLoc.invalidJson; } },
              ),
              Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text(materialLoc.okButtonLabel),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(context, cJSON.text);
                        }
                      }
                    ),
                    TextButton(
                      child: Text(materialLoc.cancelButtonLabel),
                      onPressed: () {
                        Navigator.pop(context, null);
                      }
                    )
                  ]
                )
              )
            ]
          )
        ),
      ))
    );
  }
}
class JSON extends StatefulWidget {
  final String _json;
  JSON(String json): _json = json;

  @override
  JSONState createState() {
    return JSONState(_json);
  }
}