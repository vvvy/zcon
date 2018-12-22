import 'pdu.dart';
//------------------------------------------------------------------------------

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
  DevList getList(List<Device> devices, {bool rebuildHint}) { return DevListIdentity(devices); }
}

typedef bool DevF(Device d);
typedef int DevS(Device d1, Device d2);

List<int> buildIndex(List<Device> devices, DevF f, DevS s) {
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
  final DevS _s;
  List<int> _pos;
  @override
  DevList getList(List<Device> devices, {bool rebuildHint}) {
    if (rebuildHint || _pos == null)
      _pos = buildIndex(devices, _f, _s);
    return DevListIndex(devices, _pos);
  }

  DevListTypeIndex({DevF f, DevS s}):
        _f = f,
        _s = s;
}

Iterable<MapEntry<T, int>> zipWithIndex<T>(Iterable<T> l) {
  var n = 0;
  return l.map((i) => MapEntry(i, n++));
}

Iterable<MapEntry<T, U>> zip<T, U>(Iterable<T> t, Iterable<U> u) {
  var ui = u.iterator;
  return t.map((tv) => ui.moveNext() ? MapEntry(tv, ui.current) : null).takeWhile((i) => i != null);
}

class DevListTypeIdList extends DevListType {
  List<String> _ids;
  List<int> _pos;

  @override
  DevList getList(List<Device> devices, {bool rebuildHint}) {
    if (rebuildHint || _pos == null) {
      var m = Map.fromEntries(zipWithIndex(devices).map((me) => MapEntry(me.key.id, me.value)));
      _ids.removeWhere((id) => !m.containsKey(id));
      _pos = _ids.map((id) => m[id]).toList();
    }
    return  DevListIndex(devices, _pos);
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

  IdName(Id id, String name) : id = id, name = name;
}

class ReorderListItem<Id> {
  final IdName<Id> i;
  final bool isSeparator;

  ReorderListItem(Id id, String name) : i = IdName(id, name), isSeparator = false;
  ReorderListItem.sep(): i = null, isSeparator = true;
  @override
  String toString() => isSeparator ? "---------" : "${i.name}@${i.id}";
}

abstract class AbstractDevListController {
  bool get isOnline;
  bool get isListEditable;
  void applyDevices(List<Device> dev, {bool rebuildHint});
  void applyConfig(int pos, List<int> master, List<int> configPos, List<List<String>> config);
  int get current;
  set current(int id);
  List<IdName> get master;
  List<ReorderListItem<int>> startEditMaster();
  void endEditMaster(List<ReorderListItem<int>> result);
  DevList get list;
  List<ReorderListItem<String>> startEditList();
  void endEditList(List<ReorderListItem<String>> result);
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


class DevListController extends AbstractDevListController {
  static Map<String, DevListType> _typeMap() => {
    "All": DevListTypeIdentity(),
    "Temperature": DevListTypeIndex(f: deviceAndProbeTypeFilter("sensorMultilevel", "temperature")),
    "Thermostats": DevListTypeIndex(f: deviceTypeFilter("thermostat")),
    "Scene": DevListTypeIndex(f: deviceTypeFilter("toggleButton")),
    "Switches": DevListTypeIndex(f: deviceTypeFilter("switchBinary")),
    "Battery": DevListTypeIndex(f: deviceTypeFilter("battery")),
    "Failed": DevListTypeIndex(f: (d) => d.metrics.isFailed == true),
    "Custom1": DevListTypeIdList(),
    "Custom2": DevListTypeIdList(),
    "Custom3": DevListTypeIdList(),
    "Custom4": DevListTypeIdList(),
    "Custom5": DevListTypeIdList(),
  };

  List<DevListType> _types;
  List<String> _typeNames;
  List<int> _generations;
  int _generation;
  List<int> _master;
  int _current;

  List<Device> _devices;

