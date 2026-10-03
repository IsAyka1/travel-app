import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../app/travel_controller.dart';
import 'document_text.dart';
import 'stored_file.dart';

enum FilePreviewType { pdf, image, docx, text, unsupported }

FilePreviewType previewType(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.pdf')) return FilePreviewType.pdf;
  if (['.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp'].any(lower.endsWith)) {
    return FilePreviewType.image;
  }
  if (lower.endsWith('.docx')) return FilePreviewType.docx;
  if (['.txt', '.md', '.csv'].any(lower.endsWith)) {
    return FilePreviewType.text;
  }
  return FilePreviewType.unsupported;
}

Future<void> openFilePreview(
  BuildContext context, {
  required TravelController controller,
  required StoredFile file,
}) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FilePreviewPage(controller: controller, file: file),
    ),
  );
}

class FilePreviewPage extends StatefulWidget {
  const FilePreviewPage({
    super.key,
    required this.controller,
    required this.file,
  });

  final TravelController controller;
  final StoredFile file;

  @override
  State<FilePreviewPage> createState() => _FilePreviewPageState();
}

class _FilePreviewPageState extends State<FilePreviewPage> {
  Future<Object>? _preview;
  PdfControllerPinch? _pdfController;

  @override
  void initState() {
    super.initState();
    _preview = _load();
  }

  Future<Object> _load() async {
    switch (previewType(widget.file.name)) {
      case FilePreviewType.pdf:
        final path = await widget.controller.filePath(widget.file);
        return PdfControllerPinch(document: PdfDocument.openFile(path));
      case FilePreviewType.image:
        return Uint8List.fromList(
          await widget.controller.readFile(widget.file),
        );
      case FilePreviewType.docx:
        if (widget.file.size > 25 * 1024 * 1024) {
          throw const FormatException(
            'This Word document is too large to preview.',
          );
        }
        return readDocxText(await widget.controller.readFile(widget.file));
      case FilePreviewType.text:
        return utf8.decode(await widget.controller.readFile(widget.file));
      case FilePreviewType.unsupported:
        return const _UnsupportedPreview();
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      final saved = await widget.controller.exportFile(widget.file);
      if (mounted && saved != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved ${widget.file.name} to your device')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save file: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.file.name, overflow: TextOverflow.ellipsis),
      actions: [
        IconButton(
          tooltip: 'Save to device',
          onPressed: _save,
          icon: const Icon(Icons.download_outlined),
        ),
      ],
    ),
    body: FutureBuilder<Object>(
      future: _preview,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not preview this file: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final value = snapshot.data!;
        if (value is PdfControllerPinch) {
          _pdfController = value;
          return PdfViewPinch(
            controller: value,
            onDocumentError: (error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not open PDF: $error')),
                );
              }
            },
          );
        }
        if (value is Uint8List) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Center(
              child: Image.memory(
                value,
                errorBuilder: (_, error, _) =>
                    Center(child: Text('Could not display image: $error')),
              ),
            ),
          );
        }
        if (value is String) {
          return SelectionArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (value.isEmpty)
                  const Text('This document has no readable text.')
                else
                  Text(value),
              ],
            ),
          );
        }
        return value as Widget;
      },
    ),
  );
}

class _UnsupportedPreview extends StatelessWidget {
  const _UnsupportedPreview();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Preview is available for PDFs, images, Word .docx files, and text. '
        'Use Save to device for this file.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}
