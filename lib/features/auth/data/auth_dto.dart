import '../../../core/storage/token_storage.dart';
import '../domain/auth.dart';

class TokenDto {
  TokenDto.fromJson(Map<String, dynamic> json)
    : accessToken = json['accessToken'] as String,
      refreshToken = json['refreshToken'] as String;
  final String accessToken, refreshToken;
}

class UserProfileDto {
  UserProfileDto.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      displayName = json['displayName'] as String,
      onboardingCompleted = json['onboardingCompleted'] as bool,
      email = json['email'] as String? ?? '',
      authProvider = json['authProvider'] as String? ?? '',
      createdAt = json['createdAt'] as String?;
  final String id, displayName;
  final bool onboardingCompleted;
  final String email, authProvider;
  final String? createdAt;
}

TokenPair mapTokens(TokenDto dto) =>
    TokenPair(dto.accessToken, dto.refreshToken);
UserProfile mapProfile(UserProfileDto dto) => UserProfile(
  id: dto.id,
  displayName: dto.displayName,
  onboardingCompleted: dto.onboardingCompleted,
  email: dto.email,
  authProvider: dto.authProvider,
  createdAt: dto.createdAt == null ? null : DateTime.parse(dto.createdAt!),
);
