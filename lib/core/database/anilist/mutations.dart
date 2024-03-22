import 'package:animestream/core/data/hive.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/core/commons/enums.dart';

class AnilistMutations {
  Future<AnilistMutationResult> mutateAnimeList({
    required int id,
    int? score,
    MediaStatus? status,
    int? progress,
  }) async {
    final query = ''' 
      mutation {
        SaveMediaListEntry(mediaId: $id, status: ${ status?.name ?? MediaStatus.CURRENT.name}, progress: ${progress ?? 0}) {
          status
        }
      }
    ''';
    final res = await Anilist().fetchQuery(query, RequestType.mutate, token: await getVal("token"));
    return AnilistMutationResult(status: res?['SaveMediaListEntry']?['status']);
  }
}
