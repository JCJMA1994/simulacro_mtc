import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../balotario/presentation/screens/balotario_screen.dart';
import '../../../history/presentation/screens/history_screen.dart';
import '../../../requisitos/presentation/screens/requisitos_screen.dart';
import '../../../simulacro/presentation/screens/catalog_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _irARequisitos() {
    setState(() {
      _currentIndex = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      CatalogScreen(
        onOpenRequirements: _irARequisitos,
      ),
      const BalotarioScreen(),
      const HistoryScreen(),
      const RequisitosScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            backgroundColor: AppColors.surface,
            elevation: 0,
            indicatorColor: const Color(0xFFE0EDFF),
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.quiz_outlined, color: AppColors.textSecondary),
                selectedIcon: Icon(Icons.quiz_rounded, color: Color(0xFF0F52BA)),
                label: 'Simulacro',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined, color: AppColors.textSecondary),
                selectedIcon: Icon(Icons.menu_book_rounded, color: Color(0xFF0F52BA)),
                label: 'Balotario',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined, color: AppColors.textSecondary),
                selectedIcon: Icon(Icons.insights_rounded, color: Color(0xFF0F52BA)),
                label: 'Historial',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined, color: AppColors.textSecondary),
                selectedIcon: Icon(Icons.assignment_rounded, color: Color(0xFF0F52BA)),
                label: 'Trámites',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
