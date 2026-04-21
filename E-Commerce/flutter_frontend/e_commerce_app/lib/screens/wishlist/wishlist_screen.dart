import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/cart_provider.dart';
import '../../utils/app_theme.dart';
import '../product/product_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('WISHLIST'),
        centerTitle: true,
      ),
      body: Consumer<WishlistProvider>(
        builder: (context, wishlist, _) {
          if (wishlist.items.isEmpty) {
            return _EmptyWishlist();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: wishlist.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final product = wishlist.items[i];
              final bgColor = Color(
                int.parse('FF${product.colorHex.replaceFirst('#', '')}', radix: 16),
              );
              return Dismissible(
                key: Key('wish_${product.id}'),
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
                onDismissed: (_) => wishlist.remove(product.id),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product),
                    ),
                  ),
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
                            color: bgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(product.imageEmoji,
                                style: const TextStyle(fontSize: 32)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name,
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text(product.category,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.muted)),
                              const SizedBox(height: 8),
                              Text(
                                '\$${product.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              onPressed: () => wishlist.remove(product.id),
                              icon: const Icon(Icons.favorite_rounded,
                                  color: Colors.red, size: 20),
                            ),
                            GestureDetector(
                              onTap: () {
                                context.read<CartProvider>().addItem(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.name} added to bag'),
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Add',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyWishlist extends StatelessWidget {
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
            child: const Icon(Icons.favorite_border_rounded,
                size: 40, color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          const Text('No saved items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('Tap ♡ on any product to save it here',
              style: TextStyle(color: AppColors.muted, fontSize: 14)),
        ],
      ),
    );
  }
}
