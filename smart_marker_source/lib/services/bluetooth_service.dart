import 'dart:async';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../models/sample.dart';
import 'recorder_service.dart';

typedef OnConnectedCallback = void Function();
typedef OnDisconnectedCallback = void Function();

class BluetoothService {
  final RecorderService recorder;
  BluetoothConnection? _connection;
  StreamSubscription<String>? _subs;
  bool isConnecting = false;
  bool get isConnected => _connection != null && _connection!.isConnected;

  BluetoothService(this.recorder);

  Future<List<BluetoothDevice>> getBondedDevices() async {
    return await FlutterBluetoothSerial.instance.getBondedDevices();
  }

  Future<void> connect(BluetoothDevice device, {OnConnectedCallback? onConnected, OnDisconnectedCallback? onDisconnected}) async {
    try {
      isConnecting = true;
      _connection = await BluetoothConnection.toAddress(device.address);
      isConnecting = false;
      onConnected?.call();
      _listen();
    } catch (e) {
      isConnecting = false;
      rethrow;
    }
  }

  void _listen() {
    if (_connection == null) return;
    _connection!.input?.transform(utf8.decoder).listen((data) {
      _handleIncoming(data);
    }, onDone: () {
      _handleDisconnect();
    }, onError: (e) {
      _handleDisconnect();
    });
  }

  void _handleIncoming(String chunk) {
    final lines = chunk.split(RegExp(r'[\r\n]+')).where((l) => l.trim().isNotEmpty);
    for (final line in lines) {
      final raw = line.trim();
      try {
        final parts = raw.split(',');
        if (parts.length >= 8) {
          final ax = double.tryParse(parts[1]) ?? 0.0;
          final ay = double.tryParse(parts[2]) ?? 0.0;
          final az = double.tryParse(parts[3]) ?? 0.0;
          final gx = double.tryParse(parts[5]) ?? 0.0;
          final gy = double.tryParse(parts[6]) ?? 0.0;
          final gz = double.tryParse(parts[7]) ?? 0.0;

          final sample = Sample(
            ts: DateTime.now().toUtc(),
            ax: ax, ay: ay, az: az,
            gx: gx, gy: gy, gz: gz,
            raw: raw,
          );
          recorder.appendSample(sample);
        } else {
          recorder.logRawLine(raw);
        }
      } catch (e) {
        recorder.logRawLine(raw);
      }
    }
  }

  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
  }

  void _handleDisconnect() {
    _connection = null;
  }
}