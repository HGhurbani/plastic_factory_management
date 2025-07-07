import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/template_model.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:plastic_factory_management/theme/app_colors.dart';
import 'add_edit_template_screen.dart';

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
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () {
              _openAddEditTemplatePage(context);
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
                        _openAddEditTemplatePage(context);
                      },
                      icon: const Icon(Icons.add,color: Colors.white,),
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
          _openAddEditTemplatePage(context);
        },
        tooltip: appLocalizations.addTemplate,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTemplateItem(BuildContext context, TemplateModel template, InventoryUseCases useCases, AppLocalizations appLocalizations) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showTemplateDetailsDialog(context, appLocalizations, template);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      const Icon(Icons.crop_square, color: AppColors.primary, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        template.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openAddEditTemplatePage(context, template: template);
                      } else if (value == 'delete') {
                        _showDeleteTemplateConfirmationDialog(context, useCases, appLocalizations, template.id, template.name);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, color: AppColors.primary), const SizedBox(width: 8), Text(appLocalizations.edit)])),
                      PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, color: Colors.redAccent), const SizedBox(width: 8), Text(appLocalizations.delete)])),
                    ],
                  ),
                ],
              ),
              const Divider(height: 16),
              _buildInfoRow(appLocalizations.templateCode, template.code, icon: Icons.qr_code_2),
              _buildInfoRow(appLocalizations.templateWeight, template.weight.toString(), icon: Icons.scale),
              _buildInfoRow(appLocalizations.templateHourlyCost, template.costPerHour.toString(), icon: Icons.attach_money),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppColors.primary.withOpacity(0.7)),
            const SizedBox(width: 8),
          ],
          Text(
            '$label:',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  void _openAddEditTemplatePage(BuildContext context, {TemplateModel? template}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTemplateScreen(template: template),
      ),
    );
  }

  void _showTemplateDetailsDialog(BuildContext context, AppLocalizations appLocalizations, TemplateModel template) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              template.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(appLocalizations.templateCode, template.code, icon: Icons.qr_code_2),
                  _buildInfoRow(appLocalizations.templateWeight, template.weight.toString(), icon: Icons.scale),
                  _buildInfoRow(appLocalizations.templateHourlyCost, template.costPerHour.toString(), icon: Icons.attach_money),
                  if (template.colors.isNotEmpty)
                    _buildInfoRow(appLocalizations.colors, template.colors.join('، '), icon: Icons.color_lens),
                  if (template.materialsUsed.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(appLocalizations.materialsUsed, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: template.materialsUsed.map((m) {
                        final name = _rawMaterialNames[m.materialId] ?? appLocalizations.unknownMaterial;
                        return Text('${m.ratio} - $name', style: const TextStyle(fontSize: 14));
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(appLocalizations.close),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(appLocalizations.confirmDeletion, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            content: Text('${appLocalizations.confirmDeleteProduct}: "$templateName"\n\n${appLocalizations.thisActionCannotBeUndone}', textAlign: TextAlign.center),
            actionsAlignment: MainAxisAlignment.spaceAround,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(appLocalizations.cancel),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
