import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'dart:math' as math;

class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _teamKey = GlobalKey();

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
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 50 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  @override
  void dispose() {
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
                _buildClientLogos(context),
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
    );
  }

  Widget _buildNavbar(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 50),
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
          ),
          
          // Center Nav Links (Hidden on small screens)
          if (MediaQuery.of(context).size.width > 800)
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
            onPressed: () => context.push('/login'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 50),
              backgroundColor: const Color(0xFFC6FF00), // Lime green accent
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: const Text(
              'MASUK ADMIN',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
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
      padding: const EdgeInsets.only(top: 150, bottom: 60),
      child: Column(
        children: [
          // Typography
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                const Text(
                  'Solusi All-in-One untuk\nAnabul Kesayanganmu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -1.5,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Mulai dari grooming, adopsi, konsultasi, hingga belanja barang peliharaan\nsemua jadi gampang buat kalian yang ada di sekitar Malang.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(150, 50),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24, width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('LIHAT DEMO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(150, 50),
                        backgroundColor: const Color(0xFFC6FF00),
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
                          Text('UNDUH APLIKASI', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_outward, size: 18),
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
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 350,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Far Left Card
                Transform.translate(
                  offset: const Offset(-450, -20),
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(-0.3)
                      ..rotateZ(-0.05),
                    alignment: Alignment.center,
                    child: _buildMockupCard(
                      width: 200, height: 260, color: Colors.white.withOpacity(0.9),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.healing, size: 40, color: Colors.blue),
                          SizedBox(height: 16),
                          Text('Klinik & Grooming', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                // Mid Left Card
                Transform.translate(
                  offset: const Offset(-250, 0),
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(-0.15),
                    alignment: Alignment.center,
                    child: _buildMockupCard(
                      width: 220, height: 280, color: Colors.white,
                      child: const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hewan Adopsi', style: TextStyle(color: Colors.grey)),
                            SizedBox(height: 8),
                            Text('500+', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                            Spacer(),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  label: Text('Kucing', style: TextStyle(fontSize: 12)),
                                  visualDensity: VisualDensity.compact,
                                ),
                                Chip(
                                  label: Text('Anjing', style: TextStyle(fontSize: 12)),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Far Right Card
                Transform.translate(
                  offset: const Offset(450, -20),
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(0.3)
                      ..rotateZ(0.05),
                    alignment: Alignment.center,
                    child: _buildMockupCard(
                      width: 200, height: 260, color: Colors.white.withOpacity(0.9),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.support_agent, size: 40, color: Colors.blue),
                          SizedBox(height: 16),
                          Text('Tanya Dokter', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                // Mid Right Card
                Transform.translate(
                  offset: const Offset(250, 0),
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(0.15),
                    alignment: Alignment.center,
                    child: _buildMockupCard(
                      width: 220, height: 280, color: const Color(0xFF1E1E1E),
                      child: const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Belanja Pakan &', style: TextStyle(color: Colors.white70, fontSize: 16)),
                            Text('Aksesoris Hewan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Terlengkap!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Center Focus Card
                Transform.translate(
                  offset: const Offset(0, 20),
                  child: _buildMockupCard(
                    width: 260, height: 320, 
                    color: const Color(0xFF2196F3).withValues(alpha: 0.85), // Glassy blue
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
                          child: Image.asset(
                            'lib/assets/img/1776076564947.png',
                            height: 60,
                            width: 60,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Pet Point', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Ekosistem Anabulmu', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

          const SizedBox(height: 40),
          
          // Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Dipercaya oleh 4.900+ Pet Lovers', style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
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

  Widget _buildMockupCard({required double width, required double height, required Color color, required Widget child}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: child,
      ),
    );
  }

  Widget _buildClientLogos(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      color: Colors.white,
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 40,
        runSpacing: 20,
        children: List.generate(5, (index) => 
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pets, color: Colors.grey.shade300, size: 24),
              const SizedBox(width: 8),
              Text('PetIpsum', style: TextStyle(color: Colors.grey.shade400, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          )
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      color: Colors.white,
      child: Column(
        children: [
          const Text('• TENTANG KAMI', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: const Text(
              'Partner terbaik untuk anabulmu\nyang bikin hidup lebih ✅ praktis\ndan 💡 menyenangkan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.w400, color: Colors.black, height: 1.2, letterSpacing: -1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppDemoSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          const Text('• PREVIEW APLIKASI', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 16),
          const Text('Lihat Aplikasi Pet Point Beraksi', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 60),
          // Realistic Android Frame
          Container(
            width: 320,
            height: 650,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), // Phone Bezel Color
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                  offset: const Offset(0, 20),
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
                    // Placeholder for the actual app demo GIF
                    Image.asset(
                      'assets/images/app_demo.gif',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFF0F4F8),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.gif_box_rounded, size: 64, color: Colors.blue),
                              const SizedBox(height: 12),
                              const Text(
                                'App Demo GIF',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                '(assets/images/app_demo.gif)',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Front Camera Punch-hole Notch
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.only(top: 14),
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E1E),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamGrid(BuildContext context) {
    final List<Map<String, dynamic>> teamMembers = [
      {
        'name': 'Pranata Putrandana',
        'role': 'Chief Executive Officer',
        'color': const Color(0xFF1E88E5), // Blue
        'textColor': Colors.white,
        'image': 'assets/images/team_1.png',
      },
      {
        'name': 'Muh. Zaky Dawamul B.',
        'role': 'Chief Technology Officer',
        'color': const Color(0xFFF5F5F5), // Light Grey
        'textColor': Colors.black,
        'image': 'assets/images/team_2.png',
      },
      {
        'name': 'Bunga Aulia Sari',
        'role': 'Chief Marketing Officer',
        'color': const Color(0xFFC6FF00), // Lime Green
        'textColor': Colors.black,
        'image': 'assets/images/team_3.png',
      },
      {
        'name': 'Khoirun Nisa Fitriani',
        'role': 'Chief Operating Officer',
        'color': const Color(0xFF1E1E1E), // Dark
        'textColor': Colors.white,
        'image': 'assets/images/team_4.png',
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
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
                spacing: 24,
                runSpacing: 24,
                children: teamMembers.map((member) => _buildTeamCard(member)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> data) {
    return Container(
      width: 275,
      height: 350,
      decoration: BoxDecoration(
        color: data['color'],
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TIM DEVELOPER', style: TextStyle(color: data['textColor'].withValues(alpha: 0.5), fontWeight: FontWeight.bold, letterSpacing: 1)),
              Icon(Icons.bar_chart, color: data['textColor']),
            ],
          ),
          const Spacer(),
          // Placeholder for the team member image
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: data['textColor'].withValues(alpha: 0.1),
              backgroundImage: AssetImage(data['image']),
              child: Icon(Icons.person, size: 50, color: data['textColor'].withValues(alpha: 0.5)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            data['name'],
            style: TextStyle(
              color: data['textColor'],
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['role'],
            style: TextStyle(
              color: data['textColor'].withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 50),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const Divider(color: Colors.black12),
              const SizedBox(height: 40),
              Row(
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
