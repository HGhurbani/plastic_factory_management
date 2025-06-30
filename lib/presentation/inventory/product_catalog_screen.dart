// plastic_factory_management/lib/presentation/inventory/product_catalog_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/data/models/template_model.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
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
  // A map to store template names as "id: name"
  Map<String, String> _templateNames = {};

  @override
  void initState() {
    super.initState();
    _fetchRawMaterialNames();
    _fetchTemplateNames();
  }

  // Fetch raw material names to display instead of IDs in BOM
  Future<void> _fetchRawMaterialNames() async {
    final inventoryUseCases = Provider.of<InventoryUseCases>(context, listen: false);
    final materials = await inventoryUseCases.getRawMaterials().first; // Get current list once
    if (mounted) {
      setState(() {
        _rawMaterialNames = {for (var material in materials) material.id: material.name};
      });
    }
  }

  // Fetch template names for display
  Future<void> _fetchTemplateNames() async {
    final inventoryUseCases = Provider.of<InventoryUseCases>(context, listen: false);
    final templates = await inventoryUseCases.getTemplates().first;
    if (mounted) {
      setState(() {
        _templateNames = {for (var t in templates) t.id: t.name};
      });
    }
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
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
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
              childAspectRatio: 0.95, //  **تعديل: جعل الكرت أقصر**
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

  // =======================================================================
  // WIDGET المُعدّل: كرت المنتج
  // =======================================================================
  Widget _buildProductGridItem(
      BuildContext context,
      ProductModel product,
      AppLocalizations appLocalizations,
      InventoryUseCases inventoryUseCases,
      ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () {
          if (product.templateIds.isNotEmpty) {
            _showProductTemplatesDialog(context, appLocalizations, inventoryUseCases, product);
          } else {
            _showProductDetailsDialog(context, appLocalizations, product);
          }
        },
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: Icon(Icons.category),
        ),
        title: Text(
          product.name,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          '${appLocalizations.templates}: ${product.templateIds.length}',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (String result) {
            if (result == 'edit') {
              _showAddEditProductDialog(context, inventoryUseCases, appLocalizations, product: product);
            } else if (result == 'delete') {
              _showDeleteProductConfirmationDialog(context, inventoryUseCases, appLocalizations, product.id, product.name);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(appLocalizations.edit),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Text(appLocalizations.delete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // **تعديل: ضمان RTL كامل**
  void _showProductDetailsDialog(BuildContext context, AppLocalizations appLocalizations, ProductModel product) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                            return const Center(child: CircularProgressIndicator());
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
                  Text(appLocalizations.colors, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(
                    product.colors.isEmpty ? appLocalizations.notApplicable : product.colors.join('، '),
                    style: TextStyle(color: Colors.grey[700]),
                  ),

                  const SizedBox(height: 12),
                  Text(appLocalizations.additives, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(
                    product.additives.isEmpty ? appLocalizations.notApplicable : product.additives.join('، '),
                    style: TextStyle(color: Colors.grey[700]),
                  ),

                  const SizedBox(height: 12),
                  Text(appLocalizations.templates, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(
                    product.templateIds.isEmpty
                        ? appLocalizations.notApplicable
                        : product.templateIds
                            .map((id) => _templateNames[id] ?? appLocalizations.unknown)
                            .join('، '),
                    style: TextStyle(color: Colors.grey[700]),
                  ),

                  const SizedBox(height: 12),
                  Text(appLocalizations.materialsUsed, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 4),
                  if (product.billOfMaterials.isEmpty)
                    Text(
                      appLocalizations.notApplicable,
                      style: TextStyle(color: Colors.grey[700]),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: product.billOfMaterials.map((bom) {
                        final materialName = _rawMaterialNames[bom.materialId] ?? appLocalizations.unknownMaterial;
                        return Text(
                          '${bom.quantityPerUnit} ${bom.unit} من $materialName',
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
          ),
        );
      },
    );
  }

  // **تعديل: تحسين row التفاصيل لـ RTL**
  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.primary.withOpacity(0.7)),
            const SizedBox(width: 8),
          ],
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showProductTemplatesDialog(BuildContext context,
      AppLocalizations appLocalizations,
      InventoryUseCases useCases,
      ProductModel product) async {
    final templates = await useCases.getTemplatesByIds(product.templateIds);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(appLocalizations.templates,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: templates
                    .map((t) => _buildTemplateDetails(appLocalizations, t))
                    .toList(),
              ),
            ),
            actions: [
              TextButton(
                child: Text(appLocalizations.close),
                onPressed: () => Navigator.of(dialogContext).pop(),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemplateDetails(
      AppLocalizations appLocalizations, TemplateModel template) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(height: 16),
            _buildDetailRow(appLocalizations.templateCode, template.code,
                icon: Icons.qr_code_2),
            _buildDetailRow(appLocalizations.timeRequired,
                template.timeRequired.toString(),
                icon: Icons.timer),
            _buildDetailRow(appLocalizations.percentage,
                template.percentage.toString(),
                icon: Icons.percent),
            if (template.colors.isNotEmpty)
              _buildDetailRow(
                  appLocalizations.colors, template.colors.join('، '),
                  icon: Icons.color_lens),
            if (template.additives.isNotEmpty)
              _buildDetailRow(
                  appLocalizations.additives, template.additives.join('، '),
                  icon: Icons.add),
            if (template.materialsUsed.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(appLocalizations.materialsUsed,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: template.materialsUsed.map((m) {
                  final name =
                      _rawMaterialNames[m.materialId] ?? appLocalizations.unknownMaterial;
                  return Text('${m.ratio} - $name',
                      style: const TextStyle(fontSize: 14));
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // **تعديل: ضمان RTL كامل**
  void _showAddEditProductDialog(
      BuildContext context,
      InventoryUseCases useCases,
      AppLocalizations appLocalizations, {
        ProductModel? product,
      }) {
    final isEditing = product != null;
    final bool isAdding = !isEditing;
    final _formKey = GlobalKey<FormState>();
    final _productCodeController = TextEditingController(text: product?.productCode);
    final _nameController = TextEditingController(text: product?.name);
    final _descriptionController = TextEditingController(text: product?.description);
    final _packagingTypeController = TextEditingController(text: product?.packagingType);
    final _expectedProductionTimeController = TextEditingController(text: product?.expectedProductionTimePerUnit.toStringAsFixed(1));

    bool _requiresPackaging = product?.requiresPackaging ?? false;
    bool _requiresSticker = product?.requiresSticker ?? false;
    String _productType = product?.productType ?? 'single';
    List<String> _colors = List<String>.from(product?.colors ?? []);
    List<String> _additives = List<String>.from(product?.additives ?? []);
    List<ProductMaterial> _billOfMaterials = List<ProductMaterial>.from(product?.billOfMaterials ?? []);
    List<String> _selectedTemplateIds = List<String>.from(product?.templateIds ?? []);

    File? _pickedImage;
    Uint8List? _pickedImageBytes;
    String? _existingImageUrl = product?.imageUrl;

    final ImagePicker _picker = ImagePicker();

    Future<void> _pickImage(StateSetter setState) async {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _pickedImageBytes = bytes;
            _pickedImage = null;
            _existingImageUrl = null;
          });
        } else {
          setState(() {
            _pickedImage = File(pickedFile.path);
            _pickedImageBytes = null;
            _existingImageUrl = null;
          });
        }
      }
    }


    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(
                  isEditing ? appLocalizations.editProduct : appLocalizations.addProduct,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                content: Form(
                  key: _formKey,
                  child: isAdding
                      ? SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: appLocalizations.productName,
                                  border: const OutlineInputBorder(),
                                  suffixIcon: const Icon(Icons.title),
                                ),
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right,
                                validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(appLocalizations.templates, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                              const SizedBox(height: 8),
                              StreamBuilder<List<TemplateModel>>(
                                stream: useCases.getTemplates(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  final templates = snapshot.data ?? [];
                                  final available = templates.where((t) => !_selectedTemplateIds.contains(t.id)).toList();
                                  final nameMap = {for (var t in templates) t.id: t.name};
                                  return Wrap(
                                    spacing: 8.0,
                                    runSpacing: 4.0,
                                    children: [
                                      ..._selectedTemplateIds.map((id) => Chip(
                                            label: Text(nameMap[id] ?? appLocalizations.unknown),
                                            deleteIcon: const Icon(Icons.cancel, size: 18),
                                            onDeleted: () { setState(() { _selectedTemplateIds.remove(id); }); },
                                            backgroundColor: AppColors.lightGrey,
                                          )),
                                      ActionChip(
                                        avatar: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                        label: Text(appLocalizations.add),
                                        onPressed: () async {
                                          final newId = await _showSelectTemplateDialog(context, available, appLocalizations);
                                          if (newId != null && !_selectedTemplateIds.contains(newId)) {
                                            setState(() { _selectedTemplateIds.add(newId); });
                                          }
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: GestureDetector(
                                  onTap: () => _pickImage(setState),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.grey[100],
                                    backgroundImage: _pickedImageBytes != null
                                        ? MemoryImage(_pickedImageBytes!)
                                        : (_pickedImage != null
                                            ? FileImage(_pickedImage!)
                                            : (_existingImageUrl != null
                                                ? NetworkImage(_existingImageUrl!)
                                                : null)) as ImageProvider?,
                                    child: _pickedImage == null &&
                                            _pickedImageBytes == null &&
                                            _existingImageUrl == null
                                        ? Icon(Icons.add_a_photo,
                                            size: 60,
                                            color: AppColors.primary.withOpacity(0.7))
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _productCodeController,
                                decoration: InputDecoration(
                                  labelText: appLocalizations.productCode,
                                  border: const OutlineInputBorder(),
                                  suffixIcon: const Icon(Icons.tag),
                                ),
                                validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: appLocalizations.productName,
                                  border: const OutlineInputBorder(),
                                  suffixIcon: const Icon(Icons.title),
                                ),
                                validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _descriptionController,
                                decoration: InputDecoration(
                                  labelText: appLocalizations.description,
                                  border: const OutlineInputBorder(),
                                  suffixIcon: const Icon(Icons.notes),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _packagingTypeController,
                                decoration: InputDecoration(
                                  labelText: appLocalizations.packagingType,
                                  border: const OutlineInputBorder(),
                                  suffixIcon: const Icon(Icons.backpack),
                                ),
                                validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _expectedProductionTimeController,
                                decoration: InputDecoration(
                                  labelText: appLocalizations.expectedProductionTimePerUnit,
                                  border: const OutlineInputBorder(),
                                  suffixIcon: const Icon(Icons.schedule),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value!.isEmpty) return appLocalizations.fieldRequired;
                                  if (double.tryParse(value) == null || double.parse(value) <= 0) return appLocalizations.invalidNumberPositive;
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              SwitchListTile(
                                title: Text(appLocalizations.requiresPackaging),
                                value: _requiresPackaging,
                                onChanged: (bool newValue) {
                                  setState(() {
                                    _requiresPackaging = newValue;
                                  });
                                },
                                secondary: const Icon(Icons.archive_outlined),
                                controlAffinity: ListTileControlAffinity.trailing,
                              ),
                              SwitchListTile(
                                title: Text(appLocalizations.requiresSticker),
                                value: _requiresSticker,
                                onChanged: (bool newValue) {
                                  setState(() {
                                    _requiresSticker = newValue;
                                  });
                                },
                                secondary: const Icon(Icons.sticky_note_2_outlined),
                                controlAffinity: ListTileControlAffinity.trailing,
                              ),
                        Center(
                          child: GestureDetector(
                            onTap: () => _pickImage(setState),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[100],
                              backgroundImage: _pickedImageBytes != null
                                  ? MemoryImage(_pickedImageBytes!)
                                  : (_pickedImage != null
                                  ? FileImage(_pickedImage!)
                                  : (_existingImageUrl != null
                                  ? NetworkImage(_existingImageUrl!)
                                  : null)) as ImageProvider?,
                              child: _pickedImage == null &&
                                  _pickedImageBytes == null &&
                                  _existingImageUrl == null
                                  ? Icon(Icons.add_a_photo,
                                  size: 60,
                                  color: AppColors.primary.withOpacity(0.7))
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _productCodeController,
                          decoration: InputDecoration(
                            labelText: appLocalizations.productCode,
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.tag),
                          ),
                          validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: appLocalizations.productName,
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.title),
                          ),
                          validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: appLocalizations.description,
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.notes),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _packagingTypeController,
                          decoration: InputDecoration(
                            labelText: appLocalizations.packagingType,
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.backpack),
                          ),
                          validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _expectedProductionTimeController,
                          decoration: InputDecoration(
                            labelText: appLocalizations.expectedProductionTimePerUnit,
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.schedule),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value!.isEmpty) return appLocalizations.fieldRequired;
                            if (double.tryParse(value) == null || double.parse(value) <= 0) return appLocalizations.invalidNumberPositive;
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: Text(appLocalizations.requiresPackaging),
                          value: _requiresPackaging,
                          onChanged: (bool newValue) {
                            setState(() {
                              _requiresPackaging = newValue;
                            });
                          },
                          secondary: const Icon(Icons.archive_outlined),
                          controlAffinity: ListTileControlAffinity.trailing,
                        ),
                        SwitchListTile(
                          title: Text(appLocalizations.requiresSticker),
                          value: _requiresSticker,
                          onChanged: (bool newValue) {
                            setState(() {
                              _requiresSticker = newValue;
                            });
                          },
                          secondary: const Icon(Icons.sticky_note_2_outlined),
                          controlAffinity: ListTileControlAffinity.trailing,
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(appLocalizations.productType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Row(
                              children: [
                                Radio<String>(
                                  value: 'compound',
                                  groupValue: _productType,
                                  onChanged: (String? value) {
                                    setState(() { _productType = value!; });
                                  },
                                  activeColor: AppColors.primary,
                                ),
                                Text(appLocalizations.compound),
                                const SizedBox(width: 16),
                                Radio<String>(
                                  value: 'single',
                                  groupValue: _productType,
                                  onChanged: (String? value) {
                                    setState(() { _productType = value!; });
                                  },
                                  activeColor: AppColors.primary,
                                ),
                                Text(appLocalizations.single),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(appLocalizations.colors, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          alignment: WrapAlignment.start,
                          children: [
                            ..._colors.map((color) => Chip(
                              label: Text(color),
                              deleteIcon: const Icon(Icons.cancel, size: 18),
                              onDeleted: () {
                                setState(() { _colors.remove(color); });
                              },
                              backgroundColor: AppColors.lightGrey,
                            )),
                            ActionChip(
                              avatar: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                              label: Text(appLocalizations.add),
                              onPressed: () async {
                                final newColor = await _showTextInputDialog(context, appLocalizations.enterColorName);
                                if (newColor != null && newColor.isNotEmpty && !_colors.contains(newColor)) {
                                  setState(() { _colors.add(newColor); });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(appLocalizations.additives, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          alignment: WrapAlignment.start,
                          children: [
                            ..._additives.map((additive) => Chip(
                              label: Text(additive),
                              deleteIcon: const Icon(Icons.cancel, size: 18),
                              onDeleted: () {
                                setState(() { _additives.remove(additive); });
                              },
                              backgroundColor: AppColors.lightGrey,
                            )),
                            ActionChip(
                              avatar: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                              label: Text(appLocalizations.add),
                              onPressed: () async {
                                final newAdditive = await _showTextInputDialog(context, appLocalizations.enterAdditiveName);
                                if (newAdditive != null && newAdditive.isNotEmpty && !_additives.contains(newAdditive)) {
                                  setState(() { _additives.add(newAdditive); });
                                }
                              },
                            ),
                          ],
                        ),
                      ], // end isEditing
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(appLocalizations.templates, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<List<TemplateModel>>(
                          stream: useCases.getTemplates(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final templates = snapshot.data ?? [];
                            final available = templates.where((t) => !_selectedTemplateIds.contains(t.id)).toList();
                            final nameMap = {for (var t in templates) t.id: t.name};
                            return Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: [
                                ..._selectedTemplateIds.map((id) => Chip(
                                  label: Text(nameMap[id] ?? appLocalizations.unknown),
                                  deleteIcon: const Icon(Icons.cancel, size: 18),
                                  onDeleted: () { setState(() { _selectedTemplateIds.remove(id); }); },
                                  backgroundColor: AppColors.lightGrey,
                                )),
                                ActionChip(
                                  avatar: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                  label: Text(appLocalizations.add),
                                  onPressed: () async {
                                    final newId = await _showSelectTemplateDialog(context, available, appLocalizations);
                                    if (newId != null && !_selectedTemplateIds.contains(newId)) {
                                      setState(() { _selectedTemplateIds.add(newId); });
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        if (isEditing) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(appLocalizations.materialsUsed, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _billOfMaterials.asMap().entries.map((entry) {
                            final int index = entry.key;
                            final ProductMaterial bom = entry.value;
                            final materialName = _rawMaterialNames[bom.materialId] ?? appLocalizations.unknownMaterial;
                            return ListTile(
                              visualDensity: VisualDensity.compact,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                '${bom.quantityPerUnit} ${bom.unit} من $materialName',
                                style: const TextStyle(fontSize: 15),
                              ),
                              leading: IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () {
                                  setState(() { _billOfMaterials.removeAt(index); });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_shopping_cart,color: Colors.white,),
                            label: Text(appLocalizations.addMaterial),
                            onPressed: () async {
                              final newBom = await _showAddBomMaterialDialog(context, useCases, appLocalizations, _billOfMaterials.map((e) => e.materialId).toList());
                              if (newBom != null) {
                                setState(() { _billOfMaterials.add(newBom); });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        ),
                      ],
                    ], // end isEditing
                    ),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(appLocalizations.cancel),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                  ),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: ElevatedButton.icon(
                      icon: Icon(isEditing ? Icons.save : Icons.add, color: Colors.white,),
                      label: Text(isEditing ? appLocalizations.save : appLocalizations.add),
                      onPressed: () async {
                        if (isEditing) {
                          if (_formKey.currentState!.validate()) {
                            if (_billOfMaterials.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(appLocalizations.bomRequired)));
                              return;
                            }
                            try {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext loadingContext) {
                                  return const Center(child: CircularProgressIndicator());
                                },
                              );
                              await useCases.updateProduct(
                                id: product!.id,
                                productCode: _productCodeController.text,
                                name: _nameController.text,
                                description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
                                newImageFile: _pickedImage,
                                newImageBytes: _pickedImageBytes,
                                existingImageUrl: _existingImageUrl,
                                billOfMaterials: _billOfMaterials,
                                colors: _colors,
                                additives: _additives,
                                templateIds: _selectedTemplateIds,
                                packagingType: _packagingTypeController.text,
                                requiresPackaging: _requiresPackaging,
                                requiresSticker: _requiresSticker,
                                productType: _productType,
                                expectedProductionTimePerUnit: double.parse(_expectedProductionTimeController.text),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(appLocalizations.productUpdatedSuccessfully)));
                              Navigator.of(context).pop();
                              Navigator.of(dialogContext).pop();
                            } catch (e) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${appLocalizations.errorSavingProduct}: ${e.toString()}')),
                              );
                            }
                          }
                        } else {
                          try {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext loadingContext) {
                                return const Center(child: CircularProgressIndicator());
                              },
                            );
                            await useCases.addProduct(
                              productCode: 'TMP-${DateTime.now().millisecondsSinceEpoch}',
                              name: _nameController.text,
                              description: null,
                              billOfMaterials: const [],
                              colors: const [],
                              additives: const [],
                              templateIds: _selectedTemplateIds,
                              packagingType: '',
                              requiresPackaging: false,
                              requiresSticker: false,
                              productType: 'single',
                              expectedProductionTimePerUnit: 0,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(appLocalizations.productAddedSuccessfully)));
                            Navigator.of(context).pop();
                            Navigator.of(dialogContext).pop();
                          } catch (e) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${appLocalizations.errorSavingProduct}: ${e.toString()}')),
                            );
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
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // **تعديل: ضمان RTL كامل**
  Future<String?> _showTextInputDialog(BuildContext context, String title) {
    TextEditingController controller = TextEditingController();
    final appLocalizations = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: title, border: const OutlineInputBorder()),
              autofocus: true,
            ),
            actions: <Widget>[
              TextButton(
                child: Text(appLocalizations.cancel),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: Text(appLocalizations.add),
                onPressed: () => Navigator.pop(context, controller.text.trim()),
              ),
            ],
          ),
        );
      },
    );
  }

  // **تعديل: ضمان RTL كامل**
  Future<ProductMaterial?> _showAddBomMaterialDialog(BuildContext context, InventoryUseCases useCases, AppLocalizations appLocalizations, List<String> existingMaterialIds) async {
    final _quantityController = TextEditingController();
    RawMaterialModel? _selectedMaterial;
    final _formKey = GlobalKey<FormState>();
    String? _unit;

    return await showDialog<ProductMaterial>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(appLocalizations.addMaterialToBom),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StreamBuilder<List<RawMaterialModel>>(
                      stream: useCases.getRawMaterials(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('${appLocalizations.errorLoadingMaterials}: ${snapshot.error}');
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Text(appLocalizations.noRawMaterialsAvailable);
                        }
                        final availableMaterials = snapshot.data!
                            .where((material) => !existingMaterialIds.contains(material.id))
                            .toList();

                        return DropdownButtonFormField<RawMaterialModel>(
                          value: _selectedMaterial,
                          decoration: InputDecoration(labelText: appLocalizations.rawMaterial, border: const OutlineInputBorder()),
                          isExpanded: true,
                          items: availableMaterials.map((material) => DropdownMenuItem(
                            value: material,
                            child: Text(material.name),
                          )).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedMaterial = value;
                              _unit = value?.unit;
                            });
                          },
                          validator: (value) => value == null ? appLocalizations.fieldRequired : null,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                          labelText: appLocalizations.quantity,
                          border: const OutlineInputBorder(),
                          suffixText: _unit ?? ''
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value!.isEmpty) return appLocalizations.fieldRequired;
                        if (double.tryParse(value) == null || double.parse(value) <= 0) return appLocalizations.invalidNumberPositive;
                        return null;
                      },
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
                    if (_formKey.currentState!.validate() && _selectedMaterial != null) {
                      Navigator.pop(dialogContext, ProductMaterial(
                        materialId: _selectedMaterial!.id,
                        quantityPerUnit: double.parse(_quantityController.text),
                        unit: _selectedMaterial!.unit,
                      ));
                    }
                  },
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<String?> _showSelectTemplateDialog(BuildContext context, List<TemplateModel> availableTemplates, AppLocalizations appLocalizations) async {
    TemplateModel? _selectedTemplate;
    return await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(appLocalizations.selectTemplate),
              content: DropdownButtonFormField<TemplateModel>(
                value: _selectedTemplate,
                decoration: InputDecoration(
                  labelText: appLocalizations.selectTemplate,
                  border: const OutlineInputBorder(),
                ),
                isExpanded: true,
                items: availableTemplates.map((template) => DropdownMenuItem(
                  value: template,
                  child: Text(template.name),
                )).toList(),
                onChanged: (value) => setState(() { _selectedTemplate = value; }),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(appLocalizations.cancel),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                ElevatedButton(
                  child: Text(appLocalizations.add),
                  onPressed: () {
                    if (_selectedTemplate != null) {
                      Navigator.pop(dialogContext, _selectedTemplate!.id);
                    }
                  },
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

// **تعديل: ضمان RTL كامل**
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
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(appLocalizations.confirmDeletion, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text(
            '${appLocalizations.confirmDeleteProduct}: "$productName"؟\n\n${appLocalizations.thisActionCannotBeUndone}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever, color: Colors.white,),
                label: Text(appLocalizations.delete),
                onPressed: () async {
                  try {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext loadingContext) {
                        return const Center(child: CircularProgressIndicator());
                      },
                    );
                    await useCases.deleteProduct(productId);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLocalizations.productDeletedSuccessfully)));
                    Navigator.of(dialogContext).pop();
                  } catch (e) {
                    Navigator.of(context).pop();
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
            ),
          ],
        ),
      );
    },
  );
}