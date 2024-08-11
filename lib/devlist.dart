import 'package:zcon/pdu.dart';
import 'package:zcon/pref.dart';
//------------------------------------------------------------------------------

enum VisLevel {
  /// only visible items
  Visible,
  /// show invisible items but not permanently hidden
  Invisible,
  /// Everything including permanently hidden
  All
}

abstract class DevList {
  Device get(int index);
  int length();
}

class DevListIdentity extends DevList {
  final List<Device> _devices;

  @override
  Device get(int index) {
    return _devices[index];
  }

  @override
  int length() {
    return _devices.length;
  }

  DevListIdentity(List<Device> devices): _devices = devices;
}

class DevListIndex extends DevList {
  final List<Device> _devices;
  final List<int> _pos;

  @override
  Device get(int index) {
    return _devices[_pos[index]];
  }

  @override
  int length() {
    return _pos.length;
  }

  DevListIndex(List<Device> devices, final List<int> pos):
        _devices = devices,
        _pos = pos;
}

abstract class DevListType {
  DevList getList(List<Device> devices, {bool rebuildHint});
}

class DevListTypeIdentity extends DevListType {
  @override
  DevList getList(List<Device> devices, {bool rebuildHint = false}) { return DevListIdentity(devices); }
}

typedef bool DevF(Device d);
typedef int DevS(Device d1, Device d2);

List<int> buildIndex(List<Device> devices, DevF f, DevS? s) {
  var pos = <int>[];
  for (int i = 0; i < devices.length; i++)
    if (f(devices[i]))
      pos.add(i);
  if (s != null)
    pos.sort((a, b) => s(devices[a], devices[b]));
  return pos;
}

class DevListTypeIndex extends DevListType {
  final DevF _f;
  final DevS? _s;
  List<int>? _pos;
  @override
  DevList getList(List<Device> devices, {bool rebuildHint = false}) {
    if (rebuildHint || _pos == null)
      _pos = buildIndex(devices, _f, _s);
    return DevListIndex(devices, _pos!);
  }

  DevListTypeIndex({required DevF f, DevS? s}):
        _f = f,
        _s = s;
}

Iterable<MapEntry<T, int>> zipWithIndex<T>(Iterable<T> l) {
  var n = 0;
  return l.map((i) => MapEntry(i, n++));
}

Iterable<MapEntry<T, U>> zip<T, U>(Iterable<T> t, Iterable<U> u) {
  var ui = u.iterator;
  return t
      .map((tv) => ui.moveNext() ? MapEntry(tv, ui.current) : null)
      .takeWhile((i) => i != null)
      .map((i) => i!);
}

class DevListTypeIdList extends DevListType {
  List<String> _ids;
  List<int>? _pos;

  DevListTypeIdList() : _ids = List.empty();
  @override
  DevList getList(List<Device> devices, {bool rebuildHint = false}) {
    if (rebuildHint || _pos == null) {
      var m = Map.fromEntries(zipWithIndex(devices).map((me) => MapEntry(me.key.id, me.value)));
      _ids.removeWhere((id) => !m.containsKey(id));
      _pos = _ids.map((id) => m[id]!).toList();
    }
    return DevListIndex(devices, _pos!);
  }

  void setIds(List<String> ids) { _pos = null; _ids = ids; }
  List<String> getIds() => List.unmodifiable(_ids);
}

DevF deviceTypeFilter(String deviceType) =>
        (Device d) => d.deviceType == deviceType;

DevF deviceAndProbeTypeFilter(String deviceType, String probeType) =>
        (Device d) => d.deviceType == deviceType && d.probeType == probeType;

//----------------------------------------------------------------------------------------------------------------------

class IdName<Id> {
  final Id id;
  final String name;

  IdName(this.id, this.name);
}

class ReorderListItem<Id> {
  final IdName<Id>? i;

  ReorderListItem(Id id, String name) : i = IdName(id, name);
  ReorderListItem.sep(): i = null;
  @override
  String toString() => i == null ? "---------" : "${i!.name}@${i!.id}";
  bool get isSeparator => i == null;
}

/// Interface class for Device List Controller
abstract class AbstractDevListController {
  /// whether this controller is operational
  bool get isOnline;
  /// whether the current filter is editable
  bool get isListEditable;
  /// apply a new or an updated device list -- called whenever device state has changed
  void applyDevices(List<Device> dev, VisLevel visLevel, {bool rebuildHint});
  /// apply configuration -- the data are usually read from persistent storage
  void applyConfig(int pos, List<int> master, List<int> configPos, List<List<String>> config);
  /// current filter id (same as position in the master list)
  int get current;
  /// current filter id
  set current(int id);
  /// master filter list
  List<IdName> getMaster(ViewNameTranslator vnt);
  /// starts editing master list
  List<ReorderListItem<int>> startEditMaster(ViewNameTranslator vnt);
  /// ends editing master list, previously started by startEditMaster
  void endEditMaster(List<ReorderListItem<int>> result);
  /// gets current device list -- this is to display in the main list view
  DevList get list;
  /// starts edit customN device list
  List<ReorderListItem<String>?>? startEditList();
  /// ends editing customN device list, previously started by startEditList
  void endEditList(List<ReorderListItem<String>> result);
  //int getTypeId(String t);
}

