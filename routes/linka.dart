import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;

Future<Response> onRequest(RequestContext context) async {
  //linka?q=how are you buddy??
  final request = context.request;

  final params = request.uri.queryParameters;

  var query = params['q'] ?? 'how are you buddy??';

  final String apiUrl =
      'https://mydiumtify.globeapp.dev/chattext?q=${Uri.encodeComponent(query)}';
  print(apiUrl);

  final response = await http.get(Uri.parse(apiUrl));
  return Response.json(body: jsonEncode(response.body));
}
