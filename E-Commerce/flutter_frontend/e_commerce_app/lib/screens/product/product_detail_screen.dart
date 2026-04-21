import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../utils/app_theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _addedToCart = false;

  Color _parseColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  void _addToCart(CartProvider cart) {
    for (int i = 0; i < _quantity; i++) {
      cart.addItem(widget.product);
    }
    setState(() => _addedToCart = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _addedToCart = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} added to bag'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Bag',
          textColor: AppColors.accent,
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final cart = context.watch<CartProvider>();
    final bgColor = _parseColor(p.colorHex);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            backgroundColor: bgColor,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.primary),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: bgColor,
                child: Center(
                  child: Text(p.imageEmoji,
                      style: const TextStyle(fontSize: 120)),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        p.category.toUpperCase(),
                        style: AppTextStyles.caption,
                      ),
                      if (p.tag != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.tag == 'Sale'
                                ? const Color(0xFFFDF2F2)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: p.tag == 'Sale'
                                  ? AppColors.tagSale
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            p.tag!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.5,
                              color: p.tag == 'Sale'
                                  ? AppColors.tagSale
                                  : AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(p.name, style: AppTextStyles.headlineMedium.copyWith(fontSize: 30)),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Text(
                        '\$${p.price.toStringAsFixed(0)}',
                        style: AppTextStyles.headlineMedium,
                      ),
                      const Spacer(),
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFF4B942), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${p.rating}  ·  ${p.reviews} reviews',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.muted),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 20),

                  const Text('ABOUT', style: AppTextStyles.caption),
                  const SizedBox(height: 8),
                  Text(p.description, style: AppTextStyles.bodyMedium),

                  const SizedBox(height: 32),

                  const Text('QUANTITY', style: AppTextStyles.caption),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _QtyBtn(
                        icon: Icons.remove,
                        onTap: () =>
                            setState(() => _quantity = (_quantity - 1).clamp(1, 99)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      ),
                      _QtyBtn(
                        icon: Icons.add,
                        onTap: () => setState(() => _quantity++),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: ElevatedButton(
                        onPressed: () => _addToCart(cart),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          _addedToCart ? AppColors.success : AppColors.primary,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _addedToCart
                                  ? Icons.check_rounded
                                  : Icons.shopping_bag_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _addedToCart ? 'Added to Bag!' : 'Add to Bag',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.local_shipping_outlined,
                            size: 18, color: AppColors.muted),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Free shipping on orders over \$200 · Easy 30-day returns',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.muted, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}
