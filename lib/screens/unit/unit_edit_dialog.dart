import 'package:flutter/material.dart';
import 'package:mina_hybird_flutter/models/unit_model.dart';
import 'package:mina_hybird_flutter/models/dtos/unit_dto.dart';
import 'package:mina_hybird_flutter/services/network_service.dart';

class UnitEditDialog extends StatefulWidget {
  final Unit? unit;
  final Function() onSave;

  const UnitEditDialog({
    super.key,
    this.unit,
    required this.onSave,
  });

  @override
  State<UnitEditDialog> createState() => _UnitEditDialogState();
}

class _UnitEditDialogState extends State<UnitEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final NetworkService _networkService = NetworkService();
  bool _isSaving = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.unit != null) {
      _nameController.text = widget.unit!.unitName;
    }
  }

  Future<void> _saveUnit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    try {
      final dto = UnitDto(unitName: _nameController.text.trim());
      final response = widget.unit != null
          ? await _networkService.putJson(
              '/api/units/${widget.unit!.unitId}',
              dto.toJson(),
            )
          : await _networkService.postJson(
              '/api/units',
              dto.toJson(),
            );

      if (response.isSuccess) {
        if (mounted) {
          Navigator.pop(context);
          widget.onSave();
          _showSnackBar(
            widget.unit != null
                ? 'Unit updated successfully'
                : 'Unit created successfully',
            isError: false,
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to save unit';
          _isSaving = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isSaving = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.unit != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // Container(
                //   width: 40,
                //   height: 40,
                //   decoration: BoxDecoration(
                //     color: Theme.of(context).primaryColor.withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(8),
                //   ),
                //   child: Icon(
                //     isEditing ? Icons.edit : Icons.add,
                //     color: Theme.of(context).primaryColor,
                //   ),
                // ),
                // const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    isEditing ? 'Edit Unit' : 'Add Unit',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Unit Name',
                  hintText: 'Enter unit name',
                  // prefixIcon: const Icon(Icons.straighten),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.red,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a unit name';
                  }
                  return null;
                },
                enabled: !_isSaving,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveUnit(),
              ),
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 20,
                      color: Colors.red[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveUnit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isEditing ? Icons.check : Icons.add,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(isEditing ? 'Update' : 'Create'),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
