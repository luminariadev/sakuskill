import 'package:flutter/material.dart';

import '../motion/saku_motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';
import 'saku_icon.dart';

/// Validator form bersama (T-01). Semua fungsi murni: menerima nilai dan
/// mengembalikan pesan error berbahasa Indonesia, atau `null` bila valid.
///
/// ```dart
/// SakuTextField(
///   label: 'Harga',
///   validator: SakuValidators.compose([
///     SakuValidators.required('Harga'),
///     SakuValidators.positiveNumber(),
///   ]),
/// )
/// ```
abstract final class SakuValidators {
  /// Panjang minimal kata sandi akun (FR-02).
  static const int passwordMinLength = 8;

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _phoneId = RegExp(r'^(?:0|\+62)8\d{7,12}$');
  static final RegExp _rpPrefix = RegExp(r'^rp\.?\s*', caseSensitive: false);
  static final RegExp _idNumber = RegExp(r'^-?[\d.]+(,\d+)?$');

  /// Wajib diisi (spasi saja dianggap kosong).
  static FormFieldValidator<String> required([String? field]) => (value) =>
      (value == null || value.trim().isEmpty)
          ? (field == null ? 'Wajib diisi' : '$field wajib diisi')
          : null;

  /// Format email `nama@domain.tld`.
  static FormFieldValidator<String> email() => (value) =>
      _email.hasMatch((value ?? '').trim()) ? null : 'Format email belum benar';

  /// Nomor WhatsApp Indonesia: 08… atau +628… (spasi/strip diabaikan).
  static FormFieldValidator<String> phoneId() => (value) =>
      _phoneId.hasMatch((value ?? '').replaceAll(RegExp(r'[\s-]'), ''))
          ? null
          : 'Nomor WhatsApp diawali 08 atau +628';

  /// Panjang minimal [min] karakter (default: aturan kata sandi).
  static FormFieldValidator<String> minLength([int min = passwordMinLength]) =>
      (value) => (value ?? '').length >= min ? null : 'Minimal $min karakter';

  /// Panjang maksimal [max] karakter.
  static FormFieldValidator<String> maxLength(int max) =>
      (value) => (value ?? '').length <= max ? null : 'Maksimal $max karakter';

  /// Harus sama dengan nilai lain, mis. konfirmasi kata sandi.
  static FormFieldValidator<String> matches(
    String Function() other, {
    String message = 'Kata sandi belum sama',
  }) =>
      (value) => value == other() ? null : message;

  /// Angka ≥ 0. Menerima format Indonesia: `50.000`, `Rp 50.000`, `12,5`.
  static FormFieldValidator<String> nonNegativeNumber() => (value) {
        final n = parseNumber(value);
        if (n == null) return 'Masukkan angka yang valid';
        return n < 0 ? 'Tidak boleh kurang dari 0' : null;
      };

  /// Angka > 0, mis. harga pesanan berbayar (FE-30).
  static FormFieldValidator<String> positiveNumber() => (value) {
        final n = parseNumber(value);
        if (n == null) return 'Masukkan angka yang valid';
        return n <= 0 ? 'Harus lebih dari 0' : null;
      };

  /// URL `https://` dengan host (bukti kerja, portofolio). Validasi
  /// keamanan lanjutan tetap di URL Sanitizer (Anggota 6).
  static FormFieldValidator<String> httpsUrl() => (value) {
        final text = (value ?? '').trim();
        final uri = Uri.tryParse(text);
        final ok = uri != null &&
            !text.contains(' ') &&
            uri.scheme == 'https' &&
            uri.host.contains('.');
        return ok ? null : 'Tautan harus diawali https:// dan valid';
      };

  /// Tanggal harus setelah hari ini (tenggat, FE-30). [now] bisa diganti di
  /// tes agar hasilnya pasti.
  static FormFieldValidator<DateTime> futureDate({DateTime Function()? now}) =>
      (value) {
        if (value == null) return 'Pilih tanggal';
        final today = (now ?? DateTime.now)();
        final tomorrow = DateTime(today.year, today.month, today.day + 1);
        return value.isBefore(tomorrow) ? 'Tanggal harus setelah hari ini' : null;
      };

