// Shrinks a picture for a template and saves it as JPEG into the templates'
// images folder:
//
//   dart run tool/prepare_template_image.dart <picture> <name.jpg>
//
// For example:
//
//   dart run tool/prepare_template_image.dart _specs/staged_images/flip7-logo.png flip7_banner.jpg
//
// Pictures wider than 1080 are shrunk to 1080 wide, which is sharp on a
// phone; narrower ones keep their size. JPEG keeps photos and box art to a
// few hundred KB, well inside the 1 MB limit for template pictures.
import 'dart:io';

import 'package:image/image.dart' as img;

const _maximumWidth = 1080;
const _quality = 82;
const _imagesFolder = 'assets/templates/images';
final _namePattern = RegExp(r'^[a-z0-9]+([_-][a-z0-9]+)*\.jpg$');

void main(List<String> arguments) {
  if (arguments.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/prepare_template_image.dart <picture> <name.jpg>',
    );
    exit(64);
  }
  final [source, name] = arguments;
  if (!_namePattern.hasMatch(name)) {
    stderr.writeln(
      '"$name" must be lowercase letters and digits, with _ or - between '
      'words, ending .jpg, like flip7_banner.jpg',
    );
    exit(64);
  }

  final picture = img.decodeImage(File(source).readAsBytesSync());
  if (picture == null) {
    stderr.writeln("Couldn't read $source as a picture.");
    exit(65);
  }

  final sized = picture.width > _maximumWidth
      ? img.copyResize(
          picture,
          width: _maximumWidth,
          interpolation: img.Interpolation.cubic,
        )
      : picture;
  final output = File('$_imagesFolder/$name')
    ..writeAsBytesSync(img.encodeJpg(sized, quality: _quality));

  stdout.writeln(
    'Saved ${output.path}: ${sized.width}x${sized.height}, '
    '${(output.lengthSync() / 1024).round()} KB',
  );
}
