import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/cart_provider.dart';
import '../../utils/app_theme.dart';
import '../orders/orders_screen.dart';
import '../admin/admin_product_screen.dart';
import '../wishlist/wishlist_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final orderCount = context.watch<OrderProvider>().orders.length;
    final wishlistCount = context.watch<WishlistProvider>().count;

    final initials = user.name.trim().split(' ').map((w) => w[0].toUpperCase()).take(2).join();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('PROFILE'), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              color: AppColors.surface,
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4C5B0),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B5B45),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(user.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 14)),
                  const SizedBox(height: 20),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatBadge(count: orderCount, label: 'Orders'),
                      Container(width: 1, height: 36, color: AppColors.border),
                      _StatBadge(count: wishlistCount, label: 'Saved'),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            _Section(
              title: 'MY ACCOUNT',
              items: [
                _MenuItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'My Orders',
                  badge: orderCount > 0 ? '$orderCount' : null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  ),
                ),
                _MenuItem(
                  icon: Icons.favorite_border_rounded,
                  label: 'Wishlist',
                  badge: wishlistCount > 0 ? '$wishlistCount' : null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WishlistScreen()),
                  ),
                ),
                _MenuItem(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Manage Products (Admin)',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminProductScreen()),
                  ),
                ),
                _MenuItem(
                  icon: Icons.location_on_outlined,
                  label: 'Saved Addresses',
                  onTap: () => _showComingSoon(context),
                ),
                _MenuItem(
                  icon: Icons.credit_card_outlined,
                  label: 'Payment Methods',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _Section(
              title: 'PREFERENCES',
              items: [
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () => _showComingSoon(context),
                ),
                _MenuItem(
                  icon: Icons.lock_outline_rounded,
                  label: 'Privacy & Security',
                  onTap: () => _showComingSoon(context),
                ),
                _MenuItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout_rounded,
                      color: AppColors.error, size: 22),
                  title: const Text('Sign Out',
                      style: TextStyle(color: AppColors.error, fontSize: 15)),
                  onTap: () => _confirmLogout(context),
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Text('v1.0.0',
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Coming soon!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              context.read<CartProvider>().clearCart();
              context.read<WishlistProvider>().clear();
              await context.read<AuthProvider>().logout();
            },
            child: const Text('Sign Out',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final int count;
  final String label;
  const _StatBadge({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count',
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                fontFamily: 'Georgia')),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(title, style: AppTextStyles.caption),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(items.length * 2 - 1, (i) {
                if (i.isOdd) {
                  return const Divider(
                      height: 1, indent: 52, color: AppColors.border);
                }
                return items[i ~/ 2];
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(badge!,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600)),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.muted, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }
}
