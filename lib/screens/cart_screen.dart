import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../models/cart_item.dart';

/// WEEK 3 — Cart Screen
/// Displays all cart items with quantity controls, subtotal, and checkout.
class CartScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final Function(List<CartItem>)? onCartUpdated;

  const CartScreen({
    super.key,
    required this.cartItems,
    this.onCartUpdated,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<CartItem> _items;

  // Pricing constants
  static const double _deliveryFee = 150.0;
  static const double _freeDeliveryThreshold = 1500.0;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.cartItems);
  }

  double get _subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get _effectiveDeliveryFee =>
      _subtotal >= _freeDeliveryThreshold ? 0.0 : _deliveryFee;

  double get _total => _subtotal + _effectiveDeliveryFee;

  void _increment(int index) {
    setState(() {
      _items[index].increment();
      widget.onCartUpdated?.call(_items);
    });
  }

  void _decrement(int index) {
    if (_items[index].quantity == 1) {
      _removeItem(index);
    } else {
      setState(() {
        _items[index].decrement();
        widget.onCartUpdated?.call(_items);
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      widget.onCartUpdated?.call(_items);
    });
  }

  void _checkout() {
    Navigator.pushReplacementNamed(
        context, AppConstants.routeOrderConfirmation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Cart'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _items.clear();
                  widget.onCartUpdated?.call(_items);
                });
              },
              child: const Text('Clear All',
                  style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
      body: _items.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                // ── Cart Items List ─────────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppConstants.padding),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Dismissible(
                        key: Key('cart_item_${item.product.id}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _removeItem(index),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: AppColors.error, size: 28),
                        ),
                        child: _buildCartItem(item, index),
                      );
                    },
                  ),
                ),

                // ── Order Summary ───────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 20,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Subtotal', 'KSh ${_subtotal.toStringAsFixed(0)}'),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'Delivery Fee',
                        _effectiveDeliveryFee == 0
                            ? 'FREE 🎉'
                            : 'KSh ${_effectiveDeliveryFee.toStringAsFixed(0)}',
                        valueColor: _effectiveDeliveryFee == 0
                            ? AppColors.success
                            : null,
                      ),
                      if (_subtotal < _freeDeliveryThreshold) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Add KSh ${(_freeDeliveryThreshold - _subtotal).toStringAsFixed(0)} more for free delivery',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.accent),
                        ),
                      ],
                      const Divider(height: 24, color: AppColors.divider),
                      _buildSummaryRow(
                        'Total',
                        'KSh ${_total.toStringAsFixed(0)}',
                        isBold: true,
                        valueColor: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _checkout,
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 18),
                          ),
                          child: const Text('Proceed to Checkout',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCartItem(CartItem item, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product emoji
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                item.product.imageEmoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'KSh ${item.product.price.toStringAsFixed(0)} / ${item.product.unit}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'KSh ${item.totalPrice.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _decrement(index),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          item.quantity == 1
                              ? Icons.delete_outline
                              : Icons.remove,
                          size: 18,
                          color: item.quantity == 1
                              ? AppColors.error
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${item.quantity}',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    InkWell(
                      onTap: () => _increment(index),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.add,
                            size: 18, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    isBold ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight:
                    isBold ? FontWeight.w700 : FontWeight.w400,
                fontSize: isBold ? 16 : null,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                fontSize: isBold ? 18 : null,
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some fresh items to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }
}
