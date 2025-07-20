// report_viewer_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // سنحتاجه للتحقق من الاتصال

enum DisplayableFileType { pdf, image, unsupported }

class ReportViewerScreen extends StatefulWidget {
  final String fileUrl;
  final String? apiFileType;
  final String reportTitle;

  const ReportViewerScreen({
    Key? key,
    required this.fileUrl,
    required this.reportTitle,
    this.apiFileType,
  }) : super(key: key);

  @override
  _ReportViewerScreenState createState() => _ReportViewerScreenState();
}

class _ReportViewerScreenState extends State<ReportViewerScreen> {
  late DisplayableFileType _fileType;
  String? _localFilePath;
  bool _isLoading = true;
  String _statusMessage = 'جاري تحليل وعرض التقرير...';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  // --- الخطوة 1: تحديد مسار الملف المحلي ---
  Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    // استخدام آخر جزء من الرابط كاسم للملف لضمان تفرده
    final fileName = Uri.parse(widget.fileUrl).pathSegments.last;
    return File('${dir.path}/$fileName');
  }

  // --- الخطوة 2: تحديث منطق التشغيل الأولي ---
  Future<void> _initialize() async {
    // تحديد نوع الملف (صور، PDF، الخ)
    _fileType = _determineFileType();

    // التعامل مع ملفات الصور (تستخدم التخزين التلقائي من المكتبة)
    if (_fileType == DisplayableFileType.image) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // التعامل مع ملفات PDF (تتطلب تخزين يدوي)
    if (_fileType == DisplayableFileType.pdf && !kIsWeb) {
      final localFile = await _getLocalFile();

      // التحقق إذا كان الملف موجودًا في الذاكرة (مخزن مؤقتًا)
      if (await localFile.exists()) {
        if (mounted) {
          setState(() {
            _localFilePath = localFile.path;
            _isLoading = false;
            _statusMessage = 'تم العرض من الذاكرة المحفوظة.';
          });
        }
      } else {
        // إذا لم يكن الملف موجودًا، حاول تحميله
        await _downloadAndCachePdf();
      }
    } else {
      // للأنواع غير المدعومة أو الويب
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- الخطوة 3: تحديث دالة التحميل مع معالجة الأخطاء ---
  Future<void> _downloadAndCachePdf() async {
    // أولاً، تحقق من وجود اتصال بالإنترنت
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      if (mounted) {
        setState(() {
          _statusMessage = 'الملف غير محفوظ، ولا يوجد اتصال بالإنترنت لتحميله.';
          _fileType = DisplayableFileType.unsupported; // اعتبره غير مدعوم الآن
          _isLoading = false;
        });
      }
      return;
    }

    // إذا كان هناك انترنت، حاول التحميل
    try {
      final uri = Uri.parse(widget.fileUrl);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final file = await _getLocalFile();
        await file.writeAsBytes(response.bodyBytes, flush: true);
        if (mounted) {
          setState(() {
            _localFilePath = file.path;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('لا توجد فحوصات ');
      }
    } on SocketException { // <-- معالجة خطأ الإنترنت بالتحديد
      if (mounted) {
        setState(() {
          _statusMessage = 'فشل الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت.';
          _fileType = DisplayableFileType.unsupported;
          _isLoading = false;
        });
      }
    } catch (e) { // <-- معالجة أي أخطاء أخرى
      if (mounted) {
        setState(() {
          _statusMessage = 'فشل تحميل الملف لعرضه.';
          _fileType = DisplayableFileType.unsupported;
          _isLoading = false;
        });
      }
    }
  }

  // --- باقي الدوال تبقى كما هي مع تعديلات بسيطة ---

  DisplayableFileType _determineFileType() {
    final typeFromServer = (widget.apiFileType ?? '').toLowerCase().trim();
    final url = widget.fileUrl.toLowerCase();

    if (typeFromServer == 'pdf' || typeFromServer == 'application/pdf' || url.endsWith('.pdf')) {
      return DisplayableFileType.pdf;
    }
    if (typeFromServer.startsWith('image') || url.endsWith('.png') || url.endsWith('.jpg') || url.endsWith('.jpeg')) {
      return DisplayableFileType.image;
    }
    return DisplayableFileType.unsupported;
  }

  Future<void> _openExternally() async {
    final uri = Uri.parse(widget.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن فتح الرابط.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reportTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined),
            tooltip: 'فتح في تطبيق خارجي / تنزيل',
            onPressed: _openExternally,
          ),
        ],
      ),
      body: _isLoading ? _buildMessageView(_statusMessage, showIndicator: true) : _buildContentView(),
    );
  }

  Widget _buildContentView() {
    switch (_fileType) {
      case DisplayableFileType.pdf:
        return (_localFilePath != null)
            ? PDFView(filePath: _localFilePath!)
            : _buildUnsupportedView(); // عرض خطأ إذا فشل التحميل لسبب ما

      case DisplayableFileType.image:
      // CachedNetworkImage يتولى التخزين المؤقت للصور تلقائيًا
        return Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4,
            child: CachedNetworkImage(
              imageUrl: widget.fileUrl,
              placeholder: (context, url) => _buildMessageView('جاري تحميل الصورة...'),
              errorWidget: (context, url, error) => _buildUnsupportedView(),
            ),
          ),
        );

      case DisplayableFileType.unsupported:
      default:
        return _buildUnsupportedView();
    }
  }

  // واجهة موحدة لعرض رسائل الحالة والتحميل
  Widget _buildMessageView(String message, {bool showIndicator = true}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showIndicator) const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildUnsupportedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              _statusMessage, // عرض رسالة الخطأ المحددة
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'يمكنك محاولة فتحه في  الخارج.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('فتح خارجيًا'),
              onPressed: _openExternally,
            ),
          ],
        ),
      ),
    );
  }
}