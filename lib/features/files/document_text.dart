import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Extracts readable paragraphs from a modern Word document (.docx).
String readDocxText(List<int> bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final entry = archive.findFile('word/document.xml');
  if (entry == null || !entry.isFile) {
    throw const FormatException('This is not a valid Word document.');
  }
  if (entry.size > 10 * 1024 * 1024) {
    throw const FormatException('This Word document is too large to preview.');
  }
  final content = entry.readBytes();
  if (content == null) {
    throw const FormatException('The Word document could not be read.');
  }
  final document = XmlDocument.parse(utf8.decode(content));
  final paragraphs = <String>[];
  for (final paragraph in document.findAllElements('w:p')) {
    final buffer = StringBuffer();
    for (final node in paragraph.descendants.whereType<XmlElement>()) {
      switch (node.name.qualified) {
        case 'w:t':
          buffer.write(node.innerText);
          break;
        case 'w:tab':
          buffer.write('\t');
          break;
        case 'w:br':
          buffer.write('\n');
          break;
      }
    }
    final text = buffer.toString().trim();
    if (text.isNotEmpty) paragraphs.add(text);
  }
  return paragraphs.join('\n\n');
}
