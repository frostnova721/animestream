import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/core/database/anilist/types.dart';

class AnilistMutations {
  Future mutateAnimeList({
    required int id,
    required int? score,
    required MediaStatus? status,
  }) async {
    final query = ''' 
      mutation {
        SaveMediaListEntry(mediaId: $id, status: ${status ?? ''}) {
          status
        }
      }
    ''';
    await Anilist().fetchQuery(query, RequestType.mutate);
  }
}
