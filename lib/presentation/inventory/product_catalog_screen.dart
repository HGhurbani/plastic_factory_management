// plastic_factory_management/lib/presentation/inventory/product_catalog_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProductCatalogScreen extends StatefulWidget {
  @override
  _ProductCatalogScreenState createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final inventoryUseCases = Provider.of<InventoryUseCases>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.productCatalog),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showAddEditProductDialog(context, inventoryUseCases, appLocalizations);
            },
            tooltip: appLocalizations.addProduct, // أضف هذا النص في ARB
          ),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: inventoryUseCases.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل المنتجات: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('لا توجد منتجات لعرضها. يرجى إضافة منتج جديد.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 cards per row
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7, // Adjust as needed to fit content
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final product = snapshot.data![index];
              return GestureDetector(
                onTap: () {
                  _showProductDetailsDialog(context, appLocalizations, product);
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias, // For image borderRadius
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                            ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Center(child: Icon(Icons.broken_image, size: 40)),
                        )
                            : Container(
                          color: Colors.grey[300],
                          child: Center(child: Icon(Icons.image, size: 40, color: Colors.grey[600])),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end, // Align to the right for Arabic
                            children: [
                              Text(
                                product.name,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                textAlign: TextAlign.right,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${appLocalizations.productCode}: ${product.productCode}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                textAlign: TextAlign.right,
                              ),
                              Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, size: 20, color: Colors.blue),
                                    onPressed: () {
                                      _showAddEditProductDialog(context, inventoryUseCases, appLocalizations, product: product);
                                    },
                                    tooltip: appLocalizations.edit,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () {
                                      _showDeleteProductConfirmationDialog(context, inventoryUseCases, appLocalizations, product.id, product.name);
                                    },
                                    tooltip: appLocalizations.delete,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showProductDetailsDialog(BuildContext context, AppLocalizations appLocalizations, ProductModel product) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(product.name, textAlign: TextAlign.right),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end, // Align all content to the right
              children: [
                if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Image.network(
                      product.imageUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                _buildDetailRow(appLocalizations.productCode, product.productCode),
                if (product.description != null && product.description!.isNotEmpty)
                  _buildDetailRow(appLocalizations.description, product.description!), // أضف هذا النص في ARB
                _buildDetailRow(appLocalizations.packagingType, product.packagingType),
                _buildDetailRow(appLocalizations.requiresPackaging, product.requiresPackaging ? appLocalizations.yes : appLocalizations.no), // أضف نصوص نعم/لا
                _buildDetailRow(appLocalizations.requiresSticker, product.requiresSticker ? appLocalizations.yes : appLocalizations.no),
                _buildDetailRow(appLocalizations.productType, product.productType == 'single' ? appLocalizations.single : appLocalizations.compound),
                _buildDetailRow('الوقت المتوقع للإنتاج', '${product.expectedProductionTimePerUnit.toStringAsFixed(1)} ${appLocalizations.minutesPerUnit}'), // أضف هذا النص في ARB

                Divider(height: 24),
                Text(appLocalizations.colors, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.right),
                Text(product.colors.isEmpty ? appLocalizations.notApplicable : product.colors.join(', '), textAlign: TextAlign.right), // أضف نص "غير متاح"

                SizedBox(height: 8),
                Text(appLocalizations.additives, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.right),
                Text(product.additives.isEmpty ? appLocalizations.notApplicable : product.additives.join(', '), textAlign: TextAlign.right),

                SizedBox(height: 8),
                Text(appLocalizations.materialsUsed, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.right),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: product.billOfMaterials.map((bom) =>
                      Text('${bom.quantityPerUnit} ${bom.unit} من ${bom.materialId}', // TODO: Fetch material name from ID
                          textAlign: TextAlign.right)).toList(),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.close), // أضف هذا النص في ARB
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? textColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
          SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }


  void _showAddEditProductDialog(
      BuildContext context,
      InventoryUseCases useCases,
      AppLocalizations appLocalizations, {
        ProductModel? product,
      }) {
    final isEditing = product != null;
    final _formKey = GlobalKey<FormState>();
    final _productCodeController = TextEditingController(text: product?.productCode);
    final _nameController = TextEditingController(text: product?.name);
    final _descriptionController = TextEditingController(text: product?.description);
    final _packagingTypeController = TextEditingController(text: product?.packagingType);
    final _expectedProductionTimeController = TextEditingController(text: product?.expectedProductionTimePerUnit.toString());

    bool _requiresPackaging = product?.requiresPackaging ?? false;
    bool _requiresSticker = product?.requiresSticker ?? false;
    String _productType = product?.productType ?? 'single';
    List<String> _colors = List<String>.from(product?.colors ?? []);
    List<String> _additives = List<String>.from(product?.additives ?? []);
    List<ProductMaterial> _billOfMaterials = List<ProductMaterial>.from(product?.billOfMaterials ?? []);

    File? _pickedImage;
    String? _existingImageUrl = product?.imageUrl;

    final ImagePicker _picker = ImagePicker();

    Future<void> _pickImage() async {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
          _existingImageUrl = null; // Clear existing URL if new image is picked
        });
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? appLocalizations.editProduct : appLocalizations.addProduct),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Image Picker
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _pickedImage != null
                              ? FileImage(_pickedImage!)
                              : (_existingImageUrl != null ? NetworkImage(_existingImageUrl!) as ImageProvider : null),
                          child: _pickedImage == null && _existingImageUrl == null
                              ? Icon(Icons.camera_alt, size: 50, color: Colors.grey[700])
                              : null,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _productCodeController,
                        decoration: InputDecoration(labelText: appLocalizations.productCode, border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: appLocalizations.productName, border: OutlineInputBorder()), // أضف هذا النص في ARB
                        validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(labelText: appLocalizations.description, border: OutlineInputBorder()),
                        maxLines: 3,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _packagingTypeController,
                        decoration: InputDecoration(labelText: appLocalizations.packagingType, border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _expectedProductionTimeController,
                        decoration: InputDecoration(labelText: appLocalizations.expectedProductionTimePerUnit, border: OutlineInputBorder()), // أضف هذا النص
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) return appLocalizations.fieldRequired;
                          if (double.tryParse(value) == null || double.parse(value) <= 0) return appLocalizations.invalidNumber;
                          return null;
                        },
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 12),
                      // Requires Packaging checkbox
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(appLocalizations.requiresPackaging, textDirection: TextDirection.rtl),
                          Checkbox(
                            value: _requiresPackaging,
                            onChanged: (bool? newValue) {
                              setState(() {
                                _requiresPackaging = newValue ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                      // Requires Sticker checkbox
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(appLocalizations.requiresSticker, textDirection: TextDirection.rtl),
                          Checkbox(
                            value: _requiresSticker,
                            onChanged: (bool? newValue) {
                              setState(() {
                                _requiresSticker = newValue ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                      // Product Type Radio Buttons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(appLocalizations.productType, style: TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(appLocalizations.single, textDirection: TextDirection.rtl),
                              Radio<String>(
                                value: 'single',
                                groupValue: _productType,
                                onChanged: (String? value) {
                                  setState(() {
                                    _productType = value!;
                                  });
                                },
                              ),
                              SizedBox(width: 16),
                              Text(appLocalizations.compound, textDirection: TextDirection.rtl),
                              Radio<String>(
                                value: 'compound',
                                groupValue: _productType,
                                onChanged: (String? value) {
                                  setState(() {
                                    _productType = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Colors (Add/Remove chips)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(appLocalizations.colors, style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        textDirection: TextDirection.rtl,
                        children: [
                          ..._colors.map((color) => Chip(
                            label: Text(color),
                            onDelete: () {
                              setState(() {
                                _colors.remove(color);
                              });
                            },
                          )),
                          ActionChip(
                            avatar: Icon(Icons.add),
                            label: Text(appLocalizations.add),
                            onPressed: () async {
                              final newColor = await _showTextInputDialog(context, appLocalizations.enterColorName); // أضف هذا النص
                              if (newColor != null && newColor.isNotEmpty && !_colors.contains(newColor)) {
                                setState(() {
                                  _colors.add(newColor);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Additives (Add/Remove chips) - Similar to colors
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(appLocalizations.additives, style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        textDirection: TextDirection.rtl,
                        children: [
                          ..._additives.map((additive) => Chip(
                            label: Text(additive),
                            onDelete: () {
                              setState(() {
                                _additives.remove(additive);
                              });
                            },
                          )),
                          ActionChip(
                            avatar: Icon(Icons.add),
                            label: Text(appLocalizations.add),
                            onPressed: () async {
                              final newAdditive = await _showTextInputDialog(context, appLocalizations.enterAdditiveName); // أضف هذا النص
                              if (newAdditive != null && newAdditive.isNotEmpty && !_additives.contains(newAdditive)) {
                                setState(() {
                                  _additives.add(newAdditive);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Bill of Materials
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(appLocalizations.materialsUsed, style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: _billOfMaterials.asMap().entries.map((entry) {
                          final int index = entry.key;
                          final ProductMaterial bom = entry.value;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _billOfMaterials.removeAt(index);
                                  });
                                },
                              ),
                              Expanded(
                                child: Text(
                                  '${bom.quantityPerUnit} ${bom.unit} من ${bom.materialId}', // TODO: Convert ID to name
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: Icon(Icons.add),
                        label: Text(appLocalizations.addMaterial), // أضف هذا النص
                        onPressed: () async {
                          // Show dialog to add a material to BOM
                          final newBom = await _showAddBomMaterialDialog(context, useCases, appLocalizations);
                          if (newBom != null) {
                            setState(() {
                              _billOfMaterials.add(newBom);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(appLocalizations.cancel),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  child: Text(isEditing ? appLocalizations.save : appLocalizations.add),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (_billOfMaterials.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.bomRequired))); // أضف هذا النص
                        return;
                      }
                      try {
                        if (isEditing) {
                          await useCases.updateProduct(
                            id: product!.id,
                            productCode: _productCodeController.text,
                            name: _nameController.text,
                            description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
                            newImageFile: _pickedImage,
                            existingImageUrl: _existingImageUrl,
                            billOfMaterials: _billOfMaterials,
                            colors: _colors,
                            additives: _additives,
                            packagingType: _packagingTypeController.text,
                            requiresPackaging: _requiresPackaging,
                            requiresSticker: _requiresSticker,
                            productType: _productType,
                            expectedProductionTimePerUnit: double.parse(_expectedProductionTimeController.text),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.productUpdatedSuccessfully))); // أضف هذا النص
                        } else {
                          await useCases.addProduct(
                            productCode: _productCodeController.text,
                            name: _nameController.text,
                            description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
                            imageFile: _pickedImage,
                            billOfMaterials: _billOfMaterials,
                            colors: _colors,
                            additives: _additives,
                            packagingType: _packagingTypeController.text,
                            requiresPackaging: _requiresPackaging,
                            requiresSticker: _requiresSticker,
                            productType: _productType,
                            expectedProductionTimePerUnit: double.parse(_expectedProductionTimeController.text),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.productAddedSuccessfully))); // أضف هذا النص
                        }
                        Navigator.of(dialogContext).pop();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorSavingProduct}: $e'))); // أضف هذا النص
                        print('Error saving product: $e');
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _showTextInputDialog(BuildContext context, String title) {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, textAlign: TextAlign.right),
          content: TextField(
            controller: controller,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(hintText: title),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text(AppLocalizations.of(context)!.add),
              onPressed: () => Navigator.pop(context, controller.text),
            ),
          ],
        );
      },
    );
  }

  Future<ProductMaterial?> _showAddBomMaterialDialog(BuildContext context, InventoryUseCases useCases, AppLocalizations appLocalizations) async {
    final _quantityController = TextEditingController();
    RawMaterialModel? _selectedMaterial;
    final _formKey = GlobalKey<FormState>();

    return await showDialog<ProductMaterial>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(appLocalizations.addMaterialToBom, textAlign: TextAlign.right), // أضف هذا النص
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<List<RawMaterialModel>>(
                  stream: useCases.getRawMaterials(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('خطأ في تحميل المواد: ${snapshot.error}');
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text('لا توجد مواد أولية متاحة.');
                    }
                    return DropdownButtonFormField<RawMaterialModel>(
                      value: _selectedMaterial,
                      decoration: InputDecoration(labelText: appLocalizations.rawMaterial, border: OutlineInputBorder()), // أضف هذا النص
                      items: snapshot.data!.map((material) => DropdownMenuItem(
                        value: material,
                        child: Text(material.name, textDirection: TextDirection.rtl),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMaterial = value;
                        });
                      },
                      validator: (value) => value == null ? appLocalizations.fieldRequired : null,
                    );
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(labelText: appLocalizations.quantity, border: OutlineInputBorder()), // أضف هذا النص
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return appLocalizations.fieldRequired;
                    if (double.tryParse(value) == null || double.parse(value)! <= 0) return appLocalizations.invalidNumber;
                    return null;
                  },
                  textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            ElevatedButton(
              child: Text(appLocalizations.add),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, ProductMaterial(
                    materialId: _selectedMaterial!.id,
                    quantityPerUnit: double.parse(_quantityController.text),
                    unit: _selectedMaterial!.unit, // استخدام وحدة المادة المختارة
                  ));
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteProductConfirmationDialog(
      BuildContext context,
      InventoryUseCases useCases,
      AppLocalizations appLocalizations,
      String productId,
      String productName,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(appLocalizations.confirmDeletion),
          content: Text('${appLocalizations.confirmDeleteProduct}: "$productName"؟'), // أضف هذا النص
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: Text(appLocalizations.delete),
              onPressed: () async {
                try {
                  await useCases.deleteProduct(productId);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.productDeletedSuccessfully))); // أضف هذا النص
                  Navigator.of(dialogContext).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorDeletingProduct}: $e'))); // أضف هذا النص
                }
              },
            ),
          ],
        );
      },
    );
  }
}