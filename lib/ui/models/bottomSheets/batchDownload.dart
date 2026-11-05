import 'dart:async';

import 'package:animestream/core/anime/downloader/downloadManager.dart';
import 'package:animestream/core/anime/downloader/downloaderHelper.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/hlsParser/audioStream.dart';
import 'package:animestream/core/commons/hlsParser/hlsMasterPlaylist.dart';
import 'package:animestream/core/commons/hlsParser/hlsParser.dart';
import 'package:animestream/core/commons/hlsParser/qualityStream.dart';
import 'package:animestream/ui/models/providers/infoProvider.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class BatchDownloadSheetContent extends StatefulWidget {
  final InfoProvider provider;
  const BatchDownloadSheetContent({super.key, required this.provider});

  @override
  State<BatchDownloadSheetContent> createState() => _BatchDownloadSheetContentState();
}

class _BatchDownloadSheetContentState extends State<BatchDownloadSheetContent> {
  int _step = 0;
  late Set<int> _selectedIndices;

  late String _preferredQuality;
  late bool _preferDubs;
  bool _includeSubtitles = true;

  @override
  void initState() {
    super.initState();
    final totalEpisodes = widget.provider.epLinks.length;
    final watched = widget.provider.watched;

    // Default to unwatched episodes if available, otherwise select all
    if (watched > 0 && watched < totalEpisodes) {
      _selectedIndices = {for (int i = watched; i < totalEpisodes; i++) i};
    } else {
      _selectedIndices = {for (int i = 0; i < totalEpisodes; i++) i};
    }

    _preferredQuality = currentUserSettings?.preferredQuality ?? "720p";
    _preferDubs = widget.provider.preferDubs;
  }

  void _selectAll() {
    setState(() {
      final total = widget.provider.epLinks.length;
      if (_selectedIndices.length == total) {
        _selectedIndices.clear();
      } else {
        _selectedIndices = {for (int i = 0; i < total; i++) i};
      }
    });
  }

  void _selectUnwatchedOnly() {
    setState(() {
      final total = widget.provider.epLinks.length;
      final watched = widget.provider.watched;
      _selectedIndices = {
        for (int i = 0; i < total; i++)
          if (i >= watched) i,
      };
    });
  }

  void _invertSelection() {
    setState(() {
      final total = widget.provider.epLinks.length;
      final inverted = <int>{};
      for (int i = 0; i < total; i++) {
        if (!_selectedIndices.contains(i)) {
          inverted.add(i);
        }
      }
      _selectedIndices = inverted;
    });
  }

  Future<void> _startBatchDownload(BuildContext context) async {
    if (!(await DownloaderHelper().checkAndRequestPermission())) {
      floatingSnackBar("Allow 'All files access' to download files.");
      return;
    }

    final selectedIndicesSorted = _selectedIndices.toList()..sort();
    final totalCount = selectedIndicesSorted.length;

    final titles = widget.provider.data.title;
    final defaultTitle = titles['english'] ?? titles['romaji'] ?? "";
    final showTitle = (currentUserSettings?.nativeTitle ?? false) ? titles['native'] ?? defaultTitle : defaultTitle;

    final sourceIdentifier = widget.provider.selectedSource.identifier;
    final epLinks = List<EpisodeDetails>.from(widget.provider.epLinks);
    final preferredQuality = _preferredQuality;
    final dubPreference = _preferDubs;
    final includeSubs = _includeSubtitles;

    Navigator.of(context).pop();
    floatingSnackBar("Queueing $totalCount episodes for download...");

    unawaited(
      _processBatchQueue(
        epLinks: epLinks,
        selectedIndices: selectedIndicesSorted,
        showTitle: showTitle,
        sourceIdentifier: sourceIdentifier,
        preferredQuality: preferredQuality,
        dubPreference: dubPreference,
        includeSubs: includeSubs,
      ),
    );
  }

