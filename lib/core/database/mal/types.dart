// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:animestream/core/database/types.dart';

class MalException implements Exception {
  final String message;
  final int statusCode;
  MalException(this.message, this.statusCode);

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() {
    return "MalException: $message";
  }
}

class MALAuthResponse {
  String accessToken;
  int expires_in;
  String refreshToken;

  MALAuthResponse({
    required this.accessToken, required this.expires_in, required this.refreshToken,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'access_token': accessToken,
      'expires_in': expires_in,
      'refresh_token': refreshToken,
    };
  }

  factory MALAuthResponse.fromMap(Map<String, dynamic> map) {
    return MALAuthResponse(
      accessToken: map['access_token'] as String,
      expires_in: map['expires_in'] as int,
      refreshToken: map['refresh_token'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory MALAuthResponse.fromJson(String source) => MALAuthResponse.fromMap(json.decode(source) as Map<String, dynamic>);
}

class MALMutationResult extends DatabaseMutationResult {
  //idk
}

class MALAnimeWatchProgress extends DatabaseAnimeWatchProgress {
  final int id;
  final int? progress;
  final int? totalEpisodes;
  final String? status;

  MALAnimeWatchProgress({
    required this.id,
    required this.progress,
    required this.totalEpisodes,
    required this.status,
  });

  factory MALAnimeWatchProgress.fromJson(String jsonString) {
    final Map<String, dynamic> data = json.decode(jsonString);
    final myListStatus = data['my_list_status'];

    return MALAnimeWatchProgress(
      id: data['id'],
      progress: myListStatus != null ? myListStatus['num_episodes_watched'] : null,
      totalEpisodes: data['num_episodes'],
      status: myListStatus != null ? myListStatus['status'] : null,
    );
  }
}
