import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/role_helpers.dart';
import '../../../data/models/invoice_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/invoice_provider.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/inputs/dropdown_field.dart';
import '../../widgets/dialogs/confirm_delete_dialog.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  bool _editMode = false;
  bool _saving = false;

  // Edit form fields
  late TextEditingController _invoiceRefController;
  late TextEditingController _amountController;
  late TextEditingController _creditDaysController;

  String _status = 'Pending';
  String _paymentTerms = 'Cash';
  DateTime? _invoiceDate;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _invoiceRefController = TextEditingController();
    _amountController = TextEditingController();
    _creditDaysController = TextEditingController();
  }

  @override
  void dispose() {
    _invoiceRefController.dispose();
    _amountController.dispose();
    _creditDaysController.dispose();
    super.dispose();
  }

  void _initializeForm(Invoice invoice) {
    _invoiceRefController.text = invoice.invoiceReference;
    _amountController.text = invoice.amount;
    _creditDaysController.text = invoice.creditDays ?? '';
    _status = invoice.status;
    _paymentTerms = invoice.paymentTerms;
    _invoiceDate = invoice.invoiceDate;
    _dueDate = invoice.dueDate;
  }

  Future<void> _handleSaveChanges(Invoice invoice) async {
    if (_invoiceRefController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice reference is required')),
      );
      return;
    }

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount is required')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final updateData = {
        'invoiceReference': _invoiceRefController.text,
        'amount': _amountController.text,
        'status': _status,
        'paymentTerms': _paymentTerms,
        if (_paymentTerms == 'Credit' && _creditDaysController.text.isNotEmpty)
          'creditDays': _creditDaysController.text,
        if (_invoiceDate != null) 'invoiceDate': _invoiceDate!.toIso8601String(),
        if (_dueDate != null) 'dueDate': _dueDate!.toIso8601String(),
      };

      await ref.read(invoicesProvider.notifier).updateInvoice(widget.invoiceId, updateData);
      ref.invalidate(invoiceByIdProvider(widget.invoiceId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice updated successfully')),
        );
        setState(() => _editMode = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    showConfirmDeleteDialog(
      context: context,
      title: 'Delete Invoice',
      message: 'Are you sure you want to delete this invoice? This action cannot be undone.',
      onConfirm: () async {
        setState(() => _saving = true);
        final success = await ref.read(invoicesProvider.notifier).deleteInvoice(widget.invoiceId);
        setState(() => _saving = false);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice deleted successfully')),
          );
          context.pop();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete invoice')),
          );
        }
      },
    );
  }

  Future<void> _pickDate(bool isInvoiceDate) async {
    final initialDate = isInvoiceDate
        ? (_invoiceDate ?? DateTime.now())
        : (_dueDate ?? DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        if (isInvoiceDate) {
          _invoiceDate = date;
        } else {
          _dueDate = date;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoiceAsync = ref.watch(invoiceByIdProvider(widget.invoiceId));
    final role = ref.watch(userRoleProvider);
    final canDelete = RoleHelpers.canDelete(role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: invoiceAsync.when(
        data: (invoice) {
          if (invoice == null) {
            return const Center(child: Text('Invoice not found'));
          }

          if (_editMode && _invoiceRefController.text.isEmpty) {
            _initializeForm(invoice);
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action Buttons
                    _buildActionButtons(invoice, canDelete),
                    const SizedBox(height: 16),

                    // Header Card
                    _buildHeaderCard(invoice),
                    const SizedBox(height: 16),

                    // Payment Details Card
                    _buildPaymentDetailsCard(invoice),
                    const SizedBox(height: 16),

                    // Project Card
                    if (invoice.project != null) ...[
                      _buildProjectCard(invoice),
                      const SizedBox(height: 16),
                    ],

                    // Created info
                    _buildInfoCard(invoice),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              if (_saving)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildActionButtons(Invoice invoice, bool canDelete) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saving
                ? null
                : () {
                    if (_editMode) {
                      _handleSaveChanges(invoice);
                    } else {
                      setState(() {
                        _editMode = true;
                        _initializeForm(invoice);
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _editMode ? AppColors.success : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: Icon(_editMode ? Icons.save : Icons.edit),
            label: Text(_editMode ? 'Save Changes' : 'Edit Invoice'),
          ),
        ),
        if (!_editMode && canDelete) ...[
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _handleDelete,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeaderCard(Invoice invoice) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _editMode
                      ? TextField(
                          controller: _invoiceRefController,
                          decoration: const InputDecoration(
                            labelText: 'Invoice Reference',
                            border: OutlineInputBorder(),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.invoiceReference,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              invoice.projectClientName,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
                if (!_editMode) StatusBadge(status: invoice.status),
              ],
            ),
            const SizedBox(height: 16),
            if (_editMode) ...[
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (PKR)',
                  border: OutlineInputBorder(),
                  prefixText: 'PKR ',
                ),
              ),
              const SizedBox(height: 12),
              DropdownField<String>(
                label: 'Status',
                value: _status,
                items: ['Pending', 'Paid', 'Overdue', 'Cancelled']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'PKR ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      invoice.amount,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard(Invoice invoice) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (_editMode) ...[
              DropdownField<String>(
                label: 'Payment Terms',
                value: _paymentTerms,
                items: ['Cash', 'Credit']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _paymentTerms = value);
                },
              ),
              const SizedBox(height: 12),
              if (_paymentTerms == 'Credit') ...[
                TextField(
                  controller: _creditDaysController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Credit Days',
                    border: OutlineInputBorder(),
                    suffixText: 'days',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              InkWell(
                onTap: () => _pickDate(true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Invoice Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _invoiceDate != null
                        ? DateFormatter.formatDate(_invoiceDate)
                        : 'Select date',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _pickDate(false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _dueDate != null
                        ? DateFormatter.formatDate(_dueDate)
                        : 'Select date',
                  ),
                ),
              ),
            ] else ...[
              _buildDetailRow('Payment Terms', invoice.paymentTerms),
              if (invoice.isCredit && invoice.creditDays != null)
                _buildDetailRow('Credit Days', '${invoice.creditDays} days'),
              _buildDetailRow(
                'Invoice Date',
                DateFormatter.formatDate(invoice.invoiceDate),
              ),
              _buildDetailRow(
                'Due Date',
                DateFormatter.formatDate(invoice.dueDate),
                valueColor: DateFormatter.isOverdue(invoice.dueDate)
                    ? AppColors.error
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(Invoice invoice) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Project',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.push('/projects/${invoice.project!.id}');
                  },
                  child: const Text('View Project'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Client', invoice.project!.clientName),
            if (invoice.project!.description.isNotEmpty)
              _buildDetailRow('Description', invoice.project!.description),
            _buildDetailRow('Status', invoice.project!.status),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Invoice invoice) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              'Created by',
              invoice.createdBy?.name ?? 'Unknown',
            ),
            _buildDetailRow(
              'Created at',
              DateFormatter.formatDateTime(invoice.createdAt),
            ),
            _buildDetailRow(
              'Last updated',
              DateFormatter.formatDateTime(invoice.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
