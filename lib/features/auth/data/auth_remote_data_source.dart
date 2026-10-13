import 'package:dio/dio.dart';

import 'auth_dto.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this.dio);
  final Dio dio;
  Future<TokenDto> _tokens(String path, Map<String, dynamic> body) async =>
      TokenDto.fromJson(
        (await dio.post<Map<String, dynamic>>(
          path,
          data: body,
          options: Options(extra: {'public': true}, receiveTimeout: const Duration(seconds: 15)),
        )).data!,
      );
  Future<TokenDto> login(String email, String password) =>
      _tokens('/api/auth/login', {'email': email, 'password': password});
  Future<TokenDto> register(String email, String password, String name) =>
      _tokens('/api/auth/register', {
        'email': email,
        'password': password,
        'displayName': name,
      });
  Future<TokenDto> refresh(String refreshToken) =>
      _tokens('/api/auth/refresh', {'refreshToken': refreshToken});
  Future<void> logout(String refreshToken) async {
    await dio.post<void>(
      '/api/auth/logout',
      data: {'refreshToken': refreshToken, 'allDevices': false},
      options: Options(extra: {'public': true}, receiveTimeout: const Duration(seconds: 15)),
    );
  }

  Future<UserProfileDto> profile() async => UserProfileDto.fromJson(
    (await dio.get<Map<String, dynamic>>('/api/users/me')).data!,
  );
  Future<UserProfileDto> updateDisplayName(String displayName) async =>
      UserProfileDto.fromJson(
        (await dio.patch<Map<String, dynamic>>(
          '/api/users/me',
          data: {'displayName': displayName},
        )).data!,
      );
}
