import 'dart:io';

class Logger {
  static final Logger _instance = Logger._internal();
  Logger._internal();
  factory Logger() => _instance;

  final List<String> _logBuffer = [];

  void addLog(String log) {
    _logBuffer.add(log);
  }

  void clearLog() => _logBuffer.clear();

  Future<void> writeLog() async {
    //write the log to Documents folder
    final dir = await Directory('/storage/emulated/0/Documents/animestream/logs');
    if(!(await dir.exists())) {
      await dir.create(recursive: true);
    }
    final now = DateTime.now();
    final dateAndTime = "${now.day}${now.month}${now.year}_${now.hour}${now.minute}${now.second}";
    final filePath = "${dir.path}/$dateAndTime.txt";
    final file = File(filePath);
    final data = _logBuffer.join(' \n');
    await file.writeAsString(data);
    print("written stuff to $filePath");
  }
}