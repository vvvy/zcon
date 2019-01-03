import 'package:flutter/material.dart';
import 'pref.dart';
import 'pdu.dart';
import 'devstate.dart';
import 'devlist.dart';
import 'nv.dart';
import 'reorder.dart';


void main() => runApp(MyApp());

class AppState extends State<MyApp> with WidgetsBindingObserver implements DevStateNest {
  DevState devState;
  NVController nvc = NVController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    reload();
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
      case AppLifecycleState.paused:
        setDevState(DevStateEmpty(this.devState, error: "Application paused"));
        break;
      case AppLifecycleState.resumed:
        setDevState(DevStateEmpty.init(this));
        break;
      default:
        break;
    }
  }

  @override
  void setDevState(DevState devState) {
    nvc.setUpdateHook(() => devState.flagNeedsUpdate());
    setState(() {
      if (this.devState != devState && this.devState != null)
        this.devState.cleanup();
      this.devState = devState;
    });
  }

  void reload() {
    setDevState(DevStateEmpty.init(this));
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

  Widget _buildRow(Device d, BuildContext context) {
    String title = d.metrics.title;
    NV nv = nvc.getNV(d);
    var notF = (String s) => Scaffold.of(context).showSnackBar(SnackBar(content: Text(s)));
    var errorF = (String s) => notF("Error: $s");

    Widget trailing = (nv) {
      if (nv is NVShow) {
        return Text(nv.value, style: _biggerFont);
      } else if (nv is NVPushButton) {
        return IconButton(icon: Icon(Icons.launch), onPressed: () { notF("Activating $title"); nv.onPressed(errorF); });
      } else if (nv is NVSwitch) {
        return Switch(value: nv.value, onChanged: (v) { notF("Setting $title ${v?'on':'off'}"); nv.onToggle(v, errorF); });
      } else {
        return Text("?");
      }
    } (nv);

    return ListTile(
      title: Text(title, style: _biggerFont),
      subtitle: Text(_formatUpdateTime(d.updateTime), style: _smallerFont),
      onLongPress: () { if(nv is NVUpdate) { notF("Updating $title"); nv.onUpdate(errorF); } },
      trailing: trailing
    );
  }

  Widget buildMainView(BuildContext context) {
    var v = devState.getDeviceView((s) => Scaffold.of(context).showSnackBar(SnackBar(content: Text(s))));
    if (v is DevViewFull) {
      //print("@buildMainView");
      return ListView.separated(
          itemBuilder: (context, i) => _buildRow(v.devices.get(i), context),
          separatorBuilder: (context, i) => Divider(),
          itemCount: v.devices.length()
      );
    } else if (v is DevViewEmpty) {
      if (v.error != null)
        return Text("Error: ${v.error}");
      else if (v.isLoading)
        return CircularProgressIndicator();
      else
        return Text("ZCon");
    } else {
      return Text("ZCon (unknown view)");
    }
  }

  List<Widget> _appBarActions(BuildContext context) {
    final w = <Widget>[];

    FVC viewEditor = devState.listsOnline && devState.isListEditable ? (context) => showDialog(
        context: context,
        builder: (context) => Reorder<ReorderListItem<String>>(
            devState.startEditList(),
                (s) => s.isSeparator ? null : s.i.name
        )
    ).then((vs) { if (vs != null) devState.endEditList(vs); })
        : null;

    FVC masterEditor = devState.listsOnline ? (context) => showDialog(
        context: context,
        builder: (context) => Reorder<ReorderListItem<int>>(
            devState.startEditMaster(),
                (s) => s.isSeparator ? null : s.i.name
        )
    ).then((vs) { if (vs != null) devState.endEditMaster(vs); })
        : null;

    if (devState.listsOnline) {
      w.add(DropdownButton<int>(
          value: devState.getFilter(),
          items: devState.getAvailableFilters().map((n) => DropdownMenuItem<int>(value: n.id, child: Text(n.name))).toList(),
          onChanged: (s) => devState.setFilter(s)
      ));
    }

    w.add(IconButton(
        icon: Icon(Icons.settings),
        onPressed: () async {
          final orig = await readSettings();
          final edited = await showDialog(context: context, builder: (context) => Preferences(orig, masterEditor, viewEditor));
          if (edited != null) {
            await writeSettings(edited);
            reload();
          }
        }
    ));

    //w.add(IconButton(icon: Icon(Icons.settings), onPressed: () {
    //  return readSettings().then((s) => Navigator.push(
    //    context,
    //    MaterialPageRoute(builder: (context) => Preferences(s)),
    //  )).then((s) { if (s != null) writeSettings(s); })
    //      .then((_) => reload());
    //}));

    w.add(IconButton(
        icon: Icon(Icons.refresh),
        //TODO somewhat better e.g. animation
        color: devState.isLoading ? Colors.blueGrey : Colors.white,
        onPressed: () {
          reload();
        }));

    return w;
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Z-Way Console",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Builder(builder: (context) =>
          Scaffold(
            appBar: AppBar(
              title: Text("ZCon"),
              actions: _appBarActions(context)
            ),
            body: Center(
                child: Builder(builder: (context) {
                  return buildMainView(context);
                })
            ),
          )
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  State createState() => new AppState();
}


