import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class NetworkUtils {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    },
  ));

  static Future<String?> fetchWithFallback(String url) async {
    final proxies = [
      'https://corsproxy.io/?',
      'https://api.allorigins.win/raw?url=',
    ];

    for (var proxy in proxies) {
      try {
        final effectiveUrl = kIsWeb ? '$proxy${Uri.encodeComponent(url)}' : url;
        final response = await _dio.get(effectiveUrl);
        if (response.statusCode == 200) {
          return response.data.toString();
        }
      } catch (e) {
        debugPrint('Proxy $proxy failed for $url: $e');
        if (!kIsWeb) break;
      }
    }
    return null;
  }
}