  /// Lewati validator bila kosong (untuk field opsional).
  static FormFieldValidator<String> optional(FormFieldValidator<String> v) =>
      (value) => (value == null || value.trim().isEmpty) ? null : v(value);

  /// Jalankan berurutan, kembalikan error pertama.
  static FormFieldValidator<T> compose<T>(List<FormFieldValidator<T>> list) =>
      (value) {
        for (final v in list) {
          final error = v(value);
          if (error != null) return error;
        }
        return null;
      };

  /// Membaca angka format Indonesia: `Rp 1.250.000`, `50.000`, `12,5`, `-3`.
  /// Titik = pemisah ribuan, koma = desimal. Null bila bukan angka.
  static num? parseNumber(String? value) {
    var text = (value ?? '').trim().replaceFirst(_rpPrefix, '');
    if (!_idNumber.hasMatch(text)) return null;
    text = text.replaceAll('.', '').replaceAll(',', '.');
    return num.tryParse(text);
  }
}

/// Field berlabel (Figma "SakuSkill / Input"): label 12/600, jarak 6, kotak
/// putih border 1 #E2E8F0 radius 8 padding 12, teks 13/18.
/// State: Default · Focus (border 1.5 emerald) · Error (border 1.5 merah).
/// Border beranimasi 200 ms saat fokus/eror berubah.
class SakuTextField extends StatefulWidget {
  const SakuTextField({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.icon,
    this.obscure = false,
    this.errorText,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.textInputAction,
    this.readOnly = false,
    this.onTap,
    this.fieldKey,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
  });

  final String? label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final SakuIcons? icon;
  final bool obscure;
  final String? errorText;
  final TextInputType? keyboardType;
  final int minLines;
  final int? maxLines;

  /// Bila diisi, tampil penghitung "142 / 500" di bawah teks.
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final bool readOnly;
  final VoidCallback? onTap;
  final Key? fieldKey;

  /// Validator (mis. dari [SakuValidators]). Bila diisi, field menjadi
  /// [FormField] sehingga ikut `Form.of(context).validate()`; pesan error
  /// tampil di bawah field. [errorText] (mis. error dari server) tetap
  /// diprioritaskan bila diisi.
  final FormFieldValidator<String>? validator;
  final AutovalidateMode autovalidateMode;

  @override
  State<SakuTextField> createState() => _SakuTextFieldState();
}

