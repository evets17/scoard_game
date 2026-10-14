import 'dart:async';
import 'dart:convert';

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

  Future<String> _get(Uri url) async {
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
    // GitHub serves raw files as text/plain, which http would decode as
    // Latin-1. Templates are UTF-8.
    return utf8.decode(response.bodyBytes);
  }
}

class _FetchError implements Exception {
  const _FetchError(this.message);

  final String message;
}
