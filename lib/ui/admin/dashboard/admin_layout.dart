import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/services/auth_service.dart';
import '../management/management_screen.dart'; // We should probably move management to inventory/dashboard etc, but let's just show it here.
import '../admin/add_pet_screen.dart'; // This is also an admin feature
import '../profile/admin_profile_screen.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

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
      const AddPetScreen(),           // Pet insertion
      const Center(child: Text("Adoption Requests Table", style: TextStyle(fontSize: 24))),
      const AdminProfileScreen(),     // Admin Profile
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
                      icon: Icon(Icons.pets_outlined),
                      selectedIcon: Icon(Icons.pets),
                      label: Text('Add Pet'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.assignment_ind_outlined),
                      selectedIcon: Icon(Icons.assignment_ind),
                      label: Text('Adoptions'),
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
                      icon: Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(Icons.inventory_2),
                      label: Text('Inventory'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.pets_outlined),
                      selectedIcon: Icon(Icons.pets),
                      label: Text('Add Pet'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.assignment_ind_outlined),
                      selectedIcon: Icon(Icons.assignment_ind),
                      label: Text('Adoptions'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profile'),
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
