import 'package:animestream/core/database/types.dart';

class SimklSearchResult extends DatabaseSearchResult {
  final int id;
  final String cover;
  final Map<String, String?> title;

  SimklSearchResult({
    required this.cover, 
    required this.id,
    required this.title,
  });
}