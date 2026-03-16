// ============================================================
// محرر الصور الاحترافي
// المطور: داوود الأحمدي
// البريد: almubarmaj8@gmail.com
// جميع الحقوق محفوظة © 2025
// ============================================================

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() {
  runApp(const PhotoEditorApp());
}

// ── نموذج بيانات النص المضاف على الصورة ──
class TextOverlay {
  String text;
  Offset position;
  Color color;
  double fontSize;
  TextOverlay({
    required this.text,
    required this.position,
    required this.color,
    required this.fontSize,
  });
}

// ── تعريف الفلاتر ──
enum FilterType {
  original,
  blackAndWhite,
  sepia,
  warm,
  cool,
  highContrast,
  fade,
}

const Map<FilterType, String> filterNames = {
  FilterType.original: 'أصلي',
  FilterType.blackAndWhite: 'أبيض وأسود',
  FilterType.sepia: 'سيبيا',
  FilterType.warm: 'دافئ',
  FilterType.cool: 'بارد',
  FilterType.highContrast: 'تباين عالٍ',
  FilterType.fade: 'باهت',
};

const Map<FilterType, List<double>> filterMatrices = {
  FilterType.original: [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ],
  FilterType.blackAndWhite: [
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ],
  FilterType.sepia: [
    0.393, 0.769, 0.189, 0, 0,
    0.349, 0.686, 0.168, 0, 0,
    0.272, 0.534, 0.131, 0, 0,
    0,     0,     0,     1, 0,
  ],
  FilterType.warm: [
    1.2, 0,   0,    0, 0,
    0,   1.0, 0,    0, 0,
    0,   0,   0.8,  0, 0,
    0,   0,   0,    1, 0,
  ],
  FilterType.cool: [
    0.8, 0,   0,   0, 0,
    0,   0.9, 0,   0, 0,
    0,   0,   1.3, 0, 0,
    0,   0,   0,   1, 0,
  ],
  FilterType.highContrast: [
    1.5, 0,   0,   0, -40,
    0,   1.5, 0,   0, -40,
    0,   0,   1.5, 0, -40,
    0,   0,   0,   1,   0,
  ],
  FilterType.fade: [
    0.9, 0,   0,   0, 20,
    0,   0.9, 0,   0, 20,
    0,   0,   0.9, 0, 20,
    0,   0,   0,   1,  0,
  ],
};

// ── ألوان التطبيق ──
const Color kBackground   = Color(0xFF0D0D0D);
const Color kSurface      = Color(0xFF1A1A1A);
const Color kCard         = Color(0xFF242424);
const Color kAccent       = Color(0xFFFF6B35);
const Color kAccent2      = Color(0xFFFF9B71);

