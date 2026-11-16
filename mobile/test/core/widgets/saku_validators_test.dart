import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuskill/core/widgets/saku_form.dart';

void main() {
  group('SakuValidators', () {
    test('required', () {
      final v = SakuValidators.required('Nama lengkap');
      expect(v(null), 'Nama lengkap wajib diisi');
      expect(v('   '), 'Nama lengkap wajib diisi');
      expect(v('Salma'), isNull);
      expect(SakuValidators.required()(''), 'Wajib diisi');
    });

    test('email', () {
      final v = SakuValidators.email();
      expect(v('salma@gmail.com'), isNull);
      expect(v('  salma@uinsgd.ac.id '), isNull);
      for (final bad in ['', 'salma', 'salma@', 'salma@gmail', 'a b@c.id']) {
        expect(v(bad), 'Format email belum benar', reason: bad);
      }
    });

    test('phoneId', () {
      final v = SakuValidators.phoneId();
      expect(v('081223456789'), isNull);
      expect(v('+62 812-2345-6789'), isNull);
      expect(v('0212345678'), isNotNull); // bukan nomor seluler
      expect(v('0812'), isNotNull);
    });

    test('minLength / maxLength (aturan sandi 8 karakter)', () {
      expect(SakuValidators.minLength()('1234567'), 'Minimal 8 karakter');
      expect(SakuValidators.minLength()('12345678'), isNull);
      expect(SakuValidators.maxLength(5)('123456'), 'Maksimal 5 karakter');
      expect(SakuValidators.maxLength(5)('12345'), isNull);
    });

    test('matches (konfirmasi sandi)', () {
      var password = 'rahasia123';
      final v = SakuValidators.matches(() => password);
      expect(v('rahasia123'), isNull);
      expect(v('rahasia12'), 'Kata sandi belum sama');
      password = 'baru';
      expect(v('rahasia123'), 'Kata sandi belum sama');
    });

    test('parseNumber membaca format Indonesia', () {
      expect(SakuValidators.parseNumber('50.000'), 50000);
      expect(SakuValidators.parseNumber('Rp 1.250.000'), 1250000);
      expect(SakuValidators.parseNumber('rp50000'), 50000);
      expect(SakuValidators.parseNumber('12,5'), 12.5);
      expect(SakuValidators.parseNumber('-3'), -3);
      expect(SakuValidators.parseNumber('lima puluh'), isNull);
      expect(SakuValidators.parseNumber(''), isNull);
    });

    test('nonNegativeNumber vs positiveNumber', () {
      final nonNeg = SakuValidators.nonNegativeNumber();
      final pos = SakuValidators.positiveNumber();
      expect(nonNeg('0'), isNull);
      expect(pos('0'), 'Harus lebih dari 0');
      expect(nonNeg('-1'), 'Tidak boleh kurang dari 0');
      expect(pos('Rp 50.000'), isNull);
      expect(nonNeg('abc'), 'Masukkan angka yang valid');
    });

    test('httpsUrl', () {
      final v = SakuValidators.httpsUrl();
      expect(v('https://drive.google.com/salma/final.pdf'), isNull);
      for (final bad in [
        'http://drive.google.com/x',
        'javascript:alert(1)',
        'https://',
        'https://localhost',
        'drive.google.com/x',
        'https://drive google.com',
      ]) {
        expect(v(bad), 'Tautan harus diawali https:// dan valid', reason: bad);
      }
    });

    test('futureDate dengan jam tetap', () {
      final v = SakuValidators.futureDate(now: () => DateTime(2026, 11, 16, 23, 59));
      expect(v(null), 'Pilih tanggal');
      expect(v(DateTime(2026, 11, 16, 23, 59, 59)), 'Tanggal harus setelah hari ini');
      expect(v(DateTime(2026, 11, 15)), 'Tanggal harus setelah hari ini');
      expect(v(DateTime(2026, 11, 17)), isNull);
    });

    test('optional & compose', () {
      final url = SakuValidators.optional(SakuValidators.httpsUrl());
      expect(url(''), isNull);
      expect(url('ftp://x.id'), isNotNull);

      final price = SakuValidators.compose([
        SakuValidators.required('Harga'),
        SakuValidators.positiveNumber(),
      ]);
      expect(price(''), 'Harga wajib diisi'); // error pertama yang menang
      expect(price('0'), 'Harus lebih dari 0');
      expect(price('25.000'), isNull);
    });
  });

  testWidgets('SakuTextField + validator ikut Form.validate()', (tester) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Form(
          key: formKey,
          child: SakuTextField(
            fieldKey: const Key('email'),
            controller: controller,
            label: 'Alamat Email',
            validator: SakuValidators.compose([
              SakuValidators.required('Email'),
              SakuValidators.email(),
            ]),
          ),
        ),
      ),
    ));

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Email wajib diisi'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('email')), 'salma');
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Format email belum benar'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('email')), 'salma@gmail.com');
    expect(formKey.currentState!.validate(), isTrue);
    await tester.pump();
    expect(find.textContaining('email'), findsNothing);
  });

  testWidgets('errorText dari server diprioritaskan di atas validator',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Form(
          child: SakuTextField(
            initialValue: 'salma@gmail.com',
            errorText: 'Email sudah terdaftar',
            validator: _alwaysValid,
          ),
        ),
      ),
    ));
    expect(find.text('Email sudah terdaftar'), findsOneWidget);
  });
}

String? _alwaysValid(String? _) => null;
