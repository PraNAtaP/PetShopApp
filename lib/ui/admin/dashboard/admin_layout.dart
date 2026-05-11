import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/services/auth_service.dart';
import '../management/management_screen.dart';
import '../profile/admin_profile_screen.dart';
import '../grooming/booking_management_screen.dart';
import '../adoption/admin_adoption_management_screen.dart';
import '../chat/admin_chat_list_screen.dart';
import 'package:petshopapp/ui/admin/funfact/admin_funfact_screen.dart';
import '../shop/order_management_screen.dart';

import 'package:petshopapp/services/in_app_chat_notifier.dart';

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

    if (user == null || user.role.value != 'admin') {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Replace these placeholders with actual Admin screens
    final List<Widget> _adminScreens = [
      const Center(child: Text("Dashboard Overview", style: TextStyle(fontSize: 24))),
      const ManagementScreen(),       // Manage/View Inventory, Users, etc.
      const OrderManagementScreen(),  // Kelola Pesanan (Shop)
      const BookingManagementScreen(), // Grooming Bookings
      const AdminAdoptionManagementScreen(), // Adoptions Management
      const AdminChatListScreen(),    // Chat with Customers
      const AdminProfileScreen(),     // Admin Profile
       AdminFunFactScreen(),     // Admin FunFact
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Point Admin Dashboard'),
        actions: [
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
                  backgroundColor: AppColors.cardBackground,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  extended: true,
                  leading: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
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
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profile'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.tips_and_updates_outlined),
                      selectedIcon: Icon(Icons.tips_and_updates),
                      label: Text('FunFact'),
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
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profile'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.tips_and_updates_outlined),
                      selectedIcon: Icon(Icons.tips_and_updates),
                      label: Text('FunFact'),
                    ),
                  ],
                ),
              const VerticalDivider(thickness: 1, width: 1),
              // Main content panel
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
