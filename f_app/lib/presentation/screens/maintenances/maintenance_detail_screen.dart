import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/role_helpers.dart';
import '../../../data/models/maintenance_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/maintenance_provider.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/inputs/dropdown_field.dart';
import '../../widgets/dialogs/user_assignment_dialog.dart';
import '../../widgets/dialogs/confirm_delete_dialog.dart';

class MaintenanceDetailScreen extends ConsumerStatefulWidget {
  final String maintenanceId;

  const MaintenanceDetailScreen({super.key, required this.maintenanceId});

  @override
  ConsumerState<MaintenanceDetailScreen> createState() => _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends ConsumerState<MaintenanceDetailScreen> {
  bool _editMode = false;
  bool _saving = false;

  // Edit form fields
  late TextEditingController _clientNameController;
  late TextEditingController _remarksController;

  String _status = 'Pending';
  List<ServiceDate> _serviceDates = [];

  @override
  void initState() {
    super.initState();
    _clientNameController = TextEditingController();
    _remarksController = TextEditingController();
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _initializeForm(Maintenance maintenance) {
    _clientNameController.text = maintenance.clientName;
    _remarksController.text = maintenance.remarks.value;
    _status = maintenance.status;
    _serviceDates = List.from(maintenance.serviceDates);
  }

  Future<void> _handleSaveChanges(Maintenance maintenance) async {
    if (_clientNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client name is required')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final updateData = {
        'clientName': _clientNameController.text,
        'remarks': {
          'value': _remarksController.text,
          'isEdited': _remarksController.text != maintenance.remarks.value,
        },
        'status': _status,
        'serviceDates': _serviceDates.map((e) => e.toJson()).toList(),
      };

      await ref.read(maintenancesProvider.notifier).updateMaintenance(widget.maintenanceId, updateData);
      ref.invalidate(maintenanceByIdProvider(widget.maintenanceId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maintenance updated successfully')),
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
      title: 'Delete Maintenance',
      message: 'Are you sure you want to delete this maintenance? This action cannot be undone.',
      onConfirm: () async {
        setState(() => _saving = true);
        final success = await ref.read(maintenancesProvider.notifier).deleteMaintenance(widget.maintenanceId);
        setState(() => _saving = false);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maintenance deleted successfully')),
          );
          context.pop();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete maintenance')),
          );
        }
      },
    );
  }

  Future<void> _handleAssignUsers(Maintenance maintenance) async {
    final result = await showUserAssignmentDialog(
      context: context,
      currentUsers: maintenance.users,
      onAssign: (userIds) async {
        return await ref.read(maintenancesProvider.notifier).assignUsers(widget.maintenanceId, userIds);
      },
    );

    if (result == true) {
      ref.invalidate(maintenanceByIdProvider(widget.maintenanceId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Users assigned successfully')),
        );
      }
    }
  }

  void _addServiceDate() {
    final now = DateTime.now();
    setState(() {
      _serviceDates.add(ServiceDate(
        month: now.month,
        year: now.year,
        isCompleted: false,
        paymentStatus: 'Pending',
      ));
    });
  }

