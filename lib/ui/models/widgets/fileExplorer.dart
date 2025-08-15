import 'dart:io';

import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/downloadHistory.dart';
import 'package:animestream/ui/models/providers/playerDataProvider.dart';
import 'package:animestream/ui/models/providers/playerProvider.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/watchPageUtil.dart';
import 'package:animestream/ui/pages/watch.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FileExplorer extends StatefulWidget {
  const FileExplorer({super.key});

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  @override
  void initState() {
    _readDir();
    super.initState();
  }

  Future<void> _deleteDownload(String filePath, int? id) async {
    if (id != null) await DownloadHistory.removeItem(id);
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  final _rootDir = (currentUserSettings?.downloadPath ?? "/storage/emulated/0/Download/animestream");

  String _getFileName(String path) {
    return Platform.isWindows ? path.split("\\").last : path.split("/").last;
  }

  void _navBack() {
    currentDir = currentDir.parent;
    _readDir();
    setState(() {});
  }

  bool get _canGoBack => currentDir.path != _rootDir;
  Future<void> _readDir() async {
    currentDirPathSplit = currentDir.path.split(Platform.isWindows ? "\\" : "/");
    setState(() {
      _loadingFiles = true;
    });
    final items = <FileSystemEntity>[];
    currentDir.list().listen(
      (it) {
        items.add(it);
      },
      onDone: () {
        if (mounted)
          setState(() {
            entities = items;
            _loadingFiles = false;
          });
      },
    );
  }

  Directory currentDir = Directory(currentUserSettings?.downloadPath ?? '/storage/emulated/0/Download/animestream');

  List<FileSystemEntity> entities = [];

  bool _loadingFiles = false;

  IconData _getTypeIcon(String ext) {
    return switch (ext) {
      "mp4" => Icons.movie_rounded,
      "webm" => Icons.movie_rounded,
      "mkv" => Icons.movie_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
  }

  late List<String> currentDirPathSplit;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (bool didPop, __) {
        if (didPop) return;
        _navBack();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _currentPathAndFile(),
          Expanded(
            child: entities.isEmpty
                ? Center(
                    child: Text(
                      "Empty folder!",
                      style: TextStyle(fontFamily: "NunitoSans"),
                    ),
                  )
                : ListView.builder(
                    itemCount: entities.length,
                    itemBuilder: (context, index) {
                      final e = entities[index];
                      if (e is Directory)
                        return _folderTile(e);
                      else
                        return _fileTile(e);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _currentPathAndFile() {
    return Container(
      decoration:
          BoxDecoration(color: appTheme.backgroundSubColor.withAlpha(100), borderRadius: BorderRadius.circular(10)),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 13),
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentDirPathSplit.sublist(0, currentDirPathSplit.length - 1).join('/') + "/",
                    style: TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currentDirPathSplit.last,
                    style: _titleStyle().copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          // Spacer(),
          if (_loadingFiles)
            CircularProgressIndicator(
              color: appTheme.textSubColor,
            )
          else
            Text(
              "${entities.length} items",
              style: TextStyle(fontSize: 12, fontFamily: "NunitoSans", fontWeight: FontWeight.bold),
            )
        ],
      ),
    );
  }

  Container _folderTile(FileSystemEntity entity) {
    return _tappable(
      entity: entity,
      onTap: () {
        currentDir = Directory(entity.path);
        _readDir();
        setState(() {});
      },
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.folder_rounded,
              size: 28,
            ),
          ),
          Expanded(
              child: Text(
            _getFileName(entity.path),
            style: _titleStyle(),
            overflow: TextOverflow.ellipsis,
          )),
        ],
      ),
    );
  }

  final _episodeNumRegex = RegExp(r'EP\s+(\d+)', caseSensitive: false);

  final _supportedFiles = ["mp4", "webm", "mkv", "avi", "m4a"];

  Container _fileTile(FileSystemEntity entity) {
    final ep = _episodeNumRegex.firstMatch(entity.path)?.group(1);
    return _tappable(
      entity: entity,
      onTap: () {
        // file should have an extension and be included in supported type! doesnt prevent the user from fw the extension
        final ext = entity.path.split(".").lastOrNull;
        if (ext != null && _supportedFiles.contains(ext)) {
          _playVideo(entity.path);
        } else {
          floatingSnackBar("Unsupported file type!");
        }
      },
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16), //12 means symmetrical to folder structure, but feels off here
            child: Icon(
              _getTypeIcon(entity.path.split(".").last),
              size: 28,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ep != null ? "Episode $ep" : _getFileName(entity.path),
                  style: _titleStyle(),
                  overflow: TextOverflow.ellipsis,
                ),
                if (ep != null)
                  Text(
                    "${_toMegs(File(entity.path).lengthSync())} MB",
                    style: TextStyle(color: appTheme.textSubColor, fontFamily: "NotoSans", fontSize: 13),
                  ),
              ],
            ),
          ),
          IconButton(
              onPressed: () {
                _deleteDialog(entity.path, null).then((val) => _readDir());
              },
              icon: Icon(Icons.delete)),
        ],
      ),
    );
  }

  Container _tappable({required Widget child, required FileSystemEntity entity, required void Function() onTap}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
      ),
      // decoration: BoxDecoration(
      // borderRadius: BorderRadius.circular(12),
      // ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: child,
        ),
      ),
    );
  }

  Future<T?> _deleteDialog<T>(String filepath, int? id) {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("You Sure?"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("no"),
                ),
                TextButton(
                  onPressed: () async {
                    await _deleteDownload(filepath, id);
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: appTheme.accentColor,
                    foregroundColor: appTheme.onAccent,
                  ),
                  child: Text("Yes"),
                ),
              ],
              content: Padding(
                padding: const EdgeInsets.all(5),
                child: Text('Are you sure to delete "${_getFileName(filepath)}" from your device?'),
              ),
            ));
  }

  void _playVideo(String filepath) {
    final controller = Platform.isWindows ? VideoPlayerWindowsWrapper() : BetterPlayerWrapper();
    final filename = _getFileName(filepath);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (context) => PlayerDataProvider(
                initialStreams: [],
                initialStream: VideoStream(quality: "default", link: filepath, server: "local", backup: false),
                epLinks: [], // doesnt matter
                showTitle: filename,
                showId: 0, // doesnt matter
                selectedSource: "default", //doesnt matter
                startIndex: 0, // does matter! [change with episode number, need to fw download methods]
                altDatabases: [], // doesnt matter
                preferDubs: false, // doesnt matter
                lastWatchDuration: null, // does matter!
              ),
            ),
            ChangeNotifierProvider(
              create: (context) => PlayerProvider(controller),
            ),
          ],
          child: Watch(
            controller: controller,
            localSource: true,
          ),
        ),
      ),
    );
  }

  String _toMegs(int sizeInBytes) => (sizeInBytes / (1024 * 1024)).toStringAsFixed(1);

  TextStyle _titleStyle() => TextStyle(fontFamily: "NunitoSans", fontWeight: FontWeight.bold, fontSize: 18);
}
