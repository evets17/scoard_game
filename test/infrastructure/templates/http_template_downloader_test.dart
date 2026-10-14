import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scoard_game/application/repositories/online_template_repository.dart';
import 'package:scoard_game/infrastructure/templates/http_template_downloader.dart';

final baseUrl = Uri.parse('https://example.com/templates/');

/// Serves [files] by name under [baseUrl]; anything else is a 404.
HttpTemplateDownloader downloaderServing(
  Map<String, Object> files, {
  Duration timeout = const Duration(seconds: 10),
}) {
  return HttpTemplateDownloader(
    timeout: timeout,
    client: MockClient((request) async {
      final name = request.url.pathSegments.last;
      final body = files[name];
      if (body is Future<String>) {
        return http.Response.bytes(utf8.encode(await body), 200);
      }
      if (body is String) {
        // GitHub sends text/plain with no charset declared for some files.
        return http.Response.bytes(
          utf8.encode(body),
          200,
          headers: {'content-type': 'text/plain'},
        );
      }
      return http.Response('Not Found', 404);
    }),
  );
}

String index(List<String> files) =>
    jsonEncode({'indexVersion': 1, 'templates': files});

void main() {
  test('downloads every listed file from the template URL', () async {
    final download = await downloaderServing({
      'index.json': index(['a.json', 'b.json']),
      'a.json': '{"name": "A × 2"}',
      'b.json': '{"name": "B"}',
    }).download(baseUrl);

    expect(download.listedFiles, ['a.json', 'b.json']);
    // UTF-8 survives a text/plain response.
    expect(download.files, {'a.json': '{"name": "A × 2"}', 'b.json': '{"name": "B"}'});
    expect(download.failures, isEmpty);
  });

  test('a file that fails is reported and the rest still download', () async {
    final download = await downloaderServing({
      'index.json': index(['a.json', 'missing.json']),
      'a.json': '{}',
    }).download(baseUrl);

    expect(download.files.keys, ['a.json']);
    expect(download.failures, {'missing.json': 'HTTP 404'});
  });

  test('a missing or unreadable index fails the whole download', () async {
    await expectLater(
      downloaderServing({}).download(baseUrl),
      throwsA(
        isA<TemplateDownloadException>().having(
          (error) => error.message,
          'message',
          "Couldn't read index.json: HTTP 404",
        ),
      ),
    );
    await expectLater(
      downloaderServing({
        'index.json': '{"indexVersion": 9, "templates": []}',
      }).download(baseUrl),
      throwsA(isA<TemplateDownloadException>()),
    );
  });

  test('a slow file times out instead of hanging', () async {
    final download = await downloaderServing(
      {
        'index.json': index(['slow.json']),
        'slow.json': Completer<String>().future,
      },
      timeout: const Duration(milliseconds: 20),
    ).download(baseUrl);

    expect(download.failures, {'slow.json': 'timed out'});
  });
}
