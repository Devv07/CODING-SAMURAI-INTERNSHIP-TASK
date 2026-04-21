import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../product/product_list_screen.dart';
import '../cart/cart_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../profile/profile_screen.dart';
import '../../utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = const [
    ProductListScreen(),
    WishlistScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;
    final wishlistCount = context.watch<WishlistProvider>().count;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.muted,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Catalogue',
            ),
            BottomNavigationBarItem(
              icon: _BadgeIcon(icon: Icons.favorite_border_rounded, activeIcon: Icons.favorite_rounded, count: wishlistCount, active: _currentIndex == 1, badgeColor: Colors.red),
              label: 'Saved',
            ),
            BottomNavigationBarItem(
              icon: _BadgeIcon(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag_rounded, count: cartCount, active: _currentIndex == 2, badgeColor: AppColors.accent),
              label: 'Bag',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int count;
  final bool active;
  final Color badgeColor;

  const _BadgeIcon({required this.icon, required this.activeIcon, required this.count, required this.active, required this.badgeColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(active ? activeIcon : icon),
        if (count > 0)
          Positioned(
            top: -6,
            right: -8,
            child: Container(
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
              child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }
}
