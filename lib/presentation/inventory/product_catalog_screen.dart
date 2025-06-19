// plastic_factory_management/lib/presentation/inventory/product_catalog_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:plastic_factory_management/theme/app_colors.dart'; // Ensure this defines primary, secondary, etc.

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  _ProductCatalogScreenState createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  // A map to store raw material names, fetched once to avoid repeated calls
  Map<String, String> _rawMaterialNames = {};

  @override
  void initState() {
    super.initState();
    _fetchRawMaterialNames();
  }

  // Fetch raw material names to display instead of IDs in BOM
  Future<void> _fetchRawMaterialNames() async {
    final inventoryUseCases = Provider.of<InventoryUseCases>(context, listen: false);
    final materials = await inventoryUseCases.getRawMaterials().first; // Get current list once
    setState(() {
      _rawMaterialNames = {for (var material in materials) material.id: material.name};
    });
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final inventoryUseCases = Provider.of<InventoryUseCases>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.productCatalog),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined), // More specific icon for product
            onPressed: () {
              _showAddEditProductDialog(context, inventoryUseCases, appLocalizations);
            },
            tooltip: appLocalizations.addProduct,
          ),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: inventoryUseCases.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      appLocalizations.errorLoadingProducts, // New localization key
                      style: const TextStyle(fontSize: 18, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${appLocalizations.technicalDetails}: ${snapshot.error}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category_outlined, color: Colors.grey[400], size: 80), // Specific icon
                    const SizedBox(height: 16),
                    Text(
                      appLocalizations.noProductsAvailable, // New localization key
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appLocalizations.tapToAddFirstProduct, // New localization key
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showAddEditProductDialog(context, inventoryUseCases, appLocalizations);
                      },
                      icon: const Icon(Icons.add),
                      label: Text(appLocalizations.addProduct),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75, // Slightly adjusted for better fit with added content
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final product = snapshot.data![index];
              return _buildProductGridItem(context, product, appLocalizations, inventoryUseCases);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditProductDialog(context, inventoryUseCases, appLocalizations);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: appLocalizations.addProduct,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductGridItem(
      BuildContext context,
      ProductModel product,
      AppLocalizations appLocalizations,
      InventoryUseCases inventoryUseCases,
      ) {
    return GestureDetector(
      onTap: () {
        _showProductDetailsDialog(context, appLocalizations, product);
      },
      child: Card(
        elevation: 6, // Increased elevation for a more prominent card
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // More rounded corners
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                    product.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.progress,
                          color: AppColors.primary,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey[400])),
                  )
                      : Container(
                    color: Colors.grey[200],
                    child: Center(child: Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.grey[500])),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.productType == 'single' ? Colors.blue.withOpacity(0.8) : Colors.green.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.productType == 'single' ? appLocalizations.single : appLocalizations.compound,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17), // Slightly larger
                      textAlign: TextAlign.right,
                      maxLines: 1, // Limit to one line for better fit
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${appLocalizations.productCode}: ${product.productCode}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      textAlign: TextAlign.right,
                    ),
                    Text(
                      '${appLocalizations.packagingType}: ${product.packagingType}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.right,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 22, color: AppColors.secondary),
                          onPressed: () {
                            _showAddEditProductDialog(context, inventoryUseCases, appLocalizations, product: product);
                          },
                          tooltip: appLocalizations.edit,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 22, color: Colors.redAccent), // Outline icon
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
  }

  void _showProductDetailsDialog(BuildContext context, AppLocalizations appLocalizations, ProductModel product) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(product.name, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(value: loadingProgress.progress),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              height: 180,
                              color: Colors.grey[200],
                              child: Center(child: Icon(Icons.broken_image, size: 60, color: Colors.grey[400])),
                            ),
                      ),
                    ),
                  ),
                _buildDetailRow(appLocalizations.productCode, product.productCode, icon: Icons.qr_code),
                if (product.description != null && product.description!.isNotEmpty)
                  _buildDetailRow(appLocalizations.description, product.description!, icon: Icons.description),
                _buildDetailRow(appLocalizations.packagingType, product.packagingType, icon: Icons.eco),
                _buildDetailRow(appLocalizations.requiresPackaging, product.requiresPackaging ? appLocalizations.yes : appLocalizations.no, icon: Icons.archive),
                _buildDetailRow(appLocalizations.requiresSticker, product.requiresSticker ? appLocalizations.yes : appLocalizations.no, icon: Icons.sticky_note_2),
                _buildDetailRow(appLocalizations.productType, product.productType == 'single' ? appLocalizations.single : appLocalizations.compound, icon: Icons.category),
                _buildDetailRow(appLocalizations.expectedProductionTimePerUnit, '${product.expectedProductionTimePerUnit.toStringAsFixed(1)} ${appLocalizations.minutesPerUnit}', icon: Icons.timer),

                const Divider(height: 24),
                Text(appLocalizations.colors, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17), textAlign: TextAlign.right),
                const SizedBox(height: 4),
                Text(
                  product.colors.isEmpty ? appLocalizations.notApplicable : product.colors.join(', '),
                  textAlign: TextAlign.right,
                  style: TextStyle(color: Colors.grey[700]),
                ),

                const SizedBox(height: 12),
                Text(appLocalizations.additives, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17), textAlign: TextAlign.right),
                const SizedBox(height: 4),
                Text(
                  product.additives.isEmpty ? appLocalizations.notApplicable : product.additives.join(', '),
                  textAlign: TextAlign.right,
                  style: TextStyle(color: Colors.grey[700]),
                ),

                const SizedBox(height: 12),
                Text(appLocalizations.materialsUsed, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17), textAlign: TextAlign.right),
                const SizedBox(height: 4),
                if (product.billOfMaterials.isEmpty)
                  Text(
                    appLocalizations.notApplicable,
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey[700]),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: product.billOfMaterials.map((bom) {
                      final materialName = _rawMaterialNames[bom.materialId] ?? appLocalizations.unknownMaterial;
                      return Text(
                        '${bom.quantityPerUnit} ${bom.unit} من $materialName',
                        textAlign: TextAlign.right,
                        style: TextStyle(color: Colors.grey[700]),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.close),
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? textColor, bool isBold = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15, // Slightly larger font size
                color: textColor ?? Colors.black87,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 15, // Slightly larger font size
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 18, color: AppColors.primary.withOpacity(0.7)), // Icon for visual clarity
          ]
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
    final _expectedProductionTimeController = TextEditingController(text: product?.expectedProductionTimePerUnit.toStringAsFixed(1)); // Format for display

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
          _existingImageUrl = null;
        });
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEditing ? appLocalizations.editProduct : appLocalizations.addProduct,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Image Picker
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 60, // Larger avatar
                            backgroundColor: Colors.grey[100],
                            backgroundImage: _pickedImage != null
                                ? FileImage(_pickedImage!)
                                : (_existingImageUrl != null ? NetworkImage(_existingImageUrl!) as ImageProvider : null),
                            child: _pickedImage == null && _existingImageUrl == null
                                ? Icon(Icons.add_a_photo, size: 60, color: AppColors.primary.withOpacity(0.7)) // More inviting icon
                                : null,
                            foregroundColor: Colors.white, // Ensure icon color is visible on background
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _productCodeController,
                        decoration: InputDecoration(
                          labelText: appLocalizations.productCode,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.tag), // Icon for code
                        ),
                        validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: appLocalizations.productName,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.title), // Icon for name
                        ),
                        validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: appLocalizations.description,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.notes), // Icon for description
                        ),
                        maxLines: 3,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _packagingTypeController,
                        decoration: InputDecoration(
                          labelText: appLocalizations.packagingType,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.packaging), // Icon for packaging
                        ),
                        validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _expectedProductionTimeController,
                        decoration: InputDecoration(
                          labelText: appLocalizations.expectedProductionTimePerUnit,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.schedule), // Icon for time
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) return appLocalizations.fieldRequired;
                          if (double.tryParse(value) == null || double.parse(value) <= 0) return appLocalizations.invalidNumberPositive; // New validation message
                          return null;
                        },
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 12),
                      // Requires Packaging checkbox
                      SwitchListTile(
                        title: Text(appLocalizations.requiresPackaging, textDirection: TextDirection.rtl),
                        value: _requiresPackaging,
                        onChanged: (bool newValue) {
                          setState(() {
                            _requiresPackaging = newValue;
                          });
                        },
                        secondary: const Icon(Icons.archive_outlined), // Icon for switch
                      ),
                      // Requires Sticker checkbox
                      SwitchListTile(
                        title: Text(appLocalizations.requiresSticker, textDirection: TextDirection.rtl),
                        value: _requiresSticker,
                        onChanged: (bool newValue) {
                          setState(() {
                            _requiresSticker = newValue;
                          });
                        },
                        secondary: const Icon(Icons.sticky_note_2_outlined), // Icon for switch
                      ),
                      const SizedBox(height: 12),
                      // Product Type Radio Buttons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(appLocalizations.productType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                activeColor: AppColors.primary,
                              ),
                              const SizedBox(width: 16),
                              Text(appLocalizations.compound, textDirection: TextDirection.rtl),
                              Radio<String>(
                                value: 'compound',
                                groupValue: _productType,
                                onChanged: (String? value) {
                                  setState(() {
                                    _productType = value!;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Colors (Add/Remove chips)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(appLocalizations.colors, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        textDirection: TextDirection.rtl,
                        children: [
                          ..._colors.map((color) => Chip(
                            label: Text(color),
                            deleteIcon: const Icon(Icons.cancel, size: 18),
                            onDeleted: () {
                              setState(() {
                                _colors.remove(color);
                              });
                            },
                            backgroundColor: AppColors.lightGrey, // Custom chip color
                          )),
                          ActionChip(
                            avatar: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                            label: Text(appLocalizations.add),
                            onPressed: () async {
                              final newColor = await _showTextInputDialog(context, appLocalizations.enterColorName);
                              if (newColor != null && newColor.isNotEmpty && !_colors.contains(newColor)) {
                                setState(() {
                                  _colors.add(newColor);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Additives (Add/Remove chips) - Similar to colors
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(appLocalizations.additives, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        textDirection: TextDirection.rtl,
                        children: [
                          ..._additives.map((additive) => Chip(
                            label: Text(additive),
                            deleteIcon: const Icon(Icons.cancel, size: 18),
                            onDeleted: () {
                              setState(() {
                                _additives.remove(additive);
                              });
                            },
                            backgroundColor: AppColors.lightGrey,
                          )),
                          ActionChip(
                            avatar: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                            label: Text(appLocalizations.add),
                            onPressed: () async {
                              final newAdditive = await _showTextInputDialog(context, appLocalizations.enterAdditiveName);
                              if (newAdditive != null && newAdditive.isNotEmpty && !_additives.contains(newAdditive)) {
                                setState(() {
                                  _additives.add(newAdditive);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Bill of Materials
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(appLocalizations.materialsUsed, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: _billOfMaterials.isEmpty
                            ? [
                          Text(
                            appLocalizations.noMaterialsAdded, // New localization key
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.right,
                          )
                        ]
                            : _billOfMaterials.asMap().entries.map((entry) {
                          final int index = entry.key;
                          final ProductMaterial bom = entry.value;
                          final materialName = _rawMaterialNames[bom.materialId] ?? appLocalizations.unknownMaterial;
                          return ListTile(
                            visualDensity: VisualDensity.compact, // Compact list tile
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${bom.quantityPerUnit} ${bom.unit} من $materialName',
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(fontSize: 15),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _billOfMaterials.removeAt(index);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_shopping_cart), // More specific icon
                        label: Text(appLocalizations.addMaterial),
                        onPressed: () async {
                          final newBom = await _showAddBomMaterialDialog(context, useCases, appLocalizations);
                          if (newBom != null) {
                            setState(() {
                              _billOfMaterials.add(newBom);
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary, // Use secondary color
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(appLocalizations.cancel),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                ),
                ElevatedButton.icon(
                  icon: Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(isEditing ? appLocalizations.save : appLocalizations.add),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (_billOfMaterials.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(appLocalizations.bomRequired)));
                        return;
                      }
                      try {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext loadingContext) {
                            return const Center(child: CircularProgressIndicator());
                          },
                        );

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
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(appLocalizations.productUpdatedSuccessfully)));
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
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(appLocalizations.productAddedSuccessfully)));
                        }
                        Navigator.of(context).pop(); // Pop the loading indicator
                        Navigator.of(dialogContext).pop(); // Pop the dialog
                      } catch (e) {
                        Navigator.of(context).pop(); // Pop the loading indicator
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${appLocalizations.errorSavingProduct}: ${e.toString()}')),
                        );
                        print('Error saving product: $e'); // For debugging
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
        final appLocalizations = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(title, textAlign: TextAlign.right),
          content: TextField(
            controller: controller,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(hintText: title, border: const OutlineInputBorder()),
            autofocus: true, // Auto focus for quick input
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text(appLocalizations.add),
              onPressed: () => Navigator.pop(context, controller.text.trim()), // Trim whitespace
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

    // Fetch materials once for the dropdown to avoid flickering
    final materialsFuture = useCases.getRawMaterials().first;

    return await showDialog<ProductMaterial>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(appLocalizations.addMaterialToBom, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<List<RawMaterialModel>>(
                  future: materialsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('${appLocalizations.errorLoadingMaterials}: ${snapshot.error}');
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text(appLocalizations.noRawMaterialsAvailable);
                    }
                    return DropdownButtonFormField<RawMaterialModel>(
                      value: _selectedMaterial,
                      decoration: InputDecoration(
                        labelText: appLocalizations.rawMaterial,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.recycling), // Icon for raw material
                      ),
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
                      menuMaxHeight: MediaQuery.of(context).size.height * 0.4, // Limit dropdown height
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.quantity,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.unfold_less_double), // Icon for quantity
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return appLocalizations.fieldRequired;
                    if (double.tryParse(value) == null || double.parse(value)! <= 0) return appLocalizations.invalidNumberPositive;
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
                    unit: _selectedMaterial!.unit,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(appLocalizations.confirmDeletion, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text(
            '${appLocalizations.confirmDeleteProduct}: "$productName"?\n\n${appLocalizations.thisActionCannotBeUndone}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: Text(appLocalizations.delete),
              onPressed: () async {
                try {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext loadingContext) {
                      return const Center(child: CircularProgressIndicator());
                    },
                  );
                  await useCases.deleteProduct(productId);
                  Navigator.of(context).pop(); // Pop the loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.productDeletedSuccessfully)));
                  Navigator.of(dialogContext).pop();
                } catch (e) {
                  Navigator.of(context).pop(); // Pop the loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.errorDeletingProduct}: ${e.toString()}')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}