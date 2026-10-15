import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:scoard_game/application/services/templates/template_images.dart';

final _memoryImages = Expando<MemoryImage>('TemplateImage');

/// The picture called [name], or null when there is none, so the line shows
/// its text instead.
ImageProvider? templateImageProvider(TemplateImages images, String? name) {
  if (name == null) {
    return null;
  }
  final Uint8List? bytes = images.online(name);
  if (bytes != null) {
    return _memoryImages[bytes] ??= MemoryImage(bytes);
  }
  if (images.isBundled(name)) {
    return AssetImage('${TemplateImages.bundledFolder}$name');
  }
  return null;
}
