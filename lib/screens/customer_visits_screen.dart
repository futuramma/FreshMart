import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/customer_visit.dart';
import '../utils/database_helper.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

/// Screen to record daily customer visits and activity status.
class CustomerVisitsScreen extends StatefulWidget {
  const CustomerVisitsScreen({super.key});

  @override
  State<CustomerVisitsScreen> createState() => _CustomerVisitsScreenState();
}

class _CustomerVisitsScreenState extends State<CustomerVisitsScreen> {
  final DatabaseHelper _db = DatabaseHelper();

  List<Customer> _customers = [];
  Map<int, String> _statusMap = {}; // customerId -> status
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _existingVisits = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load customers and existing visits for the selected date.
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final customers = await _db.getAllCustomers();
      final dateStr = _formatDateForDb(_selectedDate);
      final hasExisting = await _db.hasCustomerVisitsForDate(dateStr);

      // Default status: Active
      Map<int, String> statusMap = {
        for (final c in customers) c.id!: 'Active',
      };

      if (hasExisting) {
        final records = await _db.getCustomerVisitsByDate(dateStr);
        for (final r in records) {
          statusMap[r.customerId] = r.status;
        }
      }

      if (!mounted) return;
      setState(() {
        _customers = customers;
        _statusMap = statusMap;
        _existingVisits = hasExisting;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load customers: $e');
    }
  }

  String _formatDateForDb(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatDateDisplay(DateTime date) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }

  void _markAll(String status) {
    setState(() {
      for (final id in _statusMap.keys) {
        _statusMap[id] = status;
      }
    });
  }

  Future<void> _saveVisits() async {
    if (_customers.isEmpty) return;

    if (_existingVisits) {
      final confirmed = await _showOverwriteDialog();
      if (confirmed != true) return;
    }

    setState(() => _isSaving = true);

    try {
      final dateStr = _formatDateForDb(_selectedDate);
      final records = _customers.map((c) {
        return CustomerVisit(
          customerId: c.id!,
          date: dateStr,
          status: _statusMap[c.id!] ?? 'Active',
        );
      }).toList();

      await _db.saveCustomerVisitsBatch(records);

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _existingVisits = true;
      });
      _showSuccessSnackBar('Visits saved successfully for ${_customers.length} customers');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showErrorSnackBar('Failed to save visits: $e');
    }
  }

  Future<bool?> _showOverwriteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text('Overwrite Records?'),
          ],
        ),
        content: Text(
          'Visit logs already exist for ${_formatDateDisplay(_selectedDate)}.\n\n'
          'Do you want to overwrite them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Overwrite'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Map<String, int> get _statusCounts {
    int active = 0, pending = 0, inactive = 0;
    for (final status in _statusMap.values) {
      if (status == 'Active') active++;
      if (status == 'Pending') pending++;
      if (status == 'Inactive') inactive++;
    }
    return {'active': active, 'pending': pending, 'inactive': inactive};
  }

  Color _colorForStatus(String status) {
    if (status == 'Active') return AppColors.success;
    if (status == 'Pending') return AppColors.warning;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Visits Log'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading ? _buildLoadingState() : _buildBody(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: AppConstants.padding),
          Text(
            'Loading customers...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_customers.isEmpty) return _buildEmptyState();

    return Column(
      children: [
        _buildDateSelector(),
        _buildBulkActions(),
        _buildSummaryBanner(),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(child: _buildCustomerList()),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 72,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            const Text(
              'No Customers Registered',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            const Text(
              'Register customers first before logging visits.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppConstants.routeCustomers);
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Manage Customers'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLarge,
                  vertical: 14,
                ),
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

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.padding,
        AppConstants.padding,
        AppConstants.padding,
        AppConstants.paddingSmall,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        color: AppColors.surface,
        child: InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.padding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              color: AppColors.surface,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppConstants.padding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LOG DATE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary.withOpacity(0.8),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDateDisplay(_selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down_circle_outlined,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulkActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () => _markAll('Active'),
            icon: const Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
            label: const Text('Mark All Active', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
          ),
          TextButton.icon(
            onPressed: () => _markAll('Inactive'),
            icon: const Icon(Icons.highlight_off, size: 18, color: AppColors.error),
            label: const Text('Mark All Inactive', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBanner() {
    final counts = _statusCounts;
    final active = counts['active'] ?? 0;
    final pending = counts['pending'] ?? 0;
    final inactive = counts['inactive'] ?? 0;
    final total = _customers.length;

    final activeRate = total > 0 ? (active / total * 100).toStringAsFixed(0) : '0';

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppConstants.padding,
        0,
        AppConstants.padding,
        AppConstants.padding,
      ),
      padding: const EdgeInsets.all(AppConstants.padding),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        gradient: AppColors.primaryGradient,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Active', active.toString(), Colors.white),
          _buildSummaryItem('Pending', pending.toString(), Colors.white.withOpacity(0.9)),
          _buildSummaryItem('Inactive', inactive.toString(), Colors.white.withOpacity(0.8)),
          Container(
            height: 40,
            width: 1,
            color: Colors.white24,
          ),
          Column(
            children: [
              Text(
                '$activeRate%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Active Rate',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
      itemCount: _customers.length,
      itemBuilder: (context, index) {
        final customer = _customers[index];
        final status = _statusMap[customer.id!] ?? 'Active';

        return Card(
          elevation: 0,
          color: AppColors.surface,
          margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            side: BorderSide(color: AppColors.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.padding),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    customer.fullName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.padding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customer.email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    DropdownButton<String>(
                      value: status,
                      elevation: 4,
                      icon: Icon(Icons.arrow_drop_down, color: _colorForStatus(status)),
                      underline: const SizedBox(),
                      style: TextStyle(
                        color: _colorForStatus(status),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      onChanged: (String? newStatus) {
                        if (newStatus != null) {
                          setState(() {
                            _statusMap[customer.id!] = newStatus;
                          });
                        }
                      },
                      items: <String>['Active', 'Pending', 'Inactive']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveVisits,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_outlined, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Save Daily Log',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
