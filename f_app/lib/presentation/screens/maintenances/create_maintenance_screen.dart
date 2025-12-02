import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/maintenance_model.dart';
import '../../../data/models/value_model.dart';
import '../../../providers/maintenance_provider.dart';
import '../../widgets/inputs/input_field.dart';
import '../../widgets/inputs/dropdown_field.dart';
import '../../widgets/common/loading_indicator.dart';

class CreateMaintenanceScreen extends ConsumerStatefulWidget {
  const CreateMaintenanceScreen({super.key});

  @override
  ConsumerState<CreateMaintenanceScreen> createState() => _CreateMaintenanceScreenState();
}

class _CreateMaintenanceScreenState extends ConsumerState<CreateMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _remarksController = TextEditingController();

  String _selectedStatus = 'Pending';
  final List<_ServiceDateEntry> _serviceDates = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _clientNameController.dispose();
    _remarksController.dispose();
    for (final entry in _serviceDates) {
      entry.jcController.dispose();
      entry.invoiceController.dispose();
    }
    super.dispose();
  }

  void _addServiceDate() {
    setState(() {
      _serviceDates.add(_ServiceDateEntry());
    });
  }

  void _removeServiceDate(int index) {
    setState(() {
      _serviceDates[index].jcController.dispose();
      _serviceDates[index].invoiceController.dispose();
      _serviceDates.removeAt(index);
    });
  }

  Future<void> _selectServiceDate(int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _serviceDates[index].serviceDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _serviceDates[index].serviceDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final serviceDates = _serviceDates.map((entry) {
      return ServiceDate(
        serviceDate: entry.serviceDate,
        month: entry.serviceDate?.month,
        year: entry.serviceDate?.year,
        jcReference: entry.jcController.text.trim(),
        invoiceRef: entry.invoiceController.text.trim(),
        paymentStatus: entry.paymentStatus,
        isCompleted: entry.isCompleted,
      );
    }).toList();

    final request = CreateMaintenanceRequest(
      clientName: _clientNameController.text.trim(),
      remarks: _remarksController.text.isNotEmpty
          ? Value(value: _remarksController.text.trim())
          : null,
      serviceDates: serviceDates.isNotEmpty ? serviceDates : null,
      status: _selectedStatus,
    );

    final maintenance = await ref.read(maintenancesProvider.notifier).createMaintenance(request);

    setState(() => _isLoading = false);

    if (maintenance != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maintenance created successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else if (mounted) {
      final error = ref.read(maintenancesProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to create maintenance'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Maintenance'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InputField(
                  controller: _clientNameController,
                  label: 'Client Name *',
                  hint: 'Enter client name',
                  validator: (value) => Validators.required(value, 'Client name'),
                ),
                const SizedBox(height: 16),

                InputField(
                  controller: _remarksController,
                  label: 'Remarks',
                  hint: 'Enter remarks',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                DropdownField<String>(
                  label: 'Status',
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Service Dates Section
                _buildServiceDatesSection(),
                const SizedBox(height: 24),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: const Text('Create Maintenance'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceDatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Service Dates',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: _addServiceDate,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_serviceDates.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'No service dates added',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...List.generate(_serviceDates.length, (index) {
            final entry = _serviceDates[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Service Date ${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeServiceDate(index),
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: AppColors.error,
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Date Picker
                  InputField(
                    label: 'Date',
                    hint: 'Select date',
                    readOnly: true,
                    controller: TextEditingController(
                      text: entry.serviceDate != null
                          ? '${entry.serviceDate!.day}/${entry.serviceDate!.month}/${entry.serviceDate!.year}'
                          : '',
                    ),
                    prefixIcon: Icons.calendar_today,
                    onTap: () => _selectServiceDate(index),
                  ),
                  const SizedBox(height: 12),

                  InputField(
                    controller: entry.jcController,
                    label: 'JC Reference',
                    hint: 'Enter JC reference',
                  ),
                  const SizedBox(height: 12),

                  InputField(
                    controller: entry.invoiceController,
                    label: 'Invoice Reference',
                    hint: 'Enter invoice reference',
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownField<String>(
                          label: 'Payment Status',
                          value: entry.paymentStatus,
                          items: const [
                            DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                            DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                            DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                entry.paymentStatus = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Switch(
                            value: entry.isCompleted,
                            onChanged: (value) {
                              setState(() {
                                entry.isCompleted = value;
                              });
                            },
                            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                            activeThumbColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _ServiceDateEntry {
  DateTime? serviceDate;
  final TextEditingController jcController = TextEditingController();
  final TextEditingController invoiceController = TextEditingController();
  String paymentStatus = 'Pending';
  bool isCompleted = false;
}