  static Future<void> _processBatchQueue({
    required List<EpisodeDetails> epLinks,
    required List<int> selectedIndices,
    required String showTitle,
    required String sourceIdentifier,
    required String preferredQuality,
    required bool dubPreference,
    required bool includeSubs,
  }) async {
    int queuedCount = 0;
    int failedCount = 0;

    for (final index in selectedIndices) {
      if (index < 0 || index >= epLinks.length) continue;
      final ep = epLinks[index];
      final episodeNum = "${index + 1}";
      final fileName = "$showTitle EP ${episodeNum.padLeft(2, '0')}";

      try {
        final streams = await _fetchStreamsForEpisode(
          sourceIdentifier: sourceIdentifier,
          episode: ep,
          dub: dubPreference,
        );

        if (streams.isEmpty) {
          Logs.downloader.log("[BATCH] No streams found for episode ${index + 1}");
          failedCount++;
          continue;
        }

        final matchingDubStreams = streams.where((s) => s.dub == dubPreference).toList();
        final candidateStreams = matchingDubStreams.isNotEmpty ? matchingDubStreams : streams;

        VideoStream? selectedVideoStream;
        QualityStream? selectedQualityStream;
        List<AudioStream> selectedAudioStreams = const [];

        final multiQualityStream = candidateStreams.firstWhereOrNull(
          (s) => s.quality == "multi-quality" || s.quality == "auto",
        );

        if (multiQualityStream != null) {
          try {
            final HlsMasterPlaylist playlist = await HlsParser.parseMasterPlaylist(
              multiQualityStream.url,
              customHeader: multiQualityStream.customHeaders,
            );

            if (playlist.qualityStreams.isNotEmpty) {
              final targetQuality =
                  playlist.qualityStreams.firstWhereOrNull(
                    (q) => q.quality.toLowerCase().contains(preferredQuality.toLowerCase()),
                  ) ??
                  playlist.qualityStreams.first;

              selectedVideoStream = multiQualityStream;
              selectedQualityStream = targetQuality;

              if (playlist.audioStreams.isNotEmpty) {
                final chosenAudio =
                    playlist.audioStreams.firstWhereOrNull((a) => dubPreference ? a.isEnglish : !a.isEnglish) ??
                    playlist.audioStreams.first;
                selectedAudioStreams = [chosenAudio];
              }
            }
          } catch (e) {
            Logs.downloader.log("[BATCH] Master playlist parse error for ep ${index + 1}: $e");
          }
        }

        if (selectedQualityStream == null) {
          selectedVideoStream =
              candidateStreams.firstWhereOrNull(
                (s) => s.quality.toLowerCase().contains(preferredQuality.toLowerCase()),
              ) ??
              candidateStreams.first;

          selectedQualityStream = QualityStream(
            quality: selectedVideoStream.quality,
            url: selectedVideoStream.url,
            resolution: "??",
          );
        }

        final subtitleUrl = includeSubs ? selectedVideoStream?.subtitle : null;

        await DownloadManager().addDownloadTask(
          selectedQualityStream.url,
          fileName,
          customHeaders: selectedVideoStream?.customHeaders ?? {},
          subtitleUrl: (subtitleUrl?.isEmpty ?? true) ? null : subtitleUrl,
          videoStream: selectedQualityStream,
          audioStreams: selectedAudioStreams,
        );

        queuedCount++;
      } catch (e) {
        Logs.downloader.log("[BATCH] Error queuing episode ${index + 1}: $e");
        failedCount++;
      }
    }

    if (failedCount > 0) {
      floatingSnackBar("Queued $queuedCount episodes. $failedCount failed.");
    } else {
      floatingSnackBar("Successfully queued $queuedCount episodes for download.");
    }
  }

