import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/api/api_config.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The product photo everywhere it's read-only: the web table row, the mobile
// card, and the view-details sheet. [imageUrl] is the relative `/uploads/...`
// path stored on the product — resolved to a loadable URL here so callers
// never have to remember to.
//
// No image, still loading, or failed to load all land on the same fallback
// box — a bordered card printing the first 4 letters of the product's name,
// the same "no photo yet" treatment the Clients list uses initials for. Only
// the first 4 characters, never the full SKU — a code like "CFB-SBF-001"
// isn't what identifies the product to a person glancing at the row.
// ─────────────────────────────────────────────────────────────────────────────
class ProductThumbnail extends StatelessWidget {
  final String? imageUrl;

  /// Shown in the fallback box when there's no photo — pass the product's
  /// name (only its first 4 characters are used). Blank falls back to a
  /// generic icon instead of an empty box.
  final String fallbackLabel;

  final double size;
  final double radius;

  const ProductThumbnail({
    super.key,
    required this.imageUrl,
    this.fallbackLabel = '',
    this.size = 40,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return _Placeholder(
        colors: colors,
        size: size,
        radius: radius,
        label: fallbackLabel,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        ApiConfig.resolveImageUrl(url),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _Placeholder(
          colors: colors,
          size: size,
          radius: radius,
          label: fallbackLabel,
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _Placeholder(
            colors: colors,
            size: size,
            radius: radius,
            label: fallbackLabel,
            loading: true,
          );
        },
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final AppThemeColors colors;
  final double size;
  final double radius;
  final String label;
  final bool loading;

  const _Placeholder({
    required this.colors,
    required this.size,
    required this.radius,
    required this.label,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colors.divider),
      ),
      child: Center(child: loading ? _spinner() : _label()),
    );
  }

  Widget _spinner() => SizedBox(
    width: size * 0.32,
    height: size * 0.32,
    child: CircularProgressIndicator(strokeWidth: 2, color: colors.accent),
  );

  Widget _label() {
    if (label.isEmpty) {
      return Icon(
        Icons.inventory_2_outlined,
        size: size * 0.45,
        color: colors.textHint,
      );
    }
    final text = (label.length > 4 ? label.substring(0, 4) : label)
        .toUpperCase();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size * 0.08),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          style: TextStyle(
            fontSize: size * 0.26,
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
            fontFamily: brandFontFamily,
          ),
        ),
      ),
    );
  }
}
