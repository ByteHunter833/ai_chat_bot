import 'package:dio/dio.dart';

class DioClient {
  DioClient(String apiKey)
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'https://openrouter.ai/api/v1',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'http://localhost',
            'X-Title': 'Nova AI',
          },
        ),
      );

  final Dio _dio;

  Future<Response> post(String path, {Map<String, dynamic>? data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            e.message ??
            'Unknown network error',
      );
    }
  }
}
