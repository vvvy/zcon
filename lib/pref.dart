import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


Future<List<String>> readConfig() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getStringList("config");
}

Future<void> writeConfig(List<String> configRaw) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setStringList("config", configRaw);
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
      url: prefs.getString('url') ?? "",
      username: prefs.getString('username') ?? "",
      password: prefs.getString('password') ?? "",
      intervalMainS: prefs.getInt('intervalMainS') ?? _intervalMainS,
      intervalErrorRetryS: prefs.getInt('intervalErrorRetryS') ?? _intervalErrorRetryS,
      intervalUpdateS: prefs.getInt('intervalUpdateS') ?? _intervalUpdateS
  );
}

Future<void> writeSettings(Settings settings) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('url', settings.url);
  await prefs.setString('username', settings.username);
  await prefs.setString('password', settings.password);
  await prefs.setInt('intervalMainS', settings.intervalMainS);
  await prefs.setInt('intervalErrorRetryS', settings.intervalErrorRetryS);
  await prefs.setInt('intervalUpdateS', settings.intervalUpdateS);
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
  final Settings initSettings;
  final FVC _masterEditor, _viewEditor;

  TextEditingController
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
    final header = <Widget>[
      Text("URL"),
      TextFormField(
        controller: cUrl,
        validator: (value) {
          if (value.isEmpty) {
            return 'Please enter some text';
          }
        },
      ),
      Text("Username"),
      TextFormField(
        controller: cUsername,
        validator: (value) {
          if (value.isEmpty) {
            return 'Please enter some text';
          }
        },
      ),
      Text("Password"),
      TextFormField(
        controller: cPassword,
        validator: (value) {
          if (value.isEmpty) {
            return 'Please enter some text';
          }
        },
        obscureText: true,
      ),
    ];

    final footer = <Widget>[
      Divider(),
      Text("Advanced", style: _boldFont),
      Text("Update interval, seconds"),
      TextFormField(
        autovalidate: true,
        controller: cIntervalMainS,
        validator: (value) {
          var iv = int.tryParse(value);
          var t = iv != null;
          t = t && iv >= 5;
          if (!t) {
            return 'Must be an int >= 5';
          }
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

    final view = (_masterEditor != null || _viewEditor != null) ?
        <Widget>[
          Divider(),
          Text("View settings", style: _boldFont),
          Row(children: (
              _masterEditor != null ?
                <Widget>[RaisedButton(child: Text("Edit view list"), onPressed: () => _masterEditor(context))]
                  :
                <Widget>[]
            ) + (
              _viewEditor != null ?
              <Widget>[RaisedButton(child: Text("Edit current view"), onPressed: () => _viewEditor(context))]
                  :
              <Widget>[]
          ))
        ]
        :
        <Widget>[];

    final children = header + view + footer;

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