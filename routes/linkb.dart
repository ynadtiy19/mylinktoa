import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // 导入 MediaType 所在的包
import 'package:mime/mime.dart';

Future<Response> onRequest(RequestContext context) async {
  //linkb?q=how are you buddy??
  // 检查是否为 POST 请求
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'error': 'Only POST method is allowed.'},
    );
  }

  try {
    // 检查内容类型是否为 multipart/form-data
    final contentType = context.request.headers['content-type'];
    if (contentType == null || !contentType.startsWith('multipart/form-data')) {
      return Response.json(
        statusCode: HttpStatus.unsupportedMediaType,
        body: {'error': 'Unsupported content type.'},
      );
    }

    // 获取请求体中的字节流
    final boundary = contentType.split('boundary=')[1];
    final transformer = MimeMultipartTransformer(boundary);
    final bodyStream = context.request.bytes().asBroadcastStream();

    // 解析 multipart 数据
    final parts = await transformer.bind(bodyStream).toList();

    Uint8List? imageData;
    String? query;

    // 遍历请求中的所有部分，查找图像数据和查询参数
    for (var part in parts) {
      final headers = part.headers;
      final contentDisposition = headers['content-disposition'];

      if (contentDisposition != null) {
        if (contentDisposition.contains('filename=')) {
          // 处理图像文件
          final data = await part.toList();
          imageData = Uint8List.fromList(data.expand((x) => x).toList());
        } else if (contentDisposition.contains('form-data; name="q"')) {
          // 处理查询参数
          final data = await part.toList();
          query = utf8.decode(data.expand((x) => x).toList());
        }
      }
    }

    // 检查是否包含图像数据
    if (imageData == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'No image provided.'},
      );
    }

    // 使用默认查询参数
    query ??=
        'What do you see? Use lists. Start with a headline for each image.';

    // 准备要发送到目标服务器的 multipart 数据
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://mydiumtify.globeapp.dev/chatadvance'),
    );

    // 添加查询参数
    request.fields['q'] = query;

    // 添加图像文件
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageData,
      filename: 'image.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));

    // 发送请求到目标服务器
    final response = await request.send();

    // 处理目标服务器的响应
    final responseBody = await response.stream.bytesToString();
    final decodedResponse = jsonDecode(responseBody);

    // 返回目标服务器的响应
    return Response.json(
      body: decodedResponse,
    );
  } catch (e) {
    // 捕获异常并返回错误响应
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'error': 'Failed to process the request.',
        'details': e.toString()
      },
    );
  }
}
