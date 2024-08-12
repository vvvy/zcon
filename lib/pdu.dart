import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:zcon/i18n.dart';

class Metrics {
// "scaleTitle":"°C",
  final String? scaleTitle;
// "level":23,
  final dynamic level;
// "min":5,
  final dynamic min;
// "max":40,
  final dynamic max;
// "icon":"thermostat",
  final String? icon;
// "title":"TS F2",
  final String? title;
// "isFailed":false
  final bool? isFailed;

  Metrics({this.scaleTitle, this.level, this.min, this.max, this.icon, this.title, this.isFailed});

  factory Metrics.fromJson(Map<String, dynamic> json) {
    return Metrics(
      // "scaleTitle":"°C",
      scaleTitle: json['scaleTitle'],
// "level":23,
      level: json['level'],
// "min":5,
      min: json['min'],
// "max":40,
      max: json['max'],
// "icon":"thermostat",
      icon: json['icon'],
// "title":"TS F2",
      title: json['title'],
// "isFailed":false
      isFailed: json['isFailed'],
    );
  }
}

class Device {
// "creationTime":1452191339,
  final int? creationTime;
// "creatorId":1,
  final int? creatorId;
// "customIcons":{},
  final Map<String, String>? customIcons;
// "deviceType":"thermostat",
  final String? deviceType;
// "h":-647335312,
  final int? h;
// "hasHistory":false,
  final bool? hasHistory;
// "id":"ZWayVDev_zway_11-0-67-1",
  final String? id;
// "location":2,
  final int? location;
// "metrics":{"scaleTitle":"°C","level":23,"min":5,"max":40,"icon":"thermostat","title":"TS F2","isFailed":false},
  final Metrics? metrics;
// "order":{"rooms":0,"elements":0,"dashboard":11,"room":6},
  final Map<String, int>? order;
// "permanently_hidden":false,
  final bool? permanentlyHidden;
// "probeType":"thermostat_set_point",
  final String? probeType;
// "tags":[],
  final List<String>? tags;
// "visibility":true,
  final bool? visibility;
// "updateTime":1543532722
  final int? updateTime;

  Device({
    this.creationTime, this.creatorId, this.customIcons, this.deviceType,
    this.h, this.hasHistory, this.id, this.location,
    this.metrics, this.order, this.permanentlyHidden, this.probeType,
    this.tags, this.visibility, this.updateTime
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
// "creationTime":1452191339,
      creationTime: json['creationTime'],
// "creatorId":1,
      creatorId: json['creatorId'],
// "customIcons":{},
      customIcons: asMap(json['customIcons']),
// "deviceType":"thermostat",
      deviceType: json['deviceType'],
// "h":-647335312,
      h: json['h'],
// "hasHistory":false,
      hasHistory: json['hasHistory'],
// "id":"ZWayVDev_zway_11-0-67-1",
      id: json['id'],
// "location":2,
      location: json['location'],
// "metrics":{"scaleTitle":"°C","level":23,"min":5,"max":40,"icon":"thermostat","title":"TS F2","isFailed":false},
      metrics: Metrics.fromJson(json['metrics']),
// "order":{"rooms":0,"elements":0,"dashboard":11,"room":6},
      order: asMap(json['order']),
// "permanently_hidden":false,
      permanentlyHidden: json['permanently_hidden'],
// "probeType":"thermostat_set_point",
      probeType: json['probeType'],
// "tags":[],
      tags: asList(json['tags']),
// "visibility":true,
      visibility: json['visibility'],
// "updateTime":1543532722
      updateTime: json['updateTime'],
    );
  }
}

class DeviceLink {
  final String _devId;
  int _positionHint = -1;
  DeviceLink(this._devId);

  /// get the device by link, possibly updating _positionHint
  Device? getDevice(List<Device> devices) {
    //if the device is still in its old position, return it immediately
    if (_positionHint >= 0 && _positionHint < devices.length &&
        devices[_positionHint].id == _devId) return devices[_positionHint];
    //Search for the device
    final pos = devices.indexWhere((dev) => dev.id == _devId);
    if (pos >= 0) {
      _positionHint = pos;
      return devices [_positionHint];
    }
    return null;
  }
}

class Devices {
  final bool? structureChanged;
  final int? updateTime;
  final List<Device>? devices;