// ════════════════════════════════════════════════════════════
//  التطبيق الرئيسي
// ════════════════════════════════════════════════════════════
class PhotoEditorApp extends StatelessWidget {
  const PhotoEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'محرر الصور الاحترافي',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBackground,
        colorScheme: const ColorScheme.dark(
          primary: kAccent,
          secondary: kAccent2,
          surface: kSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kSurface,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'sans-serif',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: kAccent,
          thumbColor: kAccent,
          inactiveTrackColor: Colors.white12,
          overlayColor: kAccent.withOpacity(0.2),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const PhotoEditorHome(),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  الشاشة الرئيسية
// ════════════════════════════════════════════════════════════
class PhotoEditorHome extends StatefulWidget {
  const PhotoEditorHome({super.key});

  @override
  State<PhotoEditorHome> createState() => _PhotoEditorHomeState();
}

class _PhotoEditorHomeState extends State<PhotoEditorHome>
    with SingleTickerProviderStateMixin {
  // ── الحالة ──
  Uint8List? _imageBytes;
  FilterType _selectedFilter = FilterType.original;
  double _brightness = 0.0;
  double _contrast  = 1.0;
  final List<TextOverlay> _textOverlays = [];
  int? _draggingIndex;

  final ImagePicker      _picker            = ImagePicker();
  final ScreenshotController _screenshotCtrl = ScreenshotController();

  // ── ToolTab ──
  int _activeToolTab = 0; // 0=فلاتر  1=ضبط  2=نص

  // ─────────────────────────────────────
  //  اختيار الصورة
  // ─────────────────────────────────────
  Future<void> _pickImage() async {
    final XFile? file =
        await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _selectedFilter = FilterType.original;
        _brightness = 0.0;
        _contrast   = 1.0;
        _textOverlays.clear();
      });
    }
  }

  // ─────────────────────────────────────
  //  بناء مصفوفة اللون المركّبة
  // ─────────────────────────────────────
  ColorFilter _buildColorFilter() {
    final base = filterMatrices[_selectedFilter]!;
    // تطبيق السطوع والتباين فوق فلتر الألوان
    final double b = _brightness * 255;
    final double c = _contrast;
    return ColorFilter.matrix([
      base[0]*c,  base[1]*c,  base[2]*c,  base[3],  base[4]  + b,
      base[5]*c,  base[6]*c,  base[7]*c,  base[8],  base[9]  + b,
      base[10]*c, base[11]*c, base[12]*c, base[13], base[14] + b,
      base[15],   base[16],   base[17],   base[18], base[19],
    ]);
  }

  // ─────────────────────────────────────
  //  حفظ / تصدير الصورة
  // ─────────────────────────────────────
  Future<void> _saveImage() async {
    final bytes = await _screenshotCtrl.capture(pixelRatio: 3.0);
    if (bytes == null) return;

    // على الويب: تنزيل الملف مباشرة
    // على Android/iOS: حفظ في Gallery عبر مشاركة
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('جارٍ حفظ الصورة...'),
        backgroundColor: kAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // استخدام Share API لكلا المنصتين
    try {
      // نحاول عبر path_provider إذا كان متاحاً
    } catch (_) {}

    // للويب: نستخدم anchor download trick
    await _downloadBytesWeb(bytes);
  }

  Future<void> _downloadBytesWeb(Uint8List bytes) async {
    // طريقة عالمية: عرض الصورة في نافذة جديدة
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('حفظ الصورة',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            const Text(
              'اضغط مطولاً على الصورة لحفظها على جهازك',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(color: kAccent)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────
  //  إضافة نص على الصورة
  // ─────────────────────────────────────
  Future<void> _addTextDialog() async {
    String inputText = '';
    Color textColor  = Colors.white;
    double fontSize  = 28;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: kCard,
          title: const Text('إضافة نص', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'اكتب نصك هنا...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: kSurface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => inputText = v,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('الحجم:', style: TextStyle(color: Colors.white70)),
                    Expanded(
                      child: Slider(
                        value: fontSize,
                        min: 12,
                        max: 80,
                        onChanged: (v) => setDlgState(() => fontSize = v),
                      ),
                    ),
                    Text(fontSize.toInt().toString(),
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('اللون:', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Colors.white, Colors.black, kAccent,
                    Colors.yellow, Colors.greenAccent, Colors.cyanAccent,
                  ].map((c) => GestureDetector(
                    onTap: () => setDlgState(() => textColor = c),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: textColor == c
                              ? kAccent
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                if (inputText.trim().isNotEmpty) {
                  setState(() {
                    _textOverlays.add(TextOverlay(
                      text: inputText.trim(),
                      position: const Offset(80, 80),
                      color: textColor,
                      fontSize: fontSize,
                    ));
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  //  حوار معلومات المطور
  // ─────────────────────────────────────
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kAccent.withOpacity(0.5), width: 1),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أيقونة
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [kAccent, kAccent2]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.photo_filter_rounded,
                    size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text('محرر الصور الاحترافي',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('الإصدار 2.0.0',
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
              const SizedBox(height: 20),
              // معلومات المطور
              _infoTile(
                  Icons.person_rounded,
                  'المطور',
                  'داوود الأحمدي'),
              const SizedBox(height: 10),
              _infoTile(
                  Icons.email_rounded,
                  'البريد الإلكتروني',
                  'almubarmaj8@gmail.com',
                  isEmail: true),
              const SizedBox(height: 16),
              // تحذير قانوني
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.gavel_rounded,
                        color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'جميع الحقوق محفوظة للمطور. أي محاولة لسرقة أو نسخ الكود المصدري أو التطبيق ستعرض الفاعل للملاحقة القانونية.',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                            height: 1.5),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value,
      {bool isEmail = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: kAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: isEmail
                      ? () => launchUrl(Uri.parse('mailto:$value'))
                      : null,
                  child: Text(value,
                      style: TextStyle(
                          color: isEmail ? kAccent2 : Colors.white,
                          fontSize: 14,
                          decoration: isEmail
                              ? TextDecoration.underline
                              : TextDecoration.none)),
                ),
              ],
            ),
          ),
          if (isEmail)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ البريد الإلكتروني'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Icon(Icons.copy_rounded,
                  color: Colors.white38, size: 18),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  بناء الواجهة
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackground,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // ── منطقة معاينة الصورة ──
            Expanded(child: _buildImagePreview()),
            // ── أدوات التحرير ──
            if (_imageBytes != null) ..._buildToolSection(),
            // ── زر اختيار الصورة ──
            _buildPickButton(),
          ],
        ),
      ),
    );
  }

  // ── AppBar ──
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kSurface,
      title: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [kAccent, kAccent2]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.photo_filter_rounded,
                size: 20, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Text('محرر الصور الاحترافي'),
        ],
      ),
      actions: [
        if (_imageBytes != null)
          IconButton(
            onPressed: _saveImage,
            icon: const Icon(Icons.save_alt_rounded, color: kAccent),
            tooltip: 'حفظ الصورة',
          ),
        IconButton(
          onPressed: _showAboutDialog,
          icon: const Icon(Icons.info_outline_rounded,
              color: Colors.white54),
          tooltip: 'حول التطبيق',
        ),
      ],
    );
  }

  // ── معاينة الصورة مع النصوص المتحركة ──
  Widget _buildImagePreview() {
    if (_imageBytes == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined,
                  size: 50, color: Colors.white24),
            ),
            const SizedBox(height: 20),
            const Text('اختر صورة للبدء',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 18,
                    fontWeight: FontWeight.w300)),
            const SizedBox(height: 8),
            const Text('اضغط على الزر أدناه لاختيار صورة من مكتبتك',
                style: TextStyle(color: Colors.white24, fontSize: 13)),
          ],
        ),
      );
    }

    return Screenshot(
      controller: _screenshotCtrl,
      child: Stack(
        children: [
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: _buildColorFilter(),
              child: Image.memory(
                _imageBytes!,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // النصوص المتحركة
          ..._textOverlays.asMap().entries.map((e) {
            final i = e.key;
            final overlay = e.value;
            return Positioned(
              left: overlay.position.dx,
              top:  overlay.position.dy,
              child: GestureDetector(
                onPanUpdate: (d) => setState(() {
                  _textOverlays[i].position += d.delta;
                }),
                onLongPress: () => setState(() {
                  _textOverlays.removeAt(i);
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white24,
                      style: _activeToolTab == 2
                          ? BorderStyle.solid
                          : BorderStyle.none,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    overlay.text,
                    style: TextStyle(
                      color: overlay.color,
                      fontSize: overlay.fontSize,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(
                            blurRadius: 4,
                            color: Colors.black54)
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── قسم الأدوات ──
  List<Widget> _buildToolSection() {
    return [
      // تبويبات الأدوات
      Container(
        color: kSurface,
        child: Row(
          children: [
            _toolTab(0, Icons.filter_rounded, 'فلاتر'),
            _toolTab(1, Icons.tune_rounded, 'ضبط'),
            _toolTab(2, Icons.text_fields_rounded, 'نص'),
          ],
        ),
      ),
      // محتوى التبويب المختار
      Container(
        color: kCard,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _activeToolTab == 0
              ? _buildFiltersBar()
              : _activeToolTab == 1
                  ? _buildAdjustPanel()
                  : _buildTextPanel(),
        ),
      ),
    ];
  }

  Widget _toolTab(int index, IconData icon, String label) {
    final bool active = _activeToolTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeToolTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? kAccent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 22,
                  color: active ? kAccent : Colors.white38),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: active ? kAccent : Colors.white38,
                      fontSize: 11,
                      fontWeight: active
                          ? FontWeight.bold
                          : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  // ── شريط الفلاتر الأفقي ──
  Widget _buildFiltersBar() {
    return SizedBox(
      height: 110,
      key: const ValueKey('filters'),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8),
        children: FilterType.values.map((filter) {
          final bool selected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () =>
                setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 75,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? kAccent : Colors.transparent,
                  width: 2,
                ),
                gradient: selected
                    ? const LinearGradient(
                        colors: [kAccent, kAccent2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight)
                    : null,
                color: selected ? null : kSurface,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _filterIcon(filter),
                    size: 26,
                    color: selected
                        ? Colors.white
                        : Colors.white54,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    filterNames[filter]!,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Colors.white54,
                      fontSize: 10,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _filterIcon(FilterType f) {
    switch (f) {
      case FilterType.original:      return Icons.image_rounded;
      case FilterType.blackAndWhite: return Icons.contrast_rounded;
      case FilterType.sepia:         return Icons.coffee_rounded;
      case FilterType.warm:          return Icons.wb_sunny_rounded;
      case FilterType.cool:          return Icons.ac_unit_rounded;
      case FilterType.highContrast:  return Icons.brightness_high_rounded;
      case FilterType.fade:          return Icons.blur_on_rounded;
    }
  }

  // ── لوحة الضبط (سطوع / تباين) ──
  Widget _buildAdjustPanel() {
    return Padding(
      key: const ValueKey('adjust'),
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sliderRow(
            icon: Icons.brightness_6_rounded,
            label: 'السطوع',
            value: _brightness,
            min: -0.5,
            max:  0.5,
            divisions: 100,
            onChanged: (v) =>
                setState(() => _brightness = v),
            onReset: () =>
                setState(() => _brightness = 0.0),
          ),
          const SizedBox(height: 8),
          _sliderRow(
            icon: Icons.exposure_rounded,
            label: 'التباين',
            value: _contrast,
            min: 0.5,
            max: 2.0,
            divisions: 150,
            onChanged: (v) =>
                setState(() => _contrast = v),
            onReset: () =>
                setState(() => _contrast = 1.0),
          ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required VoidCallback onReset,
  }) {
    return Row(
      children: [
        Icon(icon, color: kAccent, size: 20),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        GestureDetector(
          onTap: onReset,
          child: const Icon(Icons.refresh_rounded,
              color: Colors.white38, size: 18),
        ),
      ],
    );
  }

  // ── لوحة النص ──
  Widget _buildTextPanel() {
    return Padding(
      key: const ValueKey('text'),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _addTextDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة نص على الصورة'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_textOverlays.isNotEmpty) ...
            [
              const SizedBox(width: 10),
              IconButton(
                onPressed: () =>
                    setState(() => _textOverlays.clear()),
                icon: const Icon(Icons.delete_sweep_rounded,
                    color: Colors.redAccent),
                tooltip: 'حذف كل النصوص',
              ),
            ],
        ],
      ),
    );
  }

  // ── زر اختيار الصورة ──
  Widget _buildPickButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      color: kSurface,
      child: ElevatedButton.icon(
        onPressed: _pickImage,
        icon: const Icon(Icons.photo_library_rounded),
        label: Text(
            _imageBytes == null ? 'اختر صورة من المكتبة' : 'تغيير الصورة'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
