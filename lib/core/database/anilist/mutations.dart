import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/secureStorage.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/types.dart';

class AnilistMutations extends DatabaseMutation {
  @override
  Future<AnilistMutationResult> mutateAnimeList({
    required int id,
    int? score,
    MediaStatus? status,
    int? progress,
    MediaStatus? previousStatus,
  }) async {
    final query = '''
      mutation {
        SaveMediaListEntry(mediaId: $id, status: ${status?.name ?? MediaStatus.CURRENT.name}, progress: ${progress ?? 0}) {
          status
          progress
        }
      }
    ''';
    final res =
        await Anilist().fetchQuery(query, RequestType.mutate, token: await getSecureVal(SecureStorageKey.anilistToken));
    return AnilistMutationResult(
        status: res?['SaveMediaListEntry']?['status'], progress: res?['SaveMediaListEntry']?['progress']);
  }

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
