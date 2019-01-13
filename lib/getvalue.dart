import 'package:flutter/material.dart';

class GetFloat extends StatefulWidget {
  final double _value;

  GetFloat(double value): _value = value;

  @override
  State<StatefulWidget> createState() {
    return GetFloatState(_value);
  }

}

class GetFloatState extends State<GetFloat> {
  double _value;

  GetFloatState(double value): _value = value;

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
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
                  child: Text('Cancel'),
                  onPressed: () => Navigator.pop(context, null),
                ),
                FlatButton(
                  child: Text('Submit'),
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