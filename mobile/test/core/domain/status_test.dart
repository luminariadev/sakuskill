import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuskill/core/domain/status.dart';
import 'package:sakuskill/core/widgets/saku_pill.dart';
import 'package:sakuskill/core/widgets/status_tones.dart';

/// Membaca nilai `CREATE TYPE <name> AS ENUM (...)` dari migrasi backend.
Map<String, List<String>> _dbEnums() {
  final sql = File('../backend/migrations/001_init_sakuskill_schema.sql')
      .readAsStringSync();
  // Isi sampai `);` (bukan `)` pertama) karena nilai seperti
  // 'Ditahan (Simulasi)' mengandung tanda kurung.
  final re = RegExp(r"CREATE TYPE (\w+) AS ENUM \(([\s\S]*?)\);");
  return {
    for (final m in re.allMatches(sql))
      m.group(1)!: RegExp(r"'([^']*)'")
          .allMatches(m.group(2)!)
          .map((v) => v.group(1)!)
          .toList(),
  };
}

void main() {
  final db = _dbEnums();

  // enum FE → nama enum di migrasi DB.
  final cases = <String, List<ApiEnum>>{
    'order_status_enum': OrderStatus.values,
    'barter_status_enum': BarterStatus.values,
    'barter_exec_status_enum': BarterExecStatus.values,
    'payment_status_enum': PaymentStatus.values,
    'escrow_sim_status_enum': EscrowSimStatus.values,
    'report_status_enum': ReportStatus.values,
    'verification_status_enum': VerificationStatus.values,
    'offer_type_enum': OfferType.values,
  };

  final parsers = <String, ApiEnum Function(Object?)>{
    'order_status_enum': OrderStatus.fromJson,
    'barter_status_enum': BarterStatus.fromJson,
    'barter_exec_status_enum': BarterExecStatus.fromJson,
    'payment_status_enum': PaymentStatus.fromJson,
    'escrow_sim_status_enum': EscrowSimStatus.fromJson,
    'report_status_enum': ReportStatus.fromJson,
    'verification_status_enum': VerificationStatus.fromJson,
    'offer_type_enum': OfferType.fromJson,
  };

  group('Enum status baku sama persis dengan enum DB', () {
    for (final entry in cases.entries) {
      test(entry.key, () {
        expect(db[entry.key], isNotNull, reason: 'enum DB tidak ditemukan');
        expect(
          entry.value.map((e) => e.apiValue).toList(),
          db[entry.key],
          reason: 'urutan & ejaan harus sama dengan migrasi',
        );
      });
    }
  });

  group('Round-trip toJson → fromJson', () {
    for (final entry in cases.entries) {
      test(entry.key, () {
        for (final value in entry.value) {
          expect(parsers[entry.key]!(value.toJson()), same(value));
          expect(value.label, value.apiValue, reason: 'label = nilai baku (NFR-22)');
        }
      });
    }
  });

  group('Nilai asing', () {
    test('fromJson melempar FormatException', () {
      expect(() => OrderStatus.fromJson('Sedang dikerjakan'),
          throwsA(isA<FormatException>()));
      expect(() => PaymentStatus.fromJson(null), throwsA(isA<FormatException>()));
      expect(() => EscrowSimStatus.fromJson('Ditahan'),
          throwsA(isA<FormatException>()));
    });

    test('tryParse mengembalikan null', () {
      expect(OrderStatus.tryParse('dibayar'), isNull); // peka huruf besar
      expect(BarterStatus.tryParse(42), isNull);
      expect(ReportStatus.tryParse('Selesai'), ReportStatus.resolved);
    });

    test('OfferType.fromApi tetap longgar untuk data listing lama', () {
      expect(OfferType.fromApi('Barter'), OfferType.barter);
      expect(OfferType.fromApi('Tukar'), OfferType.paid);
      expect(OfferType.fromApi(null), OfferType.paid);
    });
  });

  group('Warna StatusPill', () {
    test('contoh pemetaan bahasa warna', () {
      expect(OrderStatus.completed.tone, SakuPillTone.primary);
      expect(OrderStatus.disputed.tone, SakuPillTone.dispute);
      expect(OrderStatus.awaitingConfirmation.tone, SakuPillTone.integrity);
      expect(BarterStatus.executing.tone, SakuPillTone.barter);
      expect(PaymentStatus.failed.tone, SakuPillTone.dispute);
      expect(EscrowSimStatus.held.tone, SakuPillTone.escrow);
      expect(VerificationStatus.verified.tone, SakuPillTone.primary);
    });

    test('statusTone tersedia untuk setiap nilai', () {
      for (final values in cases.values) {
        for (final v in values) {
          expect(() => statusTone(v), returnsNormally);
        }
      }
    });

    testWidgets('StatusPill menampilkan label baku', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: StatusPill(OrderStatus.awaitingConfirmation)),
      ));
      expect(find.text('Menunggu Konfirmasi'), findsOneWidget);
      expect(find.bySemanticsLabel('Status: Menunggu Konfirmasi'), findsOneWidget);
    });
  });
}
