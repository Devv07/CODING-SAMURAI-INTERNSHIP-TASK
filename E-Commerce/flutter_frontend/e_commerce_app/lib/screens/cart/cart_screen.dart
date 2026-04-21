import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../utils/app_theme.dart';
import '../checkout/checkout_screen.dart';
import '../../widgets/cart_item_tile.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('YOUR BAG'),
        centerTitle: true,
        actions: [
          Consumer<CartProvider>(
            builder: (_, cart, __) => cart.items.isEmpty
                ? const SizedBox.shrink()
                : TextButton(
              onPressed: () => _confirmClear(context, cart),
              child: const Text(
                'Clear',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) return const _EmptyCart();

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: cart.itemList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      CartItemTile(cartItem: cart.itemList[i]),
                ),
              ),
              _OrderSummary(cart: cart),
            ],
          );
        },
      ),
    );
  }

  void _confirmClear(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Bag?'),
        content: const Text('Remove all items from your bag?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cart.clearCart();
              Navigator.pop(context);
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 40,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your bag is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add some items to get started',
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final CartProvider cart;
  const _OrderSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.totalPrice;
    final shipping = subtotal >= 200 ? 0.0 : 12.0;
    final total = subtotal + shipping;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          _SummaryRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _SummaryRow(
            'Shipping',
            shipping == 0 ? 'Free' : '\$${shipping.toStringAsFixed(2)}',
            valueColor:
            shipping == 0 ? AppColors.success : AppColors.primary,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.border),
          ),
          _SummaryRow(
            'Total',
            '\$${total.toStringAsFixed(2)}',
            isBold: true,
            valueFontSize: 20,
            useSerif: true,
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CheckoutScreen(),
                ),
              ),
              child: const Text('Proceed to Checkout'),
            ),
          ),

          if (shipping > 0)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Add \$${(200 - subtotal).toStringAsFixed(0)} more for free shipping',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final double? valueFontSize;
  final bool useSerif;
  final Color? valueColor;

  const _SummaryRow(
      this.label,
      this.value, {
        this.isBold = false,
        this.valueFontSize,
        this.useSerif = false,
        this.valueColor,
      });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.w500 : FontWeight.w400,
            color: AppColors.primary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: valueFontSize ?? (isBold ? 15 : 14),
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            fontFamily: useSerif ? 'Georgia' : null,
            color: valueColor ?? AppColors.primary,
          ),
        ),
      ],
    );
  }
}
