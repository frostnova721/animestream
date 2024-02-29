class TrendingResult {
  final int episode;
  final Map<String, String?> title;
  final int id;
  final String type;
  final String? banner;
  final String cover;
  final dynamic genres;
  final int? rating;

  TrendingResult({
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
