import '../../../../core/network/json_helpers.dart';

class AppUser {
  const AppUser({
    required this.email,
    required this.isAdmin,
    this.username,
    this.discordId,
    this.discordHandle = '',
    this.noDiscord = false,
    this.firstName = '',
    this.lastName = '',
    this.nickname = '',
    this.pokemonIcon,
    this.strikeCount = 0,
    this.isRestricted = false,
  });

  final String email;
  final bool isAdmin;
  final String? username;
  final String? discordId;
  final String discordHandle;
  final bool noDiscord;
  final String firstName;
  final String lastName;
  final String nickname;
  final String? pokemonIcon;
  final int strikeCount;
  final bool isRestricted;

  String get displayName {
    if (nickname.trim().isNotEmpty) return nickname.trim();
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;
    return email;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      email: asString(json['email']),
      isAdmin: asBool(json['is_admin']),
      username: json['username']?.toString(),
      discordId: json['discord_id']?.toString(),
      discordHandle: asString(json['discord_handle']),
      noDiscord: asBool(json['no_discord']),
      firstName: asString(json['first_name']),
      lastName: asString(json['last_name']),
      nickname: asString(json['nickname']),
      pokemonIcon: _pokemonIconFilename(json),
      strikeCount: asInt(json['strike_count']),
      isRestricted: asBool(json['is_restricted']),
    );
  }

  static String? _pokemonIconFilename(Map<String, dynamic> json) {
    final direct = json['pokemon_icon'];
    if (direct is Map) {
      return asString(direct['filename']).isEmpty
          ? null
          : asString(direct['filename']);
    }
    final filename = asString(json['pokemon_icon_filename'],
        fallback: direct == null ? '' : '$direct');
    return filename.isEmpty ? null : filename;
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'is_admin': isAdmin,
      'username': username,
      'discord_id': discordId,
      'discord_handle': discordHandle,
      'no_discord': noDiscord,
      'first_name': firstName,
      'last_name': lastName,
      'nickname': nickname,
      'pokemon_icon': pokemonIcon,
      'strike_count': strikeCount,
      'is_restricted': isRestricted,
    };
  }
}
