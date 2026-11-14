import 'dart:io';

import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/commons/enums/hiveEnums.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/local/local.dart';
import 'package:animestream/core/database/types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory dir;

  final anilist = LocalTracker(source: Databases.anilist);
  final simkl = LocalTracker(source: Databases.simkl);

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('local_tracker_test');
    Hive.init(dir.path);

    // legacy data, as the old watching.dart stored it (active db was anilist)
    final legacy = await Hive.openBox(HiveBox.animestream.boxName);
    await legacy.put(HiveKey.watching.name, [
      {'title': 'Old Show', 'imageUrl': 'old.jpg', 'id': 1, 'watched': 3, 'rating': 7.5, 'totalEpisodes': 12},
    ]);
  });

  tearDownAll(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('migrates legacy watching list once', () async {
    final p = await anilist.getAnimeWatchProgress(1);
    expect(p.progress, 3);
    expect(p.status, 'CURRENT');

    final legacy = await Hive.openBox(HiveBox.animestream.boxName);
    expect(legacy.get(HiveKey.watching.name), isNull);
  });

  test('saveMeta alone does not list the anime', () async {
    await anilist.saveMeta(id: 2, title: {'english': 'New'}, cover: 'new.jpg', totalEpisodes: 2);

    final p = await anilist.getAnimeWatchProgress(2);
    expect(p.progress, isNull);
    expect(p.status, isNull);
    final lists = await anilist.getUserAnimeList('');
    expect(lists.expand((l) => l.list).any((i) => i.id == 2), isFalse);
  });

  test('mutate keeps unspecified fields and auto-completes', () async {
    await anilist.mutateAnimeList(id: 2, status: MediaStatus.CURRENT, progress: 1);
    await anilist.mutateAnimeList(id: 2, status: MediaStatus.PAUSED);
    expect((await anilist.getAnimeWatchProgress(2)).progress, 1);

    final res = await anilist.mutateAnimeList(id: 2, status: MediaStatus.CURRENT, progress: 2);
    expect(res?.status, 'COMPLETED');
  });

  test('lists group by status and filter', () async {
    final all = await anilist.getUserAnimeList('');
    expect(all.map((l) => l.name), ['Watching', 'Completed']);
    expect(all.first.list.single.title['english'], 'Old Show');

    final current = await anilist.getUserAnimeList('', status: [MediaStatus.CURRENT]);
    expect(current.single.list.single.id, 1);
  });

  test('entry without an id for the active db is hidden, then linked via otherIds', () async {
    // anime 1 only has an anilist id so far
    expect((await simkl.getAnimeWatchProgress(501)).status, isNull);
    expect((await simkl.getUserAnimeList('')).expand((l) => l.list), isEmpty);

    // user opens it while on simkl; simkl's info gives all ids
    await simkl.mutateAnimeList(
      id: 501,
      progress: 4,
      otherIds: [AlternateDatabaseId(database: Databases.anilist, id: 1)],
    );

    final onSimkl = await simkl.getUserAnimeList('', status: [MediaStatus.CURRENT]);
    expect(onSimkl.single.list.single.id, 501); // simkl id, so the info page opens right
    expect(onSimkl.single.list.single.title['english'], 'Old Show'); // same entry, meta kept

    // switching back to anilist shows the same progress
    expect((await anilist.getAnimeWatchProgress(1)).progress, 4);
  });

  test('two entries for the same anime get merged, newest progress wins', () async {
    await anilist.saveMeta(id: 3, title: {'english': 'Split'}, cover: 'split.jpg');
    await anilist.mutateAnimeList(id: 3, progress: 2);
    await simkl.mutateAnimeList(id: 903, progress: 5); // tracked separately, no link yet

    await simkl.mutateAnimeList(
      id: 903,
      otherIds: [AlternateDatabaseId(database: Databases.anilist, id: 3)],
    );

    final a = await anilist.getEntry(3);
    final s = await simkl.getEntry(903);
    expect(a?.progress, 5);
    expect(s?.title['english'], 'Split');
    expect(a?.ids, s?.ids);

    final box = await Hive.openBox(HiveBox.localTracker.boxName);
    expect(box.values.where((v) => (v as Map)['ids']['anilist'] == 3).length, 1);
  });

  test('delete removes the entry for every id', () async {
    await anilist.deleteAnimeEntry(id: 1);
    expect((await anilist.getAnimeWatchProgress(1)).status, isNull);
    expect((await simkl.getAnimeWatchProgress(501)).status, isNull);
  });
}
