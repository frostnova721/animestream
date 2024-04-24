import 'dart:io';

class Logger {
  Future<void> writeLog(String data) async {
    //write the log to Documents folder
    final dir = await Directory('/storage/emulated/0/Documents/animestream/logs');
    if(!(await dir.exists())) {
      await dir.create(recursive: true);
    }
    final now = DateTime.now();
    final dateAndTime = "${now.day}${now.month}${now.year}_${now.hour}${now.minute}${now.second}";
    final filePath = "${dir.path}/$dateAndTime.txt";
    final file = File(filePath);
    await file.writeAsString(data);
    print("written stuff to $filePath");
  }
}