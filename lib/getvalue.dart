import 'package:flutter/material.dart';
import 'package:zcon/model.dart';
import 'package:zcon/nv.dart';
import 'package:zcon/i18n.dart';
import 'package:zcon/pdu.dart';

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
        Flexible(child: TextButton(child: Text("5"), onPressed: (){ setState(() { _value = 5.0; }); })),
        Flexible(child: TextButton(child: Text("7"), onPressed: (){ setState(() { _value = 7.0; }); })),
        Flexible(child: TextButton(child: Text("21"), onPressed: (){ setState(() { _value = 21.0; }); })),
        Flexible(child: TextButton(child: Text("22"), onPressed: (){ setState(() { _value = 22.0; }); })),
        Flexible(child: TextButton(child: Text("23"), onPressed: (){ setState(() { _value = 23.0; }); })),
      ],),
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
                    if (_formKey.currentState!.validate())
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
  final NVSwitchMultilevel _nv;

  GetSwitchMultilevel(this._nv);

  @override
  State<StatefulWidget> createState() {
    return GetSwitchMultilevelState(_nv);
  }
}


class GetSwitchMultilevelState extends State<GetSwitchMultilevel> {

  final DeviceLink _devLink;
  int? _value;

  GetSwitchMultilevelState(NVSwitchMultilevel nv):
    _devLink = nv.getLink(),
    _value = nv.value;

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final materialLoc = matLoc(context);
    final myLoc = L10ns.of(context);
    final model = MainModel.of(context, rebuildOnChange: true);
    final nv = model.getNVbyLink(_devLink, myLoc) as NVSwitchMultilevel?;
    if (nv == null) return
      Dialog(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("Null NV"),
          TextButton(
            child: Text(materialLoc.closeButtonLabel),
            onPressed: () => Navigator.pop(context, null),
          )
        ]
    ));

    return Form(
      key: _formKey,
      child: SingleChildScrollView(child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(NVSwitchMultilevel.nvText(_value, myLoc)),
              Slider(value: nv.value!.toDouble(), min: 0.0, max: 99.0, divisions: 50, onChanged: null, label: "current"),
              Slider(value: _value!.toDouble(), min: 0.0, max: 99.0, divisions: 50, onChanged: (w) { setState(() { _value = w.toInt(); }); }),
              Row(children: <Widget>[
                Flexible(child: TextButton(child: Text(myLoc.closed), onPressed: (){ setState(() { _value = 0; }); })),
                Flexible(child: TextButton(child: Text("25%"), onPressed: (){ setState(() { _value = 25; }); })),
                Flexible(child: TextButton(child: Text("50%"), onPressed: (){ setState(() { _value = 50; }); })),
                Flexible(child: TextButton(child: Text("75%"), onPressed: (){ setState(() { _value = 75; }); })),
                Flexible(child: TextButton(child: Text(myLoc.open), onPressed: (){ setState(() { _value = 99; }); })),
              ],),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                        icon: Icon(Icons.check_circle),
                        tooltip: myLoc.goToPosition,
                        onPressed: () => model.exec(nv.setLevelCmd(_value!))
                    ),
                    IconButton(
                        icon: Icon(Icons.arrow_drop_up),
                        tooltip: myLoc.increase,
                        onPressed: () => model.exec(nv.increaseCmd())
                    ),
                    IconButton(
                        icon: Icon(Icons.arrow_upward),
                        tooltip: myLoc.startUp,
                        onPressed: () => model.exec(nv.startUpCmd())
                    ),
                    IconButton(
                        icon: Icon(Icons.stop),
                        tooltip: myLoc.stop,
                        onPressed: () => model.exec(nv.stopCmd())
                    ),
                    IconButton(
                        icon: Icon(Icons.arrow_downward),
                        tooltip: myLoc.startDown,
                        onPressed: () => model.exec(nv.startDownCmd())
                    ),
                    IconButton(
                        icon: Icon(Icons.arrow_drop_down),
                        tooltip: myLoc.decrease,
                        onPressed: () => model.exec(nv.decreaseCmd())
                    ),
                  ]
                )
              ),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: Text(materialLoc.closeButtonLabel),
                          onPressed: () => Navigator.pop(context, null),
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

