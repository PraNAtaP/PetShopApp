import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petshopapp/models/chat_room_model.dart';
import 'package:petshopapp/services/chat_service.dart';
import '../management/management_screen.dart';
import '../profile/admin_profile_screen.dart';
import '../grooming/booking_management_screen.dart'; // Menghapus typo 'q' di ujung import aslimu
import '../adoption/admin_adoption_management_screen.dart';
import '../chat/admin_chat_list_screen.dart';
import 'package:petshopapp/ui/admin/funfact/admin_funfact_screen.dart';
import '../shop/order_management_screen.dart';
import '../shop/admin_pos_screen.dart';
import 'admin_dashboard_screen.dart';

import 'package:petshopapp/services/in_app_chat_notifier.dart';
import 'package:petshopapp/services/web_notification/web_notification_service.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      InAppChatNotifier.instance.startListening(context);
    });
    WebNotificationService.instance.initialize();
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

    if (user == null || user.role.value != 'admin') {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final List<Widget> _adminScreens = [
      const AdminDashboardScreen(),
      const AdminPosScreen(),
      const ManagementScreen(),       
      const OrderManagementScreen(),  
      const BookingManagementScreen(), 
      const AdminAdoptionManagementScreen(), 
      const AdminChatListScreen(),    
      AdminFunFactScreen(),     
      const AdminProfileScreen(),     
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Point Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Aktifkan Notifikasi Browser',
            onPressed: () async {
              await WebNotificationService.instance.requestPermissionManually();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Permintaan izin notifikasi telah dikirim ke browser.')),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authService.logout();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;
          return Row(
            children: [
              if (isDesktop)
                NavigationRail(
                  backgroundColor: Colors.white,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  extended: true,
                  selectedIconTheme: const IconThemeData(
                    color: AppColors.primary,
                    size: 26,
                  ),
                  unselectedIconTheme: IconThemeData(
                    color: Colors.black.withValues(alpha: 0.54),
                  ),
                  useIndicator: true, 
                  indicatorColor: AppColors.primary.withValues(alpha: 0.08), 
                  indicatorShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minExtendedWidth: 250,
                  selectedLabelTextStyle: const TextStyle(
                    color: AppColors.primary, 
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    color: Colors.black.withValues(alpha: 0.65), 
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 26),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.point_of_sale_outlined),
                      selectedIcon: Icon(Icons.point_of_sale),
                      label: Text('Kasir'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(Icons.inventory_2),
                      label: Text('Inventory'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.shopping_bag_outlined),
                      selectedIcon: Icon(Icons.shopping_bag),
                      label: Text('Pesanan'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month),
                      label: Text('Grooming'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.pets_outlined),
                      selectedIcon: Icon(Icons.pets),
                      label: Text('Adopsi'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.chat_outlined),
                      selectedIcon: Icon(Icons.chat),
                      label: Text('Chat'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.tips_and_updates_outlined),
                      selectedIcon: Icon(Icons.tips_and_updates),
                      label: Text('FunFact'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profile'),
                    ),
                  ],
                )
              else
                NavigationRail(
                  backgroundColor: AppColors.cardBackground,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  extended: false,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.point_of_sale_outlined),
                      selectedIcon: Icon(Icons.point_of_sale),
                      label: Text('Kasir'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(Icons.inventory_2),
                      label: Text('Inventory'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.shopping_bag_outlined),
                      selectedIcon: Icon(Icons.shopping_bag),
                      label: Text('Pesanan'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month),
                      label: Text('Grooming'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.pets_outlined),
                      selectedIcon: Icon(Icons.pets),
                      label: Text('Adopsi'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.chat_outlined),
                      selectedIcon: Icon(Icons.chat),
                      label: Text('Chat'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.tips_and_updates_outlined),
                      selectedIcon: Icon(Icons.tips_and_updates),
                      label: Text('FunFact'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profile'),
                    ),
                  ],
                ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: _adminScreens[_selectedIndex],
              ),
            ],
          );
        },
      ),
    );
  }
}