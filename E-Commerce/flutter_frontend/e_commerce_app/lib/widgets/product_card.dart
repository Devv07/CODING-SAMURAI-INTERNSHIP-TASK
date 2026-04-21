import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../utils/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  Color _parseColor(String hex) {
    return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final inCart = cart.contains(product.id);
    final inWishlist = wishlist.contains(product.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _parseColor(product.colorHex),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Center(child: Text(product.imageEmoji, style: const TextStyle(fontSize: 52))),
                  ),
                  if (product.tag != null)
                    Positioned(
                      top: 10, left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.tag == 'Sale' ? AppColors.tagSale : AppColors.tagNew,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(product.tag!.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                      ),
                    ),

                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => wishlist.toggle(product),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          inWishlist ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 16,
                          color: inWishlist ? Colors.red : AppColors.muted,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 10, right: 10,
                    child: GestureDetector(
                      onTap: () => cart.addItem(product),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: inCart ? AppColors.success : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8)],
                        ),
                        child: Icon(inCart ? Icons.check : Icons.add, size: 16, color: inCart ? Colors.white : AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(product.category.toUpperCase(),
                        style: const TextStyle(fontSize: 9, letterSpacing: 2, color: AppColors.muted, fontWeight: FontWeight.w300)),
                    Text(product.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('\$${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(fontFamily: 'Georgia', fontSize: 15, fontWeight: FontWeight.w600)),
                        Row(children: [
                          const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF4B942)),
                          const SizedBox(width: 2),
                          Text('${product.rating}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
