import 'package:flutter/material.dart';
import 'package:mina_hybird_flutter/models/product_model.dart';
import 'package:mina_hybird_flutter/models/category_model.dart';
import 'package:mina_hybird_flutter/models/unit_model.dart';
import 'package:mina_hybird_flutter/models/dtos/product_dto.dart';
import 'package:mina_hybird_flutter/services/network_service.dart';

class ProductEditDialog extends StatefulWidget {
  final Product? product;
  final Function() onSave;

  const ProductEditDialog({
    super.key,
    this.product,
    required this.onSave,
  });

  @override
  State<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<ProductEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _salePriceController = TextEditingController();

  final NetworkService _networkService = NetworkService();
  bool _isSaving = false;
  bool _isLoading = true;
  String _errorMessage = '';

  List<Category> _categories = [];
  List<Unit> _units = [];
  Category? _selectedCategory;
  Unit? _selectedUnit;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    try {
      // Load categories
      final categoryResponse = await _networkService.get('/api/categories');
      if (categoryResponse.isSuccess) {
        _categories = categoryFromJson(categoryResponse.content);
      }

      // Load units
      final unitResponse = await _networkService.get('/api/units');
      if (unitResponse.isSuccess) {
        _units = unitFromJson(unitResponse.content);
      }

      // Set initial values if editing
      if (widget.product != null) {
        _nameController.text = widget.product!.productName;
        _quantityController.text = widget.product!.quantity.toString();
        _priceController.text = widget.product!.price.toString();
        _salePriceController.text = widget.product!.salePrice.toString();

        _selectedCategory = _categories.firstWhere(
          (category) => category.categoryId == widget.product!.categoryId,
        );
        _selectedUnit = _units.firstWhere(
          (unit) => unit.unitId == widget.product!.unitId,
        );
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading form data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null || _selectedUnit == null) {
      setState(() {
        _errorMessage = 'Please select both category and unit';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    try {
      final dto = ProductDto(
        productName: _nameController.text.trim(),
        quantity: int.parse(_quantityController.text),
        price: int.parse(_priceController.text),
        salePrice: int.parse(_salePriceController.text),
        categoryId: _selectedCategory!.categoryId,
        unitId: _selectedUnit!.unitId,
      );

      final response = widget.product != null
          ? await _networkService.putJson(
              '/api/products/${widget.product!.productId}',
              dto.toJson(),
            )
          : await _networkService.postJson(
              '/api/products',
              dto.toJson(),
            );

      if (response.isSuccess) {
        if (mounted) {
          Navigator.pop(context);
          widget.onSave();
          _showSnackBar(
            widget.product != null
                ? 'Product updated successfully'
                : 'Product created successfully',
            isError: false,
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to save product';
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
    final isEditing = widget.product != null;

    if (_isLoading) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 650, // Set a fixed width for larger screens
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
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
                    isEditing ? 'Edit Product' : 'Add Product',
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
            // Form Content
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Product Name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter product name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown<Category>(
                        value: _selectedCategory,
                        items: _categories,
                        label: 'Category',
                        getLabel: (category) => category.categoryName,
                        onChanged: (category) {
                          setState(() => _selectedCategory = category);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown<Unit>(
                        value: _selectedUnit,
                        items: _units,
                        label: 'Unit',
                        getLabel: (unit) => unit.unitName,
                        onChanged: (unit) {
                          setState(() => _selectedUnit = unit);
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _quantityController,
                              label: 'Quantity',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _priceController,
                              label: 'Price',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _salePriceController,
                              label: 'Sale Price',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                final salePrice = int.parse(value);
                                final regularPrice =
                                    int.tryParse(_priceController.text) ?? 0;
                                if (salePrice > regularPrice) {
                                  return 'Must be ≤ regular price';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Error Message
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
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
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
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveProduct,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
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
      keyboardType: keyboardType,
      validator: validator,
      enabled: !_isSaving,
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required String label,
    required String Function(T) getLabel,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(getLabel(item)),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: label,
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
      onChanged: _isSaving ? null : onChanged,
      icon: const Icon(Icons.arrow_drop_down),
      isExpanded: true,
      dropdownColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }
}
