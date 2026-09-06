import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/api/api_config.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The photo box on the Add/Edit Product dialog — one widget shared by web and
// mobile, since the dialog itself already is. Three states:
//   • empty            → dashed-feeling bordered box, tap to pick
//   • picked (bytes)    → live preview of a file chosen this session, not yet
//                          uploaded (upload happens on Save, not on pick)
//   • existing (url)    → the product's current photo, loaded from the server
// A picked file always wins over an existing url, and either can be cleared
// with the remove badge.
// ─────────────────────────────────────────────────────────────────────────────
class ProductImagePicker extends StatelessWidget {
  /// Bytes of a file picked this session — takes priority for the preview.
  final Uint8List? pickedBytes;

  /// The product's photo as it stands on the server (relative `/uploads/...`
  /// path). Ignored once [pickedBytes] is set or [removed] is true.
  final String? existingImageUrl;

  /// True once the user has tapped the remove badge on an existing photo.
  final bool removed;

  final VoidCallback onPick;
  final VoidCallback onRemove;
  final AppThemeColors colors;
  final double size;

  const ProductImagePicker({
    super.key,
    required this.pickedBytes,
    required this.existingImageUrl,
    required this.removed,
    required this.onPick,
    required this.onRemove,
    required this.colors,
    this.size = 96,
  });

  bool get _hasExisting =>
      !removed && existingImageUrl != null && existingImageUrl!.isNotEmpty;
  bool get _hasImage => pickedBytes != null || _hasExisting;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: colors.inputFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: _hasImage ? _preview() : _empty(),
            ),
          ),
          if (_hasImage)
            Positioned(
              top: -6,
              right: -6,
              child: _Badge(
                icon: Icons.close_rounded,
                background: const Color(0xFFEF4444),
                onTap: onRemove,
              ),
            ),
          Positioned(
            bottom: -6,
            right: -6,
            child: _Badge(
              icon: _hasImage
                  ? Icons.edit_rounded
                  : Icons.add_photo_alternate_outlined,
              background: AppColors.primaryOrange,
              onTap: onPick,
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview() {
    final image = pickedBytes != null
        ? Image.memory(
            pickedBytes!,
            fit: BoxFit.cover,
            // A picked file that fails to decode (wrong format, truncated)
            // still counts as "has an image" — the remove badge has to stay
            // reachable, so this reads as broken rather than reverting to
            // the empty "Add Photo" prompt as if nothing were selected.
            errorBuilder: (context, error, stackTrace) => _broken(),
          )
        : Image.network(
            ApiConfig.resolveImageUrl(existingImageUrl!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _broken(),
          );
    return ClipRRect(borderRadius: BorderRadius.circular(13), child: image);
  }

  Widget _broken() {
    return Center(
      child: Icon(
        Icons.broken_image_outlined,
        size: 26,
        color: colors.textHint,
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 26,
            color: colors.textHint,
          ),
          const SizedBox(height: 4),
          Text(
            'Add Photo',
            style: TextStyle(
              fontSize: 10.5,
              color: colors.textHint,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

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
