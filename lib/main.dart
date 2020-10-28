import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:scoped_model/scoped_model.dart';

import 'pref.dart';
import 'pdu.dart';
import 'devstate.dart';
import 'devlist.dart';
import 'nv.dart';
import 'reorder.dart';
import 'davatar.dart';
import 'getvalue.dart';
import 'i18n.dart';
import 'model.dart';

void main() => runApp(ZConApp());

class ZConAppState extends State<ZConApp> with WidgetsBindingObserver {
  final _l10nModel = L10nModel();
  final _mainModel = MainModel();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mainModel.init(_l10nModel);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("AppLifecycleState: $state");
    switch (state) {
      case AppLifecycleState.paused:  return _mainModel.submit(CommonModelEvents.AppPaused);
      case AppLifecycleState.resumed: return _mainModel.submit(CommonModelEvents.AppResumed);
      default: break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<L10nModel>(
      model: _l10nModel,
      child: ScopedModelDescendant<L10nModel>(builder: (context, child, l10nModel) => MaterialApp(
        title: "Z-Way Console",
        localizationsDelegates: [
          //app-specific localization delegates
          ...l10nModel.locales.list,
          //framework delegates
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: supportedLocales,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Builder(builder: (context) =>
          ScopedModel<MainModel>(
            model: _mainModel,
            child: ScopedModelDescendant<MainModel>(builder: (context, child, mainModel) =>
              Scaffold(
                drawer: Drawer(
                  child: ListView(
                      padding: EdgeInsets.zero,
                      children: <Widget>[
                        DrawerHeader(
                          child: Text('Z-Way Console (ZCon)', textScaleFactor: 1.5, style: TextStyle(color: Colors.white)),
                          decoration: BoxDecoration(
                              color: Colors.blue,
                              image: const DecorationImage(image: AssetImage("assets/icon/lamp.png"))
                          ),
                        ),
                        ListTile(
                          leading: Icon(Icons.refresh),
                          title: Text('Refresh'),
                          onTap: () {
                            mainModel.reload();
                            Navigator.pop(context);
                          }
                        ),
                        ListTile(
                          leading: Icon(Icons.settings),
                          title: Text('Settings'),
                          onTap: () {
                            _editSettings(context);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit config (advanced)'),
                          onTap: () {
                            _editJSON(context);
                            Navigator.pop(context);
                          },
                        ),
                      if (mainModel.devState.alerts.isNotEmpty) Divider(),
                      if (mainModel.devState.alerts.isNotEmpty) Text("Alerts", textAlign: TextAlign.center,),
                      for (var alert in mainModel.devState.alerts)
                        ListTile(
                          leading: Icon(Icons.warning, color: Colors.yellow),
                          title: Text(alert.text),
                          onTap: () {
                            if (alert.filterId >= 0) mainModel.devState.setFilter(alert.filterId);
                            Navigator.pop(context);
                          },
                        )
                      ],
                    )
                  ),
                  //------------------------------
                  appBar: AppBar(
                      title: Text("ZCon"),
                      actions: _appBarActions(context)
                  ),
                  body: Center(
                      child: Builder(builder: (context) {
                        return _buildMainView(context, mainModel);
                      })
                  )
              ),
            )
          )
        ),
      ))
    );
  }


  final _biggerFont = const TextStyle(fontSize: 18.0);
  final _smallerFont = const TextStyle(fontSize: 12.0);

  String _formatUpdateTime(int time) {
    final now = DateTime.now();
    final then = DateTime.fromMillisecondsSinceEpoch(time * 1000);
    final diff = now.difference(then);
    final diffSec = diff.inSeconds;
    if (diffSec >= 3600 * 24) return "${diff.inDays}d ago";
    if (diffSec >= 3600) return "${diff.inHours}h ago";
    if (diffSec >= 60) return "${diff.inMinutes}min ago";
    return "${diffSec}s ago";
  }

  Widget _buildRow(Device d, BuildContext context, MainModel mainModel) {
    String title = d.metrics.title;
    NV nv = mainModel.nvc.getNV(d);
    var notF = (String s) => Scaffold.of(context).showSnackBar(SnackBar(content: Text(s)));
    var errorF = (String s) => notF("Error: $s");

    Widget trailing = (nv) {
      if (nv is NVShow) {
        return Text(nv.value, style: _biggerFont);
      } else if (nv is NVPushButton) {
        return IconButton(icon: Icon(Icons.launch), onPressed: () async { notF("Activating $title"); nv.onPressed(errorF); });
      } else if (nv is NVSwitch) {
        return Switch(value: nv.value, onChanged: (v) async { notF("Setting $title ${v?'on':'off'}"); nv.onToggle(v, errorF); });
      } else if (nv is NVThermostatSetPoint) {
        return FlatButton(child: Text(nv.title), onPressed: () =>
            showDialog(
                context: context,
                builder: (context) => GetThermostatSetPoint(nv.value)
            ).then((v) async { if (v != null) {
              notF("Setting level of $title to $v");
              nv.onSet(v, errorF);
            }})
        );
      } else if (nv is NVSwitchMultilevel) {
        return FlatButton(child: Text(nv.title), onPressed: () =>
            showDialog(
                context: context,
                builder: (context) => GetSwitchMultilevel(nv.value)
            ).then((v) async { if (v != null) {
              notF("Setting level of $title to $v");
              nv.onSet(v, errorF);
            }})
        );
      } else {
        return Text("?");
      }
    } (nv);

    return ListTile(
        title: Text(title, style: _biggerFont),
        leading: avatar(d),
        subtitle: Text(_formatUpdateTime(d.updateTime), style: _smallerFont),
        onLongPress: () async { if(nv is NVUpdate) { notF("Updating $title"); nv.onUpdate(errorF); } },
        trailing: trailing
    );
  }

  Widget _buildMainView(BuildContext context, MainModel mainModel) {
    var v = mainModel.devState.getDeviceView((s) => Scaffold.of(context).showSnackBar(SnackBar(content: Text(s))));
    if (v is DevViewFull) {
      //print("@buildMainView");
      return ListView.separated(
          itemBuilder: (context, i) => _buildRow(v.devices.get(i), context, mainModel),
          separatorBuilder: (context, i) => Divider(),
          itemCount: v.devices.length()
      );
    } else if (v is DevViewEmpty) {
      if (v.error != null)
        return Text("ERROR:\n${v.error}", style:
        DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.5, color: Colors.red, fontWeightDelta: 3),
        );
      else if (v.isLoading)
        return CircularProgressIndicator();
      else
        return Text("ZCon");
    } else {
      return Text("ZCon (unknown view)");
    }
  }

  static Future<void> _viewEditor(BuildContext context) async {
    final vs = await showDialog<List<ReorderListItem<String>>>(
      context: context,
      builder: (context) => Reorder<ReorderListItem<String>>(
        ScopedModel.of<MainModel>(context).devState.startEditList(),
        (s) => s.isSeparator ? null : s.i.name
      )
    );
    if (vs != null)
      ScopedModel.of<MainModel>(context).devState.endEditList(vs);
  }

  static Future<void> _masterEditor(BuildContext context) async {
    final vs = await showDialog<List<ReorderListItem<int>>>(
        context: context,
        builder: (context) => Reorder<ReorderListItem<int>>(
          ScopedModel.of<MainModel>(context).devState.startEditMaster(),
          (s) => s.isSeparator ? null : s.i.name
        )
    );
    if (vs != null)
      ScopedModel.of<MainModel>(context).devState.endEditMaster(vs);
  }

  void _editSettings(BuildContext context) async {
    final mainModel = ScopedModel.of<MainModel>(context);

    FVC viewEditor =
      mainModel.devState.listsOnline && mainModel.devState.isListEditable ?
      _viewEditor : null;

    FVC masterEditor = mainModel.devState.listsOnline ?
      _masterEditor : null;

    final orig = mainModel.settings;
    final edited = await showDialog<Settings>(
        context: context,
        builder: (context) => Preferences(orig, masterEditor, viewEditor)
    );
    if (edited != null) {
      ScopedModel.of<L10nModel>(context).setLocale(edited.localeCode);
      mainModel.submit(edited);
    }
  }

  void _editJSON(BuildContext context) async {
    final jsonS = await configToJson();
    print("starting json edit, config=$jsonS");
    final edited = await showDialog(context: context, builder: (context) => JSON(jsonS));
    if (edited != null) {
      await configFromJson(edited);
      ScopedModel.of<MainModel>(context).reload();
    }
  }

  List<Widget> _appBarActions(BuildContext context) {
    final w = <Widget>[];
    final model = ScopedModel.of<MainModel>(context);

    List<Alert> alerts = model.devState.alerts;
    if (alerts.isNotEmpty) {
      int i = alerts.map((a) => a.filterId).reduce((a, b) => a > b ? a : b);
      w.add(IconButton(
        icon: Icon(Icons.warning, color: Colors.yellow),
        tooltip: alerts.map((a) => a.text).join("\n"),
        onPressed: (i >= 0) ? () => model.devState.setFilter(i) : null,
      ));
    }

    if (model.devState.listsOnline) {
      w.add(DropdownButton<int>(
          value: model.devState.getFilter(),
          items: model.devState.getAvailableFilters().map((n) => DropdownMenuItem<int>(value: n.id, child: Text(n.name))).toList(),
          onChanged: (s) => model.devState.setFilter(s)
      ));
    }

    w.add(IconButton(
        icon: Icon(Icons.settings),
        onPressed: () async { _editSettings(context); }
    ));

    w.add(IconButton(
        icon: Icon(Icons.refresh),
        //TODO somewhat better e.g. animation
        color: model.devState.isLoading ? Colors.blueGrey : Colors.white,
        onPressed: () {
          model.reload();
        }));

    return w;
  }
}


class ZConApp extends StatefulWidget {
  @override
  State createState() => new ZConAppState();
}


