import 'package:flutter/material.dart';
import '../utils/database_helper.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

/// Screen displaying customer visit analytics, trends, and logs.
class CustomerVisitReportScreen extends StatefulWidget {
  const CustomerVisitReportScreen({super.key});

  @override
  State<CustomerVisitReportScreen> createState() => _CustomerVisitReportScreenState();
}

class _CustomerVisitReportScreenState extends State<CustomerVisitReportScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isLoading = true;
  int _customerCount = 0;
  Map<String, int> _visitStats = {
    'total_records': 0,
    'active_count': 0,
    'pending_count': 0,
    'inactive_count': 0,
  };
  List<Map<String, dynamic>> _report = [];
  List<String> _visitDates = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load report statistics from SQLite.
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _dbHelper.getCustomerCount(),
        _dbHelper.getCustomerVisitsStats(),
        _dbHelper.getCustomerVisitsReport(),
        _dbHelper.getCustomerVisitsDates(),
      ]);

      if (!mounted) return;

      setState(() {
        _customerCount = results[0] as int;
        _visitStats = results[1] as Map<String, int>;
        _report = results[2] as List<Map<String, dynamic>>;
        _visitDates = results[3] as List<String>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load reports: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Color _rateColor(double percentage) {
    if (percentage > 75) return AppColors.success;
    if (percentage >= 50) return AppColors.warning;
    return AppColors.error;
  }

  double _percentage(num numerator, num denominator) {
    if (denominator == 0) return 0;
    return (numerator / denominator) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Visit Reports'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Data',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _customerCount == 0 && _visitStats['total_records'] == 0
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(AppConstants.padding),
                    children: [
                      _buildSummaryDashboard(),
                      const SizedBox(height: AppConstants.padding),
                      _buildOverallStatsBanner(),
                      const SizedBox(height: AppConstants.paddingLarge),
                      _buildSectionHeader(
                        icon: Icons.people_alt_rounded,
                        title: 'Customer Engagement',
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),
                      if (_report.isEmpty)
                        _buildInfoCard('No visit logs recorded yet.')
                      else
                        ..._report.map(_buildCustomerActivityCard),
                      const SizedBox(height: AppConstants.paddingLarge),
                      _buildSectionHeader(
                        icon: Icons.calendar_month_rounded,
                        title: 'Logged Activity Dates',
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),
                      if (_visitDates.isEmpty)
                        _buildInfoCard('No activity has been logged yet.')
                      else
                        _buildDatesCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.assessment_outlined,
              size: 80,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppConstants.padding),
            Text(
              'No Report Data Available',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              'Log customer visit statuses to view metrics and dashboards here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryDashboard() {
    final totalRecords = _visitStats['total_records'] ?? 0;
    final activeCount = _visitStats['active_count'] ?? 0;
    final activeRate = _percentage(activeCount, totalRecords);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.people_outline_rounded,
            iconColor: AppColors.info,
            label: 'Customers',
            value: '$_customerCount',
          ),
        ),
        const SizedBox(width: AppConstants.paddingSmall),
        Expanded(
          child: _buildStatCard(
            icon: Icons.assignment_turned_in_outlined,
            iconColor: AppColors.accent,
            label: 'Logs Count',
            value: '$totalRecords',
          ),
        ),
        const SizedBox(width: AppConstants.paddingSmall),
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up_rounded,
            iconColor: _rateColor(activeRate),
            label: 'Active Rate',
            value: '${activeRate.toStringAsFixed(0)}%',
            valueColor: _rateColor(activeRate),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStatsBanner() {
    final total = _visitStats['total_records'] ?? 0;
    final active = _visitStats['active_count'] ?? 0;
    final pending = _visitStats['pending_count'] ?? 0;
    final inactive = _visitStats['inactive_count'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppConstants.padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Visit Logs Breakdown',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildIndicator(
                color: AppColors.success,
                label: 'Active',
                value: active,
                total: total,
              ),
              _buildSpacer(),
              _buildIndicator(
                color: AppColors.warning,
                label: 'Pending',
                value: pending,
                total: total,
              ),
              _buildSpacer(),
              _buildIndicator(
                color: AppColors.textSecondary,
                label: 'Inactive',
                value: inactive,
                total: total,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: active,
                    child: Container(color: AppColors.success),
                  ),
                  Expanded(
                    flex: pending,
                    child: Container(color: AppColors.warning),
                  ),
                  Expanded(
                    flex: inactive,
                    child: Container(color: AppColors.textSecondary.withOpacity(0.3)),
                  ),
                  if (total == 0)
                    Expanded(
                      child: Container(color: AppColors.divider),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpacer() => const SizedBox(width: 8);

  Widget _buildIndicator({
    required Color color,
    required String label,
    required int value,
    required int total,
  }) {
    final percent = _percentage(value, total);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$value (${percent.toStringAsFixed(0)}%)',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String text) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerActivityCard(Map<String, dynamic> row) {
    final name = row['customer_name'] as String;
    final email = row['customer_email'] as String;
    final total = row['total'] as int;
    final active = row['active_count'] as int;
    final pending = row['pending_count'] as int;
    final inactive = row['inactive_count'] as int;

    final activeRate = _percentage(active, total);

    return Card(
      color: AppColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  radius: 18,
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _rateColor(activeRate).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${activeRate.toStringAsFixed(0)}% Active',
                    style: TextStyle(
                      color: _rateColor(activeRate),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Logs: $total',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  'Active: $active  |  Pending: $pending  |  Inactive: $inactive',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? active / total : 0,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(_rateColor(activeRate)),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesCard() {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: BorderSide(color: AppColors.divider),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _visitDates.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.divider),
        itemBuilder: (context, index) {
          final dateStr = _visitDates[index];
          // Simple date display formatting
          return ListTile(
            leading: const Icon(Icons.event_available, color: AppColors.primary),
            title: Text(
              dateStr,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
            onTap: () {
              // We could navigate back to visits screen showing this date if needed.
            },
          );
        },
      ),
    );
  }
}
