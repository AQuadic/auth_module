import 'package:dio/dio.dart';

abstract class AuthNetworkClient {
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    dynamic multiPartBody,
    String? token,
    CancelToken? cancelToken,
  });

  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  });
}
