import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_test/features/files/document_text.dart';
import 'package:my_test/features/files/file_preview_page.dart';

void main() {
  test('recognizes previewable file types regardless of case', () {
    expect(previewType('TICKET.PDF'), FilePreviewType.pdf);
    expect(previewType('photo.JPEG'), FilePreviewType.image);
    expect(previewType('route.docx'), FilePreviewType.docx);
    expect(previewType('notes.txt'), FilePreviewType.text);
    expect(previewType('old.doc'), FilePreviewType.unsupported);
  });

  test('reads Word document paragraphs in order', () {
    final archive = Archive()
      ..add(
        ArchiveFile.string(
          'word/document.xml',
          '<w:document xmlns:w="http://schemas.openxmlformats.org/'
              'wordprocessingml/2006/main"><w:body>'
              '<w:p><w:r><w:t>Flight</w:t></w:r>'
              '<w:r><w:tab/><w:t>AB 123</w:t></w:r></w:p>'
              '<w:p><w:r><w:t>Hotel &amp; spa</w:t></w:r></w:p>'
              '</w:body></w:document>',
        ),
      );
    final bytes = ZipEncoder().encodeBytes(archive);
    expect(readDocxText(bytes), 'Flight\tAB 123\n\nHotel & spa');
  });
}
