import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/brand_controller.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/settings/views/appearance/appearance_widgets.dart';
import 'package:shc_stock/app/modules/settings/views/appearance/color_palette_card.dart';
import 'package:shc_stock/app/modules/settings/views/appearance/theme_preview_panel.dart';
import 'package:shc_stock/app/shared/widgets/async_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Settings › Appearance — the white-label control panel.
//
// Editors on the left, a sticky live preview on the right. On a narrow window
// the preview moves above the editors rather than being dropped: seeing the
// palette is the point of the screen, so it is the one thing that must never
// be the part that gets cut.
// ─────────────────────────────────────────────────────────────────────────────
class AppearanceTab extends StatelessWidget {
  const AppearanceTab({super.key});

  static const _previewWidth = 300.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 900;
        final editors = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            BrandIdentityCard(),
            SizedBox(height: 16),
            ColorPaletteCard(),
            SizedBox(height: 16),
            TypographyShapeCard(),
          ],
        );

        final rail = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            ThemePreviewPanel(),
            SizedBox(height: 16),
            _AppearanceActions(),
          ],
        );

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [rail, const SizedBox(height: 16), editors],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: editors),
            const SizedBox(width: 16),
            SizedBox(width: _previewWidth, child: rail),
          ],
        );
      },
    );
  }
}

class _AppearanceActions extends StatelessWidget {
  const _AppearanceActions();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bc = Get.find<BrandController>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(c.radius + 2),
        border: Border.all(color: c.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppAsyncButton(
            label: 'Apply theme',
            expand: true,
            padding: const EdgeInsets.symmetric(vertical: 13),
            radius: c.radius,
            onPressed: () async {
              final saved = await bc.apply();
              // The theme is live on this device either way; only say it
              // reached everyone when the server actually took it.
              showAppToast(
                saved ? 'Theme applied' : 'Applied here only',
                saved
                    ? 'Every screen, dialog and exported report now uses this '
                          'palette — for everyone in the portal.'
                    : "Saved on this device, but the server didn't accept it. "
                          'Check the connection and apply again so your team '
                          'gets it too.',
                backgroundColor: saved ? c.success : c.warning,
                colorText: Colors.white,
                icon: saved
                    ? Icons.check_circle_outline
                    : Icons.cloud_off_rounded,
              );
            },
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: bc.discard,
            borderRadius: BorderRadius.circular(c.radius),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(c.radius),
                border: Border.all(color: c.border),
              ),
              child: Text(
                'Discard changes',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: bc.restoreDefaults,
            child: Text(
              'Restore Secure Heat Care default',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.primaryOrange),
            ),
          ),
        ],
      ),
    );
  }
}