  DevListController() {
    final typeMap = _typeMap();
    _typeNames = typeMap.keys.toList(growable: false);
    _types = typeMap.values.toList(growable: false);
    _generations = Iterable.generate(_types.length, (_) => 0).toList(growable: false);
    _generation = 0;
  }

  @override
  bool get isOnline => _master != null && _devices != null;

  @override
  bool get isListEditable => _types[_current] is DevListTypeIdList;

  @override
  int get current => _current;

  @override
  set current(int current) {
    if (_master.indexOf(current) < 0)
      print("setPos: Error: ivalid current=$current on master=$_master");
    else
      _current = current;
  }

  @override
  List<IdName<int>> get master =>  _master.map((i) => IdName(i, _typeNames[i])).toList();

  @override
  List<ReorderListItem<int>> startEditMaster() {
    final masterComplement = Iterable.generate(_typeNames.length).toSet().difference(_master.toSet());
    final l = _master.map((i) => ReorderListItem(i, _typeNames[i])).toList();
    final m = masterComplement.map((i) => ReorderListItem(i, _typeNames[i])).toList();
    return l + [ReorderListItem.sep()] + m;
  }

  bool _masterValid(List<int> rv) {
    var t = rv.toSet().length == rv.length;
    t = t && !rv.any((v) => v < 0) && !rv.any((v) => v >= _types.length);
    t = t && rv.length == _types.length;
    return t;
  }

  @override
  void endEditMaster(List<ReorderListItem<int>> result) {
    int sep = result.indexWhere((i) => i.isSeparator);
    if (sep >= 0) result = result.take(sep);
    final rv = result.map((rli) => rli.i.id);
    if (_masterValid(rv))
      _master = rv;
    else
      print("Error: endEditMaster: invalid input: $result");
  }

  @override
  void applyDevices(List<Device> dev, {bool rebuildHint}) {
    _devices = dev;
    if (rebuildHint) _generation++;
  }

  @override
  DevList get list {
    var rebuildHint = false;
    if (_generations[_current] != _generation) {
      _generations[_current] = _generation;
      rebuildHint = true;
    }
    return _types[_current].getList(_devices, rebuildHint: rebuildHint);
  }

