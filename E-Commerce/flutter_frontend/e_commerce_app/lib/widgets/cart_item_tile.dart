import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../utils/app_theme.dart';

class CartItemTile extends StatelessWidget {
  final CartItem cartItem;
  const CartItemTile({super.key, required this.cartItem});

  Color _parseColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final p = cartItem.product;

    return Dismissible(
      key: Key('cart_${p.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF2F2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      onDismissed: (_) => cart.removeItem(p.id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _parseColor(p.colorHex),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(p.imageEmoji,
                    style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.category,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _QtyControl(
                        onDec: () => cart.decrement(p.id),
                        onInc: () => cart.increment(p.id),
                        qty: cartItem.quantity,
                      ),
                      const Spacer(),
                      Text(
                        '\$${cartItem.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final VoidCallback onDec;
  final VoidCallback onInc;
  final int qty;

  const _QtyControl({
    required this.onDec,
    required this.onInc,
    required this.qty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(icon: Icons.remove, onTap: onDec),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$qty',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          _Btn(icon: Icons.add, onTap: onInc),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 14, color: AppColors.primary),
      ),
    );
  }
}