  void _editServiceDate(int index) {
    final serviceDate = _serviceDates[index];
    showDialog(
      context: context,
      builder: (context) => _ServiceDateEditDialog(
        serviceDate: serviceDate,
        onSave: (updated) {
          setState(() {
            _serviceDates[index] = updated;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maintenanceAsync = ref.watch(maintenanceByIdProvider(widget.maintenanceId));
    final role = ref.watch(userRoleProvider);
    final canDelete = RoleHelpers.canDelete(role);
    final canAssign = RoleHelpers.canAssignUsers(role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Details'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: maintenanceAsync.when(
        data: (maintenance) {
          if (maintenance == null) {
            return const Center(child: Text('Maintenance not found'));
          }

          if (_editMode && _clientNameController.text.isEmpty) {
            _initializeForm(maintenance);
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action Buttons
                    _buildActionButtons(maintenance, canDelete, canAssign),
                    const SizedBox(height: 16),

                    // Header Card
                    _buildHeaderCard(maintenance),
                    const SizedBox(height: 16),

                    // Service Dates Card
                    _buildServiceDatesCard(maintenance),
                    const SizedBox(height: 16),

                    // Assigned Users
                    _buildUsersCard(maintenance, canAssign),
                    const SizedBox(height: 16),

                    // Created info
                    _buildInfoCard(maintenance),
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

  Widget _buildActionButtons(Maintenance maintenance, bool canDelete, bool canAssign) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saving
                ? null
                : () {
                    if (_editMode) {
                      _handleSaveChanges(maintenance);
                    } else {
                      setState(() {
                        _editMode = true;
                        _initializeForm(maintenance);
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _editMode ? AppColors.success : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: Icon(_editMode ? Icons.save : Icons.edit),
            label: Text(_editMode ? 'Save Changes' : 'Edit Maintenance'),
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

  Widget _buildHeaderCard(Maintenance maintenance) {
    final serviceDates = _editMode ? _serviceDates : maintenance.serviceDates;
    final completedCount = serviceDates.where((s) => s.isCompleted).length;
    final totalCount = serviceDates.length;

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
                          controller: _clientNameController,
                          decoration: const InputDecoration(
                            labelText: 'Client Name',
                            border: OutlineInputBorder(),
                          ),
                        )
                      : Text(
                          maintenance.clientName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                if (!_editMode) StatusBadge(status: maintenance.status),
              ],
            ),
            const SizedBox(height: 12),
            if (_editMode) ...[
              TextField(
                controller: _remarksController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownField<String>(
                label: 'Status',
                value: _status,
                items: ['Pending', 'In Progress', 'Completed', 'Cancelled']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
            ] else ...[
              if (maintenance.remarks.value.isNotEmpty) ...[
                Text(
                  maintenance.remarks.value,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Progress indicator
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$completedCount of $totalCount services completed',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (totalCount > 0) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: totalCount > 0 ? completedCount / totalCount : 0,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDatesCard(Maintenance maintenance) {
    final serviceDates = _editMode ? _serviceDates : maintenance.serviceDates;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Service Dates (${serviceDates.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_editMode)
                  TextButton.icon(
                    onPressed: _addServiceDate,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Date'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (serviceDates.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No service dates', style: TextStyle(color: AppColors.textSecondary)),
                ),
              )
            else
              ...serviceDates.asMap().entries.map((entry) =>
                  _buildServiceDateItem(entry.value, entry.key)),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDateItem(ServiceDate serviceDate, int index) {
    final monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    String dateText = '';
    if (serviceDate.month != null && serviceDate.year != null) {
      dateText = '${monthNames[serviceDate.month!]} ${serviceDate.year}';
    } else if (serviceDate.serviceDate != null) {
      dateText = DateFormatter.formatDate(serviceDate.serviceDate);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: serviceDate.isCompleted
            ? AppColors.hasValueBg
            : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: serviceDate.isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (_editMode)
                    Checkbox(
                      value: serviceDate.isCompleted,
                      onChanged: (value) {
                        setState(() {
                          _serviceDates[index] = serviceDate.copyWith(isCompleted: value);
                        });
                      },
                    )
                  else
                    Icon(
                      serviceDate.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: serviceDate.isCompleted
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    dateText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildPaymentStatusBadge(serviceDate.paymentStatus),
                  if (_editMode) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _editServiceDate(index),
                      icon: const Icon(Icons.edit, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _serviceDates.removeAt(index);
                        });
                      },
                      icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (serviceDate.actualDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Actual: ${DateFormatter.formatDate(serviceDate.actualDate)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (serviceDate.jcReference.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'JC: ${serviceDate.jcReference}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (serviceDate.invoiceRef.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Invoice: ${serviceDate.invoiceRef}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Paid':
        bgColor = AppColors.paymentPaidBg;
        textColor = AppColors.statusCompletedText;
        break;
      case 'Overdue':
        bgColor = AppColors.paymentOverdueBg;
        textColor = AppColors.statusCancelledText;
        break;
      default:
        bgColor = AppColors.paymentPendingBg;
        textColor = AppColors.statusPendingText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildUsersCard(Maintenance maintenance, bool canAssign) {
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
                  'Assigned Users',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (canAssign && !_editMode)
                  TextButton.icon(
                    onPressed: () => _handleAssignUsers(maintenance),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Assign'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (maintenance.users.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 48, color: AppColors.textSecondary),
                      SizedBox(height: 8),
                      Text('No users assigned', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: maintenance.users.map((user) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    label: Text(user.name),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Maintenance maintenance) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              'Created by',
              maintenance.createdBy?.name ?? 'Unknown',
            ),
            _buildDetailRow(
              'Created at',
              DateFormatter.formatDateTime(maintenance.createdAt),
            ),
            _buildDetailRow(
              'Last updated',
              DateFormatter.formatDateTime(maintenance.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Service Date Edit Dialog
class _ServiceDateEditDialog extends StatefulWidget {
  final ServiceDate serviceDate;
  final Function(ServiceDate) onSave;

  const _ServiceDateEditDialog({
    required this.serviceDate,
    required this.onSave,
  });

  @override
  State<_ServiceDateEditDialog> createState() => _ServiceDateEditDialogState();
}

class _ServiceDateEditDialogState extends State<_ServiceDateEditDialog> {
  late int _month;
  late int _year;
  late bool _isCompleted;
  late String _paymentStatus;
  late TextEditingController _jcController;
  late TextEditingController _invoiceController;
  DateTime? _actualDate;

  @override
  void initState() {
    super.initState();
    _month = widget.serviceDate.month ?? DateTime.now().month;
    _year = widget.serviceDate.year ?? DateTime.now().year;
    _isCompleted = widget.serviceDate.isCompleted;
    _paymentStatus = widget.serviceDate.paymentStatus;
    _jcController = TextEditingController(text: widget.serviceDate.jcReference);
    _invoiceController = TextEditingController(text: widget.serviceDate.invoiceRef);
    _actualDate = widget.serviceDate.actualDate;
  }

  @override
  void dispose() {
    _jcController.dispose();
    _invoiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Service Date',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Month & Year
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _month,
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(value: m, child: Text(monthNames[m - 1])))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _month = value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _year,
                    items: List.generate(10, (i) => 2020 + i)
                        .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _year = value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Completed
            CheckboxListTile(
              value: _isCompleted,
              onChanged: (value) {
                setState(() => _isCompleted = value ?? false);
              },
              title: const Text('Completed'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            // Payment Status
            DropdownButtonFormField<String>(
              initialValue: _paymentStatus,
              items: ['Pending', 'Paid', 'Overdue']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _paymentStatus = value);
              },
              decoration: const InputDecoration(
                labelText: 'Payment Status',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Actual Date
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _actualDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() => _actualDate = date);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Actual Date',
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_actualDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _actualDate = null),
                        ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
                child: Text(
                  _actualDate != null
                      ? DateFormatter.formatDate(_actualDate)
                      : 'Select date (optional)',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // JC Reference
            TextField(
              controller: _jcController,
              decoration: const InputDecoration(
                labelText: 'JC Reference',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Invoice Reference
            TextField(
              controller: _invoiceController,
              decoration: const InputDecoration(
                labelText: 'Invoice Reference',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSave(ServiceDate(
                        month: _month,
                        year: _year,
                        isCompleted: _isCompleted,
                        paymentStatus: _paymentStatus,
                        jcReference: _jcController.text,
                        invoiceRef: _invoiceController.text,
                        actualDate: _actualDate,
                      ));
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
