import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

/// A primary action button that owns its own in-flight state: while the
/// [onPressed] future is running it swaps its label for a spinner and stops
/// accepting taps.
///
/// Every button that hits the API should be one of these — API calls carry a
/// deliberate ~1s delay, so a plain button just looks dead for a second and
/// invites a second tap (which would post the record twice).
///
/// The busy flag is an `.obs` read through [Obx] — no setState, per the
/// project's state rule.
class AppAsyncButton extends StatefulWidget {
  final String label;

  /// Runs on tap; the button stays busy until this completes.
  final Future<void> Function() onPressed;

  final IconData? icon;
  final Color background;
  final Color foreground;

  /// Fills the available width — used inside dialogs and mobile forms.
  final bool expand;

  final EdgeInsets padding;
  final double fontSize;
  final double radius;

  const AppAsyncButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.background = AppColors.primaryOrange,
    this.foreground = Colors.white,
    this.expand = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
    this.fontSize = 14,
    this.radius = 9,
  });

  @override
  State<AppAsyncButton> createState() => _AppAsyncButtonState();
}

class _AppAsyncButtonState extends State<AppAsyncButton> {
  final _busy = false.obs;

  @override
  void dispose() {
    _busy.close();
    super.dispose();
  }

  Future<void> _run() async {
    if (_busy.value) return;
    _busy.value = true;
    try {
      await widget.onPressed();
    } catch (error, stack) {
      // Controllers surface their own API failures as toasts, so there is
      // nothing to show here — but the button must never be left spinning,
      // and the error still has to be reported rather than swallowed.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'shc_stock',
          context: ErrorDescription('running the "${widget.label}" action'),
        ),
      );
    } finally {
      // The action often closes the page or dialog this button lives on, so
      // the state can be gone by the time the future completes.
      if (mounted) _busy.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = _busy.value;
      final button = ElevatedButton(
        onPressed: busy ? null : _run,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.background,
          disabledBackgroundColor: widget.background.withValues(alpha: 0.75),
          elevation: 0,
          padding: widget.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
        child: busy
            ? SizedBox(
                height: widget.fontSize + 4,
                width: widget.fontSize + 4,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.foreground,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 16, color: widget.foreground),
                    const SizedBox(width: 8),
                  ],
                  // Flexible: a long label in a narrow (expanded) button —
                  // "Save Purchase" on a phone — would otherwise overflow
                  // the row rather than shrink.
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        fontWeight: FontWeight.w600,
                        color: widget.foreground,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
      );
      return widget.expand
          ? SizedBox(width: double.infinity, child: button)
          : button;
    });
  }
}
