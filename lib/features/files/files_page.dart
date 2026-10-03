import 'package:flutter/material.dart';

import '../../app/travel_controller.dart';
import 'file_preview_page.dart';
import 'stored_file.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key, required this.controller});

  final TravelController controller;

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  bool busy = false;

  Future<void> _import() async {
    setState(() => busy = true);
    try {
      final count = await widget.controller.importFiles();
      if (mounted && count > 0) {
        _message('Imported $count file${count == 1 ? '' : 's'}');
      }
    } catch (error) {
      if (mounted) _message('Could not import file: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _export(StoredFile file) async {
    setState(() => busy = true);
    try {
      final saved = await widget.controller.exportFile(file);
      if (mounted && saved != null) {
        _message('Saved ${file.name} to your device');
      }
    } catch (error) {
      if (mounted) _message('Could not save file: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _delete(StoredFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete imported file?'),
        content: Text(
          'Remove ${file.name} from app storage? The original file is not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      await widget.controller.deleteFile(file);
      if (mounted) _message('${file.name} removed');
    } catch (error) {
      if (mounted) _message('Could not delete file: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _icon(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png')) {
      return Icons.image_outlined;
    }
    if (lower.endsWith('.zip')) return Icons.folder_zip_outlined;
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final files = widget.controller.files.toList()
      ..sort((a, b) => b.importedAt.compareTo(a.importedAt));
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip files',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Keep tickets, itineraries, and documents with your travel plans.',
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: busy || !widget.controller.supportsFiles
                  ? null
                  : _import,
              icon: const Icon(Icons.upload_file),
              label: const Text('Import from device'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Imported files are copied into this app’s documents folder on your device. '
              'Tap a file to view it here, or use Save to device to keep a copy elsewhere.',
            ),
          ),
        ),
        if (!widget.controller.supportsFiles) ...[
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(22),
              child: Text(
                'Device file storage is available in the Android, iOS, and desktop app.',
              ),
            ),
          ),
        ] else if (files.isEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No files imported yet.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 12),
          for (final file in files)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(child: Icon(_icon(file.name))),
                title: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(_size(file.size)),
                onTap: busy
                    ? null
                    : () => openFilePreview(
                        context,
                        controller: widget.controller,
                        file: file,
                      ),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'View ${file.name}',
                      onPressed: busy
                          ? null
                          : () => openFilePreview(
                              context,
                              controller: widget.controller,
                              file: file,
                            ),
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                    IconButton(
                      tooltip: 'Save ${file.name} to device',
                      onPressed: busy ? null : () => _export(file),
                      icon: const Icon(Icons.download_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete ${file.name}',
                      onPressed: busy ? null : () => _delete(file),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
