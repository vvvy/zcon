import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:zcon/pref.dart';

class Metrics {
// "scaleTitle":"°C",
  final String scaleTitle;
// "level":23,
  final dynamic level;
// "min":5,
  final dynamic min;
// "max":40,
  final dynamic max;
// "icon":"thermostat",
  final String icon;
// "title":"TS F2",
  final String title;
// "isFailed":false
  final bool isFailed;

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
  final int creationTime;
// "creatorId":1,
  final int creatorId;
// "customIcons":{},
  final Map<String, String> customIcons;
// "deviceType":"thermostat",
  final String deviceType;
// "h":-647335312,
  final int h;
// "hasHistory":false,
  final bool hasHistory;
// "id":"ZWayVDev_zway_11-0-67-1",
  final String id;
// "location":2,
  final int location;
// "metrics":{"scaleTitle":"°C","level":23,"min":5,"max":40,"icon":"thermostat","title":"TS F2","isFailed":false},
  final Metrics metrics;
// "order":{"rooms":0,"elements":0,"dashboard":11,"room":6},
  final Map<String, int> order;
// "permanently_hidden":false,
  final bool permanentlyHidden;
// "probeType":"thermostat_set_point",
  final String probeType;
// "tags":[],
  final List<String> tags;
// "visibility":true,
  final bool visibility;
// "updateTime":1543532722
  final int updateTime;

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

class Devices {
  final bool structureChanged;
  final int updateTime;
  final List<Device> devices;

  Devices({this.structureChanged, this.updateTime, this.devices});

  factory Devices.fromJson(Map<String, dynamic> json) {
    return Devices(
      structureChanged: json['structureChanged'],
      updateTime: json['updateTime'],
      devices: (() {
        var r = json['devices'] as List<dynamic>;
        var rv = List<Device>();
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
        var m = Map.fromEntries(update.devices.map((dev) => MapEntry(dev.id, dev)));
        var rv = devices.map((d) => m.containsKey(d.id) ? m.remove(d.id) : d).toList();
        if (m.isNotEmpty) rv.addAll(m.values);
        return rv;
      }()
    );
  }
}

class Null { }

String joinPaths(String a, String b) {
  return a + ((a.endsWith("/") || b.isEmpty || b.startsWith(new RegExp("[/?#]"))) ? "" : "/") + b;
}

//https://dacha.vybornov.name/ZAutomation/api/v1/devices?since=1543949982
//{"data":{"structureChanged":false,"updateTime":1543949984,"devices":[]},"code":200,"message":"200 OK","error":null}

Future<T> fetch<T>(String p, Settings settings) async {
  if (settings.url.isEmpty) return Future.error("URL not set - please set it via settings");
  HttpClient client = new HttpClient();
  var url = joinPaths(joinPaths(settings.url, "ZAutomation/api/v1/devices"), p);
  print("Connecting to: $url");
  var uri = Uri.tryParse(url);
  if (uri == null) {
    return Future.error("Invalid URL");
  }
  if (settings.username != "")
    client.addCredentials(uri, "",
        new HttpClientBasicCredentials(settings.username, settings.password));

  /*
  final request = await client.getUrl(uri);
  final response = await request.close();
  if (response.statusCode == 200) {
    // If the call to the server was successful, parse the JSON
    final jsonS = await response.transform(utf8.decoder).join(" ");
    var zr = ZAResponse<T>.fromJson(json.decode(jsonS));
    if (zr.code != 200)
      return Future<T>.error("ZA app error: " + zr.message);
    //print("ZR data: " +(zr.data as Device).metrics.level.toString());
    return Future<T>.value(zr.data);
  } else {
    // If that call was not successful, throw an error.
    return Future<T>.error('Failed to process ZA response: ' + response.statusCode.toString());
  }
  */
  final response = await client.getUrl(
      uri
  ).then((HttpClientRequest request) =>
      request.close()
  ).then((HttpClientResponse response) {
    if (response.statusCode == 200) {
      // If the call to the server was successful, parse the JSON

      return response.transform(utf8.decoder).join(" ").then((jsonS){
        var zr = ZAResponse<T>.fromJson(json.decode(jsonS));
        if (zr.code != 200) return Future<T>.error("ZA app error: " + zr.message);
        //print("ZR data: " +(zr.data as Device).metrics.level.toString());
        return Future<T>.value(zr.data);
        });
    } else {
      // If that call was not successful, throw an error.
      return Future<T>.error('Failed to process ZA response: ' + response.statusCode.toString());
  }
  });
  return response;
}

T dataFromJson<T>(dynamic json) {
  if (T == Device) {
    return Device.fromJson(json) as T;
  } else if (T == Devices) {
      return Devices.fromJson(json) as T;
  } else if (T == Null) {
    return Null() as T;
  } else {
    throw new Exception("unknown type");
  }
}

List<T> asList<T>(dynamic s) {
  var r = s as List<dynamic>;
  var rv = List<T>();
  for(var v in r) {
    rv.add(v as T);
  }
  return rv;
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
  final T data;
  final int code;
  final String message;
  final String error;

  ZAResponse({this.data, this.code, this.message, this.error});

  factory ZAResponse.fromJson(Map<String, dynamic> json) {
    return ZAResponse<T>(
      data: dataFromJson<T>(json['data']),
      code: json['code'],
      message: json['message'],
      error: json['error'],
    );
  }
}

T nvl<T>(T t, T alt) {
  if (t == null) return alt; else return t;
}