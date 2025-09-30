import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/sample.dart';
import 'package:intl/intl.dart';

class RecorderService {
  final List<Sample> _buffer = [];
  File? _tempFile;
  IOSink? _tempSink;

  bool get hasData => _buffer.isNotEmpty;

  Future<void> initTempFile() async {
    final dir = await getTemporaryDirectory();
    final path = '\${dir.path}/smartmarker_tmp.csv';
    _tempFile = File(path);
    if (!await _tempFile!.exists()) {
      await _tempFile!.create(recursive: true);
    }
    _tempSink = _tempFile!.openWrite(mode: FileMode.append);
  }

  void appendSample(Sample s) async {
    _buffer.add(s);
    if (_tempSink == null) await initTempFile();
    _tempSink?.writeln(s.toCsvRow());
  }

  void logRawLine(String raw) async {
    if (_tempSink == null) await initTempFile();
    _tempSink?.writeln('\${DateTime.now().toUtc().toIso8601String()},RAW,,,,,,"\$raw"');
  }

  Future<String> saveToDownloads() async {
    final dir = await getExternalStorageDirectory();
    final outDir = Directory('\${dir!.path}/SmartMarker');
    if (!await outDir.exists()) await outDir.create(recursive: true);
    final stamp = DateFormat("yyyyMMdd_HHmmss").format(DateTime.now());
    final fname = 'smartmarker_\$stamp.csv';
    final outFile = File('\${outDir.path}/\$fname');

    final sink = outFile.openWrite(mode: FileMode.write);
    sink.writeln('timestamp,ax,ay,az,gx,gy,gz,source_line');
    for (final s in _buffer) {
      sink.writeln(s.toCsvRow());
    }
    await sink.flush();
    await sink.close();

    _buffer.clear();
    await _tempSink?.flush();
    await _tempSink?.close();
    _tempFile?.deleteSync();
    _tempFile = null;
    _tempSink = null;

    return outFile.path;
  }

  Future<void> clear() async {
    _buffer.clear();
    await _tempSink?.flush();
    await _tempSink?.close();
    if (_tempFile != null && await _tempFile!.exists()) await _tempFile!.delete();
    _tempFile = null;
    _tempSink = null;
  }

  List<Sample> get buffer => List.unmodifiable(_buffer);
}