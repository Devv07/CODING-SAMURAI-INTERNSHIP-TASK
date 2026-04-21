import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import '../../utils/app_theme.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('MY ORDERS'), centerTitle: true),
      body: Consumer<OrderProvider>(
        builder: (_, op, __) {
          if (op.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            );
          }
          if (op.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 48, color: AppColors.muted),
                  const SizedBox(height: 12),
                  Text(op.error,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 14),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: op.fetchOrders,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (!op.hasOrders) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.receipt_long_outlined,
                        size: 40, color: AppColors.muted),
                  ),
                  const SizedBox(height: 20),
                  const Text('No orders yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  const Text('Your completed orders will appear here',
                      style: TextStyle(color: AppColors.muted, fontSize: 14)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: op.orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _OrderCard(order: op.orders[i]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.processing: return const Color(0xFFE67E22);
      case OrderStatus.shipped:    return const Color(0xFF2980B9);
      case OrderStatus.delivered:  return AppColors.success;
      case OrderStatus.cancelled:  return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final o           = widget.order;
    final statusColor = _statusColor(o.status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.id,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(_formatDate(o.createdAt),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${o.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(o.statusLabel,
                        style: TextStyle(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: AppColors.muted,
              ),
            ]),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: AppColors.border),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(o.shippingAddress,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted)),
                  ),
                ]),
                if (o.status == OrderStatus.processing) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final ok = await context
                          .read<OrderProvider>()
                          .cancelOrder(o.id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? 'Order cancelled'
                              : 'Could not cancel order'),
                          backgroundColor: ok
                              ? AppColors.primary
                              : AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.error),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Cancel Order',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ]),
    );
  }

  String _formatDate(DateTime dt) {
    const m = ['','Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month]} ${dt.day}, ${dt.year}';
  }
}
