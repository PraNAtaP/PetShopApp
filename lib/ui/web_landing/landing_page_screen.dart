import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart' hide PlayerState;
import 'package:universal_html/html.dart' as html;
import 'dart:math' as math;
import 'dart:ui';

class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  html.AudioElement? _webAudioPlayer;
  bool _isPlaying = false;

  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _teamKey = GlobalKey();

  void _showDemoVideo() {
    bool wasPlaying = _isPlaying;
    if (wasPlaying) {
      _webAudioPlayer?.pause();
      setState(() => _isPlaying = false);
    }

    final controller = YoutubePlayerController.fromVideoId(
      videoId: 'KiB1-axuzKE', // Video ID asli dari iFrame Pet Point
      autoPlay: true,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 500),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title bar with close button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    border: Border(bottom: BorderSide(color: Colors.white12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Video Demo Pet Point', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 24,
                      ),
                    ],
                  ),
                ),
                // Video player
                Flexible(
                  child: YoutubePlayer(controller: controller),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (wasPlaying && mounted) {
        _webAudioPlayer?.play();
        setState(() => _isPlaying = true);
      }
    });
  }

  void _scrollToSection(GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _playBackgroundMusic();
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 50 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  void _playBackgroundMusic() {
    // Pada Flutter Web, path file statis berada di dalam folder assets/
    _webAudioPlayer = html.AudioElement()
      ..src = 'assets/lib/assets/music/music.mp3'
      ..loop = true
      ..autoplay = false;
      
    // Coba putar (auto-play)
    _webAudioPlayer?.play().then((_) {
      if (mounted) setState(() => _isPlaying = true);
    }).catchError((e) {
      debugPrint("Auto-play blocked by browser: $e");
    });
  }

  void _toggleMusic() {
    if (_isPlaying) {
      _webAudioPlayer?.pause();
    } else {
      _webAudioPlayer?.play().catchError((e) {
        debugPrint("Error playing music: $e");
      });
    }
    if (mounted) setState(() => _isPlaying = !_isPlaying);
  }

  @override
  void dispose() {
    _webAudioPlayer?.pause();
    _webAudioPlayer?.removeAttribute('src');
    _webAudioPlayer?.load();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            controller: _scrollController,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: [
                Container(key: _homeKey, child: _buildHeroSection(context)),
                Container(key: _aboutKey, child: _buildAboutSection(context)),
                _buildAppDemoSection(context),
                Container(key: _teamKey, child: _buildTeamGrid(context)),
                _buildFooter(context),
                ],
              ),
            ),
          ),
          
          // Sticky Navbar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildNavbar(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleMusic,
        backgroundColor: Colors.black87,
        child: Icon(
          _isPlaying ? Icons.music_note : Icons.music_off,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildNavbar(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 50),
      decoration: BoxDecoration(
        color: _isScrolled ? Colors.white : Colors.transparent,
        boxShadow: _isScrolled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ]
            : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'lib/assets/img/1776076564947.png',
                height: 36,
              ),
              if (!isMobile) ...[
                const SizedBox(width: 12),
                Text(
                  'Pet Point',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _isScrolled ? AppColors.textDark : Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ],
          ),
          
          // Center Nav Links (Hidden on small screens)
          if (!isMobile)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _navLink('BERANDA', _isScrolled, () => _scrollToSection(_homeKey)),
                const SizedBox(width: 32),
                _navLink('TENTANG KAMI', _isScrolled, () => _scrollToSection(_aboutKey)),
                const SizedBox(width: 32),
                _navLink('TIM KAMI', _isScrolled, () => _scrollToSection(_teamKey)),
              ],
            ),

          // Action Button
          ElevatedButton(
            onPressed: () async {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'pranatapu08@gmail.com',
                query: 'subject=Pertanyaan Seputar Pet Point',
              );
              if (!await launchUrl(emailLaunchUri)) {
                debugPrint('Could not launch $emailLaunchUri');
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: isMobile ? const Size(100, 40) : const Size(120, 50),
              backgroundColor: const Color(0xFF4FC3F7), 
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 12 : 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: Text(
              'CONTACT US',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: isMobile ? 11 : 13, letterSpacing: 1),
            ),
          )
        ],
      ),
    );
  }

  Widget _navLink(String text, bool isScrolled, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: isScrolled ? AppColors.textDark : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    return Container(
      width: double.infinity,
      // Background image of a pet in a landscape
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const NetworkImage('https://images.unsplash.com/photo-1450778869180-41d0601e046e?q=80&w=2560&auto=format&fit=crop'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.35),
            BlendMode.darken,
          ),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2B83E5), // Deep sky blue
            Color(0xFF67B5F7), // Light sky blue
            Color(0xFF8CD0FF), // Very light blue
          ],
        ),
      ),
      padding: const EdgeInsets.only(top: 110, bottom: 45),
      child: Column(
        children: [
          // Typography
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isMobile ? 360 : 800),
            child: Column(
              children: [
                Text(
                  'Solusi All-in-One untuk\nAnabul Kesayanganmu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 32 : 43,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -1.0,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Mulai dari grooming, adopsi, konsultasi, hingga belanja barang peliharaan\nsemua jadi gampang buat kalian yang ada di sekitar Malang.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 12,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                // Buttons
                if (isMobile)
                  Column(
                    children: [
                      OutlinedButton(
                        onPressed: _showDemoVideo,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(200, 50),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('LIHAT VIDEO PROMOSIr', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          final Uri url = Uri.parse('download/PetPoint.apk');
                          if (!await launchUrl(url)) {
                            debugPrint('Could not launch $url');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(200, 50),
                          backgroundColor: const Color(0xFF4FC3F7), // Light Sky Blue
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.android, size: 20),
                            SizedBox(width: 8),
                            Text('UNDUH APLIKASI ANDROID', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: _showDemoVideo,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(150, 50),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24, width: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('LIHAT VIDEO PROMOSI', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          final Uri url = Uri.parse('download/PetPoint.apk');
                          if (!await launchUrl(url)) {
                            debugPrint('Could not launch $url');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(150, 50),
                          backgroundColor: const Color(0xFF4FC3F7), // Light Sky Blue
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.android, size: 20),
                            SizedBox(width: 8),
                            Text('UNDUH APLIKASI ANDROID', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 60),

          // 3D Curved Cards Mockup
          IgnorePointer(
            child: Transform.scale(
              scale: isMobile ? MediaQuery.of(context).size.width / 800 : 1.0,
              child: SizedBox(
                width: 800, // Fixed logical width for the 3D stack
                height: 350,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Far Left Card
                  Transform.translate(
                    offset: const Offset(-306, -13),
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(-0.3)
                        ..rotateZ(-0.05),
                      alignment: Alignment.center,
                      child: _buildMockupCard(
                        width: 135, height: 175, 
                        bgImageUrl: 'https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?q=80&w=300&auto=format&fit=crop',
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shower, size: 36, color: Colors.white),
                            SizedBox(height: 14),
                            Text('Layanan\nGrooming', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Mid Left Card
                  Transform.translate(
                    offset: const Offset(-171, 0),
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(-0.15),
                      alignment: Alignment.center,
                      child: _buildMockupCard(
                        width: 148, height: 189, 
                        bgImageUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?q=80&w=300&auto=format&fit=crop',
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hewan Adopsi', style: TextStyle(color: Colors.white70, fontSize: 8)),
                              SizedBox(height: 4),
                              Text('15+', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Far Right Card
                  Transform.translate(
                    offset: const Offset(306, -13),
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(0.3)
                        ..rotateZ(0.05),
                      alignment: Alignment.center,
                      child: _buildMockupCard(
                        width: 135, height: 175,
                        bgImageUrl: 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?q=80&w=300&auto=format&fit=crop',
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.medical_services, size: 36, color: Colors.white),
                            SizedBox(height: 14),
                            Text('Konsultasi\nTerkait Anabul', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Mid Right Card
                  Transform.translate(
                    offset: const Offset(171, 0),
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(0.15),
                      alignment: Alignment.center,
                      child: _buildMockupCard(
                        width: 148, height: 189, 
                        bgImageUrl: 'https://images.unsplash.com/photo-1573865526739-10659fec78a5?q=80&w=300&auto=format&fit=crop',
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Belanja Pakan &', style: TextStyle(color: Colors.white70, fontSize: 9)),
                              Text('Aksesoris Hewan', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              Text('Terlengkap!', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Center Focus Card
                  Transform.translate(
                    offset: const Offset(0, 13),
                    child: _buildMockupCard(
                      width: 175, height: 216, 
                      isGlass: true,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'lib/assets/img/1776076564947.png',
                            height: 80,
                            width: 80,
                          ),
                          const SizedBox(height: 16),
                          const Text('Pet Point', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          const Text('Ekosistem Anabulmu', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
          
          // Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Dipercaya oleh Pet Lovers Malang', style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
              const SizedBox(width: 12),
              Row(
                children: List.generate(5, (index) => const Icon(Icons.star, color: Color(0xFFC6FF00), size: 16)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMockupCard({required double width, required double height, Color? color, Gradient? gradient, String? bgImageUrl, bool isGlass = false, required Widget child}) {
    Widget cardContent = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isGlass ? Colors.white.withOpacity(0.05) : color,
        gradient: isGlass ? null : gradient,
        border: isGlass ? Border.all(color: Colors.white.withOpacity(0.2), width: 1.5) : null,
        image: bgImageUrl != null ? DecorationImage(
          image: NetworkImage(bgImageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
        ) : null,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isGlass) BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          if (!isGlass) BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );

    if (isGlass) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        // Removed BackdropFilter to fix extreme lag on mobile CanvasKit
        child: Container(
          color: Colors.white.withValues(alpha: 0.05),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  Widget _buildAboutSection(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    return Container(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 80, horizontal: isMobile ? 16 : 24),
      color: Colors.white,
      child: Column(
        children: [
          const Text('• MENGAPA PET POINT?', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Text(
              'Satu aplikasi untuk seluruh kebutuhan anabul kesayanganmu.\nMulai dari Adopsi, grooming, hingga belanja keperluan Anabul.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: isMobile ? 24 : 42, fontWeight: FontWeight.w400, color: Colors.black, height: 1.3, letterSpacing: -1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppDemoSection(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 80, horizontal: 16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          const Text('• PREVIEW APLIKASI', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 16),
          Text('Lihat Aplikasi Pet Point Beraksi', 
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isMobile ? 28 : 36, fontWeight: FontWeight.bold, color: Colors.black)),
          SizedBox(height: isMobile ? 30 : 60),
          // Realistic Android Frame
          Transform.scale(
            scale: isMobile ? (MediaQuery.of(context).size.width / 400).clamp(0.5, 1.0) : 1.0,
            child: Container(
            width: 315,
            height: 700,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), // Phone Bezel Color
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF444444),
                width: 3,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0), // Bezel thickness
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Auto-playing Video Demo
                    const _AutoPlayVideoDemo(),
                    
                    // Top Notch (Poni Kamera)
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 130,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ), // Closing Transform.scale
        ],
      ),
    );
  }

  Widget _buildTeamGrid(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    final List<Map<String, dynamic>> teamMembers = [
      {
        'name': 'Pranata Putrandana',
        'role': 'Lead Developer',
        'color': const Color(0xFF1E88E5), // Blue
        'textColor': Colors.white,
        'image': 'lib/assets/img/team_1.jpg',
      },
      {
        'name': 'Muh. Zaky Dawamul B.',
        'role': 'Developer',
        'color': const Color(0xFFF5F5F5), // Light Grey
        'textColor': Colors.black,
        'image': 'lib/assets/img/team_2.png',
      },
      {
        'name': 'Bunga Aulia Sari',
        'role': 'Developer',
        'color': const Color(0xFFC6FF00), // Lime Green
        'textColor': Colors.black,
        'image': 'lib/assets/img/team_3.png',
      },
      {
        'name': 'Khoirun Nisa Fitriani',
        'role': 'Developer',
        'color': const Color(0xFF1E1E1E), // Dark
        'textColor': Colors.white,
        'image': 'lib/assets/img/team_4.jpeg',
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 50, vertical: 40),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Text('MEET THE TEAM', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              Wrap(
                spacing: isMobile ? 16 : 24,
                runSpacing: isMobile ? 16 : 24,
                children: teamMembers.map((member) => _buildTeamCard(member, context)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> data, BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    double spacing = isMobile ? 16 : 24;
    double horizontalPadding = isMobile ? 40 : 100; // 20 * 2 for mobile grid padding
    double cardWidth = isMobile ? (MediaQuery.of(context).size.width - horizontalPadding - spacing) / 2 : 275;

    return Container(
      width: cardWidth,
      height: isMobile ? 240 : 350,
      decoration: BoxDecoration(
        color: data['color'],
        borderRadius: BorderRadius.circular(isMobile ? 20 : 32),
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!isMobile)
                Text('TIM DEVELOPER', style: TextStyle(color: data['textColor'].withValues(alpha: 0.5), fontWeight: FontWeight.bold, letterSpacing: 1)),
              if (isMobile)
                Expanded(child: Text('TIM DEV', style: TextStyle(color: data['textColor'].withValues(alpha: 0.5), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1))),
              Icon(Icons.bar_chart, color: data['textColor'], size: isMobile ? 18 : 24),
            ],
          ),
          const Spacer(),
          // Placeholder for the team member image
          Center(
            child: CircleAvatar(
              radius: isMobile ? 35 : 50,
              backgroundColor: data['textColor'].withValues(alpha: 0.1),
              backgroundImage: AssetImage(data['image']),
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          SizedBox(
            height: isMobile ? 36 : 56, // Fixed height to enforce 2 lines exactly
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                data['name'],
                style: TextStyle(
                  color: data['textColor'],
                  fontSize: isMobile ? 16 : 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(height: isMobile ? 4 : 8),
          SizedBox(
            height: isMobile ? 28 : 36, // Fixed height to enforce 2 lines exactly
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                data['role'],
                style: TextStyle(
                  color: data['textColor'].withValues(alpha: 0.7),
                  fontSize: isMobile ? 11 : 14,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: isMobile ? 20 : 50),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const Divider(color: Colors.black12),
              const SizedBox(height: 40),
              isMobile 
              ? Column(
                  children: [
                    const Text(
                      '© 2026 Aplikasi Pet Point Malang. Hak Cipta Dilindungi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: const Text('Kebijakan Privasi', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Syarat & Ketentuan', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  ]
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '© 2026 Aplikasi Pet Point Malang. Hak Cipta Dilindungi.',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: const Text('Kebijakan Privasi', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Syarat & Ketentuan', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AutoPlayVideoDemo extends StatefulWidget {
  const _AutoPlayVideoDemo();

  @override
  State<_AutoPlayVideoDemo> createState() => _AutoPlayVideoDemoState();
}

class _AutoPlayVideoDemoState extends State<_AutoPlayVideoDemo> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Video demo aplikasi Pet Point
    _controller = VideoPlayerController.asset('lib/assets/video/demo_app.mp4')
      ..initialize().then((_) {
        _controller.setLooping(true);
        _controller.setVolume(0); // Harus di-mute agar bisa auto-play di Web
        _controller.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          )
        : Container(
            color: const Color(0xFFF0F4F8),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          );
  }
}
