import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;

Future<Response> onRequest(RequestContext context) async {
  //linka?q=how are you buddy??
  // 获取请求参数
  final request = context.request;
  final params = request.uri.queryParameters;
  var query = params['q'] ?? 'how are you buddy??';

  // 目标API的URL
  final String apiUrl =
      'https://mydiumtify.globeapp.dev/chattext?q=${Uri.encodeComponent(query)}';
  print(apiUrl);

  try {
    // 向目标服务器发送GET请求
    final response = await http.get(Uri.parse(apiUrl));

    // 检查响应状态码
    if (response.statusCode != 200) {
      // 处理错误情况并返回错误信息
      return Response.json(body: {
        'error': 'Failed to fetch or parse response',
        'details': 'Response status code: ${response.statusCode}',
      });
    }

    // 解析响应内容
    final responseBody = jsonDecode(response.body);

    // 提取其中的text部分
    final text = responseBody['text'] ?? 'No text found';
    // 构建新的JSON并返回
    return Response.json(body: {
      'isSender': false,
      'text': text,
    });
  } catch (e) {
    // 处理错误情况并返回错误信息
    return Response.json(body: {
      'error': 'Failed to fetch or parse response',
      'details': e.toString(),
    });
  }
}
