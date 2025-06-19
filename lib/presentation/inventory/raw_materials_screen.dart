// plastic_factory_management/lib/presentation/inventory/raw_materials_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:plastic_factory_management/theme/app_colors.dart'; // Assuming this defines your app's color scheme

class RawMaterialsScreen extends StatefulWidget {
  const RawMaterialsScreen({super.key});

  @override
  _RawMaterialsScreenState createState() => _RawMaterialsScreenState();
}

class _RawMaterialsScreenState extends State<RawMaterialsScreen> {
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final inventoryUseCases = Provider.of<InventoryUseCases>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.rawMaterials),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor, // Consistent theme color
        foregroundColor: Colors.white, // White text for better contrast
        elevation: 0, // No shadow for a cleaner look
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline), // More descriptive icon
            onPressed: () {
              _showAddEditMaterialDialog(context, inventoryUseCases, appLocalizations);
            },
            tooltip: appLocalizations.addRawMaterial,
          ),
        ],
      ),
      body: StreamBuilder<List<RawMaterialModel>>(
        stream: inventoryUseCases.getRawMaterials(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Enhanced error message
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      appLocalizations.errorLoadingMaterials, // New localization key
                      style: const TextStyle(fontSize: 18, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${appLocalizations.technicalDetails}: ${snapshot.error}', // New localization key
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Enhanced empty state message
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.widgets_outlined, color: Colors.grey[400], size: 80),
                    const SizedBox(height: 16),
                    Text(
                      appLocalizations.noRawMaterialsAvailable, // New localization key
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appLocalizations.tapToAddFirstMaterial, // New localization key
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showAddEditMaterialDialog(context, inventoryUseCases, appLocalizations);
                      },
                      icon: const Icon(Icons.add),
                      label: Text(appLocalizations.addRawMaterial),
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

          return ListView.builder(
            itemCount: snapshot.data!.length,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemBuilder: (context, index) {
              final material = snapshot.data![index];
              final isBelowMin = material.currentQuantity <= material.minStockLevel;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4, // Slightly increased elevation for better prominence
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners for a softer look
                  side: isBelowMin ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none, // Red border for low stock
                ),
                color: isBelowMin ? Colors.red.shade50 : Theme.of(context).cardColor, // Use theme's card color
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isBelowMin ? Colors.red : AppColors.primary, // Dynamic leading icon color
                      child: Icon(
                        isBelowMin ? Icons.warning_amber : Icons.inventory_2_outlined, // More relevant icon
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      material.name,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), // Larger, bolder title
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${appLocalizations.currentQuantity}: ${material.currentQuantity} ${material.unit}',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: isBelowMin ? Colors.red[800] : Colors.grey[700],
                            fontWeight: isBelowMin ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        Text(
                          '${appLocalizations.minStockLevel}: ${material.minStockLevel} ${material.unit}',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (isBelowMin)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              appLocalizations.lowStockWarning,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.secondary), // Use secondary color for edit
                          onPressed: () {
                            _showAddEditMaterialDialog(context, inventoryUseCases, appLocalizations, material: material);
                          },
                          tooltip: appLocalizations.edit,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent), // A slightly softer red for delete
                          onPressed: () {
                            _showDeleteConfirmationDialog(context, inventoryUseCases, appLocalizations, material.id, material.name);
                          },
                          tooltip: appLocalizations.delete,
                        ),
                      ],
                    ),
                    onTap: () {
                      // Optional: Navigate to a detail screen for the raw material
                      // Navigator.of(context).push(MaterialPageRoute(builder: (_) => RawMaterialDetailScreen(material: material)));
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditMaterialDialog(context, inventoryUseCases, appLocalizations);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: appLocalizations.addRawMaterial,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditMaterialDialog(
      BuildContext context,
      InventoryUseCases useCases,
      AppLocalizations appLocalizations, {
        RawMaterialModel? material,
      }) {
    final isEditing = material != null;
    final _nameController = TextEditingController(text: material?.name);
    final _quantityController = TextEditingController(text: material?.currentQuantity.toString());
    final _unitController = TextEditingController(text: material?.unit);
    final _minStockController = TextEditingController(text: material?.minStockLevel.toString());
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            isEditing ? appLocalizations.editRawMaterial : appLocalizations.addRawMaterial,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.materialName,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.article), // Icon for name
                    ),
                    validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.currentQuantity,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.numbers), // Icon for quantity
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return appLocalizations.fieldRequired;
                      if (double.tryParse(value) == null) return appLocalizations.invalidNumber;
                      if (double.parse(value) < 0) return appLocalizations.quantityCannotBeNegative; // New validation
                      return null;
                    },
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _unitController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.unitOfMeasurement,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.straighten), // Icon for unit
                    ),
                    validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _minStockController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.minStockLevel,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.low_priority), // Icon for min stock
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return appLocalizations.fieldRequired;
                      if (double.tryParse(value) == null) return appLocalizations.invalidNumber;
                      if (double.parse(value) < 0) return appLocalizations.minStockCannotBeNegative; // New validation
                      return null;
                    },
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]), // Styled cancel button
            ),
            ElevatedButton.icon( // Changed to ElevatedButton.icon
              icon: Icon(isEditing ? Icons.save : Icons.add),
              label: Text(isEditing ? appLocalizations.save : appLocalizations.add),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    if (isEditing) {
                      await useCases.updateRawMaterial(
                        id: material!.id,
                        name: _nameController.text,
                        currentQuantity: double.parse(_quantityController.text),
                        unit: _unitController.text,
                        minStockLevel: double.parse(_minStockController.text),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(appLocalizations.materialUpdatedSuccessfully)));
                    } else {
                      await useCases.addRawMaterial(
                        name: _nameController.text,
                        currentQuantity: double.parse(_quantityController.text),
                        unit: _unitController.text,
                        minStockLevel: double.parse(_minStockController.text),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(appLocalizations.materialAddedSuccessfully)));
                    }
                    Navigator.of(dialogContext).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${appLocalizations.errorSavingMaterial}: ${e.toString()}')), // Use e.toString() for better error message
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
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context,
      InventoryUseCases useCases,
      AppLocalizations appLocalizations,
      String materialId,
      String materialName,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(appLocalizations.confirmDeletion, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text(
            '${appLocalizations.confirmDeleteMaterial}: "$materialName"?\n\n${appLocalizations.thisActionCannotBeUndone}', // Added warning
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceAround, // Distribute buttons
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),
            ElevatedButton.icon( // Changed to ElevatedButton.icon
              icon: const Icon(Icons.delete_forever), // More impactful icon
              label: Text(appLocalizations.delete),
              onPressed: () async {
                try {
                  await useCases.deleteRawMaterial(materialId);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(appLocalizations.materialDeletedSuccessfully)));
                  Navigator.of(dialogContext).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.errorDeletingMaterial}: ${e.toString()}')),
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