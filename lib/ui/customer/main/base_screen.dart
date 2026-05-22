import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/services/auth_service.dart';
import '../chat/chat_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../shop/shop_screen.dart';

import 'package:petshopapp/services/in_app_chat_notifier.dart';

class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});

  static BaseScreenState? of(BuildContext context) => context.findAncestorStateOfType<BaseScreenState>();

  @override
  State<BaseScreen> createState() => BaseScreenState();
}

class BaseScreenState extends State<BaseScreen> {
  int _currentIndex = 0;

  void setTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // Start listening for in-app chat notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      InAppChatNotifier.instance.startListening(context);
    });
  }

  @override
  void dispose() {
    InAppChatNotifier.instance.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // KOREKSI 1: Sekarang hanya berisi 4 halaman utama saja
    final List<Widget> screens = const [
      HomeScreen(),
      ShopScreen(),
      ChatScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), // Dikembalikan ke padding 20 yang lega
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // MENU 1: HOME (Index 0)
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
              ),
              
              // MENU 2: SHOP (Index 1)
              _buildNavItem(
                index: 1,
                icon: Icons.storefront_outlined,
                activeIcon: Icons.storefront_rounded,
                label: 'Shop',
              ),
              
              // MENU 3: CHAT DENGAN REAL-TIME UNREAD BADGE (Index 2)
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 2),
                behavior: HitTestBehavior.opaque,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chat_rooms')
                      .where('participants', arrayContains: user.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int unreadCountTotal = 0;
                    
                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        unreadCountTotal += (data['userUnreadCount'] as int? ?? 0);
                      }
                    }

                    final isSelected = _currentIndex == 2;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected ? 12 : 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                isSelected ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
                                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                                size: isSelected ? 24 : 22,
                              ),
                              if (unreadCountTotal > 0)
                                Positioned(
                                  right: -6,
                                  top: -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      '$unreadCountTotal',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chat',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // MENU 4: PROFILE (Index 3)
              _buildNavItem(
                index: 3,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
              size: isSelected ? 24 : 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}