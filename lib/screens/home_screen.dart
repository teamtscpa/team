import 'package:flutter/material.dart';

import '../main.dart';
import 'chats_tab.dart';
import 'contacts_tab.dart';
import 'me_tab.dart';
import 'nearby_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Start the mesh as soon as the app has a profile.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.of(context).mesh.start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mesh = AppScope.of(context).mesh;
    final tabs = const [NearbyTab(), ChatsTab(), ContactsTab(), MeTab()];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: AnimatedBuilder(
        animation: mesh,
        builder: (_, __) => NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            NavigationDestination(
              icon: Badge(
                isLabelVisible: mesh.connectedPeers.isNotEmpty,
                label: Text('${mesh.connectedPeers.length}'),
                child: const Icon(Icons.radar_outlined),
              ),
              selectedIcon: const Icon(Icons.radar),
              label: 'Nearby',
            ),
            const NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Chats'),
            const NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Contacts'),
            const NavigationDestination(
                icon: Icon(Icons.badge_outlined),
                selectedIcon: Icon(Icons.badge),
                label: 'Me'),
          ],
        ),
      ),
    );
  }
}
