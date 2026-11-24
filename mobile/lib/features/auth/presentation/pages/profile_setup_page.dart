import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_sheets.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../data/auth_session.dart';

/// Figma "4 · Setup profil" — langkah setelah registrasi & edit profil.
/// Diisi bersih sesuai akun aktif, termasuk unggah foto profil dari galeri.
class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key, this.pickPhoto});

  /// Opsional override pemilih foto (berguna untuk pengujian widget).
  final Future<Uint8List?> Function()? pickPhoto;

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  static const int bioMaxLength = 300;
  static const int _maxPhotoBytes = 350 * 1024;
  static const List<String> _suggestedSkills = [
    'Desain Grafis',
    'Edit Video',
    'Fotografi',
    'Install Laptop',
    'Pemrograman',
  ];

  final _formKey = GlobalKey<FormState>();
  final _bio = TextEditingController();
  final _linkCtrl = TextEditingController();
  final List<String> _offered = [];
  final List<String> _wanted = [];
  bool _loadedRemote = false;
  Uint8List? _photoBytes;
  String? _photoDataUri;
  bool _photoDirty = false;
  bool _pickingPhoto = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _photoDataUri = AuthSession.instance.photoUrl;
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    if (_loadedRemote || AppConfig.useMockData) return;
    _loadedRemote = true;
    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) return;

    try {
      final res = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/users/me'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(AppConfig.networkTimeout);
      if (!mounted || res.statusCode < 200 || res.statusCode >= 300) return;

      final json = jsonDecode(utf8.decode(res.bodyBytes));
      final data = json is Map<String, dynamic> ? json['data'] : null;
      if (data is Map<String, dynamic>) {
        final remoteBio = (data['deskripsi_profil'] ?? '').toString().trim();
        final remotePhoto =
            (data['foto_profil'] ?? data['foto_url'] ?? '').toString().trim();
        if (!mounted) return;
        setState(() {
          if (remoteBio.isNotEmpty && _bio.text.isEmpty) {
            _bio.text = remoteBio;
          }
          if (!_photoDirty && remotePhoto.isNotEmpty) {
            _photoDataUri = remotePhoto;
          }
        });
        if (!_photoDirty && remotePhoto.isNotEmpty) {
          AuthSession.instance.updatePhotoUrl(remotePhoto);
        }
      }
    } catch (_) {
      // Abaikan jika gagal memuat profil sementara
    }
  }

  String _detectMime(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  Future<void> _selectFromGallery() async {
    if (_pickingPhoto || _saving) return;
    setState(() => _pickingPhoto = true);
    try {
      Uint8List? bytes;
      if (widget.pickPhoto != null) {
        bytes = await widget.pickPhoto!();
      } else {
        final picker = ImagePicker();
        final file = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 320,
          maxHeight: 320,
          imageQuality: 70,
        );
        if (file != null) {
          bytes = await file.readAsBytes();
        }
      }
      if (!mounted || bytes == null || bytes.isEmpty) return;
      if (bytes.length > _maxPhotoBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ukuran foto terlalu besar. Pilih foto berukuran lebih kecil.',
            ),
          ),
        );
        return;
      }
      final mime = _detectMime(bytes);
      final encoded = 'data:$mime;base64,${base64Encode(bytes)}';
      SakuMotion.tick();
      setState(() {
        _photoBytes = bytes;
        _photoDataUri = encoded;
        _photoDirty = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak dapat membuka galeri. Pastikan izin akses foto diberikan.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  void _removePhoto() {
    SakuMotion.tick();
    setState(() {
      _photoBytes = null;
      _photoDataUri = null;
      _photoDirty = true;
    });
  }

  @override
  void dispose() {
    _bio.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

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

  Widget _tags(List<String> tags, Color color) {
    final quickPicks = _suggestedSkills
        .where((skill) => !tags.contains(skill))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            for (final t in tags)
              RemovableTag(
                key: ValueKey(t),
                label: t,
                color: color,
                onRemove: () => setState(() => tags.remove(t)),
              ),
            SakuTextLink(
              '+ Tambah Tag',
              color: color,
              onTap: () => _addTag(tags),
            ),
          ],
        ),
        if (quickPicks.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final suggestion in quickPicks)
                ActionChip(
                  label: Text(
                    '+ $suggestion',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.7),
                  side: BorderSide(color: color.withValues(alpha: 0.25)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: () {
                    SakuMotion.tick();
                    setState(() => tags.add(suggestion));
                  },
                ),
            ],
          ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    SakuMotion.tick();

    final bioText = _bio.text.trim();
    final token = AuthSession.instance.accessToken;
    setState(() => _saving = true);
    try {
      if (_photoDirty || _photoDataUri != null) {
        AuthSession.instance.updatePhotoUrl(_photoDataUri);
      }

      if (token != null && !AppConfig.useMockData) {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}/users/me');
        final res = await http
            .put(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'deskripsi_profil': bioText,
                if (_photoDirty || (_photoDataUri != null && _photoDataUri!.isNotEmpty))
                  'foto_profil': _photoDataUri ?? '',
              }),
            )
            .timeout(AppConfig.networkTimeout);

        if (res.statusCode >= 400) {
          String message = 'Gagal menyimpan profil ke server.';
          try {
            final decoded = jsonDecode(utf8.decode(res.bodyBytes));
            if (decoded is Map<String, dynamic> && decoded['message'] is String) {
              message = decoded['message'] as String;
            }
          } catch (_) {}
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
            );
          }
          return;
        }
      }

      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.shell, (_) => false);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.shell, (_) => false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawName = (AuthSession.instance.userName ?? '').trim();
    final displayName = rawName.isEmpty ? 'Mahasiswa SakuSkill' : rawName;
    final hasPhoto = _photoBytes != null ||
        (_photoDataUri != null && _photoDataUri!.trim().isNotEmpty);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SakuScreen(
        background: AppColors.canvasLight,
        showBack: Navigator.of(context).canPop(),
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
          SakuCard(
            radius: 18,
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _selectFromGallery,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.canvasLight,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.flat,
                        ),
                        child: InitialsAvatar(
                          name: displayName,
                          size: 72,
                          imageBytes: _photoBytes,
                          photoUrl: _photoDataUri,
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.photo_camera_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      const Text(
                        'Gunakan foto profil dari galeri agar mitra mudah mengenali Anda.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 17 / 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          OutlinedButton.icon(
                            key: const Key('profile-pick-photo'),
                            onPressed: _pickingPhoto ? null : _selectFromGallery,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.4),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.pillBr,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            icon: const Icon(Icons.photo_library_rounded, size: 16),
                            label: Text(
                              _pickingPhoto
                                  ? 'Membuka Galeri...'
                                  : (hasPhoto ? 'Ganti Foto' : 'Pilih Foto dari Galeri'),
                            ),
                          ),
                          if (hasPhoto)
                            TextButton(
                              key: const Key('profile-remove-photo'),
                              onPressed: _removePhoto,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Hapus Foto'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SakuTextField(
            fieldKey: const Key('profile-bio'),
            controller: _bio,
            label: 'Bio Singkat',
            hint:
                'Ceritakan keahlian, pengalaman, atau layanan yang Anda kuasai...',
            minLines: 3,
            maxLines: 5,
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
            child: _tags(_offered, AppColors.primaryPressed),
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
            child: _tags(_wanted, AppColors.barterText),
          ),
          SakuTextField(
            fieldKey: const Key('profile-link'),
            controller: _linkCtrl,
            label: 'Tautan Portofolio (Opsional)',
            hint: 'https://behance.net/nama-anda',
            keyboardType: TextInputType.url,
            validator: SakuValidators.optional(SakuValidators.httpsUrl()),
          ),
          SakuButton(
            key: const Key('profile-save'),
            label: _saving ? 'Menyimpan...' : 'Simpan & Masuk ke Beranda',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
