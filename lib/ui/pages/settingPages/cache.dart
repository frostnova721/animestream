import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/network/caching/cache_config.dart';
import 'package:animestream/core/network/caching/cache_manager.dart';
import 'package:animestream/ui/models/popup.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/widgets/clickableItem.dart';
import 'package:animestream/ui/models/widgets/toggleItem.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:flutter/material.dart';

class CacheSetting extends StatefulWidget {
  const CacheSetting({super.key});

  @override
  State<CacheSetting> createState() => _CacheSettingState();
}

class _CacheSettingState extends State<CacheSetting> {
  final _cacheManager = CacheManager();
  bool loaded = false;
  bool enableCaching = true;
  bool bypassCache = false;
  int maxCacheSize = 200 * 1024 * 1024;

  int _currentSizeBytes = 0;
  int _entryCount = 0;
  bool _isLoadingStats = false;

  final List<int> sizeOptions = [
    50 * 1024 * 1024,
    100 * 1024 * 1024,
    150 * 1024 * 1024,
    200 * 1024 * 1024,
    250 * 1024 * 1024,
    // 500 * 1024 * 1024,
    // 1024 * 1024 * 1024,
    // 2 * 1024 * 1024 * 1024,
  ];

  @override
  void initState() {
    super.initState();
    _loadSettingsAndStats();
  }

  Future<void> _loadSettingsAndStats() async {
    final config = cacheConfigController.value;
    setState(() {
      enableCaching = config.enableCaching;
      bypassCache = config.bypassCache;
      maxCacheSize = config.maxCacheSize;
      loaded = true;
    });
    await _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoadingStats = true;
    });
    try {
      final size = await _cacheManager.getCacheSize();
      final entries = await _cacheManager.getAllEntries();
      if (mounted) {
        setState(() {
          _currentSizeBytes = size;
          _entryCount = entries.length;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;
    if (bytes >= gb) {
      return "${(bytes / gb).toStringAsFixed(2)} GB";
    } else if (bytes >= mb) {
      return "${(bytes / mb).toStringAsFixed(1)} MB";
    } else if (bytes >= kb) {
      return "${(bytes / kb).toStringAsFixed(1)} KB";
    }
    return "$bytes B";
  }

  Widget _sizeSheet(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setcState) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        margin: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                "Select Max Cache Size",
                style: textStyle().copyWith(fontSize: 23),
                textAlign: TextAlign.left,
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: sizeOptions.length,
              itemBuilder: (context, index) {
                final optionSize = sizeOptions[index];
                final isSelected = optionSize == maxCacheSize;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: isSelected ? appTheme.accentColor : appTheme.backgroundSubColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        cacheConfigController.setMaxCacheSize(optionSize);
                        setState(() {
                          maxCacheSize = optionSize;
                        });
                        setcState(() {});
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        child: Text(
                          _formatBytes(optionSize),
                          style: textStyle().copyWith(
                            color: isSelected ? appTheme.onAccent : appTheme.textMainColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: loaded
          ? SingleChildScrollView(
              child: Padding(
                padding: pagePadding(context, bottom: true),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    settingPagesTitleHeader(context, "Cache Manager"),
                    ToggleItem(
                      label: "Enable network caching",
                      value: enableCaching,
                      description: "Cache AniList & provider API requests",
                      onTapFunction: () {
                        setState(() {
                          enableCaching = !enableCaching;
                        });
                        cacheConfigController.setEnableCaching(enableCaching);
                      },
                    ),
                    ToggleItem(
                      label: "Bypass cache",
                      value: bypassCache,
                      description: "Always fetch fresh data from network",
                      onTapFunction: () {
                        setState(() {
                          bypassCache = !bypassCache;
                        });
                        cacheConfigController.setBypassCache(bypassCache);
                      },
                    ),
                    ClickableItem(
                      onTap: () {
                        showPopup(
                          context: context,
                          showSheetHandle: true,
                          isScrollControlledSheet: true,
                          builder: (context) => _sizeSheet(context),
                        );
                      },
                      label: "Max cache size",
                      description: _formatBytes(maxCacheSize),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    ClickableItem(
                      onTap: () {
                        _loadStats();
                      },
                      label: "Current cache size",
                      description: _isLoadingStats
                          ? "Calculating..."
                          : "${_formatBytes(_currentSizeBytes)} ($_entryCount entries)",
                      suffixIcon: const Icon(Icons.refresh_rounded),
                    ),
                    ClickableItem(
                      onTap: () async {
                        await _cacheManager.clearExpired();
                        await _loadStats();
                        floatingSnackBar("Expired cache cleared!");
                      },
                      label: "Clear expired cache",
                      description: "Clean up outdated cached entries",
                      suffixIcon: const Icon(Icons.cleaning_services_rounded),
                    ),
                    ClickableItem(
                      onTap: () async {
                        await _cacheManager.clearCache();
                        await _loadStats();
                        floatingSnackBar("All cache cleared!");
                      },
                      label: "Clear all cache",
                      description: "Delete all cached API & network data",
                      suffixIcon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ),
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
