import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:scoard_game/application/repositories/online_template_repository.dart';
import 'package:scoard_game/core/templates/template_index.dart';

/// Downloads templates over HTTPS: `index.json` from the template URL, then
/// each file it lists.
class HttpTemplateDownloader implements TemplateDownloader {
  HttpTemplateDownloader({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
    this.parallelDownloads = 4,
  }) : _givenClient = client;

  final http.Client? _givenClient;

  // Made on first use, so an app that never checks opens no connections.
  late final http.Client _client = _givenClient ?? http.Client();
  final Duration timeout;
  final int parallelDownloads;

  @override
  Future<TemplateDownload> download(Uri baseUrl) async {
    final TemplateIndex index;
    try {
      final source = await _get(baseUrl.resolve(templateIndexFileName));
      index = parseTemplateIndex(source);
    } on FormatException catch (error) {
      throw TemplateDownloadException(error.message);
    } on _FetchError catch (error) {
      throw TemplateDownloadException(
        "Couldn't read $templateIndexFileName: ${error.message}",
      );
    }

    final files = <String, String>{};
    final failures = <String, String>{};
    final queue = [...index.files];

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final file = queue.removeLast();
        try {
          files[file] = await _get(baseUrl.resolve(file));
        } on _FetchError catch (error) {
          failures[file] = error.message;
        }
      }
    }

    await Future.wait([
      for (var count = 0; count < parallelDownloads; count++) worker(),
    ]);

    return TemplateDownload(
      listedFiles: index.files,
      files: files,
      failures: failures,
    );
  }

  @override
  Future<ImageDownload> downloadImages(Uri baseUrl, Set<String> names) async {
    final images = <String, Uint8List>{};
    final failures = <String, String>{};
    final queue = [...names];

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final name = queue.removeLast();
        try {
          final bytes = await _getBytes(baseUrl.resolve('images/$name'));
          if (bytes.length > maximumImageBytes) {
            failures[name] = 'larger than ${maximumImageBytes ~/ 1024} KB';
          } else if (!_looksLikeImage(bytes)) {
            failures[name] = 'not a PNG, JPEG, or WebP picture';
          } else {
            images[name] = bytes;
          }
        } on _FetchError catch (error) {
          failures[name] = error.message;
        }
      }
    }

    await Future.wait([
      for (var count = 0; count < parallelDownloads; count++) worker(),
    ]);
    return ImageDownload(images: images, failures: failures);
  }

  /// Line pictures are small icons; anything bigger is a mistake.
  static const maximumImageBytes = 1024 * 1024;

  static bool _looksLikeImage(Uint8List bytes) {
    bool startsWith(List<int> prefix, [int offset = 0]) =>
        bytes.length >= offset + prefix.length &&
        [
          for (var index = 0; index < prefix.length; index++)
            bytes[offset + index] == prefix[index],
        ].every((same) => same);

    return startsWith(const [0x89, 0x50, 0x4E, 0x47]) || // PNG
        startsWith(const [0xFF, 0xD8, 0xFF]) || // JPEG
        (startsWith(const [0x52, 0x49, 0x46, 0x46]) && // RIFF....WEBP
            startsWith(const [0x57, 0x45, 0x42, 0x50], 8));
  }

  Future<String> _get(Uri url) async {
    // GitHub serves raw files as text/plain, which http would decode as
    // Latin-1. Templates are UTF-8.
    return utf8.decode(await _getBytes(url));
  }

  Future<Uint8List> _getBytes(Uri url) async {
    final http.Response response;
    try {
      response = await _client.get(url).timeout(timeout);
    } on TimeoutException {
      throw const _FetchError('timed out');
    } on Exception catch (error) {
      throw _FetchError('could not connect ($error)');
    }
    if (response.statusCode != 200) {
      throw _FetchError('HTTP ${response.statusCode}');
    }
    return response.bodyBytes;
  }
}

class _FetchError implements Exception {
  const _FetchError(this.message);

  final String message;
}
