import 'package:dio/dio.dart';

import 'auth_network_client.dart';

class DioHelperNetworkClient implements AuthNetworkClient {
  DioHelperNetworkClient(this.dioHelper);

  final dynamic dioHelper;

  @override
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    multiPartBody,
    String? token,
    CancelToken? cancelToken,
  }) async {
    return dioHelper.postData(
      endpoint,
      body: body,
      multiPartBody: multiPartBody,
      token: token,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    return dioHelper.getData(endpoint, body: body, token: token);
  }

  @override
  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    return dioHelper.deleteData(endpoint, body: body, token: token);
  }
}
