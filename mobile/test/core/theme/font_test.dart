import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sakuskill/core/theme/app_theme.dart';
import 'package:sakuskill/core/theme/app_typography.dart';

void main() {
  test('tema memakai Plus Jakarta Sans (T-04)', () {
    final theme = AppTheme.light;
    expect(AppTypography.fontFamily, 'PlusJakartaSans');
    expect(theme.textTheme.bodyMedium?.fontFamily, 'PlusJakartaSans');
    expect(theme.textTheme.displaySmall?.fontFamily, 'PlusJakartaSans');
  });

  test('semua bobot yang didaftarkan ada sebagai berkas TTF + lisensi OFL', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final assets = RegExp(r'asset: (assets/fonts/\S+\.ttf)')
        .allMatches(pubspec)
        .map((m) => m.group(1)!)
        .toList();
    expect(assets, hasLength(5));
    for (final path in assets) {
      final bytes = File(path).readAsBytesSync();
      // Signature TrueType 0x00010000.
      expect(bytes.sublist(0, 4), [0, 1, 0, 0], reason: path);
    }
    expect(File('assets/fonts/plus_jakarta_sans/OFL.txt').existsSync(), isTrue);
  });

  testWidgets('Text tanpa fontFamily mewarisi font tema', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: Text('Halo', style: TextStyle(fontSize: 13))),
    ));
    final style = DefaultTextStyle.of(tester.element(find.text('Halo'))).style;
    expect(style.fontFamily, 'PlusJakartaSans');
  });
}
