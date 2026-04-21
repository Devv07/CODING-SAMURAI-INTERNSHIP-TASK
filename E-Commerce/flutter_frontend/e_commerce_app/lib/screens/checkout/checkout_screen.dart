import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import '../../utils/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  int    _step           = 0; // 0=Address 1=Payment 2=Confirmation
  String _paymentMethod  = 'card';
  bool   _isPlacing      = false;
  String _apiError       = '';

  final _nameCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl   = TextEditingController();
  final _zipCtrl    = TextEditingController();
  final _cardNumCtrl = TextEditingController();
  final _expiryCtrl  = TextEditingController();
  final _cvvCtrl     = TextEditingController();

  Order? _placedOrder;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _phoneCtrl, _streetCtrl, _cityCtrl, _zipCtrl,
      _cardNumCtrl, _expiryCtrl, _cvvCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _placeOrder() async {
    setState(() { _isPlacing = true; _apiError = ''; });

    final cart          = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();
    final address = '${_nameCtrl.text}, ${_streetCtrl.text}, '
        '${_cityCtrl.text} ${_zipCtrl.text}';

    final order = await orderProvider.placeOrder(
      items:           cart.itemList,
      shippingAddress: address,
      paymentMethod:   _paymentMethod,
    );

    if (!mounted) return;

    if (order != null) {
      cart.clearCart();
      setState(() { _placedOrder = order; _isPlacing = false; _step = 2; });
    } else {
      setState(() {
        _isPlacing = false;
        _apiError  = orderProvider.error.isNotEmpty
            ? orderProvider.error
            : 'Failed to place order. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _step < 2
          ? AppBar(title: const Text('CHECKOUT'), centerTitle: true)
          : null,
      body: _step == 2 ? _buildConfirmation() : _buildCheckoutFlow(),
    );
  }

  Widget _buildCheckoutFlow() {
    return Column(
      children: [
        _StepIndicator(currentStep: _step),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: _step == 0 ? _buildAddressForm() : _buildPaymentForm(),
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildAddressForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DELIVERY ADDRESS', style: AppTextStyles.caption),
        const SizedBox(height: 16),
        _field(_nameCtrl,   'Full Name',       TextInputType.name),
        const SizedBox(height: 12),
        _field(_phoneCtrl,  'Phone Number',    TextInputType.phone),
        const SizedBox(height: 12),
        _field(_streetCtrl, 'Street Address',  TextInputType.streetAddress),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _field(_cityCtrl, 'City', TextInputType.text)),
          const SizedBox(width: 12),
          SizedBox(width: 120,
              child: _field(_zipCtrl, 'ZIP Code', TextInputType.number)),
        ]),
        const SizedBox(height: 24),
        const Text('DELIVERY METHOD', style: AppTextStyles.caption),
        const SizedBox(height: 12),
        _DeliveryOption(
          title: 'Standard Shipping', subtitle: '5–7 business days',
          price: 'Free on orders over \$200',
          icon: Icons.local_shipping_outlined, selected: true, onTap: () {},
        ),
        const SizedBox(height: 8),
        _DeliveryOption(
          title: 'Express Shipping', subtitle: '2–3 business days',
          price: '\$19.00',
          icon: Icons.flash_on_rounded, selected: false, onTap: () {},
        ),
      ],
    );
  }

  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PAYMENT METHOD', style: AppTextStyles.caption),
        const SizedBox(height: 16),
        _PaymentOption(label: 'Credit / Debit Card',
            icon: Icons.credit_card_rounded,    value: 'card',
            groupValue: _paymentMethod, onChanged: (v) => setState(() => _paymentMethod = v!)),
        const SizedBox(height: 8),
        _PaymentOption(label: 'Apple Pay',
            icon: Icons.phone_iphone_rounded,   value: 'apple',
            groupValue: _paymentMethod, onChanged: (v) => setState(() => _paymentMethod = v!)),
        const SizedBox(height: 8),
        _PaymentOption(label: 'PayPal',
            icon: Icons.account_balance_wallet_outlined, value: 'paypal',
            groupValue: _paymentMethod, onChanged: (v) => setState(() => _paymentMethod = v!)),
        if (_paymentMethod == 'card') ...[
          const SizedBox(height: 24),
          const Text('CARD DETAILS', style: AppTextStyles.caption),
          const SizedBox(height: 16),
          _field(_cardNumCtrl, 'Card Number', TextInputType.number, maxLen: 16),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field(_expiryCtrl, 'MM/YY', TextInputType.number, maxLen: 5)),
            const SizedBox(width: 12),
            SizedBox(width: 100,
                child: _field(_cvvCtrl, 'CVV', TextInputType.number, maxLen: 3)),
          ]),
        ],
        const SizedBox(height: 24),
        const Text('ORDER SUMMARY', style: AppTextStyles.caption),
        const SizedBox(height: 12),
        Consumer<CartProvider>(
          builder: (_, cart, __) {
            final shipping = cart.totalPrice >= 200 ? 0.0 : 12.0;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: [
                _SummaryRow('Items (${cart.itemCount})',
                    '\$${cart.totalPrice.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                _SummaryRow('Shipping',
                    shipping == 0 ? 'Free' : '\$${shipping.toStringAsFixed(2)}'),
                const Divider(color: AppColors.border, height: 20),
                _SummaryRow('Total',
                    '\$${(cart.totalPrice + shipping).toStringAsFixed(2)}',
                    bold: true),
              ]),
            );
          },
        ),

        if (_apiError.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF2F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_apiError,
                  style: const TextStyle(fontSize: 13, color: AppColors.error))),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar() {
    return Consumer<CartProvider>(
      builder: (_, cart, __) {
        final shipping = cart.totalPrice >= 200 ? 0.0 : 12.0;
        final total    = cart.totalPrice + shipping;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
                Text('\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 22,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: _isPlacing ? null : () {
                  if (_step == 0) {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _step = 1);
                    }
                  } else {
                    if (_paymentMethod == 'card' &&
                        !_formKey.currentState!.validate()) return;
                    _placeOrder();
                  }
                },
                child: _isPlacing
                    ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : Text(_step == 0
                    ? 'Continue to Payment'
                    : 'Place Order'),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildConfirmation() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          const Spacer(),
          Container(
            width: 100, height: 100,
            decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded,
                color: AppColors.success, size: 52),
          ),
          const SizedBox(height: 28),
          const Text('Order Placed!',
              style: TextStyle(fontFamily: 'Georgia',
                  fontSize: 32, fontWeight: FontWeight.w400)),
          const SizedBox(height: 12),
          Text(_placedOrder?.id ?? '',
              style: const TextStyle(color: AppColors.muted, fontSize: 14)),
          const SizedBox(height: 16),
          Text(
            'Your order has been confirmed and will be\ndelivered to '
                '${_placedOrder?.shippingAddress.split(',').first ?? 'your address'}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.6),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              _ConfirmRow(Icons.receipt_outlined,
                  'Order ID', _placedOrder?.id ?? ''),
              const Divider(color: AppColors.border, height: 20),
              _ConfirmRow(Icons.payments_outlined, 'Total',
                  '\$${_placedOrder?.total.toStringAsFixed(2) ?? '0'}'),
              const Divider(color: AppColors.border, height: 20),
              _ConfirmRow(Icons.local_shipping_outlined, 'Status',
                  _placedOrder?.statusLabel ?? 'Processing'),
            ]),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Continue Shopping'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint,
      TextInputType type, {int? maxLen}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLength: maxLen,
      decoration: InputDecoration(hintText: hint, counterText: ''),
      validator: (v) =>
      v == null || v.trim().isEmpty ? 'Required' : null,
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const steps = ['Address', 'Payment', 'Confirm'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: AppColors.surface,
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 1,
                color: i ~/ 2 < currentStep
                    ? AppColors.primary
                    : AppColors.border,
              ),
            );
          }
          final idx    = i ~/ 2;
          final done   = idx < currentStep;
          final active = idx == currentStep;
          return Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done || active
                    ? AppColors.primary
                    : AppColors.surface,
                border: Border.all(
                  color: done || active
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text('${idx + 1}',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500,
                      color: active ? Colors.white : AppColors.muted,
                    )),
              ),
            ),
            const SizedBox(height: 4),
            Text(steps[idx],
                style: TextStyle(
                  fontSize: 10, letterSpacing: 0.5,
                  color: active ? AppColors.primary : AppColors.muted,
                  fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                )),
          ]);
        }),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label, value, groupValue;
  final IconData icon;
  final ValueChanged<String?> onChanged;
  const _PaymentOption({required this.label, required this.icon,
    required this.value, required this.groupValue,
    required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(icon, size: 22,
              color: selected ? AppColors.primary : AppColors.muted),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w500 : FontWeight.w400)),
          const Spacer(),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: selected ? AppColors.primary : AppColors.muted, size: 18,
          ),
        ]),
      ),
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  final String title, subtitle, price;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _DeliveryOption({required this.title, required this.subtitle,
    required this.price, required this.icon,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(icon, size: 22, color: AppColors.muted),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
              Text(subtitle, style: const TextStyle(
                  fontSize: 12, color: AppColors.muted)),
            ],
          )),
          Text(price, style: const TextStyle(
              fontSize: 13, color: AppColors.muted)),
        ]),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _SummaryRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
            fontSize: bold ? 15 : 14,
            fontWeight: bold ? FontWeight.w500 : FontWeight.w400,
            color: bold ? AppColors.primary : AppColors.muted)),
        Text(value, style: TextStyle(
            fontSize: bold ? 15 : 14,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            fontFamily: bold ? 'Georgia' : null)),
      ],
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _ConfirmRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.muted),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(
          fontSize: 13, color: AppColors.muted)),
      const Spacer(),
      Text(value, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500)),
    ]);
  }
}
