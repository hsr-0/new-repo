// report_viewer_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

// enum لتحديد نوع الملف القابل للعرض بوضوح
enum DisplayableFileType { pdf, image, unsupported }

class ReportViewerScreen extends StatefulWidget {
  final String fileUrl;
  final String? apiFileType; // أصبح اختياريًا الآن
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
  String? _localPdfPath;
  bool _isLoading = true;
  String _loadingMessage = 'جاري تحليل وعرض التقرير...';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 1. تحديد نوع الملف بذكاء
    _fileType = _determineFileType();

    // 2. إذا كان الملف PDF، قم بتحميله أولاً
    if (_fileType == DisplayableFileType.pdf && !kIsWeb) {
      await _downloadPdf();
    }

    // 3. إيقاف شاشة التحميل
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // هذه هي الدالة الذكية لتحديد النوع
  DisplayableFileType _determineFileType() {
    final typeFromServer = (widget.apiFileType ?? '').toLowerCase().trim();
    final url = widget.fileUrl.toLowerCase();

    // المستوى الأول: الثقة بالنوع القادم من الخادم
    if (typeFromServer == 'pdf' || typeFromServer == 'application/pdf') {
      return DisplayableFileType.pdf;
    }
    if (typeFromServer.startsWith('image')) { // 'image/png', 'image/jpeg' etc.
      return DisplayableFileType.image;
    }

    // المستوى الثاني: تحليل رابط الملف
    if (url.endsWith('.pdf')) {
      return DisplayableFileType.pdf;
    }
    if (url.endsWith('.png') || url.endsWith('.jpg') || url.endsWith('.jpeg')) {
      return DisplayableFileType.image;
    }

    // المستوى الثالث: إذا فشل كل شيء
    return DisplayableFileType.unsupported;
  }

  Future<void> _downloadPdf() async {
    try {
      final uri = Uri.parse(widget.fileUrl);
      final response = await http.get(uri);
      final bytes = response.bodyBytes;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${widget.reportTitle.replaceAll(' ', '_')}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      if (mounted) {
        setState(() {
          _localPdfPath = file.path;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingMessage = 'فشل تحميل الملف لعرضه.';
          // سنجعل النوع غير مدعوم إذا فشل التحميل
          _fileType = DisplayableFileType.unsupported;
        });
      }
    }
  }

  // دالة لفتح الرابط خارجيًا
  Future<void> _openExternally() async {
    final uri = Uri.parse(widget.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن فتح الرابط. تأكد من تثبيت متصفح ويب.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reportTitle),
        // إضافة زر تنزيل دائم في الأعلى
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined),
            tooltip: 'فتح في تطبيق خارجي / تنزيل',
            onPressed: _openExternally,
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingView() : _buildContentView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(_loadingMessage),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    switch (_fileType) {
      case DisplayableFileType.pdf:
        if (_localPdfPath != null) {
          return PDFView(filePath: _localPdfPath!);
        }
        // عرض رسالة خطأ إذا فشل التحميل
        return _buildUnsupportedView();

      case DisplayableFileType.image:
        return Center(
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: widget.fileUrl,
              placeholder: (context, url) => _buildLoadingView(),
              errorWidget: (context, url, error) => _buildUnsupportedView(),
            ),
          ),
        );

      case DisplayableFileType.unsupported:
      default:
        return _buildUnsupportedView();
    }
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
            const Text(
              'تعذر عرض هذا الملف داخل التطبيق.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'يمكنك محاولة فتحه في تطبيق خارجي أو تنزيله.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('فتح خارجيًا'),
              onPressed: _openExternally,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}