import 'package:flutter/material.dart';
import 'package:zcon/nv.dart';
import 'package:zcon/i18n.dart';

class GetThermostatSetPoint extends StatefulWidget {
  final double _value;

  GetThermostatSetPoint(double value): _value = value;

  @override
  State<StatefulWidget> createState() {
    return GetThermostatSetPointState(_value);
  }
}

class GetThermostatSetPointState extends State<GetThermostatSetPoint> {
  double _value;

  GetThermostatSetPointState(double value): _value = value;

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final materialLoc = matLoc(context);
    final children = <Widget>[
      Text(_value.toString()),
      Slider(value: _value, min: 5.0, max: 30.0, divisions: 50, onChanged: (w) { setState(() { _value = w; }); }),
      Row(children: <Widget>[
        Flexible(child: FlatButton(child: Text("5"), onPressed: (){ setState(() { _value = 5.0; }); })),
        Flexible(child: FlatButton(child: Text("7"), onPressed: (){ setState(() { _value = 7.0; }); })),
        Flexible(child: FlatButton(child: Text("21"), onPressed: (){ setState(() { _value = 21.0; }); })),
        Flexible(child: FlatButton(child: Text("22"), onPressed: (){ setState(() { _value = 22.0; }); })),
        Flexible(child: FlatButton(child: Text("23"), onPressed: (){ setState(() { _value = 23.0; }); })),
      ],),
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FlatButton(
                  child: Text(materialLoc.cancelButtonLabel),
                  onPressed: () => Navigator.pop(context, null),
                ),
                FlatButton(
                  child: Text(materialLoc.okButtonLabel),
                  onPressed: () {
                    if (_formKey.currentState.validate())
                      Navigator.pop(context, _value);
                  },
                ),
              ]
          )
      )
    ];

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


class GetSwitchMultilevel extends StatefulWidget {
  final int _value;

  GetSwitchMultilevel(int value): _value = value;

  @override
  State<StatefulWidget> createState() {
    return GetSwitchMultilevelState(_value);
  }
}


class GetSwitchMultilevelState extends State<GetSwitchMultilevel> {
  int _value;

  GetSwitchMultilevelState(int value): _value = value;

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final materialLoc = matLoc(context);
    final myLoc = L10ns.of(context);
    final children = <Widget>[
      Text(NVSwitchMultilevel.nvText(_value)),
      Slider(value: _value.toDouble(), min: 0.0, max: 99.0, divisions: 50, onChanged: (w) { setState(() { _value = w.toInt(); }); }),
      Row(children: <Widget>[
        Flexible(child: FlatButton(child: Text(myLoc.closed), onPressed: (){ setState(() { _value = 0; }); })),
        Flexible(child: FlatButton(child: Text("25%"), onPressed: (){ setState(() { _value = 25; }); })),
        Flexible(child: FlatButton(child: Text("50%"), onPressed: (){ setState(() { _value = 50; }); })),
        Flexible(child: FlatButton(child: Text("75%"), onPressed: (){ setState(() { _value = 75; }); })),
        Flexible(child: FlatButton(child: Text(myLoc.open), onPressed: (){ setState(() { _value = 99; }); })),
      ],),
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FlatButton(
                  child: Text(materialLoc.cancelButtonLabel),
                  onPressed: () => Navigator.pop(context, null),
                ),
                FlatButton(
                  child: Text(materialLoc.okButtonLabel),
                  onPressed: () {
                    if (_formKey.currentState.validate())
                      Navigator.pop(context, _value);
                  },
                ),
              ]
          )
      )
    ];

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
