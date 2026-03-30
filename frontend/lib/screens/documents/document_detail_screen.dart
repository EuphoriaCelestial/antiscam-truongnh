import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../providers/document_provider.dart';

class DocumentDetailScreen extends StatefulWidget {
  final int documentId;
  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      docProvider.fetchDocument(widget.documentId);
    });

    // Audio player listeners
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() => _position = position);
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio(String audioUrl) async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play(UrlSource(audioUrl));
      setState(() => _isPlaying = true);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF00F2FF)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        title: Text(
          'Tài liệu',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0F1A),
              Color(0xFF1A0033),
              Color(0xFF0F0F1A),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Consumer<DocumentProvider>(
          builder: (context, docProvider, child) {
            if (docProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFFD60A),
                ),
              );
            }

            if (docProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Color(0xFFFF2D55),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      docProvider.error!,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => docProvider.fetchDocument(widget.documentId),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final doc = docProvider.currentDocument;
            if (doc == null) {
              return Center(
                child: Text(
                  'Document not found',
                  style: GoogleFonts.montserrat(color: Colors.white),
                ),
              );
            }

            return Row(
              children: [
                // Left panel - Document info (30%)
                Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF667eea).withOpacity(0.15),
                        const Color(0xFF764ba2).withOpacity(0.15),
                      ],
                    ),
                    border: Border(
                      right: BorderSide(
                        color: const Color(0xFF5B4EFF).withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail
                        if (doc.thumbnailUrl != null)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF5B4EFF).withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                doc.thumbnailUrl!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      height: 200,
                                      color: Colors.grey[800],
                                      child: const Icon(Icons.image, size: 60, color: Colors.white54),
                                    ),
                              ),
                            ),
                          ).animate().fadeIn(),
                        
                        const SizedBox(height: 24),
                        
                        // Title
                        Text(
                          doc.title,
                          style: GoogleFonts.bungee(
                            fontSize: 20,
                            color: const Color(0xFFFFD60A),
                            shadows: [
                              Shadow(
                                color: const Color(0xFFFFD60A).withOpacity(0.5),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 100.ms),
                        
                        const SizedBox(height: 16),
                        
                        Divider(color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        
                        // Info section
                        _buildInfoRow(Icons.person, 'T\u00e1c gi\u1ea3', doc.author ?? 'Unknown'),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.visibility, 'L\u01b0\u1ee3t xem', '${doc.viewsCount}'),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.calendar_today, 'Ng\u00e0y t\u1ea1o', 
                          '${doc.createdAt.day}/${doc.createdAt.month}/${doc.createdAt.year}'),
                        
                        if (doc.category != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.category, 'Danh m\u1ee5c', doc.category!),
                        ],
                        
                        const SizedBox(height: 24),
                        Divider(color: Colors.white.withOpacity(0.2)),
                          // Audio player
                        if (doc.audioUrl != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\u0110\u1ecdc b\u00e0i',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFFD60A),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
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
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF00F2FF), Color(0xFF4FACFE)],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                            size: 40,
                                            color: Colors.white,
                                          ),
                                          onPressed: () => _toggleAudio(doc.audioUrl!),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Slider(
                                        value: _position.inSeconds.toDouble(),
                                        max: _duration.inSeconds.toDouble() > 0 
                                          ? _duration.inSeconds.toDouble() 
                                          : 1.0,
                                        activeColor: const Color(0xFF00F2FF),
                                        inactiveColor: Colors.white.withOpacity(0.2),
                                        onChanged: (value) async {
                                          final position = Duration(seconds: value.toInt());
                                          await _audioPlayer.seek(position);
                                        },
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDuration(_position),
                                            style: GoogleFonts.montserrat(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            _formatDuration(_duration),
                                            style: GoogleFonts.montserrat(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(delay: 200.ms),
                              const SizedBox(height: 24),
                            ],
                          ),
                        // Content preview
                        Text(
                          'N\u1ed9i dung',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFD60A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          doc.content.length > 200 
                              ? '${doc.content.substring(0, 200)}...'
                              : doc.content,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.white70,
                          ),
                          maxLines: 8,
                          overflow: TextOverflow.ellipsis,
                        ).animate().fadeIn(delay: 300.ms),
                      ],
                    ),
                  ),
                ),
                
                // Right panel - Document viewer (70%)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: doc.pdfUrl != null && doc.pdfUrl!.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf,
                                    color: const Color(0xFFFF2D55),
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'T\u00e0i li\u1ec7u PDF',
                                    style: GoogleFonts.bungee(
                                      fontSize: 24,
                                      color: const Color(0xFFFFD60A),
                                      shadows: [
                                        Shadow(
                                          color: const Color(0xFFFFD60A).withOpacity(0.5),
                                          blurRadius: 15,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF667eea).withOpacity(0.2),
                                        const Color(0xFF764ba2).withOpacity(0.2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF5B4EFF).withOpacity(0.5),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF5B4EFF).withOpacity(0.3),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: doc.pdfUrl!.startsWith('assets/')
                                        ? SfPdfViewer.asset(
                                            doc.pdfUrl!,
                                            enableDoubleTapZooming: true,
                                            enableTextSelection: true,
                                            onDocumentLoadFailed: (details) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Failed to load PDF: ${details.error}'),
                                                  backgroundColor: const Color(0xFFFF2D55),
                                                ),
                                              );
                                            },
                                          )
                                        : SfPdfViewer.network(
                                            doc.pdfUrl!,
                                            enableDoubleTapZooming: true,
                                            enableTextSelection: true,
                                            onDocumentLoadFailed: (details) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Failed to load PDF: ${details.error}'),
                                                  backgroundColor: const Color(0xFFFF2D55),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ).animate().fadeIn(delay: 400.ms),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.article,
                                      color: const Color(0xFF00F2FF),
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'N\u1ed9i dung t\u00e0i li\u1ec7u',
                                      style: GoogleFonts.bungee(
                                        fontSize: 24,
                                        color: const Color(0xFFFFD60A),
                                        shadows: [
                                          Shadow(
                                            color: const Color(0xFFFFD60A).withOpacity(0.5),
                                            blurRadius: 15,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF667eea).withOpacity(0.1),
                                        const Color(0xFF764ba2).withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF5B4EFF).withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    doc.content,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      height: 1.8,
                                      color: Colors.white,
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 400.ms),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
