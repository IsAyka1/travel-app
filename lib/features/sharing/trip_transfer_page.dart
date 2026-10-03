import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/travel_controller.dart';
import 'trip_package.dart';

class TripTransferPage extends StatefulWidget {
  const TripTransferPage({super.key, required this.controller});

  final TravelController controller;

  @override
  State<TripTransferPage> createState() => _TripTransferPageState();
}

class _TripTransferPageState extends State<TripTransferPage> {
  bool busy = false;

  String _count(int value, String singular, String plural) =>
      '$value ${value == 1 ? singular : plural}';

  String get _packageName {
    final today = DateTime.now();
    final date =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    return 'travel-atlas-$date.zip';
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _savePackage() async {
    setState(() => busy = true);
    try {
      final bytes = await widget.controller.createTripPackage();
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Save Travel Atlas trip package',
        fileName: _packageName,
        bytes: bytes,
      );
      if (mounted && saved != null) _message('Trip package saved');
    } catch (error) {
      if (mounted) _message('Could not save trip package: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _sharePackage() async {
    setState(() => busy = true);
    try {
      final bytes = await widget.controller.createTripPackage();
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          title: 'Share Travel Atlas trip',
          files: [XFile.fromData(bytes, mimeType: 'application/zip')],
          fileNameOverrides: [_packageName],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (error) {
      if (mounted) _message('Could not share trip package: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _importPackage() async {
    setState(() => busy = true);
    try {
      final picked = await FilePicker.pickFiles();
      if (picked.isEmpty) return;
      final source = picked.first;
      if ((source.lengthSync() ?? 0) > TripPackageCodec.maxPackageBytes) {
        throw const FormatException('Trip package is too large to import.');
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in source.readAsByteStream()) {
        if (builder.length + chunk.length > TripPackageCodec.maxPackageBytes) {
          throw const FormatException('Trip package is too large to import.');
        }
        builder.add(chunk);
      }
      final package = await widget.controller.readTripPackage(
        builder.toBytes(),
      );
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import trip package?'),
          content: Text(
            'Add ${_count(package.places.length, 'place', 'places')}, '
            '${_count(package.actions.length, 'calendar action', 'calendar actions')}, '
            '${_count(package.visaPlans.length, 'visa block', 'visa blocks')}, and '
            '${_count(package.files.length, 'file', 'files')}? '
            'Your current plans will stay in place.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await widget.controller.importTripPackage(package);
      if (mounted) _message('Trip package imported');
    } catch (error) {
      if (mounted) _message('Could not import trip package: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text('Share trips', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      const Text(
        'A trip package includes all saved places, calendar actions, visa blocks, and imported files.',
      ),
      if (busy) ...[
        const SizedBox(height: 18),
        const LinearProgressIndicator(),
      ],
      const SizedBox(height: 24),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send or save',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Send the package through your device share menu, including Bluetooth when available, or save a ZIP file to send later.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: busy ? null : _sharePackage,
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share package'),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : _savePackage,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Save package file'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Receive a trip',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a Travel Atlas ZIP package saved on this device. Its contents will be added to your current plans.',
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: busy ? null : _importPackage,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Import package file'),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
