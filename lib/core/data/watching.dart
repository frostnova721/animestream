import "package:hive/hive.dart";

Future<void> storeWatching(
    String title, String imageUrl, int id, int watched) async {
  try {
  var box = await Hive.openBox('animestream');
  if (!box.isOpen) {
    box = await Hive.openBox('animestream');
  }
  final List watchingList = box.get('watching') ?? [];
  final currList = watchingList.where((item) => item['id'] == id).toList();
  if (currList.length != 0 && currList[0]['watched'] <= watched) {
    watchingList.removeWhere((item) => item['id'] == id);
  }
  watchingList.add(
      {'title': title, 'imageUrl': imageUrl, 'id': id, 'watched': watched,});
  box.put('watching', watchingList);
  box.close();
  } catch(err) {
    print(err);
  }
}

Future<void> updateWatching(String title, int watched) async {
  try {
  var box = await Hive.openBox('animestream');
  if (!box.isOpen) {
    box = await Hive.openBox('animestream');
  }
  final List watchingList = box.get('watching') ?? [];
  final index = watchingList.indexWhere((item) => item['title'] == title);
  if (index != -1) {
    watchingList[index]['watched'] = watched;
  } else {
    print('noData');
  }
  box.put('watching', watchingList);
  box.close();
  } catch(err) {
    print(err);
  }
}
