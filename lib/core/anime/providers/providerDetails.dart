// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ProviderDetails {
  final String name;
  final String identifier;
  final String version;
  final String? icon;
  final String? code;
  final bool supportDownloads;

  ProviderDetails({
    required this.name,
    required this.identifier,
    required this.version,
    this.icon,
    this.code,
    this.supportDownloads = false,
  });

  ProviderDetails copyWith({
    String? name,
    String? identifier,
    String? version,
    String? icon,
    String? code,
    bool? supportDownloads,
  }) {
    return ProviderDetails(
      name: name ?? this.name,
      identifier: identifier ?? this.identifier,
      version: version ?? this.version,
      icon: icon ?? this.icon,
      code: code ?? this.code,
      supportDownloads: supportDownloads ?? this.supportDownloads,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'identifier': identifier,
      'version': version,
      'icon': icon,
      'code': code,
      'supportDownloads': supportDownloads,
    };
  }

  factory ProviderDetails.fromMap(Map<String, dynamic> map) {
    return ProviderDetails(
      name: map['name'] as String,
      identifier: map['identifier'] as String,
      version: map['version'] as String,
      icon: map['icon'] != null ? map['icon'] as String : null,
      code: map['code'] != null ? map['code'] as String : null,
      supportDownloads: (map['supportDownloads'] ?? false) as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory ProviderDetails.fromJson(String source) => ProviderDetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ProviderDetails(name: $name, identifier: $identifier, version: $version, icon: $icon, code: $code, supportDownloads: $supportDownloads)';
  }

  @override
  int get hashCode {
    return name.hashCode ^
      identifier.hashCode ^
      version.hashCode ^
      icon.hashCode ^
      code.hashCode ^
      supportDownloads.hashCode;
  }

  @override
  bool operator ==(covariant ProviderDetails other) {
    if (identical(this, other)) return true;
  
    return 
      other.name == name &&
      other.identifier == identifier &&
      other.version == version &&
      other.icon == icon &&
      other.code == code &&
      other.supportDownloads == supportDownloads;
  }
}
