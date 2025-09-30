// main.dart (simplified)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/recorder_service.dart';
import 'services/bluetooth_service.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'models/sample.dart';
import 'widgets/live_canvas.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class AppState extends ChangeNotifier {
  final RecorderService recorder = RecorderService();
  late BluetoothService bluetooth;
  bool recording = false;
  BluetoothDevice? connectedDevice;

  AppState() {
    bluetooth = BluetoothService(recorder);
  }

  void setRecording(bool v) {
    recording = v;
    notifyListeners();
  }

  void setConnectedDevice(BluetoothDevice? d) {
    connectedDevice = d;
    notifyListeners();
  }

  List<Sample> get buffer => recorder.buffer;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomePage(),
        theme: ThemeData(
          primaryColor: Color(0xFF87CEEB),
          scaffoldBackgroundColor: Colors.white,
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget { @override _HomePageState createState() => _HomePageState(); }

class _HomePageState extends State<HomePage> {
  late AppState appState;
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    appState = Provider.of<AppState>(context, listen: false);
    _uiTimer = Timer.periodic(Duration(milliseconds: 200), (_) {
      if (mounted) setState((){});
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  Future<void> _connect() async {
    final devices = await appState.bluetooth.getBondedDevices();
    final chosen = await showDialog<BluetoothDevice>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Select device'),
        children: devices.map((d) => SimpleDialogOption(child: Text(d.name ?? d.address), onPressed: (){ Navigator.pop(ctx, d); })).toList(),
      ),
    );
    if (chosen != null) {
      await appState.bluetooth.connect(chosen);
      appState.setConnectedDevice(chosen);
      appState.setRecording(true);
    }
  }

  Widget _connStatus() {
    final dev = appState.connectedDevice;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(dev!=null ? 'Connected: ${dev.name}' : 'Disconnected', style: TextStyle(fontWeight: FontWeight.bold)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF87CEEB)),
          onPressed: _connect,
          child: Text(dev==null ? 'Connect' : 'Reconnect'),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final buf = appState.buffer;
    final last = buf.isNotEmpty ? buf.last : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF87CEEB),
        title: Text('ماژیک هوشمند', textDirection: TextDirection.rtl),
      ),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            _connStatus(),
            SizedBox(height: 12),
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(children: [
                  Text('Live Readouts', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height:8),
                  Row(children: [
                    Expanded(child: Text('ax: ${last!=null ? last.ax.toStringAsFixed(3) : '-'}')),
                    Expanded(child: Text('ay: ${last!=null ? last.ay.toStringAsFixed(3) : '-'}')),
                    Expanded(child: Text('az: ${last!=null ? last.az.toStringAsFixed(3) : '-'}')),
                  ]),
                  SizedBox(height:6),
                  Row(children: [
                    Expanded(child: Text('gx: ${last!=null ? last.gx.toStringAsFixed(2) : '-'}')),
                    Expanded(child: Text('gy: ${last!=null ? last.gy.toStringAsFixed(2) : '-'}')),
                    Expanded(child: Text('gz: ${last!=null ? last.gz.toStringAsFixed(2) : '-'}')),
                  ]),
                ]),
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: LiveCanvas(samples: buf),
                ),
              ),
            ),
            SizedBox(height: 8),
            Row(children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF87CEEB)),
                onPressed: () async {
                  if (!appState.recording) {
                    appState.setRecording(true);
                  }
                },
                child: Text('Start (auto on connect)'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                onPressed: () async {
                  if (appState.buffer.isNotEmpty) {
                    final path = await appState.recorder.saveToDownloads();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to \$path')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No data to save')));
                  }
                },
                child: Text('Save'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                onPressed: () {
                  appState.recorder.clear();
                  setState((){});
                },
                child: Text('Clear'),
              )
            ],)
          ],
        ),
      ),
    );
  }
}