enum _S {
  ver,
  pos,
  mLen,
  mItem,
  cfgP,
  cfgLen,
  cfgItem,
  err
}

enum AppView {
  All,
  Temperature,
  Thermostats,
  Scene,
  Switches,
  Blinds,
  Battery,
  Failed,
  Custom1,
  Custom2,
  Custom3,
  Custom4,
  Custom5
}

typedef String ViewNameTranslator(AppView view);

class DevListController extends AbstractDevListController {
  static final Map<AppView, DevListType> _typeMap = {
    AppView.All: DevListTypeIdentity(),
    AppView.Temperature: DevListTypeIndex(f: deviceAndProbeTypeFilter("sensorMultilevel", "temperature")),
    AppView.Thermostats: DevListTypeIndex(f: deviceTypeFilter("thermostat")),
    AppView.Scene: DevListTypeIndex(f: deviceTypeFilter("toggleButton")),
    AppView.Switches: DevListTypeIndex(f: deviceTypeFilter("switchBinary")),
    AppView.Blinds: DevListTypeIndex(f: deviceAndProbeTypeFilter("switchMultilevel", "motor")),
    AppView.Battery: DevListTypeIndex(f: deviceTypeFilter("battery")),
    AppView.Failed: DevListTypeIndex(f: (d) => d.metrics?.isFailed == true),
    AppView.Custom1: DevListTypeIdList(),
    AppView.Custom2: DevListTypeIdList(),
    AppView.Custom3: DevListTypeIdList(),
    AppView.Custom4: DevListTypeIdList(),
    AppView.Custom5: DevListTypeIdList(),
  };

  static final List<AppView> _typeIds = _typeMap.keys.toList(growable: false);
  static final List<DevListType> _types = _typeMap.values.toList(growable: false);

  List<int> _generations;
  int _generation;
  List<int>? _master;
  int _current;

  List<Device>? _devices;

  DevListController() :
    _generations = Iterable.generate(_types.length, (_) => 0).toList(growable: false),
    _generation = 0,
    _current = 0
  ;

  static int getViewId(AppView v) => DevListController._typeIds.indexOf(v);

  @override
  bool get isOnline => _master != null && _devices != null;

  @override
  bool get isListEditable => _types[_current] is DevListTypeIdList;

  @override
  int get current => _current;

  @override
  set current(int current) {
    if (_master == null) return;
    if (_master!.indexOf(current) < 0)
      print("setPos: Error: invalid current=$current on master=$_master");
    else
      _current = current;
  }

  @override
  List<IdName<int>> getMaster(ViewNameTranslator vnt) =>
      _master!.map((i) => IdName(i, vnt(_typeIds[i]))).toList();

  @override
  List<ReorderListItem<int>> startEditMaster(ViewNameTranslator vnt) {
    final masterComplement = Iterable.generate(_typeIds.length).toSet().difference(_master!.toSet());
    final l = _master!.map((i) => ReorderListItem<int>(i, vnt(_typeIds[i]))).toList();
    final m = masterComplement.map((i) => ReorderListItem<int>(i, vnt(_typeIds[i]))).toList();
    return l + [ReorderListItem.sep()] + m;
  }

  bool _masterValid(List<int> rv) {
    var t = rv.isNotEmpty;
    t = t && rv.toSet().length == rv.length;
    t = t && !rv.any((v) => v < 0) && !rv.any((v) => v >= _types.length);
    return t;
  }

  @override
  void endEditMaster(List<ReorderListItem<int>> result) {
    int sep = result.indexWhere((i) => i.isSeparator);
    if (sep >= 0) result = result.take(sep).toList();
    final rv = result.map((rli) => rli.i!.id).toList();
    if (_masterValid(rv)) {
      _master = rv;
      if (_master!.indexOf(_current) < 0) {
        _current = _master![0];
      }
    } else
      print("Error: endEditMaster: invalid input: $result");
  }

