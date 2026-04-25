import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/file_category.dart';
import '../models/scan_file_item.dart';
import '../services/media_preview_service.dart';

class FileResultTile extends StatelessWidget {
  const FileResultTile({
    super.key,
    required this.item,
    required this.selected,
    required this.onChanged,
    this.recommended = false,
  });

  final ScanFileItem item;
  final bool selected;
  final bool recommended;
  final ValueChanged<bool> onChanged;

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} ${units[unitIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat(
      'dd/MM/yyyy - HH:mm',
      'fr_FR',
    ).format(item.modifiedAt);

    return Card(
      margin: EdgeInsets.zero,
      child: CheckboxListTile(
        value: selected,
        onChanged: (v) => onChanged(v ?? false),
        secondary: FilePreviewThumb(item: item),
        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item.path, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('${item.category.label} • ${_formatBytes(item.sizeBytes)}'),
            Text('Date: $dateLabel'),
            if (recommended)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Recommande a supprimer',
                  style: TextStyle(
                    color: Color(0xFF2EAF61),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (item.isSystemFile)
              const Text(
                'Fichier systeme protege',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}

class FilePreviewThumb extends StatefulWidget {
  const FilePreviewThumb({super.key, required this.item});

  final ScanFileItem item;

  @override
  State<FilePreviewThumb> createState() => _FilePreviewThumbState();
}

class _FilePreviewThumbState extends State<FilePreviewThumb> {
  Future<Uint8List?>? _videoThumbFuture;

  @override
  void initState() {
    super.initState();
    _prepareThumbnail();
  }

  @override
  void didUpdateWidget(covariant FilePreviewThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.path != widget.item.path ||
        oldWidget.item.category != widget.item.category) {
      _prepareThumbnail();
    }
  }

  void _prepareThumbnail() {
    if (widget.item.category == FileCategory.video) {
      _videoThumbFuture = MediaPreviewService.instance.getVideoThumbnail(
        path: widget.item.path,
        maxWidth: 140,
      );
      return;
    }
    _videoThumbFuture = null;
  }

  @override
  Widget build(BuildContext context) {
    const size = 56.0;

    if (widget.item.category == FileCategory.photo) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(widget.item.path),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _fallbackThumb(Icons.photo_outlined);
          },
        ),
      );
    }

    if (widget.item.category == FileCategory.video) {
      return FutureBuilder<Uint8List?>(
        future: _videoThumbFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    snapshot.data!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            );
          }
          return _fallbackThumb(Icons.videocam_outlined);
        },
      );
    }

    return _fallbackThumb(Icons.insert_drive_file_outlined);
  }

  Widget _fallbackThumb(IconData icon) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0x110A3A66),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon),
    );
  }
}
