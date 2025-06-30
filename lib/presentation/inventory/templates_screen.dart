import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/template_model.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:plastic_factory_management/theme/app_colors.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  _TemplatesScreenState createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  Map<String, String> _rawMaterialNames = {};

  @override
  void initState() {
    super.initState();
    _fetchRawMaterialNames();
  }

  Future<void> _fetchRawMaterialNames() async {
    final inventoryUseCases = Provider.of<InventoryUseCases>(context, listen: false);
    final materials = await inventoryUseCases.getRawMaterials().first;
    if (mounted) {
      setState(() {
        _rawMaterialNames = {for (var m in materials) m.id: m.name};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final inventoryUseCases = Provider.of<InventoryUseCases>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.templates),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddEditTemplateDialog(context, inventoryUseCases, appLocalizations);
            },
            tooltip: appLocalizations.addTemplate,
          ),
        ],
      ),
      body: StreamBuilder<List<TemplateModel>>(
        stream: inventoryUseCases.getTemplates(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${appLocalizations.somethingWentWrong}: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.crop_square, color: Colors.grey[400], size: 80),
                    const SizedBox(height: 16),
                    Text(appLocalizations.noTemplatesAvailable, style: TextStyle(fontSize: 18, color: Colors.grey[600]), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(appLocalizations.tapToAddFirstTemplate, style: TextStyle(fontSize: 14, color: Colors.grey[500]), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showAddEditTemplateDialog(context, inventoryUseCases, appLocalizations);
                      },
                      icon: const Icon(Icons.add),
                      label: Text(appLocalizations.addTemplate),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          final templates = snapshot.data!;
          return ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return _buildTemplateItem(context, template, inventoryUseCases, appLocalizations);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditTemplateDialog(context, inventoryUseCases, appLocalizations);
        },
        tooltip: appLocalizations.addTemplate,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTemplateItem(BuildContext context, TemplateModel template, InventoryUseCases useCases, AppLocalizations appLocalizations) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text('${template.code} - ${template.name}', textDirection: TextDirection.rtl, textAlign: TextAlign.right),
        subtitle: Text('${appLocalizations.timeRequired}: ${template.timeRequired}', textDirection: TextDirection.rtl, textAlign: TextAlign.right),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showAddEditTemplateDialog(context, useCases, appLocalizations, template: template);
            } else if (value == 'delete') {
              _showDeleteTemplateConfirmationDialog(context, useCases, appLocalizations, template.id, template.name);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, color: AppColors.primary), const SizedBox(width: 8), Text(appLocalizations.edit)])),
            PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, color: Colors.redAccent), const SizedBox(width: 8), Text(appLocalizations.delete)])),
          ],
        ),
        onTap: () {
          _showAddEditTemplateDialog(context, useCases, appLocalizations, template: template);
        },
      ),
    );
  }

  void _showAddEditTemplateDialog(BuildContext context, InventoryUseCases useCases, AppLocalizations appLocalizations, {TemplateModel? template}) {
    final isEditing = template != null;
    final _formKey = GlobalKey<FormState>();
    final _codeController = TextEditingController(text: template?.code);
    final _nameController = TextEditingController(text: template?.name);
    final _timeController = TextEditingController(text: template?.timeRequired.toString());
    final _percentageController = TextEditingController(text: template?.percentage.toString());
    List<TemplateMaterial> _materials = List<TemplateMaterial>.from(template?.materialsUsed ?? []);
    List<String> _colors = List<String>.from(template?.colors ?? []);
    List<String> _additives = List<String>.from(template?.additives ?? []);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(isEditing ? appLocalizations.editTemplate : appLocalizations.addTemplate),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _codeController,
                        decoration: InputDecoration(labelText: appLocalizations.templateCode, border: const OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: appLocalizations.templateName, border: const OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? appLocalizations.fieldRequired : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _timeController,
                        decoration: InputDecoration(labelText: appLocalizations.timeRequired, border: const OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value!.isEmpty) return appLocalizations.fieldRequired;
                          if (double.tryParse(value) == null) return appLocalizations.invalidNumber;
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _percentageController,
                        decoration: InputDecoration(labelText: appLocalizations.percentage, border: const OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value!.isEmpty) return appLocalizations.fieldRequired;
                          if (double.tryParse(value) == null) return appLocalizations.invalidNumber;
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(appLocalizations.materialsUsed, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: _materials.asMap().entries.map((entry) {
                          final i = entry.key;
                          final m = entry.value;
                          final name = _rawMaterialNames[m.materialId] ?? appLocalizations.unknownMaterial;
                          return ListTile(
                            title: Text('$name - ${m.ratio}'),
                            leading: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () { setState(() { _materials.removeAt(i); }); },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final newMat = await _showAddMaterialDialog(context, useCases, appLocalizations, _materials.map((e) => e.materialId).toList());
                          if (newMat != null) setState(() { _materials.add(newMat); });
                        },
                        icon: const Icon(Icons.add),
                        label: Text(appLocalizations.addMaterial),
                      ),
                      const SizedBox(height: 12),
                      Align(alignment: Alignment.centerRight, child: Text(appLocalizations.colors, style: const TextStyle(fontWeight: FontWeight.bold))),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8.0, runSpacing: 4.0, children: [
                        ..._colors.map((c) => Chip(label: Text(c), onDeleted: () { setState(() { _colors.remove(c); }); })),
                        ActionChip(
                          avatar: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                          label: Text(appLocalizations.add),
                          onPressed: () async {
                            final newColor = await _showTextInputDialog(context, appLocalizations.enterColorName);
                            if (newColor != null && newColor.isNotEmpty) { setState(() { _colors.add(newColor); }); }
                          },
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Align(alignment: Alignment.centerRight, child: Text(appLocalizations.additives, style: const TextStyle(fontWeight: FontWeight.bold))),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8.0, runSpacing: 4.0, children: [
                        ..._additives.map((a) => Chip(label: Text(a), onDeleted: () { setState(() { _additives.remove(a); }); })),
                        ActionChip(
                          avatar: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                          label: Text(appLocalizations.add),
                          onPressed: () async {
                            final newAdd = await _showTextInputDialog(context, appLocalizations.enterAdditiveName);
                            if (newAdd != null && newAdd.isNotEmpty) { setState(() { _additives.add(newAdd); }); }
                          },
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(appLocalizations.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        if (isEditing) {
                          await useCases.updateTemplate(
                            id: template!.id,
                            code: _codeController.text,
                            name: _nameController.text,
                            timeRequired: double.parse(_timeController.text),
                            materialsUsed: _materials,
                            colors: _colors,
                            percentage: double.parse(_percentageController.text),
                            additives: _additives,
                          );
                        } else {
                          await useCases.addTemplate(
                            code: _codeController.text,
                            name: _nameController.text,
                            timeRequired: double.parse(_timeController.text),
                            materialsUsed: _materials,
                            colors: _colors,
                            percentage: double.parse(_percentageController.text),
                            additives: _additives,
                          );
                        }
                        Navigator.of(dialogContext).pop();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.somethingWentWrong}: $e')));
                      }
                    }
                  },
                  child: Text(isEditing ? appLocalizations.save : appLocalizations.add),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<TemplateMaterial?> _showAddMaterialDialog(BuildContext context, InventoryUseCases useCases, AppLocalizations appLocalizations, List<String> existingIds) async {
    final _ratioController = TextEditingController();
    RawMaterialModel? _selected;
    final _formKey = GlobalKey<FormState>();
    String? unit;
    return await showDialog<TemplateMaterial>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(appLocalizations.addMaterial),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    StreamBuilder<List<RawMaterialModel>>(
                      stream: useCases.getRawMaterials(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox();
                        }
                        final materials = snapshot.data!.where((m) => !existingIds.contains(m.id)).toList();
                        return DropdownButtonFormField<RawMaterialModel>(
                          value: _selected,
                          decoration: InputDecoration(labelText: appLocalizations.rawMaterial, border: const OutlineInputBorder()),
                          isExpanded: true,
                          items: materials.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                          onChanged: (val) { setState(() { _selected = val; unit = val?.unit; }); },
                          validator: (val) => val == null ? appLocalizations.fieldRequired : null,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ratioController,
                      decoration: InputDecoration(labelText: appLocalizations.percentage, border: const OutlineInputBorder(), suffixText: unit ?? ''),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value!.isEmpty) return appLocalizations.fieldRequired;
                        if (double.tryParse(value) == null) return appLocalizations.invalidNumber;
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(appLocalizations.cancel)),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _selected != null) {
                      Navigator.pop(dialogContext, TemplateMaterial(materialId: _selected!.id, ratio: double.parse(_ratioController.text)));
                    }
                  },
                  child: Text(appLocalizations.add),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<String?> _showTextInputDialog(BuildContext context, String title) {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final appLocalizations = AppLocalizations.of(dialogContext)!;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(title),
            content: TextField(controller: controller, decoration: InputDecoration(hintText: title, border: const OutlineInputBorder())),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(appLocalizations.cancel)),
              ElevatedButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: Text(appLocalizations.add)),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteTemplateConfirmationDialog(BuildContext context, InventoryUseCases useCases, AppLocalizations appLocalizations, String templateId, String templateName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(appLocalizations.confirmDeletion, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            content: Text('${appLocalizations.confirmDeleteProduct}: "$templateName"\n\n${appLocalizations.thisActionCannotBeUndone}', textAlign: TextAlign.right),
            actionsAlignment: MainAxisAlignment.spaceAround,
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(appLocalizations.cancel),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever, color: Colors.white),
                label: Text(appLocalizations.delete),
                onPressed: () async {
                  try {
                    await useCases.deleteTemplate(templateId);
                    Navigator.of(dialogContext).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${appLocalizations.errorDeletingProduct}: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }
}