  @override
  void applyDevices(List<Device>? dev, VisLevel visLevel, {bool rebuildHint = false}) {
    if (dev == null || visLevel == VisLevel.All)
      _devices = dev;
    else if (visLevel == VisLevel.Invisible)
      _devices = dev.where((d) => !(d.permanentlyHidden ?? false)).toList();
    else
      _devices = dev.where((d) => (!(d.permanentlyHidden ?? false) && (d.visibility ?? false))).toList();
    if (rebuildHint) _generation++;
  }

  @override
  DevList get list {
    var rebuildHint = false;
    if (_generations[_current] != _generation) {
      _generations[_current] = _generation;
      rebuildHint = true;
    }
    return _types[_current].getList(_devices!, rebuildHint: rebuildHint);
  }

  @override
  void applyConfig(int current, List<int>? master, List<int>? configPos, List<List<String>>? config) {
    var t = true;
    t = t && master != null;
    t = t && _masterValid(master);
    t = t && current >= 0 && current < _types.length;
    t = t && master.indexOf(current) >= 0;
    t = t && configPos != null && config != null;
    t = t && !configPos.any((p) => p < 0 || p >= _types.length || _types[p] is! DevListTypeIdList);
    t = t && config.length == configPos.length;

    if (t) {
      _master = master;
      _current = current;
    } else {
      print("Invalid pos @ master $current @ $master");
      _master = Iterable<int>.generate(_types.length).toList();
      _current = 0;
    }

    for (final t in _types)
      if (t is DevListTypeIdList)
        t.setIds([]);

    if (t) {
      for (final mi in zip(configPos, config)) {
        final t = _types[mi.key];
        if (t is DevListTypeIdList)
          t.setIds(mi.value);
      }
    }
  }

  @override
  List<ReorderListItem<String>?>? startEditList() {
    final t = _types[_current];
    if (t is DevListTypeIdList) {
      final ids = t.getIds();

      final names = Map.fromEntries(_devices!.map((dev) => MapEntry(dev.id!, dev.metrics?.title ?? dev.id!)));
      final l0 = ids.map((id) => names.containsKey(id) ? ReorderListItem(id, names.remove(id)!) : null).toList();
      final l1 = names.entries.map((me) => ReorderListItem(me.key, me.value)).toList();
      return l0 + [ReorderListItem.sep()] + l1;
    }
    else
      return null;
  }

  @override
  void endEditList(List<ReorderListItem<String>> result) {
    final t = _types[_current];
    if (t is DevListTypeIdList) {
      int sep = result.indexWhere((i) => i.isSeparator);
      if (sep >= 0) result = result.take(sep).toList();
      final rv = result.map((rli) => rli.i!.id).toList();
      print("Set ids $rv");
      t.setIds(rv);
    }
  }

  ViewConfig makeConfig() {
    var l = <String>[];
    l.add("16");
    l.add(_current.toString());
    l.add(_master!.length.toString());
    l.addAll(_master!.map((w) => w.toString()));
    for (final mi in zipWithIndex(_types)) {
      final t = mi.key;
      if (t is DevListTypeIdList) {
        l.add(mi.value.toString());
        final ids = t.getIds();
        l.add(ids.length.toString());
        l.addAll(ids);
      }
    }
    //print("w cfg: $l");
    return ViewConfig(l);
  }

  void parseConfig(ViewConfig viewConfig) {
    int pos = -1;
    List<int>? master;
    List<int>? configPos;
    List<List<String>>? config;
    int cnt = -1;
    int ival = -1;

    final configRaw = viewConfig.views;

    if (configRaw != null) {
      final termS = configRaw.fold(_S.ver, (s, v) {
        if (s != _S.cfgItem) {
          ival = int.tryParse(v) ?? -1;
          if (ival < 0) return _S.err;
        }
        switch (s) {
          case _S.ver:
            return (ival == 16) ? _S.pos : _S.err;
          case _S.pos:
            pos = ival;
            return _S.mLen;
          case _S.mLen:
            cnt = ival;
            master = <int>[];
            return cnt > 0 ? _S.mItem : _S.err;
          case _S.mItem:
              master!.add(ival);
              cnt--;
              return cnt > 0 ? _S.mItem : _S.cfgP;
          case _S.cfgP:
            if (configPos == null) configPos = <int>[];
            configPos!.add(ival);
            return _S.cfgLen;
          case _S.cfgLen:
            if (config == null) config = <List<String>>[];
            cnt = ival;
            config!.add(<String>[]);
            return cnt > 0 ? _S.cfgItem : _S.cfgP;
          case _S.cfgItem:
            config!.last.add(v);
            cnt--;
            return cnt > 0 ? _S.cfgItem : _S.cfgP;
          default:
            return _S.err;
        }
      });
      if (termS != _S.cfgP) master = null;
    }

    if (master != null) {
      applyConfig(pos, master, configPos, config);
    } else {
      applyConfig(-1, null, null, null);
    }

  }

}

