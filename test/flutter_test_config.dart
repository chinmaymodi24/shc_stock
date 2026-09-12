import 'dart:async';

import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Runs once before every test in this directory (Flutter picks this file up by
// name).
//
// The brand's font is resolved through google_fonts, which loads and caches
// the family on first use. That load reaches for path_provider and the
// network, neither of which exists under `flutter test` — and because it
// fails asynchronously, the exception surfaced on whichever test happened to
// be running, failing a different one on each run.
//
// Tests keep the plain family name instead. Production is untouched: the real
// app still resolves (and fetches) the buyer's font on demand.
// ─────────────────────────────────────────────────────────────────────────────
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  kResolveBrandFonts = false;
  // No test may touch a real backend. Controllers already fetch on onInit and
  // simply swallow the failure, but once Appearance started PUT-ing the brand
  // a test run was writing its fixtures into the live database.
  ApiClient.networkEnabled = false;
  await testMain();
}
