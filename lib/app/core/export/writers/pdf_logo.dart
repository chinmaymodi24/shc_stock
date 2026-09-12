import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:shc_stock/app/core/export/writers/pdf_document.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Turns the buyer's uploaded logo into something a PDF can carry.
//
// Flutter's codecs are async and the PDF writers are not, so decoding happens
// here, once, before a report is built — the writers then receive plain
// pixels.
//
// Everything that can go wrong returns null rather than throwing, and a null
// logo simply means the report falls back to the short-code plate. A broken
// upload must never be the reason an export fails.
// ─────────────────────────────────────────────────────────────────────────────

/// The longest edge we keep. A logo prints at ~40pt; anything beyond this is
/// invisible detail that would bloat an uncompressed RGB stream (a 2000px
/// square would be 12MB on its own).
const int kMaxLogoEdge = 256;

// ── Cache ───────────────────────────────────────────────────────────────────
// The PDF writers are synchronous and decoding is not, so the logo is decoded
// once — when the brand is loaded or applied — and read back synchronously at
// export time. Keyed by the source string so a stale image can't survive a
// logo change.

String? _cachedKey;
PdfImage? _cachedLogo;

/// Decodes the applied brand's logo and holds it for the writers.
/// Awaited by [BrandController] on load and on apply.
Future<void> warmPdfLogoCache(String? base64Logo) async {
  if (base64Logo == _cachedKey) return;
  _cachedLogo = await decodeLogoForPdf(base64Logo);
  _cachedKey = base64Logo;
}

/// The decoded logo for the brand currently applied, or null when there is
/// none (or it couldn't be decoded). Safe to call from synchronous code.
PdfImage? get brandPdfLogo => _cachedLogo;

/// Drops the cache — used by tests.
void resetPdfLogoCache() {
  _cachedKey = null;
  _cachedLogo = null;
}

// ── The authorised signature ────────────────────────────────────────────────
// Same problem, same shape: an image the invoice writer needs synchronously,
// decoded once when the billing profile loads or is saved. Kept beside the
// logo cache rather than in the billing module so both images go through one
// decoder and one set of size limits.

String? _cachedSignatureKey;
PdfImage? _cachedSignature;

/// Decodes the billing profile's signature and holds it for the invoice
/// writer. Awaited by [BillingProfileController] on fetch and on save.
Future<void> warmPdfSignatureCache(String? base64Signature) async {
  if (base64Signature == _cachedSignatureKey) return;
  _cachedSignature = await decodeLogoForPdf(base64Signature);
  _cachedSignatureKey = base64Signature;
}

/// The decoded signature, or null when none is configured (or it couldn't be
/// decoded). Safe to call from synchronous code.
PdfImage? get billingPdfSignature => _cachedSignature;

/// Drops the signature cache — used by tests.
void resetPdfSignatureCache() {
  _cachedSignatureKey = null;
  _cachedSignature = null;
}

/// Decodes [base64Logo] to 8-bit RGB with alpha composited onto white.
///
/// Returns null when there is no logo, when the bytes aren't an image Flutter
/// can decode (an SVG upload, most commonly), or when the data is corrupt.
Future<PdfImage?> decodeLogoForPdf(String? base64Logo) async {
  if (base64Logo == null || base64Logo.isEmpty) return null;

  Uint8List bytes;
  try {
    bytes = base64Decode(base64Logo);
  } catch (_) {
    return null;
  }
  if (bytes.isEmpty) return null;

  ui.Image image;
  try {
    image = await _decode(bytes);
    // Only downscale. Passing targetWidth unconditionally would blow a small
    // mark UP to the cap — a 1px logo became a 256×256 image and 196KB of
    // pointless PDF.
    final longest = image.width > image.height ? image.width : image.height;
    if (longest > kMaxLogoEdge) {
      final scaled = await _decode(
        bytes,
        targetWidth: image.width >= image.height ? kMaxLogoEdge : null,
        targetHeight: image.height > image.width ? kMaxLogoEdge : null,
      );
      image.dispose();
      image = scaled;
    }
  } catch (_) {
    // SVG, or anything else the engine has no codec for.
    return null;
  }

  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;
    // Honour the view's own offset and length: `buffer.asUint8List()` alone
    // ignores both and can hand back the wrong window of the buffer.
    final rgba = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    return PdfImage(
      width: image.width,
      height: image.height,
      rgb: _flattenOntoWhite(rgba, image.width, image.height),
    );
  } catch (_) {
    return null;
  } finally {
    image.dispose();
  }
}

Future<ui.Image> _decode(
  Uint8List bytes, {
  int? targetWidth,
  int? targetHeight,
}) async {
  final codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: targetWidth,
    targetHeight: targetHeight,
  );
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// RGBA → RGB, compositing each pixel onto white.
///
/// PDF would need a separate soft-mask object to honour alpha; a logo sits on
/// a white report page, so blending here gives the same result for a fraction
/// of the machinery. A fully transparent pixel becomes white rather than
/// black, which is what the old "just drop the alpha byte" approach got wrong.
Uint8List _flattenOntoWhite(Uint8List rgba, int width, int height) {
  final out = Uint8List(width * height * 3);
  for (var i = 0, o = 0; o < out.length; i += 4, o += 3) {
    final a = rgba[i + 3];
    if (a == 255) {
      out[o] = rgba[i];
      out[o + 1] = rgba[i + 1];
      out[o + 2] = rgba[i + 2];
    } else {
      final inv = 255 - a;
      out[o] = (rgba[i] * a + 255 * inv) ~/ 255;
      out[o + 1] = (rgba[i + 1] * a + 255 * inv) ~/ 255;
      out[o + 2] = (rgba[i + 2] * a + 255 * inv) ~/ 255;
    }
  }
  return out;
}
