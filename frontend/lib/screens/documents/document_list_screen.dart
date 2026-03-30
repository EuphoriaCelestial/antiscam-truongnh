import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart' as pdf;
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import '../../models/models.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  String? _selectedType;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'title'; // 'title', 'type'
  final List<String> _types = [
    'Tất cả',
    'Hình ảnh',
    'Video',
    'Tài liệu',
  ];

  final List<AssetItem> _assets = [
    AssetItem(
      id: '1',
      title: 'Lorem Ipsum PDF',
      path: 'assets/pdf/lorem-ipsum.pdf',
      type: AssetType.document,
      description: 'Tài liệu mẫu Lorem Ipsum',
    ),
    AssetItem(
      id: '2',
      title: 'O1M EBook',
      path: 'assets/pdf/O1M_EBook (1).pdf',
      type: AssetType.document,
      description: 'Sách điện tử O1M',
    ),
    AssetItem(
      id: '3',
      title: 'Video 1',
      path: 'assets/videos/67ef2397-2c36-4698-9ac5-792782ce44d6.mp4',
      type: AssetType.video,
      description: 'Video cảnh báo lừa đảo',
    ),
    AssetItem(
      id: '4',
      title: 'Video 2',
      path: 'assets/videos/b9702804-98d2-454c-8393-0b1f677c4ab3.mp4',
      type: AssetType.video,
      description: 'Video hướng dẫn bảo mật',
    ),
    AssetItem(
      id: '5',
      title: 'Video 3',
      path: 'assets/videos/eb3c5bfc-39e6-41a0-911e-a3f5ce969c5c.mp4',
      type: AssetType.video,
      description: 'Video infographic lừa đảo',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AssetItem> _getFilteredAssets(List<AssetItem> assets) {
    var filtered = assets.where((asset) {
      final matchesSearch = _searchQuery.isEmpty ||
          asset.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (asset.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesType = _selectedType == null || _selectedType == 'All' ||
          asset.type.name.toLowerCase() == _selectedType!.toLowerCase();
      return matchesSearch && matchesType;
    }).toList();

    // Sort assets
    switch (_sortBy) {
      case 'type':
        filtered.sort((a, b) => a.type.name.compareTo(b.type.name));
        break;
      case 'title':
      default:
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF667eea).withOpacity(0.3),
                const Color(0xFF764ba2).withOpacity(0.3),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFF5B4EFF).withOpacity(0.5),
                width: 2,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Image.asset(
              'images/AppBar_Ico_1.png',
              height: 80,
              errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.image, size: 80, color: Colors.white),
            ),
            const SizedBox(width: 12),
            
            Image.asset(
              'images/AppBar_Ico_2.png',
              height: 80,
              errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.image, size: 80, color: Colors.white),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Text(
                'CẢNH BÁO CÁC CHIÊU TRÒ LỪA ĐẢO QUA KHÔNG GIAN MẠNG',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
            
            Image.asset(
              'images/AppBar_Ico_3.png',
              height: 80,
              errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.image, size: 80, color: Colors.white),
            ),
            const SizedBox(width: 16),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'CÔNG AN PHƯỜNG AN HỘI TÂY\nCHI ĐOÀN CÔNG AN',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white,
                  height: 1.2,
                ),
                textAlign: TextAlign.left,
                maxLines: 2,
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A), // Deep blue
              Color(0xFF3B82F6), // Blue
              Color(0xFF8B5CF6), // Purple
              Color(0xFF6B21A8), // Deep purple
            ],
            stops: [0.0, 0.33, 0.66, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF667eea).withOpacity(0.2),
                      const Color(0xFF764ba2).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF5B4EFF).withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.montserrat(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm tài liệu...',
                    hintStyle: GoogleFonts.montserrat(
                      color: Colors.white.withOpacity(0.5),
                    ),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF06B6D4)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Color(0xFFFF2D55)),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
            
            // Sort Options
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Sắp xếp:',
                    style: GoogleFonts.montserrat(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildSortChip('Tên A-Z', 'title'),
                  const SizedBox(width: 8),
                  _buildSortChip('Loại', 'type'),
                ],
              ),
            ),
            
            // Type Filter
            Container(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _types.map((type) {
                    final isSelected = _selectedType == type || 
                                     (_selectedType == null && type == 'Tất cả');
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFFFF2D55), Color(0xFFFF6B9D)],
                                )
                              : null,
                          color: isSelected ? null : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : const Color(0xFF06B6D4).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedType = type == 'Tất cả' ? null : type;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                type,
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          
          // Asset List
          Expanded(
            child: Builder(
              builder: (context) {
                final filteredAssets = _getFilteredAssets(_assets);
                
                if (filteredAssets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Color(0xFF06B6D4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy tài liệu phù hợp',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredAssets.length,
                  itemBuilder: (context, index) {
                    final asset = filteredAssets[index];
                    return _buildAssetCard(context, asset, index);
                  },
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildAssetCard(BuildContext context, AssetItem asset, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667eea).withOpacity(0.2),
            const Color(0xFF764ba2).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF5B4EFF).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B4EFF).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAssetDialog(context, asset),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail or Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: asset.type == AssetType.image
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            asset.path,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image, size: 40, color: Colors.white),
                          ),
                        )
                      : Icon(
                          asset.type == AssetType.video
                              ? Icons.video_file
                              : Icons.description,
                          size: 40,
                          color: Colors.white,
                        ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        asset.title,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      // Type
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F2FF).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00F2FF).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          asset.type.name.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: const Color(0xFF00F2FF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Description
                      if (asset.description != null)
                        Text(
                          asset.description!,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                
                // Arrow icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF06B6D4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 400.ms, delay: Duration(milliseconds: index * 50))
      .slideX(begin: 0.1, end: 0);
  }

  void _showAssetDialog(BuildContext context, AssetItem asset) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0F0F1A),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.95,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  asset.title,
                  style: GoogleFonts.montserrat(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
              // Content
              Flexible(
                child: _buildAssetViewer(asset),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Đóng',
                    style: GoogleFonts.montserrat(color: const Color(0xFF06B6D4)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetViewer(AssetItem asset) {
    switch (asset.type) {
      case AssetType.image:
        return LayoutBuilder(
          builder: (context, constraints) {
            double maxWidth = constraints.maxWidth;
            double maxHeight = constraints.maxHeight;
            return SizedBox(
              width: maxWidth,
              height: maxHeight > 400 ? 400 : maxHeight,
              child: Image.asset(
                asset.path,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image, size: 100, color: Colors.white),
              ),
            );
          },
        );
      case AssetType.video:
        return _VideoPlayerWidget(assetPath: asset.path);
      case AssetType.document:
        if (kIsWeb) {
          // Web: Sử dụng iframe để hiển thị PDF
          return _WebPdfViewer(assetPath: asset.path);
        }
        // Mobile: Sử dụng PDF viewer bình thường
        return LayoutBuilder(
          builder: (context, constraints) {
            double maxHeight = constraints.maxHeight;
            return Container(
              height: maxHeight,
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: pdf.SfPdfViewer.asset(
                  asset.path,
                  enableDoubleTapZooming: true,
                  enableTextSelection: true,
                ),
              ),
            );
          },
        );
    }
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF00F2FF), Color(0xFF4FACFE)],
              )
            : null,
        color: isSelected ? null : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? Colors.transparent
              : const Color(0xFF06B6D4).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _sortBy = value;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String assetPath;

  const _VideoPlayerWidget({required this.assetPath});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      if (kIsWeb) {
        // For web, use network controller with asset URL
        final videoUrl = Uri.base.resolve(widget.assetPath).toString();
        _controller = VideoPlayerController.network(videoUrl);
      } else {
        // For mobile, use asset controller
        _controller = VideoPlayerController.asset(widget.assetPath);
      }
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải video: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, size: 50, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF06B6D4),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = constraints.maxWidth;
        double maxHeight = constraints.maxHeight - 60; // Reserve space for controls
        double aspectRatio = _controller.value.aspectRatio;

        double videoWidth = maxWidth;
        double videoHeight = videoWidth / aspectRatio;

        if (videoHeight > maxHeight) {
          videoHeight = maxHeight;
          videoWidth = videoHeight * aspectRatio;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: videoWidth,
              height: videoHeight,
              child: VideoPlayer(_controller),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: const Color(0xFF06B6D4),
                  ),
                  onPressed: () {
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.replay, color: Color(0xFF06B6D4)),
                  onPressed: () {
                    _controller.seekTo(Duration.zero);
                    _controller.play();
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _WebPdfViewer extends StatefulWidget {
  final String assetPath;

  const _WebPdfViewer({required this.assetPath});

  @override
  State<_WebPdfViewer> createState() => _WebPdfViewerState();
}

class _WebPdfViewerState extends State<_WebPdfViewer> {
  final String _iframeId = 'pdf-iframe-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _registerIframe();
  }

  void _registerIframe() {
    final pdfUrl = Uri.base.resolve(widget.assetPath).toString();
    
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      _iframeId,
      (int viewId) => html.IFrameElement()
        ..src = pdfUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: HtmlElementView(viewType: _iframeId),
      ),
    );
  }
}