  @override
  void applyConfig(int current, List<int> master, List<int> configPos, List<List<String>> config) {
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
  List<ReorderListItem<String>> startEditList() {
    final t = _types[_current];
    if (t is DevListTypeIdList) {
      final ids = t.getIds();

      final names = Map.fromEntries(_devices.map((dev) => MapEntry(dev.id, dev.metrics.title ?? dev.id)));
      final l0 = ids.map((id) => names.containsKey(id) ? ReorderListItem(id, names.remove(id)) : null).toList();
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
      final rv = result.map((rli) => rli.i.id).toList();
      print("Set ids $rv");
      t.setIds(rv);
    }
  }

  List<String> makeConfig() {
    var l = <String>[];
    l.add("16");
    l.add(_current.toString());
    l.add(_master.length.toString());
    l.addAll(_master.map((w) => w.toString()));
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
    return l;
  }

  void parseConfig(List<String> configRaw) {
    int pos = -1;
    List<int> master;
    List<int> configPos;
    List<List<String>> config;
    int cnt;
    int ival;

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
              master.add(ival);
              cnt--;
              return cnt > 0 ? _S.mItem : _S.cfgP;
          case _S.cfgP:
            if (configPos == null) configPos = <int>[];
            configPos.add(ival);
            return _S.cfgLen;
          case _S.cfgLen:
            if (config == null) config = <List<String>>[];
            cnt = ival;
            config.add(<String>[]);
            return cnt > 0 ? _S.cfgItem : _S.cfgP;
          case _S.cfgItem:
            config.last.add(v);
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


/*
class DevListController2 {
  final Map<String, DevListType> _typeMap = {
    "All": DevListTypeIdentity(),
    "Temperature": DevListTypeIndex(f: deviceAndProbeTypeFilter("sensorMultilevel", "temperature")),
    "Thermostats": DevListTypeIndex(f: deviceTypeFilter("thermostat")),
    "Scene": DevListTypeIndex(f: deviceTypeFilter("toggleButton")),
    "Switches": DevListTypeIndex(f: deviceTypeFilter("switchBinary")),
    "Battery": DevListTypeIndex(f: deviceTypeFilter("battery")),
    "Failed": DevListTypeIndex(f: (d) => d.metrics.isFailed == true),
    "LeftDrawer": DevListTypeIdList(),
    "RightDrawer": DevListTypeIdList(),
    "Custom1": DevListTypeIdList(),
    "Custom2": DevListTypeIdList(),
    "Custom3": DevListTypeIdList(),
    "Custom4": DevListTypeIdList(),
    "Custom5": DevListTypeIdList(),
  };

  /// an offset into above where customizable items start
  //static final customizablePos = 7;


  void applyDevices(List<Device> dev, {bool rebuildHint}) { }




  List<Device> _devices;
  bool _rebuildHint = false;

  DevListController2() {
    //_masterConfig = fix(zipWithIndex(_typeMap.keys.toList()).map((me) => ReorderListItem(me.value, me.key)).toList());
  }


}
*/

/*

class DevListController3 {


  //final List<DevListType> _types = () {
  //  const x = List._typesStd
  //} ();

  //static final List<String> _names = _types.map((tp) => tp.getName()).toList();
  List<List<ReorderListIdItem<String>>>> _config;
  List<ReorderListItem<int>> _masterConfig;
  int _pos = 0;
  List<Device> _devices;
  bool _rebuildHint = false;

  void setDevices(List<Device> dev, {bool rebuildHint}) {
    _devices = dev;
    _rebuildHint = rebuildHint;
    //initialize current filter
  }
  List<String> getAvailableFilters() { return _names; }
  void setFilter(String name) {
    print("Setting filter: $name");
    var p = _names.indexOf(name);
    if (p >= 0) _pos = p;
    print("Actual filter index: $_pos");
  }
  String getFilter() { return _names[_pos]; }
  DevList getList() { return _types[_pos].getList(_devices, rebuildHint: _rebuildHint); }

  bool isEditable() {
    return _types[_pos] is DevListTypeIdList;
  }

  List<ReorderListItem<int>> startEditMaster() {
    return null;
  }

  void endEditMaster(List<ReorderListItem<int>> result) {
  }

  List<ReorderListItem<int>> displayMaster() {
    return null;
  }


  List<ReorderListItem<String>> startEditFilter() {
    return null;
  }

  void endEditFilter(List<ReorderListItem<String>> result) {
  }
}
*/


/*

/// Ensures there is exactly one separator; adds to the end if none
List<ReorderListItem<Id>> fix<Id>(List<ReorderListItem<Id>> s) {
  var i = s.indexWhere((w) => w.id.isSeparator);
  if (i < 0) {
    s.add(ReorderListItem.sep());
    return s;
  } else {
    //remove all but last sep
    return zipWithIndex(s).where((mi) => !mi.key.id.isSeparator || mi.value == i).map((mi) => mi.key).toList();
  }
}


List<Id> display<Id>(List<ReorderListIdItem<Id>> s) {
  var i = s.indexWhere((w) => w.isSeparator);
  if (i < 0) {
    return s.map((w) => w.id).toList();
  } else {
    return s.take(i).map((w) => w.id).toList();
  }
}

typedef String NameF<Id>(Id id);

List<ReorderListItem<Id>> edit<Id>(List<ReorderListIdItem<Id>> s, NameF nameF) {
  return s.map((w) {
    if (w.isSeparator)
      return ReorderListItem.sep();
    else {
      var name = nameF(w.id);
      if (name != null) {
        return ReorderListItem(w.id, name);
      } else {
        return null;
      }
    }
  }).where((w) => w != null);
}
*/