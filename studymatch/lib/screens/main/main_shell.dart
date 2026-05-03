import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../services/app_state.dart';
import '../../services/message_service.dart';
import 'dashboard_screen.dart';
import 'match_screen.dart';
import 'messages_screen.dart';
import 'resources_screen.dart';
import 'profile_screen.dart';
import 'dart:async';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {

  Timer? _unreadTimer;
  int _unreadCount = 0;

  @override
void initState() {
  super.initState();
  _refreshUnread();
  _unreadTimer = Timer.periodic(
    const Duration(seconds: 5), (_) => _refreshUnread());
}

@override
void dispose() {
  _unreadTimer?.cancel();
  super.dispose();
}

Future<void> _refreshUnread() async {
  final count = await context.read<AppState>().fetchUnreadCount();
  if (mounted) setState(() => _unreadCount = count);
}
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    MatchScreen(),
    MessagesScreen(),
    ResourcesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.bgCard,
          border: Border(top: BorderSide(color: AppTheme.divider, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
          unselectedLabelStyle: const TextStyle(fontSize: 11, fontFamily: 'Poppins'),
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
            const BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), activeIcon: Icon(Icons.people_alt), label: 'Match'),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.chat_bubble_outline),
                  if (state.unreadMessageCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
                        child: Center(
                          child: Text('${state.unreadMessageCount}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: const Icon(Icons.chat_bubble),
              label: 'Messages',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined), activeIcon: Icon(Icons.library_books), label: 'Resources'),
            const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
