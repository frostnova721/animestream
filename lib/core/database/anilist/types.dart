class RecentlyUpdatedResult {
  final int episode;
  final Map<String, String?> title;
  final int id;
  final String type;
  final String? banner;
  final String cover;
  final dynamic genres;
  final int? rating;

  RecentlyUpdatedResult({
    required this.episode,
    required this.title,
    required this.id,
    required this.type,
    required this.banner,
    required this.cover,
    required this.genres,
    this.rating = null,
  });
}

class TrendingResult {
  final int id;
  final Map<String, String?> title;
  final List<Object?> genres;
  final int? rating;
  final String cover;
  final String? banner;

  TrendingResult({
    required this.id,
    required this.banner,
    required this.cover,
    required this.genres,
    required this.rating,
    required this.title,
  });
}

class UserModal {
  final int id;
  final String? banner;
  final String? avatar;
  final String name;

  UserModal({
    required this.avatar,
    required this.banner,
    required this.id,
    required this.name,
  });
}
