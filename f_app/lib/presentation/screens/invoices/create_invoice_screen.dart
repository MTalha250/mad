import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/project_model.dart';
import '../../../providers/invoice_provider.dart';
import '../../../providers/project_provider.dart';
import '../../widgets/inputs/input_field.dart';
import '../../widgets/inputs/dropdown_field.dart';
import '../../widgets/common/loading_indicator.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceRefController = TextEditingController();
  final _amountController = TextEditingController();
  final _creditDaysController = TextEditingController();

  DateTime? _invoiceDate;
  DateTime? _dueDate;
  String _selectedPaymentTerms = 'Cash';
  String _selectedStatus = 'Pending';
  Project? _selectedProject;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(projectsProvider.notifier).loadProjects();
    });
  }

  @override
  void dispose() {
    _invoiceRefController.dispose();
    _amountController.dispose();
    _creditDaysController.dispose();
    super.dispose();
  }

  Future<void> _selectInvoiceDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _invoiceDate = picked;
        // Auto-calculate due date if payment terms is Credit
        if (_selectedPaymentTerms == 'Credit' && _creditDaysController.text.isNotEmpty) {
          final days = int.tryParse(_creditDaysController.text) ?? 0;
          _dueDate = picked.add(Duration(days: days));
        }
      });
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _onPaymentTermsChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedPaymentTerms = value;
        if (value == 'Cash') {
          _creditDaysController.clear();
          _dueDate = _invoiceDate;
        }
      });
    }
  }

  void _onCreditDaysChanged(String value) {
    if (_invoiceDate != null && value.isNotEmpty) {
      final days = int.tryParse(value) ?? 0;
      setState(() {
        _dueDate = _invoiceDate!.add(Duration(days: days));
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a project'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final request = CreateInvoiceRequest(
      invoiceReference: _invoiceRefController.text.trim(),
      invoiceDate: _invoiceDate,
      amount: _amountController.text.trim(),
      paymentTerms: _selectedPaymentTerms,
      creditDays: _selectedPaymentTerms == 'Credit' && _creditDaysController.text.isNotEmpty
          ? _creditDaysController.text.trim()
          : null,
      dueDate: _dueDate,
      project: _selectedProject!.id,
      status: _selectedStatus,
    );

    final invoice = await ref.read(invoicesProvider.notifier).createInvoice(request);

    setState(() => _isLoading = false);

    if (invoice != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice created successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else if (mounted) {
      final error = ref.read(invoicesProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to create invoice'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
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
                  controller: _invoiceRefController,
                  label: 'Invoice Reference *',
                  hint: 'Enter invoice reference',
                  validator: (value) => Validators.required(value, 'Invoice reference'),
                ),
                const SizedBox(height: 16),

                // Project Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Project *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Project>(
                          value: _selectedProject,
                          hint: const Text('Select a project'),
                          isExpanded: true,
                          items: projectsState.projects.map((project) {
                            return DropdownMenuItem<Project>(
                              value: project,
                              child: Text(project.clientName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedProject = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                InputField(
                  controller: _amountController,
                  label: 'Amount (PKR) *',
                  hint: 'Enter amount',
                  keyboardType: TextInputType.number,
                  validator: (value) => Validators.required(value, 'Amount'),
                ),
                const SizedBox(height: 16),

                // Invoice Date
                InputField(
                  label: 'Invoice Date',
                  hint: 'Select invoice date',
                  readOnly: true,
                  controller: TextEditingController(
                    text: _invoiceDate != null
                        ? '${_invoiceDate!.day}/${_invoiceDate!.month}/${_invoiceDate!.year}'
                        : '',
                  ),
                  prefixIcon: Icons.calendar_today,
                  onTap: () => _selectInvoiceDate(context),
                ),
                const SizedBox(height: 16),

                DropdownField<String>(
                  label: 'Payment Terms',
                  value: _selectedPaymentTerms,
                  items: const [
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'Credit', child: Text('Credit')),
                  ],
                  onChanged: _onPaymentTermsChanged,
                ),
                const SizedBox(height: 16),

                if (_selectedPaymentTerms == 'Credit') ...[
                  InputField(
                    controller: _creditDaysController,
                    label: 'Credit Days',
                    hint: 'Enter number of credit days',
                    keyboardType: TextInputType.number,
                    onChanged: _onCreditDaysChanged,
                  ),
                  const SizedBox(height: 16),
                ],

                // Due Date
                InputField(
                  label: 'Due Date',
                  hint: 'Select due date',
                  readOnly: true,
                  controller: TextEditingController(
                    text: _dueDate != null
                        ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                        : '',
                  ),
                  prefixIcon: Icons.event,
                  onTap: () => _selectDueDate(context),
                ),
                const SizedBox(height: 16),

                DropdownField<String>(
                  label: 'Status',
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: const Text('Create Invoice'),
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
}
