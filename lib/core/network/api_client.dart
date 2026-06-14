import 'package:dio/dio.dart';

/// Thin wrapper over Dio. Repositories depend on this, not on Dio directly,
/// so transport concerns stay swappable and testable.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<Response<T>> request<T>(
    String path, {
    required String method,
    Object? data,
    Map<String, String>? headers,
  }) {
    return _dio.request<T>(
      path,
      data: data,
      options: Options(method: method, headers: headers),
    );
  }
}
