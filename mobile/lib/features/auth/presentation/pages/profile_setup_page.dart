import 'package:material_ui/material_ui.dart';

import '../../../../core/demo/demo_assets.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_sheets.dart';
import '../../../../core/widgets/saku_surfaces.dart';

/// Figma "4 · Setup profil" — langkah setelah registrasi.
class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  /// Batas bio singkat (penghitung tampil di bawah field).
  static const int bioMaxLength = 300;

  final _formKey = GlobalKey<FormState>();
  final List<String> _offered = ['Desain Grafis', 'UI Design', 'Spanduk Cetak'];
  final List<String> _wanted = ['Video Editing', 'Web Frontend'];
  bool _photo = true;
  String? _portfolioFile = 'Desain_Spanduk_Katering.jpg';

  Future<void> _addTag(List<String> target) async {
    final controller = TextEditingController();
    final value = await showSakuSheet<String>(
      context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          const Text('Tambah Tag Keahlian', style: AppTypography.subheading),
          SakuTextField(
            controller: controller,
            hint: 'mis. Fotografi Produk',
            textInputAction: TextInputAction.done,
          ),
          SakuButton(
            label: 'Tambahkan',
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty && !target.contains(value)) {
      SakuMotion.tick();
      setState(() => target.add(value));
    }
  }

  Widget _tags(List<String> tags, Color color, {bool addable = false}) {
    return Wrap(
      spacing: 14,
      runSpacing: 2,
      children: [
        for (final t in tags)
          RemovableTag(
            key: ValueKey(t),
            label: t,
            color: color,
            onRemove: () => setState(() => tags.remove(t)),
          ),
        if (addable)
          SakuTextLink(
            '+ Tambah Tag',
            color: color,
            onTap: () => _addTag(tags),
          ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    SakuMotion.tick();
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.shell, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SakuScreen(
        background: AppColors.canvasLight,
        children: [
          const Text('LANGKAH PROFIL', style: AppTypography.eyebrow),
          const Text(
            'Lengkapi Profil\n& Portofolio',
            style: AppTypography.pageTitle,
          ),
          const Text(
            'Akun Anda langsung siap untuk mencari jasa atau menawarkan keahlian',
            style: AppTypography.body,
          ),
          PressableScale(
            onTap: () => setState(() => _photo = !_photo),
            child: AnimatedSwitcher(
              duration: SakuMotion.base,
              child: PhotoAvatar(
                key: ValueKey(_photo),
                name: 'Salma Nur Oktavia',
                asset: _photo ? DemoAssets.salma : null,
                size: 84,
              ),
            ),
          ),
          SakuTextLink(
            '+ Unggah Foto',
            onTap: () => setState(() => _photo = true),
          ),
          const SakuTextField(
            fieldKey: Key('profile-bio'),
            label: 'Bio Singkat',
            initialValue:
                'Desainer grafis & ilustrator digital berdomisili di '
                'Cibiru. Siap bantu kebutuhan promosi UMKM & proyek kreatif.',
            minLines: 3,
            maxLines: 5,
            // TextField membatasi input; penghitung "n / 300" tampil.
            maxLength: bioMaxLength,
          ),
          const Text(
            'Keahlian yang Ditawarkan',
            style: TextStyle(
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          InfoBox(
            tone: SakuTone.success,
            child: _tags(_offered, AppColors.primaryPressed, addable: true),
          ),
          const Text(
            'Keahlian yang Diminati / Dicari',
            style: TextStyle(
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          InfoBox(
            tone: SakuTone.barter,
            child: _tags(_wanted, AppColors.barterText, addable: true),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              const Text('Unggah Karya Portofolio', style: AppTypography.label),
              SakuDropzone(
                title: 'Unggah Dokumen Portofolio',
                subtitle: 'PDF / PNG maks 5MB',
                fileName: _portfolioFile == null ? null : '↑ $_portfolioFile',
                onTap: () => setState(
                  () => _portfolioFile = _portfolioFile == null
                      ? 'Desain_Spanduk_Katering.jpg'
                      : null,
                ),
              ),
            ],
          ),
          SakuTextField(
            fieldKey: const Key('profile-link'),
            label: 'Tautan Portofolio',
            initialValue: 'https://www.behance.net/salmanuroktavia',
            keyboardType: TextInputType.url,
            // Opsional, tetapi bila diisi wajib https:// (FE-11).
            validator: SakuValidators.optional(SakuValidators.httpsUrl()),
          ),
          SakuButton(
            key: const Key('profile-save'),
            label: 'Simpan & Masuk ke Beranda',
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
