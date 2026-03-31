import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../config/api_config.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoading = false;
  String? _statusMessage;
  bool _statusIsError = false;

  void _showStatus(String message, {bool isError = false}) {
    setState(() {
      _statusMessage = message;
      _statusIsError = isError;
    });
  }

  Future<void> _uploadQuestions() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _isLoading = true);
    try {
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.adminUploadQuestions))
        ..files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));

      final response = await request.send();
      final body = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        _showStatus(data['message'] ?? 'Upload thành công');
      } else {
        _showStatus('Lỗi: ${jsonDecode(body)['detail'] ?? body}', isError: true);
      }
    } catch (e) {
      _showStatus('Lỗi: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _isLoading = true);
    try {
      // Upload file
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.adminUploadPdf))
        ..files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final uploadData = jsonDecode(body);
        final pdfUrl = uploadData['url'] as String;
        _showStatus('File tải lên thành công');
        if (mounted) await _showCreateDocumentDialog(pdfUrl: pdfUrl);
      } else {
        _showStatus('Lỗi upload: ${jsonDecode(body)['detail'] ?? body}', isError: true);
      }
    } catch (e) {
      _showStatus('Lỗi: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Đang tải video lên (có thể mất vài phút)...';
      _statusIsError = false;
    });

    try {
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.adminUploadVideo))
        ..files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final uploadData = jsonDecode(body);
        final videoUrl = uploadData['url'] as String;
        _showStatus('Video tải lên thành công');
        if (mounted) await _showCreateDocumentDialog(videoUrl: videoUrl);
      } else {
        _showStatus('Lỗi upload: ${jsonDecode(body)['detail'] ?? body}', isError: true);
      }
    } catch (e) {
      _showStatus('Lỗi: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showCreateDocumentDialog({String? pdfUrl, String? videoUrl}) async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final authorCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo tài liệu mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Tiêu đề *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: contentCtrl,
                decoration: const InputDecoration(labelText: 'Mô tả *'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: categoryCtrl,
                decoration: const InputDecoration(labelText: 'Danh mục'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: authorCtrl,
                decoration: const InputDecoration(labelText: 'Tác giả'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bỏ qua'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Vui lòng điền tiêu đề và mô tả')),
                );
                return;
              }
              try {
                final response = await http.post(
                  Uri.parse(ApiConfig.adminDocuments),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'title': titleCtrl.text.trim(),
                    'content': contentCtrl.text.trim(),
                    'category': categoryCtrl.text.trim().isEmpty ? null : categoryCtrl.text.trim(),
                    'author': authorCtrl.text.trim().isEmpty ? null : authorCtrl.text.trim(),
                    if (pdfUrl != null) 'pdf_url': pdfUrl,
                    if (videoUrl != null) 'video_url': videoUrl,
                  }),
                );
                if (response.statusCode == 200 || response.statusCode == 201) {
                  _showStatus('Tài liệu đã được tạo thành công');
                  Navigator.pop(ctx);
                } else {
                  final err = jsonDecode(response.body)['detail'] ?? response.body;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Lỗi: $err'), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: const Color(0xFF0891B2),
        foregroundColor: Colors.white,
      ),
      body: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_statusMessage != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _statusIsError
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _statusIsError ? Colors.red : Colors.green,
                            ),
                          ),
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              color: _statusIsError ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      _buildUploadCard(
                        icon: Icons.quiz_rounded,
                        title: 'Upload Câu Hỏi',
                        subtitle: 'File Excel (.xlsx) — Cột: Câu hỏi | Đáp án A | Đáp án B | Đúng (A/B)',
                        color: Colors.blue,
                        onTap: _uploadQuestions,
                      ),
                      const SizedBox(height: 16),
                      _buildUploadCard(
                        icon: Icons.picture_as_pdf_rounded,
                        title: 'Upload PDF',
                        subtitle: 'Tải lên tài liệu PDF và thêm vào danh sách tài liệu',
                        color: Colors.red,
                        onTap: _uploadPdf,
                      ),
                      const SizedBox(height: 16),
                      _buildUploadCard(
                        icon: Icons.video_library_rounded,
                        title: 'Upload Video',
                        subtitle: 'Tải lên video và thêm vào danh sách tài liệu',
                        color: Colors.purple,
                        onTap: _uploadVideo,
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black38,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }

  Widget _buildUploadCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.upload_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
