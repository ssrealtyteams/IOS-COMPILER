import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../error/result.dart';

@singleton
class DioClient {
  DioClient(this._storage) {
    _dio = _createDio();
  }

  final FlutterSecureStorage _storage;
  late final Dio _dio;

  Dio get dio => _dio;

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Platform': 'android',
        },
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(_storage, dio),
      _ErrorInterceptor(),
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (o) {}, // Use logger in dev
      ),
    ]);

    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._storage, this._dio);
  final FlutterSecureStorage _storage;
  final Dio _dio;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        final token = await _storage.read(key: StorageKeys.accessToken);
        err.requestOptions.headers['Authorization'] = 'Bearer $token';
        final response = await _dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      }
      // Refresh failed — logout
      await _storage.deleteAll();
    }
    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
      if (refreshToken == null) return false;

      final response = await _dio.post(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );

      final data = response.data['data'];
      await _storage.write(
        key: StorageKeys.accessToken,
        value: data['accessToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}

// ─── Error Mapper ────────────────────────────────────────────────────────────
extension DioExceptionMapper on DioException {
  AppError toAppError() {
    return switch (type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        AppError.network('Connection timed out. Please check your internet.'),
      DioExceptionType.connectionError =>
        AppError.network('No internet connection. Working offline.'),
      DioExceptionType.badResponse => _mapResponseError(),
      _ => AppError.unknown(),
    };
  }

  AppError _mapResponseError() {
    final statusCode = response?.statusCode;
    final body = response?.data as Map<String, dynamic>?;
    final message = body?['error']?['message'] as String? ??
        'Something went wrong. Please try again.';
    final code = body?['error']?['code'] as String?;

    return switch (statusCode) {
      401 => AppError.unauthorized(),
      403 => AppError.forbidden(),
      404 => AppError.notFound('Resource'),
      422 => AppError.validation(message),
      _ => AppError.server(message, statusCode: statusCode, code: code),
    };
  }
}
