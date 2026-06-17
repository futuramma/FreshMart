import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';

/// WEEK 2/3 — Home Screen
/// Main product listing screen with category filter, search, and cart.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _customerName = 'Customer';
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final List<CartItem> _cartItems = [];
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = SampleProducts.categories;
  final List<Product> _allProducts = SampleProducts.all;

  @override
  void initState() {
    super.initState();
    _loadCustomerName();
  }

  Future<void> _loadCustomerName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(AppConstants.keyCustomerName) ?? 'Customer';
    if (mounted) {
      setState(() {
        _customerName = name.split(' ').first;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filtered product list based on category and search
  List<Product> get _filteredProducts {
    return _allProducts.where((product) {
      final matchesCategory = _selectedCategory == 'All' ||
          product.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  /// Total items in cart
  int get _cartCount =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  /// Add product to cart or increment quantity
  void _addToCart(Product product) {
    setState(() {
      final existingIndex =
          _cartItems.indexWhere((item) => item.product.id == product.id);
      if (existingIndex >= 0) {
        _cartItems[existingIndex].increment();
      } else {
        _cartItems.add(CartItem(product: product));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: _goToCart,
        ),
      ),
    );
  }

  void _goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(
          cartItems: _cartItems,
          onCartUpdated: (updatedCart) {
            setState(() {
              _cartItems
                ..clear()
                ..addAll(updatedCart);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ───────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              automaticallyImplyLeading: false,
              expandedHeight: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(color: AppColors.background),
              ),
              title: null,
              toolbarHeight: 0,
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top Row ───────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $_customerName! 👋',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              Text(
                                'What would you like today?',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        // Cart icon with badge
                        GestureDetector(
                          onTap: _cartCount > 0 ? _goToCart : null,
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(
                                      AppConstants.borderRadius),
                                ),
                                child: const Icon(
                                  Icons.shopping_cart_outlined,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              if (_cartCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$_cartCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Profile icon
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                              context, AppConstants.routeProfile),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadius),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Search Bar ────────────────────────────
                    TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search groceries...',
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.textSecondary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: AppColors.textSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusLarge),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Promo Banner ──────────────────────────
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadiusLarge),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Fresh Deals Today!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Up to 30% off on fruits\n& vegetables',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: Colors.white.withOpacity(0.9)),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Shop Now',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text('🥦', style: TextStyle(fontSize: 72)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Integration & Operations Quick Access ───────
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pushNamed(
                                context, AppConstants.routeApiUsers),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadius),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadow,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.info.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.people_outline,
                                        color: AppColors.info, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('API Users',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                )),
                                        Text('User Directory',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontSize: 10,
                                                  color:
                                                      AppColors.textSecondary,
                                                )),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: AppColors.textHint, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pushNamed(
                                context, AppConstants.routeNetworkPosts),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadius),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadow,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.cloud_sync_outlined,
                                        color: AppColors.primary, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Posts Cache',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                )),
                                        Text('Offline Support',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontSize: 10,
                                                  color:
                                                      AppColors.textSecondary,
                                                )),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: AppColors.textHint, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Customer Log and Activity Quick Access ───────
                    Row(
                      children: [
                        _buildQuickCard(
                          context,
                          icon: Icons.people_outline,
                          color: const Color(0xFF7C3AED),
                          label: 'Customers',
                          sub: 'Manage Profiles',
                          route: AppConstants.routeCustomers,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickCard(
                          context,
                          icon: Icons.fact_check_outlined,
                          color: AppColors.success,
                          label: 'Visits Log',
                          sub: 'Daily Activity',
                          route: AppConstants.routeCustomerVisits,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickCard(
                          context,
                          icon: Icons.bar_chart_outlined,
                          color: AppColors.accent,
                          label: 'Visit Reports',
                          sub: 'View Analytics',
                          route: AppConstants.routeCustomerVisitReport,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Categories',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Category filter chips
            SliverToBoxAdapter(
              child: SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: AppConstants.animFast,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusLarge),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_filteredProducts.length} items found',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Icon(Icons.grid_view_rounded,
                        color: AppColors.primary, size: 22),
                  ],
                ),
              ),
            ),

            // ── Product Grid ──────────────────────────────────
            _filteredProducts.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          children: [
                            const Text('🔍', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              'No products found',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.78,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = _filteredProducts[index];
                          final cartItem = _cartItems.firstWhere(
                            (item) => item.product.id == product.id,
                            orElse: () => CartItem(product: product, quantity: 0),
                          );
                          return ProductCard(
                            product: product,
                            quantityInCart: cartItem.quantity,
                            onAddToCart: () => _addToCart(product),
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppConstants.routeProductDetail,
                              arguments: product,
                            ),
                          );
                        },
                        childCount: _filteredProducts.length,
                      ),
                    ),
                  ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),

      // ── Floating Cart Button ──────────────────────────────
      floatingActionButton: _cartCount > 0
          ? FloatingActionButton.extended(
              onPressed: _goToCart,
              backgroundColor: AppColors.accent,
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text(
                'Cart ($_cartCount)',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }

  Widget _buildQuickCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String sub,
    required String route,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      sub,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
