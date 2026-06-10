import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../utils/database_helper.dart';

/// WEEK 3 — Profile Screen
/// Shows customer info, order history placeholder, and logout.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String _name = '';
  String _email = '';
  String _phone = '';
  String _address = '';
  bool _isLoading = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(AppConstants.keyCustomerEmail) ?? '';

    if (email.isNotEmpty) {
      final db = DatabaseHelper();
      final customer = await db.getCustomerByEmail(email);
      if (mounted && customer != null) {
        setState(() {
          _name = customer.fullName;
          _email = customer.email;
          _phone = customer.phone;
          _address = customer.address;
          _isLoading = false;
        });
        _animController.forward();
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.borderRadiusLarge)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of FreshMart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
          context, AppConstants.routeLogin, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                // ── Profile Header ────────────────────────────
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white70),
                      onPressed: _logout,
                      tooltip: 'Sign Out',
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.splashGradient,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 48),
                          // Avatar
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 16,
                                )
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _name.isNotEmpty
                                    ? _name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'FreshMart Customer',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  title: const Text('My Profile'),
                ),

                // ── Profile Content ───────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.all(AppConstants.padding),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),

                            // Account Info card
                            _buildSectionTitle('Account Information'),
                            _buildInfoCard([
                              _buildInfoRow(
                                  Icons.person_outline, 'Full Name', _name),
                              _buildInfoRow(
                                  Icons.email_outlined, 'Email', _email),
                              _buildInfoRow(
                                  Icons.phone_outlined, 'Phone', _phone),
                              _buildInfoRow(Icons.location_on_outlined,
                                  'Delivery Address', _address),
                            ]),

                            const SizedBox(height: 20),

                            // Order History placeholder
                            _buildSectionTitle('Recent Orders'),
                            _buildInfoCard([
                              _buildOrderPlaceholder(
                                  '#FM${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                                  'In Transit',
                                  'KSh 650',
                                  AppColors.accent),
                              const Divider(color: AppColors.divider),
                              _buildOrderPlaceholder(
                                  '#FM${(DateTime.now().millisecondsSinceEpoch - 86400000).toString().substring(7)}',
                                  'Delivered',
                                  'KSh 1,200',
                                  AppColors.success),
                            ]),

                            const SizedBox(height: 20),

                            // Quick actions
                            _buildSectionTitle('Quick Actions'),
                            _buildInfoCard([
                              _buildActionRow(Icons.shopping_bag_outlined,
                                  'Browse Products', () {
                                Navigator.pushNamedAndRemoveUntil(context,
                                    AppConstants.routeHome, (r) => false);
                              }),
                              const Divider(color: AppColors.divider),
                              // Week 4 — SQLite Customer Record Management
                              _buildActionRow(
                                  Icons.people_outlined,
                                  'Manage Customers (Week 4)',
                                  () => Navigator.pushNamed(
                                      context, AppConstants.routeCustomers)),
                              const Divider(color: AppColors.divider),
                              // Week 5 — REST API Networking
                              _buildActionRow(
                                  Icons.cloud_outlined,
                                  'API Users — Networking (Week 5)',
                                  () => Navigator.pushNamed(
                                      context, AppConstants.routeApiUsers)),
                              const Divider(color: AppColors.divider),
                              _buildActionRow(
                                  Icons.help_outline, 'Help & Support', () {}),
                              const Divider(color: AppColors.divider),
                              _buildActionRow(Icons.info_outline, 'About FreshMart',
                                  () {}),
                            ]),

                            const SizedBox(height: 20),

                            // Sign out button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _logout,
                                icon: const Icon(Icons.logout,
                                    color: AppColors.error),
                                label: const Text('Sign Out',
                                    style:
                                        TextStyle(color: AppColors.error)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  side: const BorderSide(
                                      color: AppColors.error, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppConstants.borderRadius),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderPlaceholder(
      String orderId, String status, String amount, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.receipt_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(orderId,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary)),
                Text(amount,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
      IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(AppConstants.borderRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500)),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