class _SakuTextFieldState extends State<SakuTextField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController(text: widget.initialValue);
  final FocusNode _focus = FocusNode();
  late bool _hidden = widget.obscure;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    _controller.addListener(() {
      if (widget.maxLength != null) setState(() {});
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final validator = widget.validator;
    if (validator == null) {
      return _buildField(widget.errorText, widget.onChanged);
    }
    return FormField<String>(
      initialValue: _controller.text,
      autovalidateMode: widget.autovalidateMode,
      // Validasi membaca isi controller, bukan nilai FormField yang bisa
      // tertinggal bila controller diubah dari luar.
      validator: (_) => validator(_controller.text),
      builder: (state) => _buildField(
        widget.errorText ?? state.errorText,
        (value) {
          state.didChange(value);
          widget.onChanged?.call(value);
        },
      ),
    );
  }

  Widget _buildField(String? errorText, ValueChanged<String>? onChanged) {
    final hasError = errorText != null;
    final borderColor = hasError
        ? AppColors.danger
        : _focus.hasFocus
            ? AppColors.primary
            : AppColors.borderLight;
    final borderWidth = hasError || _focus.hasFocus ? 1.5 : 1.0;
    final iconColor = hasError
        ? AppColors.danger
        : _focus.hasFocus
            ? AppColors.primary
            : AppColors.textSecondary;

    final field = AnimatedContainer(
      duration: SakuMotion.base,
      curve: SakuMotion.curve,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadius.inputBr,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      padding: EdgeInsets.fromLTRB(
        widget.icon != null ? 10 : 12,
        12 - (borderWidth - 1),
        widget.obscure ? 4 : 12,
        12 - (borderWidth - 1),
      ),
      child: Row(
        crossAxisAlignment: widget.maxLines == 1
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          if (widget.icon != null) ...[
            AnimatedSwitcher(
              duration: SakuMotion.base,
              child: SakuIcon(
                widget.icon!,
                key: ValueKey(iconColor),
                size: 22,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  key: widget.fieldKey,
                  controller: _controller,
                  focusNode: _focus,
                  obscureText: _hidden,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  minLines: widget.obscure ? 1 : widget.minLines,
                  maxLines: widget.obscure ? 1 : widget.maxLines,
                  maxLength: widget.maxLength,
                  readOnly: widget.readOnly,
                  onTap: widget.onTap,
                  onChanged: onChanged,
                  cursorColor: AppColors.primary,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 18 / 13,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: widget.hint,
                    counterText: '',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      height: 18 / 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (widget.maxLength != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_controller.text.length} / ${widget.maxLength}',
                    style: const TextStyle(
                      fontSize: 11,
                      height: 15 / 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.obscure)
            IconButton(
              tooltip: _hidden ? 'Tampilkan kata sandi' : 'Sembunyikan',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 24),
              onPressed: () => setState(() => _hidden = !_hidden),
              icon: AnimatedOpacity(
                duration: SakuMotion.fast,
                opacity: _hidden ? 0.6 : 1,
                child: const SakuIcon(
                  SakuIcons.eye,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTypography.label),
          const SizedBox(height: 6),
        ],
        field,
        AnimatedSize(
          duration: SakuMotion.base,
          curve: SakuMotion.curve,
          // errorText kosong ('') = hanya border merah, tanpa teks.
          child: hasError && errorText.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    errorText,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 15 / 11,
                      color: AppColors.danger,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Baris checkbox dengan teks (☑ Ingat Saya / ☑ Saya menyetujui ...).
class SakuCheckRow extends StatelessWidget {
  const SakuCheckRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.color = AppColors.textSecondary,
    this.fontSize = 11,
    this.bold = false,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final Color color;
  final double fontSize;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          SakuMotion.tick();
          onChanged(!value);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: SakuMotion.fast,
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(top: 1, right: 6),
              decoration: BoxDecoration(
                color: value ? AppColors.primary : AppColors.cardSurface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: value ? AppColors.primary : AppColors.dashedBorder,
                  width: 1.5,
                ),
              ),
              child: AnimatedScale(
                duration: SakuMotion.fast,
                scale: value ? 1 : 0,
                child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
              ),
            ),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  height: 15 / 11,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Area unggah putus-putus (Figma "Portfolio dropzone").
class SakuDropzone extends StatelessWidget {
  const SakuDropzone({
    super.key,
    required this.title,
    this.subtitle,
    this.onTap,
    this.fileName,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  /// Bila sudah ada berkas terpilih, tampilkan namanya dengan ikon centang.
  final String? fileName;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.985,
      onTap: onTap,
      child: CustomPaint(
        painter: const _DashedRRectPainter(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.canvasLight,
            borderRadius: AppRadius.cardBr,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: SakuMotion.base,
                child: SakuIcon(
                  fileName == null ? SakuIcons.upload : SakuIcons.check,
                  key: ValueKey(fileName == null),
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                fileName ?? title,
                style: const TextStyle(
                  fontSize: 12,
                  height: 17 / 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 17 / 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppRadius.card),
    ).deflate(0.5);
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = AppColors.dashedBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Tag/chip dengan tombol hapus (×) — dipakai di daftar keahlian profil.
class RemovableTag extends StatelessWidget {
  const RemovableTag({
    super.key,
    required this.label,
    required this.color,
    this.onRemove,
  });

  final String label;
  final Color color;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: onRemove != null,
      hint: onRemove != null ? 'Ketuk untuk menghapus' : null,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onRemove,
        child: Text(
          onRemove != null ? '$label ×' : label,
          style: TextStyle(fontSize: 12, height: 17 / 12, color: color),
        ),
      ),
    );
  }
}
