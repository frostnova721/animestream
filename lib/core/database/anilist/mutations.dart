import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/secureStorage.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/types.dart';

class AnilistMutations extends DatabaseMutation {
  /// Mutates the anime list entry for a given anime [id] with the provided parameters.
  ///
  /// Updates the entry with the new [score] (on a scale of 1-10), a new [status]
  /// (which defaults to `CURRENT`), and the new [progress] (defaults to 0).
  ///
  /// You can optionally provide the [previousStatus] if tracking status history.
  @override
  Future<AnilistMutationResult> mutateAnimeList({
    required int id,
    int? score,
    MediaStatus? status,
    int? progress,
    MediaStatus? previousStatus,
  }) async {
    // multiply score by 10 to convert to Anilist's scale (0-100)
    final rawScore = score != null ? score * 10 : null;
    
    final query = '''
      mutation {
        SaveMediaListEntry(mediaId: $id, status: ${status?.name ?? MediaStatus.CURRENT.name}, progress: ${progress ?? 0}, ${score != null ? "scoreRaw: ${rawScore}" : ""}) {
          status
          progress
          scoreRaw
        }
      }
    ''';
    final res =
        await Anilist().fetchQuery(query, RequestType.mutate, token: await getSecureVal(SecureStorageKey.anilistToken));
    return AnilistMutationResult(
        status: res?['SaveMediaListEntry']?['status'], progress: res?['SaveMediaListEntry']?['progress']);
  }

  /// Deletes an anime entry from the user's list.
  /// [id] The ID of the anime to delete.
  @override
  Future<DatabaseMutationResult?> deleteAnimeEntry({required int id}) async {
    final query = '''
      mutation {
        DeleteMediaListEntry(id: $id) {
          deleted
        }
      }
    ''';
    final res =
        await Anilist().fetchQuery(query, RequestType.mutate, token: await getSecureVal(SecureStorageKey.anilistToken));
    return AnilistMutationResult(status: res['deleted'].toString(), progress: 0);
  }
}
