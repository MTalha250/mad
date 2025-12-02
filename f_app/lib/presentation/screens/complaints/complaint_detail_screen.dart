import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/role_helpers.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/value_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/complaint_provider.dart';
import '../../../services/image_upload_service.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/badges/priority_badge.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/inputs/dropdown_field.dart';
import '../../widgets/dialogs/user_assignment_dialog.dart';
import '../../widgets/dialogs/image_viewer_dialog.dart';
import '../../widgets/dialogs/confirm_delete_dialog.dart';

class ComplaintDetailScreen extends ConsumerStatefulWidget {
  final String complaintId;

  const ComplaintDetailScreen({super.key, required this.complaintId});

  @override
  ConsumerState<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends ConsumerState<ComplaintDetailScreen> {
  bool _editMode = false;
  bool _saving = false;

  // Edit form fields
  late TextEditingController _clientNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _complaintRefController;
  late TextEditingController _poController;
  late TextEditingController _quotationController;
  late TextEditingController _remarksController;
  late TextEditingController _jcInputController;
  late TextEditingController _dcInputController;

  String _priority = 'Medium';
  DateTime? _dueDate;
  List<String> _photos = [];
  List<DateTime> _visitDates = [];
  List<Value> _jcReferences = [];
  List<Value> _dcReferences = [];

  final ImageUploadService _imageUploadService = ImageUploadService();
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _clientNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _complaintRefController = TextEditingController();
    _poController = TextEditingController();
    _quotationController = TextEditingController();
    _remarksController = TextEditingController();
    _jcInputController = TextEditingController();
    _dcInputController = TextEditingController();
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _descriptionController.dispose();
    _complaintRefController.dispose();
    _poController.dispose();
    _quotationController.dispose();
    _remarksController.dispose();
    _jcInputController.dispose();
    _dcInputController.dispose();
    super.dispose();
  }

  void _initializeForm(Complaint complaint) {
    _clientNameController.text = complaint.clientName;
    _descriptionController.text = complaint.description;
    _complaintRefController.text = complaint.complaintReference;
    _poController.text = complaint.po.value;
    _quotationController.text = complaint.quotation.value;
    _remarksController.text = complaint.remarks.value;
    _priority = complaint.priority;
    _dueDate = complaint.dueDate;
    _photos = List.from(complaint.photos);
    _visitDates = List.from(complaint.visitDates);
    _jcReferences = List.from(complaint.jcReferences);
    _dcReferences = List.from(complaint.dcReferences);
  }

  Future<void> _handleSaveChanges(Complaint complaint) async {
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
        'description': _descriptionController.text,
        'complaintReference': _complaintRefController.text,
        'po': {'value': _poController.text, 'isEdited': _poController.text != complaint.po.value},
        'quotation': {'value': _quotationController.text, 'isEdited': _quotationController.text != complaint.quotation.value},
        'remarks': {'value': _remarksController.text, 'isEdited': _remarksController.text != complaint.remarks.value},
        'priority': _priority,
        'photos': _photos,
        'visitDates': _visitDates.map((d) => d.toIso8601String()).toList(),
        'jcReferences': _jcReferences.map((e) => e.toJson()).toList(),
        'dcReferences': _dcReferences.map((e) => e.toJson()).toList(),
        if (_dueDate != null) 'dueDate': _dueDate!.toIso8601String(),
      };

