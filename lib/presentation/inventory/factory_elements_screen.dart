import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import '../../data/models/factory_element_model.dart';
import '../../core/constants/app_enums.dart';
import '../../theme/app_colors.dart';
import '../../domain/usecases/factory_element_usecases.dart';

class FactoryElementsScreen extends StatefulWidget {
  const FactoryElementsScreen({super.key});

  @override
  State<FactoryElementsScreen> createState() => _FactoryElementsScreenState();
}

class _FactoryElementsScreenState extends State<FactoryElementsScreen> {
  String _selectedType = 'all';
  final List<String> _units = ['kg', 'liter', 'piece'];

  FactoryElementType _typeFromArabic(String type) {
    switch (type) {
      case 'مواد خام':
        return FactoryElementType.rawMaterial;
      case 'ملونات':
        return FactoryElementType.colorant;
      case 'مدخلات إنتاج':
        return FactoryElementType.productionInput;
      default:
        return FactoryElementType.custom;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'مواد خام':
        return Icons.inventory_2_outlined;
      case 'ملونات':
        return Icons.color_lens_outlined;
      case 'مدخلات إنتاج':
        return Icons.input_outlined;
      default:
        return Icons.widgets_outlined;
    }
  }

  Future<void> _deleteElement(String id) async {
    final useCases =
        Provider.of<FactoryElementUseCases>(context, listen: false);
    await useCases.deleteElement(id);
  }

  void _showDeleteConfirmationDialog(FactoryElementModel element) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            loc.confirmDeletion,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          content: Text(
            '${loc.delete} "${element.name}"?\n${loc.thisActionCannotBeUndone}',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await _deleteElement(element.id);
                if (mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              label: Text(loc.delete),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(FactoryElementModel element) {
    FactoryElementType type = _typeFromArabic(element.type);
    final nameController = TextEditingController(text: element.name);
    final customTypeController = TextEditingController(
      text: type == FactoryElementType.custom ? element.type : '',
    );
    String? unit = element.unit;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.edit,
              textAlign: TextAlign.center),
          content: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<FactoryElementType>(
                  value: type,
                  decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.elementType),
                  items: const [
                    DropdownMenuItem(
                      value: FactoryElementType.rawMaterial,
                      child:
                          Text('مواد خام', textDirection: TextDirection.rtl),
                    ),
                    DropdownMenuItem(
                      value: FactoryElementType.colorant,
                      child: Text('ملونات', textDirection: TextDirection.rtl),
                    ),
                    DropdownMenuItem(
                      value: FactoryElementType.productionInput,
                      child:
                          Text('مدخلات إنتاج', textDirection: TextDirection.rtl),
                    ),
                    DropdownMenuItem(
                      value: FactoryElementType.custom,
                      child: Text('مخصص', textDirection: TextDirection.rtl),
                    ),
                  ],
                  onChanged: (val) => setState(() => type = val!),
                ),
                const SizedBox(height: 12),
                if (type == FactoryElementType.custom)
                  TextField(
                    controller: customTypeController,
                    decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)!.enterElementType),
                    textDirection: TextDirection.rtl,
                  ),
                if (type == FactoryElementType.custom)
                  const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.elementName),
                  textDirection: TextDirection.rtl,
                ),
                if (type == FactoryElementType.rawMaterial) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: unit,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.selectUnit),
                    items: _units
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u, textDirection: TextDirection.rtl),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => unit = val),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final finalType = type == FactoryElementType.custom
                    ? customTypeController.text.trim()
                    : type.toArabicString();
                if (name.isEmpty || finalType.isEmpty) return;
                final useCases =
                    Provider.of<FactoryElementUseCases>(context, listen: false);
                useCases.updateElement(
                    id: element.id,
                    type: finalType,
                    name: name,
                    unit: unit);
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        );
      },
    );
  }

  void _showAddDialog() {
    FactoryElementType type = FactoryElementType.rawMaterial;
    final nameController = TextEditingController();
    final customTypeController = TextEditingController();
    String? unit = _units.first;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.addFactoryElement,
              textAlign: TextAlign.center),
          content: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<FactoryElementType>(
                  value: type,
                  decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.elementType),
                  items: const [
                    DropdownMenuItem(
                      value: FactoryElementType.rawMaterial,
                      child:
                          Text('مواد خام', textDirection: TextDirection.rtl),
                    ),
                    DropdownMenuItem(
                      value: FactoryElementType.colorant,
                      child: Text('ملونات', textDirection: TextDirection.rtl),
                    ),
                    DropdownMenuItem(
                      value: FactoryElementType.productionInput,
                      child:
                          Text('مدخلات إنتاج', textDirection: TextDirection.rtl),
                    ),
                    DropdownMenuItem(
                      value: FactoryElementType.custom,
                      child: Text('مخصص', textDirection: TextDirection.rtl),
                    ),
                  ],
                  onChanged: (val) => setState(() => type = val!),
                ),
                const SizedBox(height: 12),
                if (type == FactoryElementType.custom)
                  TextField(
                    controller: customTypeController,
                    decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)!.enterElementType),
                    textDirection: TextDirection.rtl,
                  ),
                if (type == FactoryElementType.custom)
                  const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.elementName),
                  textDirection: TextDirection.rtl,
                ),
                if (type == FactoryElementType.rawMaterial) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: unit,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.selectUnit),
                    items: _units
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u, textDirection: TextDirection.rtl),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => unit = val),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final finalType = type == FactoryElementType.custom
                    ? customTypeController.text.trim()
                    : type.toArabicString();
                if (name.isEmpty || finalType.isEmpty) return;
                final useCases =
                    Provider.of<FactoryElementUseCases>(context, listen: false);
                useCases.addElement(type: finalType, name: name, unit: unit);
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.add),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.factoryElements),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: loc.addFactoryElement,
          ),
        ],
      ),
      body: StreamBuilder<List<FactoryElementModel>>(
          stream:
              Provider.of<FactoryElementUseCases>(context).getElements(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final elements = snapshot.data!;
            if (elements.isEmpty) {
              return Center(child: Text(loc.noData));
            }

            final types = elements.map((e) => e.type).toSet().toList();
            final filtered = _selectedType == 'all'
                ? elements
                : elements.where((e) => e.type == _selectedType).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButton<String>(
                    value: _selectedType,
                    onChanged: (val) => setState(() => _selectedType = val!),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text(loc.all, textDirection: TextDirection.rtl),
                      ),
                      ...types.map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t, textDirection: TextDirection.rtl),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final element = filtered[index];
                      return _buildElementItem(element, loc);
                    },
                  ),
                ),
              ],
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: loc.addFactoryElement,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildElementItem(FactoryElementModel element, AppLocalizations loc) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: Icon(_iconForType(element.type)),
        ),
        title: Text(
          element.name,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          element.unit != null && element.unit!.isNotEmpty
              ? '${element.type} - ${element.unit}'
              : element.type,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'edit') {
              _showEditDialog(element);
            } else if (val == 'delete') {
              _showDeleteConfirmationDialog(element);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(loc.edit),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Text(loc.delete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
