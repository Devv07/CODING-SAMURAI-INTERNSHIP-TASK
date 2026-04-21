import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/product_card.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch products from backend on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showSortSheet(BuildContext context, ProductProvider pp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        const options = [
          ('default',    'Default'),
          ('price_asc',  'Price: Low to High'),
          ('price_desc', 'Price: High to Low'),
          ('rating',     'Top Rated'),
        ];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('SORT BY', style: AppTextStyles.caption),
                ),
              ),
              ...options.map((o) => ListTile(
                title: Text(o.$2, style: const TextStyle(fontSize: 15)),
                trailing: pp.sortBy == o.$1
                    ? const Icon(Icons.check, color: AppColors.primary, size: 18)
                    : null,
                onTap: () {
                  pp.setSortBy(o.$1);
                  Navigator.pop(context);
                },
              )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MAISON'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => showDialog(
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
                      await auth.logout();
                    },
                    child: const Text('Sign Out',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ),
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, pp, _) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('New Collection', style: AppTextStyles.displayLarge),
                      const SizedBox(height: 4),
                      const Text(
                        'Curated essentials for the modern wardrobe',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: pp.setSearch,
                              decoration: const InputDecoration(
                                hintText: 'Search products…',
                                prefixIcon: Icon(Icons.search,
                                    color: AppColors.muted, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _showSortSheet(context, pp),
                            child: Container(
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.tune_rounded, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: ProductProvider.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = ProductProvider.categories[i];
                      final active = pp.selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => pp.setCategory(cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : AppColors.surface,
                            border: Border.all(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Center(
                            child: Text(
                              cat.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.2,
                                fontWeight: active
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                color: active
                                    ? Colors.white
                                    : AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              if (pp.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )

              else if (pp.hasError)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 48, color: AppColors.muted),
                        const SizedBox(height: 12),
                        Text(pp.error,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 14),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: pp.fetchProducts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )

              else if (pp.filteredProducts.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 48, color: AppColors.muted),
                          SizedBox(height: 12),
                          Text('No products found',
                              style: TextStyle(color: AppColors.muted)),
                        ],
                      ),
                    ),
                  )

                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                            (_, i) => ProductCard(
                          product: pp.filteredProducts[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(
                                product: pp.filteredProducts[i],
                              ),
                            ),
                          ),
                        ),
                        childCount: pp.filteredProducts.length,
                      ),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.68,
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
