import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/api/api_config.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The web Add/Edit Product photo field — a small square drop zone. Mobile has
// no drag surface to drop onto, so it keeps the compact tap-only
// [ProductImagePicker] instead; this widget is web/desktop only, and is
// really that same square picker with a [DropTarget] wrapped around it —
// same size, same corner badges once a photo is set, just also droppable.
//
// Three states, each its own look: empty (dashed box, browse prompt), armed
// (a file is being dragged over it — tinted, "Release to upload"), and filled
// (the picked or existing photo, with change/remove badges). Switching
// between them pops with a small scale+fade rather than a hard cut.
// ─────────────────────────────────────────────────────────────────────────────
class ProductImageDropZone extends StatefulWidget {
  final Uint8List? pickedBytes;
  final String? existingImageUrl;
  final bool removed;

  /// Called with the bytes/filename of a file that passed validation —
  /// either dropped or picked via the browse dialog.
  final void Function(Uint8List bytes, String name) onFile;
  final VoidCallback onRemove;

  /// A dropped/picked file failed validation (wrong format or over the size
  /// cap) — [reason] is a ready-to-show message.
  final ValueChanged<String> onRejected;

  final AppThemeColors colors;

  /// Square side length.
  final double size;

  static const maxBytes = 2 * 1024 * 1024;
  static const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  const ProductImageDropZone({
    super.key,
    required this.pickedBytes,
    required this.existingImageUrl,
    required this.removed,
    required this.onFile,
    required this.onRemove,
    required this.onRejected,
    required this.colors,
    this.size = 140,
  });

  @override
  State<ProductImageDropZone> createState() => _ProductImageDropZoneState();
}

class _ProductImageDropZoneState extends State<ProductImageDropZone> {
  bool _dragging = false;

  bool get _hasExisting =>
      !widget.removed &&
      widget.existingImageUrl != null &&
      widget.existingImageUrl!.isNotEmpty;
  bool get _hasImage => widget.pickedBytes != null || _hasExisting;

  String? _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return null;
    return name.substring(dot + 1).toLowerCase();
  }

  Future<void> _accept(Uint8List bytes, String name) async {
    final ext = _extensionOf(name);
    if (ext == null || !ProductImageDropZone.allowedExtensions.contains(ext)) {
      widget.onRejected('Only JPG, PNG or WEBP images are allowed.');
      return;
    }
    if (bytes.length > ProductImageDropZone.maxBytes) {
      widget.onRejected('That image is over the 2MB limit.');
      return;
    }
    widget.onFile(bytes, name);
  }

  Future<void> _onDrop(List<XFile> files) async {
    setState(() => _dragging = false);
    if (files.isEmpty) return;
    final file = files.first;
    await _accept(await file.readAsBytes(), file.name);
  }

  Future<void> _browse() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    await _accept(file.bytes!, file.name);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropTarget(
          onDragEntered: (_) => setState(() => _dragging = true),
          onDragExited: (_) => setState(() => _dragging = false),
          onDragDone: (d) => _onDrop(d.files),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onTap: _hasImage ? null : _browse,
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: _dragging
                        ? AppColors.primaryOrange.withValues(alpha: 0.05)
                        : colors.inputFill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: CustomPaint(
                    painter: _DashedBorderPainter(
                      color: _dragging
                          ? AppColors.primaryOrange
                          : colors.border,
                      radius: 14,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(scale: anim, child: child),
                        ),
                        child: _hasImage
                            ? _Preview(
                                key: const ValueKey('preview'),
                                bytes: widget.pickedBytes,
                                existingUrl: _hasExisting
                                    ? widget.existingImageUrl
                                    : null,
                                colors: colors,
                              )
                            : _Prompt(
                                key: ValueKey(_dragging ? 'dragging' : 'empty'),
                                dragging: _dragging,
                                colors: colors,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_hasImage)
                Positioned(
                  top: -6,
                  right: -6,
                  child: _Badge(
                    icon: Icons.close_rounded,
                    background: const Color(0xFFEF4444),
                    onTap: widget.onRemove,
                  ),
                ),
              if (_hasImage)
                Positioned(
                  bottom: -6,
                  right: -6,
                  child: _Badge(
                    icon: Icons.edit_rounded,
                    background: AppColors.primaryOrange,
                    onTap: _browse,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'JPG, PNG or WEBP · Max 2MB',
          style: TextStyle(
            fontSize: 10.5,
            color: colors.textHint,
            fontFamily: brandFontFamily,
          ),
        ),
      ],
    );
  }
}

class _Prompt extends StatelessWidget {
  final bool dragging;
  final AppThemeColors colors;
  const _Prompt({super.key, required this.dragging, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // A small pop on the icon itself while a file hovers over the
            // zone — the one detail that makes "release to upload" feel
            // responsive rather than just a color change on screen.
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              tween: Tween(begin: 1, end: dragging ? 1.15 : 1.0),
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  dragging
                      ? Icons.download_rounded
                      : Icons.cloud_upload_outlined,
                  color: AppColors.primaryOrange,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dragging
                  ? 'Release to\nupload'
                  : 'Drag & drop\nor click to browse',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: dragging
                    ? AppColors.primaryOrange
                    : colors.textSecondary,
                fontFamily: brandFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  final Uint8List? bytes;
  final String? existingUrl;
  final AppThemeColors colors;

  const _Preview({
    super.key,
    required this.bytes,
    required this.existingUrl,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (bytes != null) {
      return Image.memory(
        bytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _broken(),
      );
    }
    return Image.network(
      ApiConfig.resolveImageUrl(existingUrl!),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _broken(),
    );
  }

  Widget _broken() => Container(
    color: colors.inputFill,
    child: Center(
      child: Icon(
        Icons.broken_image_outlined,
        size: 26,
        color: colors.textHint,
      ),
    ),
  );
}

/// Same small circular corner badge [ProductImagePicker] uses — kept
/// identical on purpose, so a photo control looks the same whether it's
/// droppable (web) or tap-only (mobile).
class _Badge extends StatelessWidget {
  final IconData icon;
  final Color background;
  final VoidCallback onTap;

  const _Badge({
    required this.icon,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Icon(icon, size: 13, color: Colors.white),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedBorderPainter({required this.color, this.radius = 8});

  @override
  void paint(Canvas canvas, Size size) {
    const dashW = 6.0;
    const dashSp = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
          Radius.circular(radius),
        ),
      );
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + dashW), paint);
        d += dashW + dashSp;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
