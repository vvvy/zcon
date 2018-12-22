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


class Settings {
  String url;
  String username;
  String password;

  Settings({this.url, this.username, this.password});
}

Future<Settings> readSettings() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return Settings(
      url: prefs.getString('url') ?? "",
      username: prefs.getString('username') ?? "",
      password: prefs.getString('password') ?? ""
  );
}

Future<void> writeSettings(Settings settings) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('url', settings.url);
  await prefs.setString('username', settings.username);
  await prefs.setString('password', settings.password);
}

class Preferences extends StatefulWidget {
  final Settings initSettings;

  @override
  PreferencesState createState() {
    return PreferencesState(initSettings);
  }

  Preferences(Settings settings): initSettings = settings;
}

class PreferencesState extends State<Preferences> {
  final Settings initSettings;

  TextEditingController
      cUsername = TextEditingController(),
      cPassword = TextEditingController(),
      cUrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  PreferencesState(Settings settings): initSettings = settings;

  @override
  void initState() {
    super.initState();
    cUrl.text = initSettings.url;
    cUsername.text = initSettings.username;
    cPassword.text = initSettings.password;
  }

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey we created above
    return Form(
        key: _formKey,
        child: Dialog(
          child:
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: RaisedButton(
                      child: Text('Submit'),
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          Navigator.pop(context, Settings(url: cUrl.text, username: cUsername.text, password: cPassword.text));
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: RaisedButton(
                      child: Text('Cancel'),
                      onPressed: () => Navigator.pop(context, null),
                    ),
                  ),
                ],
              )
            ),
        )
    );
  }

  /*
  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey we created above
    return Form(
      key: _formKey,
      child: SimpleDialog(
        contentPadding: EdgeInsets.all(16.0),
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
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
              )
            ]
          ),
          SimpleDialogOption(
            child: Text('Submit'),
            onPressed: () {
              if (_formKey.currentState.validate()) {
                Navigator.pop(context, Settings(url: cUrl.text, username: cUsername.text, password: cPassword.text));
              }
            },
          ),
          SimpleDialogOption(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.pop(context, null);
            }
          )
        ],
      ),
    );
  }
*/


  /*
  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey we created above
    return Form(
      key: _formKey,
      child: Dialog(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: RaisedButton(
                onPressed: () {
                   if (_formKey.currentState.validate()) {
                    Navigator.pop(context, Settings(url: cUrl.text, username: cUsername.text, password: cPassword.text));
                  }
                },
                child: Text('Submit'),
              ),
            ),
          ],
        ),
      )
    );
  }
  */
}