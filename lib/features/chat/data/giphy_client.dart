import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/gif_config.dart';
import '../domain/chat_gif.dart';

/// One Giphy GIF with the two renditions the app needs.
class GifResult {
  const GifResult({
    required this.id,
    required this.title,
    required this.previewUrl,
    required this.url,
  });

  final String id;

  /// Giphy's content description, used as the tile's accessibility label.
  final String title;

  /// Small rendition for the picker grid.
  final String previewUrl;

  /// Larger rendition stored on the message.
  final String url;
}

class GifSearchFailure implements Exception {
  const GifSearchFailure(this.message);

  final String message;
}

class GiphyClient {
  GiphyClient(this._client);

  final http.Client _client;

  static const _base = 'https://api.giphy.com/v1/gifs';

  Future<List<GifResult>> trending() => _fetch('$_base/trending');

  Future<List<GifResult>> search(String query) =>
      _fetch('$_base/search', query: query.trim());

  Future<List<GifResult>> _fetch(String path, {String? query}) async {
    final uri = Uri.parse(path).replace(
      queryParameters: {
        'api_key': GifConfig.apiKey,
        'limit': '24',
        'rating': 'pg',
        'q': ?query,
      },
    );

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 8));
    } on Exception {
      throw const GifSearchFailure(
        'Could not reach GIPHY. Check your connection and try again.',
      );
    }

    if (response.statusCode == 429) {
      throw const GifSearchFailure(
        'GIPHY is rate-limiting this build. Try again in a minute.',
      );
    }
    if (response.statusCode != 200) {
      throw const GifSearchFailure('GIF search is unavailable right now.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const GifSearchFailure('GIF search returned an unreadable reply.');
    }
    return parseResults(decoded);
  }

  /// Pulls the fields the UI needs out of Giphy's response; kept static so
  /// tests can cover the shape without a network.
  static List<GifResult> parseResults(Object? decoded) {
    if (decoded is! Map<String, dynamic>) return const [];
    final data = decoded['data'];
    if (data is! List) return const [];

    final results = <GifResult>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final result = _parse(item);
      if (result != null) results.add(result);
    }
    return results;
  }

  static GifResult? _parse(Map<String, dynamic> item) {
    final images = item['images'];
    if (images is! Map<String, dynamic>) return null;

    String? rendition(String key) {
      final entry = images[key];
      if (entry is! Map<String, dynamic>) return null;
      final url = entry['url'];
      return url is String && isAllowedGifUrl(url) ? url : null;
    }

    final preview = rendition('fixed_width');
    final url =
        rendition('downsized_medium') ??
        rendition('fixed_width_downsampled') ??
        rendition('fixed_width') ??
        rendition('downsized');
    if (url == null) return null;

    final id = item['id'];
    return GifResult(
      id: id is String ? id : url,
      title: switch (item['content_description']) {
        final String text when text.trim().isNotEmpty => text.trim(),
        _ => 'GIF',
      },
      previewUrl: preview ?? url,
      url: url,
    );
  }
}
