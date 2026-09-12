import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Upload-an-image well.
//
// The brand logo and the invoice signature are the same interaction — tap to
// pick, preview what was picked, Remove to clear — so they share one widget
// rather than each carrying a private copy that drifts.
//
// Images are held as base64 because that is how both of them are stored
// (inside the brand and billing JSON blobs), so nothing here has to know about
// files after the picker closes.
// ─────────────────────────────────────────────────────────────────────────────
class ImageDropzone extends StatelessWidget {
  /// The current image, base64-encoded, or null for none.
  final String? base64Image;

  final ValueChanged<String> onPicked;
  final VoidCallback onRemove;

  final double width;
  final double height;

  /// What the empty well invites — "Upload logo", "Upload signature".
  final String emptyLabel;

  const ImageDropzone({
    super.key,
    required this.base64Image,
    required this.onPicked,
    required this.onRemove,
    required this.emptyLabel,
    this.width = 88,
    this.height = 88,
  });

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'svg'],
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) return;
    onPicked(base64Encode(bytes));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    Uint8List? bytes;
    final encoded = base64Image;
    if (encoded != null && encoded.isNotEmpty) {
      try {
        bytes = base64Decode(encoded);
      } catch (_) {
        bytes = null;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: _pick,
          borderRadius: BorderRadius.circular(c.radius),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: c.rowEven,
              borderRadius: BorderRadius.circular(c.radius),
              border: Border.all(
                color: c.border,
                style: bytes == null ? BorderStyle.solid : BorderStyle.none,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: bytes == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 24,
                        color: c.textHint,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        emptyLabel,
                        style: TextStyle(fontSize: 10, color: c.textHint),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      // An SVG (or anything Flutter can't decode) must not
                      // leave a broken box where the image should be.
                      errorBuilder: (_, _, _) => Center(
                        child: Icon(Icons.image_outlined, color: c.textHint),
                      ),
                    ),
                  ),
          ),
        ),
        if (bytes != null)
          TextButton(
            onPressed: onRemove,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Remove',
              style: TextStyle(fontSize: 11, color: c.error),
            ),
          ),
      ],
    );
  }
}