  static Future<List<VideoStream>> _fetchStreamsForEpisode({
    required String sourceIdentifier,
    required EpisodeDetails episode,
    required bool dub,
  }) async {
    final completer = Completer<List<VideoStream>>();
    final List<VideoStream> results = [];

    void handleStreamList(List<VideoStream> list, bool finished) {
      results.addAll(list);
      if (finished && !completer.isCompleted) {
        completer.complete(results);
      }
    }

    try {
      await SourceManager.instance.getDownloadSources(
        sourceIdentifier,
        episode.episodeLink,
        handleStreamList,
        dub: dub,
        metadata: episode.metadata,
      );
    } catch (err) {
      if (err is UnimplementedError) {
        try {
          await SourceManager.instance.getStreams(
            sourceIdentifier,
            episode.episodeLink,
            handleStreamList,
            dub: dub,
            metadata: episode.metadata,
          );
        } catch (e) {
          if (!completer.isCompleted) completer.complete(results);
        }
      } else {
        if (!completer.isCompleted) completer.complete(results);
      }
    }

    return completer.future.timeout(const Duration(seconds: 15), onTimeout: () => results);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 8, bottom: MediaQuery.of(context).padding.bottom + 12),
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _step == 0 ? _buildEpisodeSelectionStep() : _buildPreferencesStep(),
      ),
    );
  }

  Widget _buildEpisodeSelectionStep() {
    final totalEpisodes = widget.provider.epLinks.length;
    final watched = widget.provider.watched;

    return Column(
      key: const ValueKey("step_0"),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Batch Download",
                  style: TextStyle(
                    color: appTheme.textMainColor,
                    fontFamily: "Rubik",
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${_selectedIndices.length}/$totalEpisodes episodes selected",
                  style: TextStyle(color: appTheme.textSubColor, fontFamily: "Rubik", fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ActionChip(
                avatar: Icon(
                  _selectedIndices.length == totalEpisodes ? Icons.check_box_rounded : Icons.select_all_rounded,
                  size: 16,
                  color: appTheme.textMainColor,
                ),
                label: Text(
                  _selectedIndices.length == totalEpisodes ? "Clear All" : "Select All",
                  style: TextStyle(fontFamily: "Rubik", fontSize: 12, color: appTheme.textMainColor),
                ),
                backgroundColor: appTheme.backgroundSubColor,
                side: BorderSide(color: appTheme.textSubColor.withAlpha(50)),
                onPressed: _selectAll,
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: Icon(Icons.remove_red_eye_outlined, size: 16, color: appTheme.textMainColor),
                label: Text(
                  "Unwatched",
                  style: TextStyle(fontFamily: "Rubik", fontSize: 12, color: appTheme.textMainColor),
                ),
                backgroundColor: appTheme.backgroundSubColor,
                side: BorderSide(color: appTheme.textSubColor.withAlpha(50)),
                onPressed: _selectUnwatchedOnly,
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: Icon(Icons.swap_horiz_rounded, size: 16, color: appTheme.textMainColor),
                label: Text(
                  "Invert",
                  style: TextStyle(fontFamily: "Rubik", fontSize: 12, color: appTheme.textMainColor),
                ),
                backgroundColor: appTheme.backgroundSubColor,
                side: BorderSide(color: appTheme.textSubColor.withAlpha(50)),
                onPressed: _invertSelection,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.45),
          child: totalEpisodes == 0
              ? Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: Text(
                    "No episodes available for download.",
                    style: TextStyle(fontFamily: "Rubik", color: appTheme.textSubColor),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  itemCount: totalEpisodes,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.35,
                  ),
                  itemBuilder: (context, index) {
                    final selected = _selectedIndices.contains(index);
                    final isWatched = index < watched;

                    return Material(
                      color: selected ? appTheme.accentColor : appTheme.backgroundSubColor,
                      borderRadius: BorderRadius.circular(10),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedIndices.remove(index);
                            } else {
                              _selectedIndices.add(index);
                            }
                          });
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              "${index + 1}",
                              style: TextStyle(
                                fontFamily: "Rubik",
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: selected ? appTheme.onAccent : appTheme.textMainColor,
                              ),
                            ),
                            if (isWatched)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: selected ? appTheme.onAccent.withAlpha(180) : appTheme.textSubColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: _selectedIndices.isEmpty ? null : () => setState(() => _step = 1),
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            label: Text(
              "Next (${_selectedIndices.length})",
              style: const TextStyle(fontFamily: "Rubik", fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: appTheme.accentColor,
              foregroundColor: appTheme.onAccent,
              disabledBackgroundColor: appTheme.backgroundSubColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesStep() {
    return Column(
      key: const ValueKey("step_1"),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Preferences",
          style: TextStyle(
            color: appTheme.textMainColor,
            fontFamily: "Rubik",
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "${_selectedIndices.length} episodes will be queued",
          style: TextStyle(color: appTheme.textSubColor, fontFamily: "Rubik", fontSize: 13),
        ),
        Container(
          margin: EdgeInsets.only(top: 10, bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: appTheme.backgroundSubColor, borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPreferenceLabel("Preferred Quality", Icons.high_quality_rounded),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ["1080p", "720p", "480p", "360p"].map((quality) {
                  final selected = _preferredQuality == quality;
                  return ChoiceChip(
                    selected: selected,
                    showCheckmark: false,
                    label: Text(
                      quality,
                      style: TextStyle(
                        color: selected ? appTheme.onAccent : appTheme.textMainColor,
                        fontFamily: "Rubik",
                        fontSize: 13,
                      ),
                    ),
                    selectedColor: appTheme.accentColor,
                    backgroundColor: appTheme.backgroundColor,
                    side: BorderSide(color: selected ? appTheme.accentColor : appTheme.textSubColor.withAlpha(80)),
                    onSelected: (val) {
                      if (val) setState(() => _preferredQuality = quality);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _buildPreferenceLabel("Audio Track", Icons.audiotrack_rounded),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    selected: !_preferDubs,
                    showCheckmark: false,
                    label: Text(
                      "Sub (Japanese)",
                      style: TextStyle(
                        color: !_preferDubs ? appTheme.onAccent : appTheme.textMainColor,
                        fontFamily: "Rubik",
                        fontSize: 13,
                      ),
                    ),
                    selectedColor: appTheme.accentColor,
                    backgroundColor: appTheme.backgroundColor,
                    side: BorderSide(color: !_preferDubs ? appTheme.accentColor : appTheme.textSubColor.withAlpha(80)),
                    onSelected: (val) {
                      if (val) setState(() => _preferDubs = false);
                    },
                  ),
                  ChoiceChip(
                    selected: _preferDubs,
                    showCheckmark: false,
                    label: Text(
                      "Dub (English)",
                      style: TextStyle(
                        color: _preferDubs ? appTheme.onAccent : appTheme.textMainColor,
                        fontFamily: "Rubik",
                        fontSize: 13,
                      ),
                    ),
                    selectedColor: appTheme.accentColor,
                    backgroundColor: appTheme.backgroundColor,
                    side: BorderSide(color: _preferDubs ? appTheme.accentColor : appTheme.textSubColor.withAlpha(80)),
                    onSelected: (val) {
                      if (val) setState(() => _preferDubs = true);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPreferenceLabel("Subtitles", Icons.subtitles_rounded),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    selected: _includeSubtitles,
                    showCheckmark: false,
                    label: Text(
                      "Include Subtitles",
                      style: TextStyle(
                        color: _includeSubtitles ? appTheme.onAccent : appTheme.textMainColor,
                        fontFamily: "Rubik",
                        fontSize: 13,
                      ),
                    ),
                    selectedColor: appTheme.accentColor,
                    backgroundColor: appTheme.backgroundColor,
                    side: BorderSide(
                      color: _includeSubtitles ? appTheme.accentColor : appTheme.textSubColor.withAlpha(80),
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _includeSubtitles = true);
                    },
                  ),
                  ChoiceChip(
                    selected: !_includeSubtitles,
                    showCheckmark: false,
                    label: Text(
                      "No Subtitles",
                      style: TextStyle(
                        color: !_includeSubtitles ? appTheme.onAccent : appTheme.textMainColor,
                        fontFamily: "Rubik",
                        fontSize: 13,
                      ),
                    ),
                    selectedColor: appTheme.accentColor,
                    backgroundColor: appTheme.backgroundColor,
                    side: BorderSide(
                      color: !_includeSubtitles ? appTheme.accentColor : appTheme.textSubColor.withAlpha(80),
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _includeSubtitles = false);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: appTheme.backgroundSubColor, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: appTheme.textSubColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "The closest match for your preferred quality and audio will be downloaded.",
                  style: TextStyle(fontFamily: "Rubik", fontSize: 12, color: appTheme.textSubColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _step = 0),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: appTheme.textSubColor.withAlpha(100)),
                fixedSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                "Back",
                style: TextStyle(color: appTheme.textMainColor, fontFamily: "Rubik", fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _startBatchDownload(context),
                icon: const Icon(Icons.download_rounded, size: 20),
                label: Text(
                  "Download (${_selectedIndices.length})",
                  style: const TextStyle(fontFamily: "Rubik", fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: appTheme.accentColor,
                  foregroundColor: appTheme.onAccent,
                  fixedSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreferenceLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: appTheme.textSubColor),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: appTheme.textMainColor,
            fontFamily: "Rubik",
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
