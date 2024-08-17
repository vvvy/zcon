import 'dart:async';
import 'dart:isolate';

import 'package:zcon/pdu.dart';

import 'i18n.dart';

class NioConfig {
  final FetchConfig fetchConfig;
  final int intervalMainS;
  final int intervalUpdateS;
  final int intervalErrorRetryS;
  NioConfig({
    required this.fetchConfig,
    required this.intervalMainS,
    required this.intervalUpdateS,
    required this.intervalErrorRetryS
  });
}

sealed class NetworkRequest { }

class Configure implements NetworkRequest {
  final NioConfig config;
  Configure(this.config);
}

class ExecCommand implements NetworkRequest {
  int id;
  String? title;
  String c0;
  String c1;
  String c2;
  ExecCommand(this.id, this.c0, this.c1, this.c2, {this.title});
}

class Pause implements NetworkRequest { }
class Resume implements NetworkRequest { }
class Reload implements NetworkRequest { }

sealed class NetworkIndication { }

class FetchStart implements NetworkIndication {
  bool isFull;
  FetchStart({required this.isFull});
}

class FetchResult implements NetworkIndication {
  bool isFull;
  Devices? devices;
  AppError? error;
  FetchResult({required this.isFull, this.devices, this.error});
}

class CommandStart implements NetworkIndication {
  int id;
  String? title;
  CommandStart({required this.id, this.title});
}

class CommandResult implements NetworkIndication {
  int id;
  String? title;
  AppError? error;
  CommandResult({required this.id, this.title, this.error});
}



abstract interface class NetworkListener {
  void onNetworkEvent(NetworkIndication ni);
}

//-------------------------------------------------------------------------------------------------

class NioSender {
  SendPort? _port;

  void submit(NetworkRequest r) {
    if (_port != null)
      _port!.send(r);
    else
      print("message lost (no send port set)");
  }
}


NioSender startNio(NetworkListener nl) {
  final w = NioSender();
  final r = ReceivePort();
  final s = r.sendPort;
  r.listen((dynamic m) {
    if (m is SendPort)
      w._port = m;
    else
      nl.onNetworkEvent(m as NetworkIndication);
  });
  Isolate.spawn(_nioEntryPont, s);
  return w;
}


class Nio {
  final ReceivePort _input;
  final SendPort _output;
  Timer? _t = null;
  NioConfig? _config = null;
  int _updateTime = 0;
  bool _refresh_error = false;

  Nio(this._input, this._output);

  Future<void> execCommand(ExecCommand c) async {
    if (_config == null) {
      print("no config, bypassing exec");
      return;
    }
    final ExecCommand(id: id, c0: c0, c1: c1, c2: c2, title: title) = c;
    _output.send(CommandStart(id: id, title: title));
    print("starting exec[$id] $c0/$c1/$c2");
    try {
      final _ = await fetch<Null>("$c0/$c1/$c2", _config!.fetchConfig);
      print("exec[$id] success");
      _output.send(CommandResult(id: id, title: title));
    } catch (err) {
      print("exec[$id] failed, err=${err}");
      _output.send(CommandResult(id: id, title: title, error: AppError.convert(err)));
    }
  }

  Future<void> fetchDevices() async {
    if (_config == null) {
      print("no config, bypassing fetch");
      return;
    }
    final isFull = _updateTime == 0;
    final uri = isFull ? "" : "?since=${_updateTime}";

    _output.send(FetchStart(isFull: isFull));
    print("starting fetch, updateTime = ${_updateTime}");
    try {
      final ds = await fetch<Devices>(uri, _config!.fetchConfig);
      _updateTime = ds.updateTime ?? 0;
      print("Fetch success, count=${ds.devices?.length}");
      _output.send(FetchResult(isFull: isFull, devices: ds));
    } catch(err) {
      print("Fetch failed, err=$err");
      _output.send(FetchResult(isFull: isFull, error: AppError.convert(err)));
    }
  }

  void unSchedule() {
    _t?.cancel();
    _t = null;
  }

  void schedule(bool adhoc) {
    final intervalS;
    if (_config == null)
      intervalS = 0;
    else if (adhoc && _config!.intervalUpdateS > 0)
      intervalS = _config!.intervalUpdateS;
    else if (_refresh_error)
      intervalS = _config!.intervalErrorRetryS;
    else
      intervalS = _config!.intervalMainS;

    _t?.cancel();
    if (intervalS > 0)
      _t = Timer(Duration(seconds: intervalS), () async { await fetchDevices(); schedule(false); });
    else
      _t = null;
  }

  Future<void> listen() async {
    await for (final r in _input) {
      print("received: ${r}");


      switch (r as NetworkRequest) {
        case Configure(config: final c):
          _config = c;
          _updateTime = 0;
          await fetchDevices();
          schedule(false);
          break;

        case Reload():
          _updateTime = 0;
          await fetchDevices();
          schedule(false);
          break;

        case ExecCommand():
          await execCommand(r as ExecCommand);
          schedule(true);
          break;

        case Pause():
          unSchedule();
          break;

        case Resume():
          schedule(false);
          break;
      }
    }
  }
}



Future<void> _nioEntryPont(final SendPort output) async {
  final input = ReceivePort();
  output.send(input.sendPort);
  final nio = Nio(input, output);
  await nio.listen();
}