  Devices({this.structureChanged, this.updateTime, this.devices});

  factory Devices.fromJson(Map<String, dynamic> json) {
    return Devices(
      structureChanged: json['structureChanged'],
      updateTime: json['updateTime'],
      devices: (() {
        var r = json['devices'] as List<dynamic>;
        var rv = List<Device>.empty(growable: true);
        for(var v in r) rv.add(Device.fromJson(v));
        return rv;
      })()
      //asList(json['devices'])
    );
  }

  Devices merge(Devices update) {
    return Devices(
      structureChanged: update.structureChanged,
      updateTime: update.updateTime,  //max???
      devices: () {
        if (devices == null || devices!.isEmpty) return update.devices;
        if (update.devices == null || update.devices!.isEmpty) return devices;
        var m = Map.fromEntries(
            update.devices!.where((dev) => dev.id != null).map((dev) => MapEntry(dev.id!, dev))
        );
        var rv = devices!.map((d) => m.containsKey(d.id) ? m.remove(d.id)! : d).toList();
        rv.addAll(m.values);
        return rv;
      }()
    );
  }
}

class Null { }

String joinPaths(String a, String b) {
  return a + ((a.endsWith("/") || b.isEmpty || b.startsWith(new RegExp("[/?#]"))) ? "" : "/") + b;
}

class FetchConfig {
  final String url;
  final String username;
  final String password;
  FetchConfig({
    required this.url,
    required this.username,
    required this.password,
  });
}

//https://dacha.vybornov.name/ZAutomation/api/v1/devices?since=1543949982
//{"data":{"structureChanged":false,"updateTime":1543949984,"devices":[]},"code":200,"message":"200 OK","error":null}

Future<T> fetch<T>(String p, FetchConfig config) async {
  if (config.url.isEmpty) return Future.error(AppError.urlNeeded());
    //Future.error("URL not set - please set it via settings");
  HttpClient client = new HttpClient();
  var url = joinPaths(joinPaths(config.url, "ZAutomation/api/v1/devices"), p);
  print("Connecting to: $url");
  var uri = Uri.tryParse(url);
  if (uri == null) {
    return Future.error(AppError.urlInvalid());
  }
  if (config.username != "")
    client.addCredentials(uri, "",
        new HttpClientBasicCredentials(config.username, config.password));
  HttpClientRequest request = await client.getUrl(uri);
  HttpClientResponse response = await request.close();
  //TODO if content-type is json, parse it even if statusCode != 200
  if (response.statusCode == 200) {
    // If the call to the server was successful, parse the JSON
    final jsonO = await response.transform(utf8.decoder).transform(JsonDecoder()).first;
    final zr = ZAResponse<T>.fromJson(jsonO!);
    if (zr.code != 200)
      return Future<T>.error(AppError.zaAppError(zr.code ?? 599, zr.message ?? "<No message>"));
    return Future<T>.value(zr.data);
  } else {
    // If that call was not successful, throw an error.
    return Future<T>.error(AppError.zaHttpError(response.statusCode, response.reasonPhrase));
  }
}

T dataFromJson<T>(dynamic json) {
  if (T == Device) {
    return Device.fromJson(json) as T;
  } else if (T == Devices) {
      return Devices.fromJson(json) as T;
  } else if (T == Null) {
    return Null() as T;
  } else {
    throw new Exception("dataFromJson: unknown type");
  }
}

List<T> asList<T>(dynamic s) {
  return (s as List<dynamic>).map((v) => v as T).toList();
}

Map<String, T> asMap<T>(dynamic s) {
  var r = s as Map<String, dynamic>;
  var rv = Map<String, T>();
  for(var k in r.keys) {
    rv[k] = r[k] as T;
  }
  return rv;
}

class ZAResponse<T> {
  final T? data;
  final int? code;
  final String? message;
  final String? error;

  ZAResponse({this.data, this.code, this.message, this.error});

  factory ZAResponse.fromJson(Object json_object) {
    var json = json_object as Map<String, dynamic>;
    return ZAResponse<T>(
      data: dataFromJson<T>(json['data']),
      code: json['code'],
      message: json['message'],
      error: json['error'],
    );
  }
}

T nvl<T>(T? t, T alt) {
  if (t == null) return alt; else return t;
}