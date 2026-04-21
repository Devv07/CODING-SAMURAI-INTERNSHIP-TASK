import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../utils/app_theme.dart';

class AdminProductScreen extends StatefulWidget {
  const AdminProductScreen({super.key});

  @override
  State<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchAllProductsAdmin();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MANAGE PRODUCTS'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      ),
      body: Consumer<ProductProvider>(
        builder: (_, pp, __) {
          if (pp.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            );
          }
          if (pp.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.muted),
                const SizedBox(height: 12),
                Text(pp.error,
                    style: const TextStyle(color: AppColors.muted),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: pp.fetchAllProductsAdmin,
                    child: const Text('Retry')),
              ]),
            );
          }
          if (pp.adminProducts.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 56, color: AppColors.muted),
                const SizedBox(height: 16),
                const Text('No products yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                const Text('Tap + to add your first product',
                    style: TextStyle(color: AppColors.muted)),
              ]),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: pp.adminProducts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _ProductTile(
              product: pp.adminProducts[i],
              onEdit:   () => _openForm(context, product: pp.adminProducts[i]),
              onToggle: () => pp.toggleProductActive(pp.adminProducts[i]),
              onDelete: () => _confirmDelete(context, pp.adminProducts[i], pp),
            ),
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, {Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProductForm(product: product),
    );
  }

  void _confirmDelete(
      BuildContext context, Product product, ProductProvider pp) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deactivate Product?'),
        content: Text(
          '"${product.name}" will be hidden from the catalogue. '
              'Existing orders are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await pp.deleteProduct(product.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok ? 'Product deactivated' : pp.error),
                backgroundColor: ok ? AppColors.primary : AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
            },
            child: const Text('Deactivate',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ProductTile({
    required this.product,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = Color(
        int.parse('FF${product.colorHex.replaceFirst('#', '')}', radix: 16));

    return Container(
      decoration: BoxDecoration(
        color: product.isActive ? AppColors.surface : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(product.imageEmoji,
                style: const TextStyle(fontSize: 24)),
          ),
        ),
        title: Text(
          product.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: product.isActive
                ? AppColors.primary
                : AppColors.muted,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${product.category}  •  \$${product.price.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            if (!product.isActive)
              const Text('INACTIVE',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppColors.error,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.muted),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: Icon(
                product.isActive
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: product.isActive ? AppColors.muted : AppColors.error,
              ),
              onPressed: onToggle,
              tooltip: product.isActive ? 'Deactivate' : 'Activate',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductForm extends StatefulWidget {
  final Product? product;
  const _ProductForm({this.product});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _emojiCtrl;
  late final TextEditingController _colorCtrl;
  String _category = 'Tops';
  String? _tag;

  static const _categories = [
    'Outerwear', 'Dresses', 'Footwear',
    'Tops', 'Bottoms', 'Accessories',
  ];
  static const _tags = [null, 'New', 'Bestseller', 'Sale'];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl  = TextEditingController(text: p?.name  ?? '');
    _priceCtrl = TextEditingController(text: p != null ? '${p.price}' : '');
    _descCtrl  = TextEditingController(text: p?.description ?? '');
    _emojiCtrl = TextEditingController(text: p?.imageEmoji  ?? '🛍');
    _colorCtrl = TextEditingController(text: p?.colorHex    ?? '#C5BFB0');
    _category  = p?.category ?? 'Tops';
    _tag       = p?.tag;
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _priceCtrl, _descCtrl, _emojiCtrl, _colorCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final pp = context.read<ProductProvider>();
    final body = {
      'name':        _nameCtrl.text.trim(),
      'price':       double.parse(_priceCtrl.text.trim()),
      'category':    _category,
      'description': _descCtrl.text.trim(),
      'imageEmoji':  _emojiCtrl.text.trim(),
      'colorHex':    _colorCtrl.text.trim(),
      'tag':         _tag,
    };

    bool ok;
    if (_isEditing) {
      ok = await pp.updateProduct(widget.product!.id, body);
    } else {
      ok = await pp.createProduct(body);
    }

    setState(() => _saving = false);
    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing ? 'Product updated' : 'Product added'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(pp.error),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                _isEditing ? 'Edit Product' : 'New Product',
                style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 22, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 20),

              // Name
              _label('PRODUCT NAME'),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(hintText: 'e.g. Linen Maxi Dress'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Price + Emoji row
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('PRICE (USD)'),
                      TextFormField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                            hintText: '0.00', prefixText: '\$ '),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('EMOJI ICON'),
                      TextFormField(
                        controller: _emojiCtrl,
                        decoration: const InputDecoration(hintText: '🛍'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 14),

              // Category dropdown
              _label('CATEGORY'),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(),
                items: _categories.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c),
                )).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 14),

              // Tag
              _label('TAG (optional)'),
              DropdownButtonFormField<String?>(
                value: _tag,
                decoration: const InputDecoration(),
                items: _tags.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t ?? 'None'),
                )).toList(),
                onChanged: (v) => setState(() => _tag = v),
              ),
              const SizedBox(height: 14),

              // Color hex
              _label('CARD BACKGROUND COLOR (hex)'),
              TextFormField(
                controller: _colorCtrl,
                decoration: const InputDecoration(hintText: '#C5BFB0'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(v)) {
                    return 'Must be a valid hex color e.g. #D4C5B0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Description
              _label('DESCRIPTION'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'Brief product description...'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : Text(_isEditing ? 'Save Changes' : 'Add Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: AppTextStyles.caption),
    );
  }
}
