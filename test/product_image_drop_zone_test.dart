import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/products/widgets/product_image_drop_zone.dart';

/// A real, valid 1×1 transparent PNG — small enough to inline, but a genuine
/// image `Image.memory` can decode.
final _validPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
  '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

const _promptText = 'Drag & drop\nor click to browse';

Widget _host(Widget child) => MaterialApp(
  theme: ThemeData(extensions: const [AppThemeColors.light]),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('ProductImageDropZone', () {
    testWidgets('empty state shows the drag/browse prompt, no badges', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ProductImageDropZone(
            pickedBytes: null,
            existingImageUrl: null,
            removed: false,
            onFile: (_, __) {},
            onRemove: () {},
            onRejected: (_) {},
            colors: AppThemeColors.light,
          ),
        ),
      );

      expect(find.text(_promptText), findsOneWidget);
      expect(find.text('JPG, PNG or WEBP · Max 2MB'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(find.byIcon(Icons.edit_rounded), findsNothing);
    });

    testWidgets('an existing photo shows the remove/edit badges, and remove '
        'fires onRemove', (tester) async {
      var removed = false;
      await tester.pumpWidget(
        _host(
          ProductImageDropZone(
            pickedBytes: null,
            existingImageUrl: '/uploads/old-photo.png',
            removed: false,
            onFile: (_, __) {},
            onRemove: () => removed = true,
            onRejected: (_) {},
            colors: AppThemeColors.light,
          ),
        ),
      );
      // The network image itself won't resolve in a test — errorBuilder
      // takes over, which is fine; the badges don't depend on it loading.
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(_promptText), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.edit_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(removed, isTrue);
    });

    testWidgets('a removed existing photo reverts to the empty prompt', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ProductImageDropZone(
            pickedBytes: null,
            existingImageUrl: '/uploads/old-photo.png',
            removed: true,
            onFile: (_, __) {},
            onRemove: () {},
            onRejected: (_) {},
            colors: AppThemeColors.light,
          ),
        ),
      );

      expect(find.text(_promptText), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('a freshly picked image previews from bytes', (tester) async {
      await tester.pumpWidget(
        _host(
          ProductImageDropZone(
            pickedBytes: _validPng,
            existingImageUrl: null,
            removed: false,
            onFile: (_, __) {},
            onRemove: () {},
            onRejected: (_) {},
            colors: AppThemeColors.light,
          ),
        ),
      );
      await tester.pump();

      expect(find.text(_promptText), findsNothing);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
    });
  });
}
