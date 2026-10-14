import 'dart:convert';

/// The file listing every template, so they can be found where a folder
/// can't be listed, such as a raw GitHub URL.
const templateIndexFileName = 'index.json';

const supportedTemplateIndexVersions = {1};

/// A template file name: a template id plus `.json`. Nothing else is
/// allowed, so a name can't reach outside the template folder.
final _fileNamePattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*\.json$');

class TemplateIndex {
  const TemplateIndex(this.files);

  /// Template file names, for example `skyjo.json`.
  final List<String> files;
}

/// Reads an `index.json`. Throws a [FormatException] saying what is wrong.
TemplateIndex parseTemplateIndex(String source) {
  final Object? json;
  try {
    json = jsonDecode(source);
  } on FormatException catch (error) {
    throw FormatException('index.json is not valid JSON: ${error.message}');
  }
  if (json is! Map<String, Object?>) {
    throw const FormatException('index.json must be an object');
  }

  final version = json['indexVersion'];
  if (version is! int || !supportedTemplateIndexVersions.contains(version)) {
    throw FormatException(
      'index.json: unsupported indexVersion $version; expected one of: '
      '${supportedTemplateIndexVersions.join(', ')}',
    );
  }

  final templates = json['templates'];
  if (templates is! List<Object?>) {
    throw const FormatException('index.json: templates must be a list');
  }

  final files = <String>[];
  for (final file in templates) {
    if (file is! String || !_fileNamePattern.hasMatch(file)) {
      throw FormatException(
        'index.json: "$file" is not a template file name like skyjo.json',
      );
    }
    if (files.contains(file)) {
      throw FormatException('index.json: "$file" is listed twice');
    }
    files.add(file);
  }

  return TemplateIndex(List.unmodifiable(files));
}

/// Whether [path] is a template file rather than the index.
bool isTemplateFilePath(String path) =>
    path.endsWith('.json') &&
    path.split(RegExp(r'[/\\]')).last != templateIndexFileName;
