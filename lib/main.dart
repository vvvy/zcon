import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:scoped_model/scoped_model.dart';

import 'package:zcon/pref.dart';
import 'package:zcon/pdu.dart';
import 'package:zcon/devstate.dart';
import 'package:zcon/devlist.dart';
import 'package:zcon/nv.dart';
import 'package:zcon/reorder.dart';
import 'package:zcon/davatar.dart';
import 'package:zcon/getvalue.dart';
import 'package:zcon/i18n.dart';
import 'package:zcon/model.dart';

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
      case AppLifecycleState.paused:  return _mainModel.submit(AppPaused());
      case AppLifecycleState.resumed: return _mainModel.submit(AppResumed());
      default: break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<L10nModel>(
      model: _l10nModel,
      child: ScopedModelDescendant<L10nModel>(builder: (context, child, l10nModel) => MaterialApp(
        title: "ZConsole",
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
                          child: Text('ZConsole',
                              textScaler: TextScaler.linear(1.5),
                              style: TextStyle(color: Colors.white)),
                          decoration: BoxDecoration(
                              color: Colors.blue,
                              image: const DecorationImage(image: AssetImage("assets/icon/lamp.png"))
                          ),
                        ),
                        ListTile(
                          leading: Icon(Icons.refresh),
                          title: Text(matLoc(context).refreshIndicatorSemanticLabel),
                          onTap: () {
                            Navigator.pop(context);
                            mainModel.reloadDevices();
                          }
                        ),
                        ListTile(
                          leading: Icon(Icons.settings),
                          title: Text(L10ns.of(context).settings),
                          onTap: () {
                            Navigator.pop(context);
                            _editSettings(context);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.edit),
                          title: Text(L10ns.of(context).editConfigAdvanced),
                          onTap: () {
                            Navigator.pop(context);
                            _editJSON(context);
                          },
                        ),
                      if (mainModel.alerts.isNotEmpty) Divider(),
                      if (mainModel.alerts.isNotEmpty) Text(L10ns.of(context).alerts, textAlign: TextAlign.center,),
                      for (var alert in mainModel.alerts)
                        ListTile(
                          leading: Icon(Icons.warning, color: Colors.yellow),
                          title: Text(L10ns.of(context).alertText(alert)),
                          onTap: () {
                            Navigator.pop(context);
                            if (alert.filterId >= 0) mainModel.setFilter(alert.filterId);
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

  String _formatUpdateTime(int time, BuildContext context) {
    final now = DateTime.now();
    final then = DateTime.fromMillisecondsSinceEpoch(time * 1000);
    final diff = now.difference(then);
    return L10ns.of(context).elapsed(diff);
  }

  Widget _buildRow(Device d, BuildContext context, MainModel mainModel) {
    final myLoc = L10ns.of(context);
    String title = d.metrics?.title ?? "?";
    NV? nv = getNV(d, myLoc);

    Widget trailing = (nv) {
      if (nv is NVShow) {
        return Text(nv.value, style: _biggerFont);
      } else if (nv is NVPushButton) {
        return IconButton(
            icon: Icon(Icons.launch),
            onPressed: () => mainModel.exec(nv.pressedCmd, myLoc.activating(title))
        );
      } else if (nv is NVSwitch) {
        return Switch(
            value: nv.value,
            onChanged: (v) => mainModel.execCond(nv.toggleCmd(v), myLoc.settingOnOff(title, v))
        );
      } else if (nv is NVThermostatSetPoint) {
        return TextButton(child: Text(nv.title), onPressed: () async {
          final level = await showDialog(
              context: context,
              builder: (context) => GetThermostatSetPoint(nv.value ?? 0.0)
          );
          if (level != null) {
            mainModel.exec(nv.setCmd(level), myLoc.settingLevel(title, level));
          }
        });
      } else if (nv is NVSwitchMultilevel) {
        return TextButton(child: Text(nv.title), onPressed: () => showDialog(
              context: context,
              builder: (context) => _mainModel.scoped(GetSwitchMultilevel(nv))
          ));
      } else {
        return Text("?");
      }
    } (nv);

    return ListTile(
        title: Text(title, style: _biggerFont),
        leading: avatar(d, mainModel.settings),
        subtitle: Text(_formatUpdateTime(d.updateTime!, context), style: _smallerFont),
        onLongPress: () { if(nv is NVUpdate) { mainModel.exec(nv.updateCmd, myLoc.updating(title)); } },
        trailing: trailing
    );
  }

  Widget _buildMainView(BuildContext context, MainModel mainModel) {
    _mainModel.popupFn = (p) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10ns.of(context).popup(p))))
    ;

    var v = mainModel.getDeviceView();

    if (v is DevViewFull) {
      return ListView.separated(
          itemBuilder: (context, i) => _buildRow(v.devices.get(i), context, mainModel),
          separatorBuilder: (context, i) => Divider(),
          itemCount: v.devices.length()
      );
    } else if (v is DevViewEmpty) {
      if (v.error != null)
        return Text(
          L10ns.of(context).errorNL(v.error!),
          style: DefaultTextStyle.of(context).style.apply(
              fontSizeFactor: 1.5,
              color: Colors.red,
              fontWeightDelta: 3
          ),
        );
      else if (mainModel.isNetworkIoActive)
        return CircularProgressIndicator();
      else
        return Text("ZCon");
    } else {
      return Text("ZCon (unknown view)");
    }
  }

  static Future<void> _viewEditor(BuildContext context) async {
    final model = MainModel.of(context);
    final vs = await showDialog<List<ReorderListItem<String>>>(
      context: context,
      builder: (context) => Reorder<ReorderListItem<String>>(
        model.startEditList(),
        (s) => s.i?.name
      )
    );
    if (vs != null)
      model.endEditList(vs);
  }

  static Future<void> _masterEditor(BuildContext context) async {
    final model = MainModel.of(context);
    final vs = await showDialog<List<ReorderListItem<int>>>(
        context: context,
        builder: (context) => Reorder<ReorderListItem<int>>(
          model.startEditMaster(L10ns.of(context).viewNameOf),
          (s) => s.i?.name
        )
    );
    if (vs != null)
      model.endEditMaster(vs);
  }

  Future<void> _editSettings(BuildContext context) async {
    final mainModel = MainModel.of(context);

    FVC? viewEditor =
      mainModel.listsOnline && mainModel.isListEditable ?
      _viewEditor : null;

    FVC? masterEditor = mainModel.listsOnline ?
      _masterEditor : null;

    final orig = mainModel.settings!;
    final edited = await showDialog<Settings>(
      context: context,
      builder: (context) => mainModel.scoped(Preferences(orig, masterEditor, viewEditor))
    );
    if (edited != null) {
      ScopedModel.of<L10nModel>(context).setLocale(edited.localeCode);
      mainModel.submit(SettingsUpdate(edited));
    }
  }

  Future<void> _editJSON(BuildContext context) async {
    final jsonS = await configToJson();
    print("starting json edit, config=$jsonS");
    final edited = await showDialog(context: context, builder: (context) => JSON(jsonS));
    if (edited != null) {
      await configFromJson(edited);
      MainModel.of(context).reloadDevices();
    }
  }

  List<Widget> _appBarActions(BuildContext context) {
    final w = <Widget>[];
    final model = MainModel.of(context);

    List<Alert> alerts = model.alerts;
    if (alerts.isNotEmpty) {
      int i = alerts.map((a) => a.filterId).reduce((a, b) => a > b ? a : b);
      w.add(IconButton(
        icon: Icon(Icons.warning, color: Colors.yellow),
        tooltip: alerts.map((a) => L10ns.of(context).alertText(a)).join("\n"),
        onPressed: (i >= 0) ? () => model.setFilter(i) : null,
      ));
    }

    if (model.listsOnline) {
      w.add(DropdownButton<int>(
          value: model.getFilter(),
          items:
            model.getAvailableFilters(L10ns.of(context).viewNameOf)
                .map((n) => DropdownMenuItem<int>(value: n.id, child: Text(n.name)))
                .toList(),
          onChanged: (s) => { if (s != null ) model.setFilter(s) }
      ));
    }

    w.add(IconButton(
        icon: Icon(Icons.settings),
        onPressed: () async { _editSettings(context); }
    ));

    w.add(IconButton(
        icon: Icon(Icons.sync),
        //TODO somewhat better e.g. animation
        color: (model.isNetworkIoActive) ? Colors.blueGrey : Colors.white,
        onPressed: () {
          model.reloadDevices();
        }));

    return w;
  }
}


class ZConApp extends StatefulWidget {
  @override
  State createState() => new ZConAppState();
}


