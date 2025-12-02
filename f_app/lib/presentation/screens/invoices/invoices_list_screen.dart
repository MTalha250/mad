import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/invoice_provider.dart';
import '../../navigation/app_router.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/inputs/input_field.dart';

class InvoicesListScreen extends ConsumerStatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  ConsumerState<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends ConsumerState<InvoicesListScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _selectedPaymentTerms = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(invoicesProvider.notifier).loadInvoices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(invoicesProvider.notifier).loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesState = ref.watch(invoicesProvider);
    final filteredInvoices = invoicesState.filteredInvoices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.createInvoice),
            icon: const Icon(Icons.add),
            tooltip: 'Create Invoice',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                InputField(
                  controller: _searchController,
                  hint: 'Search invoices...',
                  prefixIcon: Icons.search,
                  onChanged: (value) {
                    ref.read(invoicesProvider.notifier).setSearchQuery(value);
                  },
                ),
                const SizedBox(height: 12),
                // Status Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Pending', 'Paid', 'Overdue', 'Cancelled']
                        .map((status) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(status),
                                selected: _selectedStatus == status,
                                onSelected: (selected) {
                                  setState(() => _selectedStatus = status);
                                  ref.read(invoicesProvider.notifier).setStatusFilter(
                                        status == 'All' ? null : status,
                                      );
                                },
                                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                                checkmarkColor: AppColors.primary,
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                // Payment Terms Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Cash', 'Credit']
                        .map((terms) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(terms),
                                selected: _selectedPaymentTerms == terms,
                                onSelected: (selected) {
                                  setState(() => _selectedPaymentTerms = terms);
                                  ref.read(invoicesProvider.notifier).setPaymentTermsFilter(
                                        terms == 'All' ? null : terms,
                                      );
                                },
                                selectedColor: AppColors.info.withValues(alpha: 0.2),
                                checkmarkColor: AppColors.info,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // Invoices List
          Expanded(
            child: invoicesState.isLoading && invoicesState.invoices.isEmpty
                ? const ShimmerLoading()
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppColors.primary,
                    child: filteredInvoices.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 64,
                                      color: AppColors.textTertiary,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No invoices found',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredInvoices.length,
                            itemBuilder: (context, index) {
                              final invoice = filteredInvoices[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          invoice.invoiceReference,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      _buildPaymentTermsBadge(invoice.paymentTerms),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        invoice.projectClientName,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'PKR ${invoice.amount}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          StatusBadge(status: invoice.status),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          if (invoice.invoiceDate != null) ...[
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormatter.formatDate(invoice.invoiceDate),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                          if (invoice.dueDate != null) ...[
                                            const SizedBox(width: 16),
                                            Icon(
                                              Icons.event,
                                              size: 14,
                                              color: DateFormatter.isOverdue(invoice.dueDate)
                                                  ? AppColors.error
                                                  : AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Due: ${DateFormatter.formatDate(invoice.dueDate)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: DateFormatter.isOverdue(invoice.dueDate)
                                                    ? AppColors.error
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  onTap: () => context.push('/home/invoices/${invoice.id}'),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTermsBadge(String terms) {
    final isCredit = terms == 'Credit';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCredit
            ? AppColors.info.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        terms,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isCredit ? AppColors.info : AppColors.success,
        ),
      ),
    );
  }
}
