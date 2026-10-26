import 'package:flutter/material.dart';
import '../../../../core/constants/campus_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/datasources/nine_router_ai_service.dart';
import '../../domain/usecases/calculate_ai_price.dart';

class AIEstimatorSheet extends StatefulWidget {
  final ValueChanged<int>? onApplyPrice;
  final String? initialTitle;
  final ServiceCategory? initialCategory;

  const AIEstimatorSheet({
    super.key,
    this.onApplyPrice,
    this.initialTitle,
    this.initialCategory,
  });

  @override
  State<AIEstimatorSheet> createState() => _AIEstimatorSheetState();
}

class _AIEstimatorSheetState extends State<AIEstimatorSheet> {
  late ServiceCategory _category;
  ServiceComplexity _complexity = ServiceComplexity.medium;
  int _deliveryHours = 4;
  final OutputFormat _outputFormat = OutputFormat.onSitePresence;
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  late AIPriceEstimateResult _estimate;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ?? ServiceCategory.itSupport;
    if (widget.initialTitle != null) {
      _descriptionController.text = widget.initialTitle!;
    }

    // Initial local baseline
    _estimate = CalculateAIPriceUseCase.execute(
      category: _category,
      complexity: _complexity,
      deliveryHours: _deliveryHours,
      outputFormat: _outputFormat,
    );

    // Automatically trigger live 9router analysis
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetch9RouterEstimate();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetch9RouterEstimate() async {
    setState(() => _isLoading = true);

    final result = await NineRouterAIService.estimatePrice(
      category: _category,
      complexity: _complexity,
      deliveryHours: _deliveryHours,
      outputFormat: _outputFormat,
      customDescription: _descriptionController.text,
    );

    if (mounted) {
      setState(() {
        _estimate = result;
        _isLoading = false;
      });
    }
  }

  void _showServerConfigDialog() {
    final urlCtrl = TextEditingController(text: NineRouterAIService.baseUrl);
    final keyCtrl = TextEditingController(text: NineRouterAIService.apiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.dns, color: AppTheme.primary, size: 20),
            SizedBox(width: 8),
            Text('Konfigurasi AI Provider', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sesuaikan endpoint LLM dan API key (Groq Cloud untuk akses 24/7 di semua HP atau 9router lokal):',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Endpoint URL',
                  hintText: 'https://api.groq.com/openai/v1/chat/completions',
                ),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: keyCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API Key (Groq / 9router)',
                  hintText: 'gsk_... atau sk-...',
                ),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('Groq Cloud (Default)', style: TextStyle(fontSize: 10)),
                    onPressed: () {
                      urlCtrl.text = 'https://api.groq.com/openai/v1/chat/completions';
                    },
                  ),
                  ActionChip(
                    label: const Text('Localhost 9router', style: TextStyle(fontSize: 10)),
                    onPressed: () {
                      urlCtrl.text = 'http://127.0.0.1:20128/v1/chat/completions';
                    },
                  ),
                  ActionChip(
                    label: const Text('Android Emulator', style: TextStyle(fontSize: 10)),
                    onPressed: () {
                      urlCtrl.text = 'http://10.0.2.2:20128/v1/chat/completions';
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              NineRouterAIService.customBaseUrl = urlCtrl.text.trim();
              NineRouterAIService.customApiKey = keyCtrl.text.trim();
              Navigator.pop(ctx);
              _fetch9RouterEstimate();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Konfigurasi AI diperbarui (${urlCtrl.text.trim()})'),
                  backgroundColor: AppTheme.primary,
                ),
              );
            },
            child: const Text('Simpan & Uji'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI Price Estimator Mahasiswa',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Didukung Groq Cloud LLM (${NineRouterAIService.modelName})',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings_ethernet, size: 20, color: AppTheme.textSecondary),
                      tooltip: 'Konfigurasi Endpoint Server AI',
                      onPressed: _showServerConfigDialog,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // AI Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _estimate.isRealTimeAI ? AppTheme.primarySurface : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _estimate.isRealTimeAI ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _estimate.isRealTimeAI ? Icons.cloud_done : Icons.dns_outlined,
                    size: 16,
                    color: _estimate.isRealTimeAI ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sumber: ${_estimate.aiModelUsed}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _estimate.isRealTimeAI ? AppTheme.primary : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                    )
                  else
                    InkWell(
                      onTap: _fetch9RouterEstimate,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          children: const [
                            Icon(Icons.refresh, size: 13, color: AppTheme.primary),
                            SizedBox(width: 4),
                            Text('Analisis Ulang', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Ethics warning
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _estimate.academicSafetyNotice,
                      style: TextStyle(fontSize: 10, color: Colors.amber.shade900, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Category selector
            const Text('1. Kategori Jasa Mikro Kampus', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ServiceCategory.values.map((cat) {
                final isSelected = _category == cat;
                return ChoiceChip(
                  label: Text(CategoryMeta.info[cat]!.label),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _category = cat);
                    _fetch9RouterEstimate();
                  },
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.background,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Complexity
            const Text('2. Tingkat Kompleksitas Pengerjaan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Row(
              children: ServiceComplexity.values.map((comp) {
                final isSelected = _complexity == comp;
                final label = comp == ServiceComplexity.simple ? 'Sederhana' : comp == ServiceComplexity.medium ? 'Sedang' : 'Kompleks';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _complexity = comp);
                        _fetch9RouterEstimate();
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected ? AppTheme.primary : Colors.white,
                        foregroundColor: isSelected ? Colors.white : AppTheme.textPrimary,
                        side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.border),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Delivery Hours Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('3. Estimasi Durasi Pengerjaan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                Text('$_deliveryHours Jam', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              ],
            ),
            Slider(
              value: _deliveryHours.toDouble(),
              min: 1,
              max: 48,
              divisions: 47,
              activeColor: AppTheme.primary,
              onChanged: (val) {
                setState(() => _deliveryHours = val.toInt());
              },
              onChangeEnd: (_) => _fetch9RouterEstimate(),
            ),
            const SizedBox(height: 10),

            // Result Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.textPrimary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'REKOMENDASI TARIF AI (UIN SGD)',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 0.6),
                      ),
                      if (_estimate.isRealTimeAI)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'LIVE AI CLOUD',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        FormatterUtils.formatIDR(_estimate.recommendedPrice),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${FormatterUtils.formatIDR(_estimate.minPrice)} - ${FormatterUtils.formatIDR(_estimate.maxPrice)})',
                        style: const TextStyle(fontSize: 11, color: Colors.white60),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 8),
                  ..._estimate.calculationBreakdown.map((line) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.check_circle_outline, size: 12, color: Color(0xFF10B981)),
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: Text(line, style: const TextStyle(fontSize: 10.5, color: Colors.white70, height: 1.25))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (widget.onApplyPrice != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onApplyPrice!(_estimate.recommendedPrice);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: Text('Terapkan Tarif AI (${FormatterUtils.formatIDR(_estimate.recommendedPrice)})'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
