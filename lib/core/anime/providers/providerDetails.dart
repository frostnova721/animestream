// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ProviderDetails {
  final String name;
  final String identifier;
  final String version;
  final String? icon;
  final String? code;

  ProviderDetails({
    required this.name,
    required this.identifier,
    required this.version,
    this.icon,
    this.code,
  });

  ProviderDetails copyWith({
    String? name,
    String? identifier,
    String? version,
    String? icon,
    String? code,
  }) {
    return ProviderDetails(
      name: name ?? this.name,
      identifier: identifier ?? this.identifier,
      version: version ?? this.version,
      icon: icon ?? this.icon,
      code: code ?? this.code,
    );
  }

  Map<String, String?> toMap() {
    return <String, String?>{
      'name': name,
      'identifier': identifier,
      'version': version,
      'icon': icon,
      'code': code,
    };
  }

  factory ProviderDetails.fromMap(Map<String, String?> map) {
    return ProviderDetails(
      name: map['name'] as String,
      identifier: map['identifier'] as String,
      version: map['version'] as String,
      icon: map['icon'] != null ? map['icon'] as String : null,
      code: map['code'] != null ? map['code'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ProviderDetails.fromJson(String source) => ProviderDetails.fromMap(json.decode(source) as Map<String, String?>);

  @override
  String toString() {
    return 'ProviderDetails(name: $name, identifier: $identifier, version: $version, icon: $icon, code: $code)';
  }

  @override
  int get hashCode {
    return name.hashCode ^
      identifier.hashCode ^
      version.hashCode ^
      icon.hashCode ^
      code.hashCode;
  }
}
