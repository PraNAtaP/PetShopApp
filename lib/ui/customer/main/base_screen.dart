import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/services/auth_service.dart';
import '../chat/chat_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../shop/shop_screen.dart';
import '../grooming/grooming_service_screen.dart';
import '../adoption/adoption_catalog_screen.dart';


class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  int _currentIndex = 0;

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

    final List<Widget> screens = const [
      HomeScreen(),
      AdoptionCatalogScreen(),
      ShopScreen(),
      GroomingServiceScreen(),
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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.pets_outlined,
                activeIcon: Icons.pets,
                label: 'Adopsi',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.storefront_outlined,
                activeIcon: Icons.storefront_rounded,
                label: 'Shop',
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.wash_outlined,
                activeIcon: Icons.wash,
                label: 'Grooming',
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: 'Chat',
              ),
              _buildNavItem(
                index: 5,
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
          horizontal: isSelected ? 12 : 8, // Reduced padding to fit 6 items
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
              size: isSelected ? 24 : 22, // Slightly reduced icon size to fit 6 items
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
