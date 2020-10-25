import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


const
  k_url = 'url',
  k_username = 'username',
  k_password = 'password',
  k_intervalMainS = 'intervalMainS',
  k_intervalErrorRetryS = 'intervalErrorRetryS',
  k_intervalUpdateS = 'intervalUpdateS',
  k_config = 'config';

Future<List<String>> readConfig() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(k_config);
}

Future<void> writeConfig(List<String> configRaw) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setStringList(k_config, configRaw);
}

/// Returns the app config as a json-serialized string.
///
/// Password fields are not included in the string.
Future<String> configToJson() async {
  Map<String, dynamic> m = Map();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  for (String k in prefs.getKeys())
    if (k != k_password)
      m[k] = prefs.get(k);
  return jsonEncode(m);
}

/// Parses and stores the app config from a json-serialized string.
///
/// Password fields are ignored.
Future<void> configFromJson(String configJson) async {
  Map<String, dynamic> m = jsonDecode(configJson);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  for(String key in {k_url, k_username})
    if (m.containsKey(key)) prefs.setString(key, m[key]);
  for(String key in {k_intervalMainS, k_intervalErrorRetryS, k_intervalUpdateS})
    if (m.containsKey(key)) prefs.setInt(key, m[key]);
  if (m.containsKey(k_config)) prefs.setStringList(k_config, <String>[for(var s in m[k_config]) s]);
}

const _intervalMainS = 60;
const _intervalErrorRetryS = 60;
const _intervalUpdateS = 5;

class Settings {
  final String url;
  final String username;
  final String password;

  final int intervalMainS;
  final int intervalErrorRetryS;
  final int intervalUpdateS;

  Settings({
    this.url, this.username, this.password,
    this.intervalMainS: _intervalMainS,
    this.intervalErrorRetryS: _intervalErrorRetryS,
    this.intervalUpdateS: _intervalUpdateS
  });
}

Future<Settings> readSettings() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return Settings(
      url: prefs.getString(k_url) ?? "",
      username: prefs.getString(k_username) ?? "",
      password: prefs.getString(k_password) ?? "",
      intervalMainS: prefs.getInt(k_intervalMainS) ?? _intervalMainS,
      intervalErrorRetryS: prefs.getInt(k_intervalErrorRetryS) ?? _intervalErrorRetryS,
      intervalUpdateS: prefs.getInt(k_intervalUpdateS) ?? _intervalUpdateS
  );
}

Future<void> writeSettings(Settings settings) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(k_url, settings.url);
  await prefs.setString(k_username, settings.username);
  await prefs.setString(k_password, settings.password);
  await prefs.setInt(k_intervalMainS, settings.intervalMainS);
  await prefs.setInt(k_intervalErrorRetryS, settings.intervalErrorRetryS);
  await prefs.setInt(k_intervalUpdateS, settings.intervalUpdateS);
}

typedef Future<void> FVC(BuildContext context);

class Preferences extends StatefulWidget {
  final Settings _initSettings;
  final FVC _masterEditor, _viewEditor;

  @override
  PreferencesState createState() {
    return PreferencesState(_initSettings, _masterEditor, _viewEditor);
  }

  Preferences(Settings settings, FVC masterEditor, FVC viewEditor):
        _initSettings = settings,
        _masterEditor = masterEditor,
        _viewEditor = viewEditor;
}

class PreferencesState extends State<Preferences> {
  final initSettings;
  final _masterEditor, _viewEditor;

  final
      cUsername = TextEditingController(),
      cPassword = TextEditingController(),
      cUrl = TextEditingController(),
      cIntervalMainS = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  PreferencesState(Settings settings, FVC masterEditor, FVC viewEditor):
        initSettings = settings,
        _masterEditor = masterEditor,
        _viewEditor = viewEditor;

  @override
  void initState() {
    super.initState();
    cUrl.text = initSettings.url;
    cUsername.text = initSettings.username;
    cPassword.text = initSettings.password;
    cIntervalMainS.text = initSettings.intervalMainS.toString();
  }

  static const _boldFont = TextStyle(fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    final vrGeneric = (String value) => value.isEmpty ? 'Please enter some text' : null;

    final children = <Widget>[
      Text("URL"),
      TextFormField(
        controller: cUrl,
        autocorrect: false,
        validator: vrGeneric,
      ),
      Text("Username"),
      TextFormField(
        controller: cUsername,
        autocorrect: false,
        validator: vrGeneric,
      ),
      Text("Password"),
      TextFormField(
        controller: cPassword,
        autocorrect: false,
        validator: vrGeneric,
        obscureText: true,
      ),
      if (_masterEditor != null || _viewEditor != null) ...(
          <Widget>[
            Divider(),
            Text("View settings", style: _boldFont),
            Row(children: <Widget>[
              if (_masterEditor != null)
                RaisedButton(child: Text("Edit view list"), onPressed: () => _masterEditor(context)),
              if(_viewEditor != null)
                RaisedButton(child: Text("Edit current view"), onPressed: () => _viewEditor(context))
            ])
          ]
      ),
      Divider(),
      Text("Advanced", style: _boldFont),
      Text("Update interval, seconds"),
      TextFormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        controller: cIntervalMainS,
        validator: (value) {
          var iv = int.tryParse(value);
          var t = iv != null;
          t = t && iv >= 5;
          if (!t) {
            return 'Must be an int >= 5';
          }
          return null;
        },
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FlatButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context, null),
            ),
            FlatButton(
              child: Text('Submit'),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  Navigator.pop(context, Settings(
                      url: cUrl.text,
                      username: cUsername.text,
                      password: cPassword.text,
                      intervalMainS: int.tryParse(cIntervalMainS.text) ?? _intervalMainS
                  ));
                }
              },
            ),
          ]
        )
      )
    ];

    // Build a Form widget using the _formKey we created above
    return Form(
        key: _formKey,
        child: SingleChildScrollView(child: Dialog(
          child:
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children
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
              Text("JSON config"),
              TextFormField(
                controller: cJSON,
                minLines: 3,
                maxLines: 6,
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) { try { jsonDecode(value); return null; } catch(_) { return "Invalid JSON"; } },
              ),
              Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FlatButton(
                      child: Text('Submit'),
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          Navigator.pop(context, cJSON.text);
                        }
                      }
                    ),
                    FlatButton(
                      child: Text('Cancel'),
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