      await ref.read(complaintsProvider.notifier).updateComplaint(widget.complaintId, updateData);
      ref.invalidate(complaintByIdProvider(widget.complaintId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint updated successfully')),
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
      title: 'Delete Complaint',
      message: 'Are you sure you want to delete this complaint? This action cannot be undone.',
      onConfirm: () async {
        setState(() => _saving = true);
        final success = await ref.read(complaintsProvider.notifier).deleteComplaint(widget.complaintId);
        setState(() => _saving = false);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Complaint deleted successfully')),
          );
          context.pop();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete complaint')),
          );
        }
      },
    );
  }

  Future<void> _handleAssignUsers(Complaint complaint) async {
    final result = await showUserAssignmentDialog(
      context: context,
      currentUsers: complaint.users,
      onAssign: (userIds) async {
        return await ref.read(complaintsProvider.notifier).assignUsers(widget.complaintId, userIds);
      },
    );

    if (result == true) {
      ref.invalidate(complaintByIdProvider(widget.complaintId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Users assigned successfully')),
        );
      }
    }
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _addVisitDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() => _visitDates.add(date));
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    setState(() => _uploadingPhoto = true);

    try {
      final url = await _imageUploadService.pickAndUploadImage();
      if (url != null) {
        setState(() => _photos.add(url));
      }
    } finally {
      setState(() => _uploadingPhoto = false);
    }
  }

  void _addJcReference() {
    if (_jcInputController.text.isEmpty) return;

    setState(() {
      _jcReferences.add(Value(
        value: _jcInputController.text,
        isEdited: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      _jcInputController.clear();
    });
  }

  void _addDcReference() {
    if (_dcInputController.text.isEmpty) return;

    setState(() {
      _dcReferences.add(Value(
        value: _dcInputController.text,
        isEdited: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      _dcInputController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final complaintAsync = ref.watch(complaintByIdProvider(widget.complaintId));
    final role = ref.watch(userRoleProvider);
    final canDelete = RoleHelpers.canDelete(role);
    final canAssign = RoleHelpers.canAssignUsers(role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: complaintAsync.when(
        data: (complaint) {
          if (complaint == null) {
            return const Center(child: Text('Complaint not found'));
          }

          if (_editMode && _clientNameController.text.isEmpty) {
            _initializeForm(complaint);
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action Buttons
                    _buildActionButtons(complaint, canDelete, canAssign),
                    const SizedBox(height: 16),

                    // Header Card
                    _buildHeaderCard(complaint),
                    const SizedBox(height: 16),

                    // Details Card
                    _buildDetailsCard(complaint),
                    const SizedBox(height: 16),

                    // Visit Dates Card
                    _buildVisitDatesCard(complaint),
                    const SizedBox(height: 16),

                    // JC/DC References Card
                    _buildReferencesCard(complaint),
                    const SizedBox(height: 16),

                    // Photos
                    _buildPhotosCard(complaint),
                    const SizedBox(height: 16),

                    // Assigned Users
                    _buildUsersCard(complaint, canAssign),
                    const SizedBox(height: 16),

                    // Created info
                    _buildInfoCard(complaint),
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

  Widget _buildActionButtons(Complaint complaint, bool canDelete, bool canAssign) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saving
                ? null
                : () {
                    if (_editMode) {
                      _handleSaveChanges(complaint);
                    } else {
                      setState(() {
                        _editMode = true;
                        _initializeForm(complaint);
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _editMode ? AppColors.success : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: Icon(_editMode ? Icons.save : Icons.edit),
            label: Text(_editMode ? 'Save Changes' : 'Edit Complaint'),
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

  Widget _buildHeaderCard(Complaint complaint) {
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
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complaint.clientName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (complaint.complaintReference.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Ref: ${complaint.complaintReference}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
                if (!_editMode)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(status: complaint.status),
                      const SizedBox(height: 4),
                      PriorityBadge(priority: complaint.priority),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_editMode) ...[
              TextField(
                controller: _complaintRefController,
                decoration: const InputDecoration(
                  labelText: 'Complaint Reference',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownField<String>(
                label: 'Priority',
                value: _priority,
                items: ['Low', 'Medium', 'High']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _priority = value);
                },
              ),
            ] else if (complaint.description.isNotEmpty) ...[
              Text(
                complaint.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(Complaint complaint) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (_editMode) ...[
              InkWell(
                onTap: _pickDueDate,
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
              const SizedBox(height: 12),
              TextField(
                controller: _quotationController,
                decoration: const InputDecoration(
                  labelText: 'Quotation',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _poController,
                decoration: const InputDecoration(
                  labelText: 'PO',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _remarksController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
              _buildDetailRow('Due Date', DateFormatter.formatDate(complaint.dueDate)),
              _buildDetailRow('Quotation', complaint.quotation.value.isNotEmpty ? complaint.quotation.value : '-'),
              _buildDetailRow('PO', complaint.po.value.isNotEmpty ? complaint.po.value : '-'),
              if (complaint.remarks.value.isNotEmpty)
                _buildDetailRow('Remarks', complaint.remarks.value),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVisitDatesCard(Complaint complaint) {
    final visitDates = _editMode ? _visitDates : complaint.visitDates;

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
                  'Visit Dates (${visitDates.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_editMode)
                  TextButton.icon(
                    onPressed: _addVisitDate,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Date'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (visitDates.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No visit dates', style: TextStyle(color: AppColors.textSecondary)),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: visitDates.asMap().entries.map((entry) {
                  return Chip(
                    avatar: const Icon(Icons.event, size: 16, color: AppColors.primary),
                    label: Text(DateFormatter.formatDate(entry.value)),
                    deleteIcon: _editMode ? const Icon(Icons.close, size: 18) : null,
                    onDeleted: _editMode
                        ? () {
                            setState(() => _visitDates.removeAt(entry.key));
                          }
                        : null,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferencesCard(Complaint complaint) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'References',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // JC References
            const Text(
              'JC References',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            if (_editMode) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _jcInputController,
                      decoration: const InputDecoration(
                        hintText: 'Enter JC reference',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addJcReference,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_editMode ? _jcReferences : complaint.jcReferences)
                  .where((e) => e.hasValue)
                  .map((jc) => Chip(
                        label: Text(jc.value),
                        deleteIcon: _editMode ? const Icon(Icons.close, size: 18) : null,
                        onDeleted: _editMode
                            ? () {
                                setState(() {
                                  _jcReferences.removeWhere((e) => e.value == jc.value);
                                });
                              }
                            : null,
                      ))
                  .toList(),
            ),
            if ((complaint.jcReferences.isEmpty || complaint.jcReferences.every((e) => !e.hasValue)) && !_editMode)
              const Text('-', style: TextStyle(color: AppColors.textSecondary)),

            const SizedBox(height: 16),

            // DC References
            const Text(
              'DC References',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            if (_editMode) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dcInputController,
                      decoration: const InputDecoration(
                        hintText: 'Enter DC reference',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addDcReference,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_editMode ? _dcReferences : complaint.dcReferences)
                  .where((e) => e.hasValue)
                  .map((dc) => Chip(
                        label: Text(dc.value),
                        deleteIcon: _editMode ? const Icon(Icons.close, size: 18) : null,
                        onDeleted: _editMode
                            ? () {
                                setState(() {
                                  _dcReferences.removeWhere((e) => e.value == dc.value);
                                });
                              }
                            : null,
                      ))
                  .toList(),
            ),
            if ((complaint.dcReferences.isEmpty || complaint.dcReferences.every((e) => !e.hasValue)) && !_editMode)
              const Text('-', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosCard(Complaint complaint) {
    final photos = _editMode ? _photos : complaint.photos;

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
                  'Photos (${photos.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_editMode)
                  TextButton.icon(
                    onPressed: _uploadingPhoto ? null : _pickAndUploadPhoto,
                    icon: _uploadingPhoto
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_photo_alternate),
                    label: Text(_uploadingPhoto ? 'Uploading...' : 'Add Photo'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (photos.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.photo_library_outlined, size: 48, color: AppColors.textSecondary),
                      SizedBox(height: 8),
                      Text('No photos', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () => showImageViewer(
                              context: context,
                              images: photos,
                              initialIndex: index,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: photos[index],
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppColors.background,
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.background,
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          ),
                          if (_editMode)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _photos.removeAt(index));
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
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
        ),
      ),
    );
  }

  Widget _buildUsersCard(Complaint complaint, bool canAssign) {
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
                    onPressed: () => _handleAssignUsers(complaint),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Assign'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (complaint.users.isEmpty)
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
                children: complaint.users.map((user) {
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

  Widget _buildInfoCard(Complaint complaint) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              'Created by',
              complaint.createdBy?.name ?? 'Unknown',
            ),
            _buildDetailRow(
              'Created at',
              DateFormatter.formatDateTime(complaint.createdAt),
            ),
            _buildDetailRow(
              'Last updated',
              DateFormatter.formatDateTime(complaint.updatedAt),
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
