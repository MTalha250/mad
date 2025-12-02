import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/value_model.dart';
import '../../../providers/complaint_provider.dart';
import '../../../services/image_upload_service.dart';
import '../../widgets/inputs/input_field.dart';
import '../../widgets/inputs/dropdown_field.dart';
import '../../widgets/common/loading_indicator.dart';

class CreateComplaintScreen extends ConsumerStatefulWidget {
  const CreateComplaintScreen({super.key});

  @override
  ConsumerState<CreateComplaintScreen> createState() => _CreateComplaintScreenState();
}

class _CreateComplaintScreenState extends ConsumerState<CreateComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _complaintRefController = TextEditingController();
  final _quotationController = TextEditingController();
  final _poController = TextEditingController();
  final _remarksController = TextEditingController();

  DateTime? _dueDate;
  String _selectedStatus = 'Pending';
  String _selectedPriority = 'Medium';
  final List<DateTime> _visitDates = [];
  final List<TextEditingController> _jcControllers = [];
  final List<TextEditingController> _dcControllers = [];
  final List<String> _uploadedPhotos = [];
  bool _isLoading = false;
  final _imageService = ImageUploadService();

  @override
  void dispose() {
    _clientNameController.dispose();
    _descriptionController.dispose();
    _complaintRefController.dispose();
    _quotationController.dispose();
    _poController.dispose();
    _remarksController.dispose();
    for (final controller in _jcControllers) {
      controller.dispose();
    }
    for (final controller in _dcControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _addVisitDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _visitDates.add(picked);
      });
    }
  }

  void _removeVisitDate(int index) {
    setState(() {
      _visitDates.removeAt(index);
    });
  }

  void _addJcReference() {
    setState(() {
      _jcControllers.add(TextEditingController());
    });
  }

  void _removeJcReference(int index) {
    setState(() {
      _jcControllers[index].dispose();
      _jcControllers.removeAt(index);
    });
  }

  void _addDcReference() {
    setState(() {
      _dcControllers.add(TextEditingController());
    });
  }

  void _removeDcReference(int index) {
    setState(() {
      _dcControllers[index].dispose();
      _dcControllers.removeAt(index);
    });
  }

  Future<void> _pickAndUploadPhotos() async {
    setState(() => _isLoading = true);
    try {
      final urls = await _imageService.pickAndUploadMultipleImages(
        maxImages: 10 - _uploadedPhotos.length,
      );
      setState(() {
        _uploadedPhotos.addAll(urls);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = CreateComplaintRequest(
      complaintReference: _complaintRefController.text.isNotEmpty
          ? _complaintRefController.text.trim()
          : null,
      clientName: _clientNameController.text.trim(),
      description: _descriptionController.text.trim(),
      quotation: _quotationController.text.isNotEmpty
          ? Value(value: _quotationController.text.trim())
          : null,
      po: _poController.text.isNotEmpty
          ? Value(value: _poController.text.trim())
          : null,
      remarks: _remarksController.text.isNotEmpty
          ? Value(value: _remarksController.text.trim())
          : null,
      dueDate: _dueDate,
      visitDates: _visitDates.isNotEmpty ? _visitDates : null,
      photos: _uploadedPhotos.isNotEmpty ? _uploadedPhotos : null,
      jcReferences: _jcControllers.isNotEmpty
          ? _jcControllers
              .where((c) => c.text.isNotEmpty)
              .map((c) => Value(value: c.text.trim()))
              .toList()
          : null,
      dcReferences: _dcControllers.isNotEmpty
          ? _dcControllers
              .where((c) => c.text.isNotEmpty)
              .map((c) => Value(value: c.text.trim()))
              .toList()
          : null,
      priority: _selectedPriority,
      status: _selectedStatus,
    );

    final complaint = await ref.read(complaintsProvider.notifier).createComplaint(request);

    setState(() => _isLoading = false);

    if (complaint != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint created successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else if (mounted) {
      final error = ref.read(complaintsProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to create complaint'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Complaint'),
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
                  controller: _complaintRefController,
                  label: 'Complaint Reference',
                  hint: 'Enter complaint reference (optional)',
                ),
                const SizedBox(height: 16),

                InputField(
                  controller: _clientNameController,
                  label: 'Client Name *',
                  hint: 'Enter client name',
                  validator: (value) => Validators.required(value, 'Client name'),
                ),
                const SizedBox(height: 16),

                InputField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Enter complaint description',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Priority
                DropdownField<String>(
                  label: 'Priority',
                  value: _selectedPriority,
                  items: const [
                    DropdownMenuItem(value: 'Low', child: Text('Low')),
                    DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'High', child: Text('High')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPriority = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

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
                  prefixIcon: Icons.calendar_today,
                  onTap: () => _selectDueDate(context),
                ),
                const SizedBox(height: 16),

                // Visit Dates Section
                _buildVisitDatesSection(),
                const SizedBox(height: 16),

                InputField(
                  controller: _quotationController,
                  label: 'Quotation',
                  hint: 'Enter quotation value',
                ),
                const SizedBox(height: 16),

                InputField(
                  controller: _poController,
                  label: 'Purchase Order (PO)',
                  hint: 'Enter PO number',
                ),
                const SizedBox(height: 16),

                // JC References
                _buildReferenceSection(
                  title: 'JC References',
                  controllers: _jcControllers,
                  onAdd: _addJcReference,
                  onRemove: _removeJcReference,
                ),
                const SizedBox(height: 16),

                // DC References
                _buildReferenceSection(
                  title: 'DC References',
                  controllers: _dcControllers,
                  onAdd: _addDcReference,
                  onRemove: _removeDcReference,
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
                const SizedBox(height: 16),

                // Photos Section
                _buildPhotosSection(),
                const SizedBox(height: 24),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: const Text('Create Complaint'),
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

  Widget _buildVisitDatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Visit Dates',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton.icon(
              onPressed: () => _addVisitDate(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        if (_visitDates.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _visitDates.asMap().entries.map((entry) {
              final date = entry.value;
              return Chip(
                label: Text('${date.day}/${date.month}/${date.year}'),
                onDeleted: () => _removeVisitDate(entry.key),
                deleteIconColor: AppColors.error,
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildReferenceSection({
    required String title,
    required List<TextEditingController> controllers,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        ...controllers.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: InputField(
                    controller: entry.value,
                    hint: 'Enter reference',
                  ),
                ),
                IconButton(
                  onPressed: () => onRemove(entry.key),
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton.icon(
              onPressed: _uploadedPhotos.length >= 10 ? null : _pickAndUploadPhotos,
              icon: const Icon(Icons.add_photo_alternate, size: 18),
              label: Text('Add (${_uploadedPhotos.length}/10)'),
            ),
          ],
        ),
        if (_uploadedPhotos.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _uploadedPhotos.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _uploadedPhotos[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _uploadedPhotos.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
