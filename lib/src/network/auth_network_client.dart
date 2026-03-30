import 'package:dio/dio.dart';

abstract class AuthNetworkClient {
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    dynamic multiPartBody,
    String? token,
    CancelToken? cancelToken,
  });

  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? query,
    String? token,
  });

  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? query,
    String? token,
  });
}
