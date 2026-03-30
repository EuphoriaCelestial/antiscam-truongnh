import '../widgets/player_name_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

String? globalPlayerName;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 1000;

    Future<void> _requirePlayerNameAndNavigate(String route) async {
      if (globalPlayerName == null || globalPlayerName!.isEmpty) {
        final name = await showPlayerNameDialog(context);
        if (name == null || name.isEmpty) return;
        globalPlayerName = name;
      }
      context.go(route);
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin'),
        backgroundColor: Colors.black54,
        mini: true,
        tooltip: 'Admin',
        child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isSmallScreen ? 140 : 110),
        child: AppBar(
          toolbarHeight: isSmallScreen ? 140 : 110,
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF06B6D4).withOpacity(0.4),
                  const Color(0xFF0891B2).withOpacity(0.4),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF06B6D4).withOpacity(0.6),
                  width: 2,
                ),
              ),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: isSmallScreen
                ? _buildMobileHeader()
                : _buildDesktopHeader(context),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
              Color(0xFF8B5CF6),
              Color(0xFF6B21A8),
            ],
            stops: [0.0, 0.33, 0.66, 1.0],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Expanded(child: SizedBox()),
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: size.width > 600 ? 500 : size.width * 0.9,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildMenuCard(
                                context,
                                'Thi một mình',
                                Icons.person_rounded,
                                Colors.blue,
                                () => _requirePlayerNameAndNavigate(
                                  '/quiz?mode=single',
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildMenuCard(
                                context,
                                'Tạo cuộc thi',
                                Icons.add_circle_rounded,
                                Colors.green,
                                () => _requirePlayerNameAndNavigate(
                                  '/create-room',
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildMenuCard(
                                context,
                                'Tham gia cuộc thi',
                                Icons.group_add_rounded,
                                Colors.orange,
                                () =>
                                    _requirePlayerNameAndNavigate('/join-room'),
                              ),
                              const SizedBox(height: 20),
                              _buildMenuCard(
                                context,
                                'Tài liệu tham khảo',
                                Icons.library_books_rounded,
                                Colors.purple,
                                () => context.go('/documents'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                      const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        height: 1,
                        width: size.width > 600 ? 600 : size.width * 0.8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFF06B6D4).withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 24,
                          bottom: 20,
                        ),
                        child: _buildCreditSection(context),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildResponsiveImage('assets/images/AppBar_Ico_1.png'),
              const SizedBox(width: 18),
              _buildResponsiveImage('assets/images/AppBar_Ico_2.png'),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              'CẢNH BÁO CÁC CHIÊU TRÒ\nLỪA ĐẢO QUA KHÔNG GIAN MẠNG',
              style: _mainTitleStyle(30),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildResponsiveImage('assets/images/AppBar_Ico_3.png'),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CÔNG AN PHƯỜNG AN HỘI TÂY',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                  Text(
                    'CHI ĐOÀN CÔNG AN',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildResponsiveImage('assets/images/AppBar_Ico_1.png', size: 40),
            const SizedBox(width: 18),
            _buildResponsiveImage('assets/images/AppBar_Ico_2.png', size: 40),
            const SizedBox(width: 18),
            _buildResponsiveImage('assets/images/AppBar_Ico_3.png',
                scale: 3, size: 40),
            const SizedBox(width: 22),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'CẢNH BÁO LỪA ĐẢO\nQUA KHÔNG GIAN MẠNG',
          style: _mainTitleStyle(22),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResponsiveImage(String path,
      {double size = 80, double scale = 1.0}) {
    if (path.endsWith('.svg')) {
      return Transform.scale(
          scale: scale,
          child: SvgPicture.asset(path, height: size, width: size));
    }
    return Transform.scale(
        scale: scale,
        child:
            Image.asset(path, height: size, width: size, fit: BoxFit.contain));
  }

  TextStyle _mainTitleStyle(double fontSize) {
    return GoogleFonts.montserrat(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      color: const Color(0xFFFFD60A),
      height: 1.2,
      letterSpacing: 0.5,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(0, 2),
          blurRadius: 4,
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final gradientColors = _getGradientColors(color);
    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(icon, size: 28, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(Color color) {
    if (color == Colors.blue)
      return [const Color(0xFFFF2D55), const Color(0xFFFF6B9D)];
    if (color == Colors.green)
      return [const Color(0xFF5B4EFF), const Color(0xFF9D50BB)];
    if (color == Colors.orange)
      return [const Color(0xFF00F2FF), const Color(0xFF4FACFE)];
    if (color == Colors.purple)
      return [const Color(0xFFFFD60A), const Color(0xFFFFA500)];
    return [color, color.withOpacity(0.7)];
  }

  Widget _buildCreditSection(BuildContext context) {
    return Column(
      children: [
        Text(
          'Ứng dụng được phát triển bởi:\nCông an phường 875-877 Quang Trung, Phường An Hội Tây, Thành phố Hồ Chí Minh.\nHotline: 028 38946073',
          style: GoogleFonts.montserrat(
            fontSize: 10,
            color: Colors.white.withOpacity(0.8),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}
