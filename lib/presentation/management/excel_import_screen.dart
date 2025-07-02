import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/theme/app_colors.dart';
import 'package:plastic_factory_management/presentation/management/excel_column_mapping_dialog.dart';

class ExcelImportScreen extends StatelessWidget {
  const ExcelImportScreen({super.key});

  Future<void> _pickAndImport(BuildContext context, String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.isNotEmpty ? excel.tables.values.first : null;
      if (sheet == null || sheet.rows.isEmpty) return;

      final headers = sheet.rows.first
          .map((c) => c?.value.toString() ?? '')
          .toList();
      final fields = _getFieldsForType(type);
      if (fields.isEmpty) return;

      final mapping = await showDialog<Map<String, String>>(
        context: context,
        builder: (_) => ExcelColumnMappingDialog(fields: fields, columns: headers),
      );
      if (mapping != null) {
        for (var i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          final data = <String, dynamic>{};
          mapping.forEach((field, column) {
            final index = headers.indexOf(column);
            if (index >= 0 && index < row.length) {
              data[field] = row[index]?.value;
            }
          });
          // ignore: avoid_print
          print('Imported row: $data');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.fileImportedSuccessfully)),
        );
      }
    }
  }

  List<String> _getFieldsForType(String type) {
    switch (type) {
      case 'raw':
        return ['code', 'name', 'unit'];
      case 'customers':
        return ['name', 'contactPerson', 'phone', 'email', 'address'];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.excelImportTitle),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          _buildImportCard(context, loc.importRawMaterials, Icons.inventory_2_outlined, 'raw'),
          _buildImportCard(context, loc.importCustomers, Icons.people_outline, 'customers'),
          _buildImportCard(context, loc.importProducts, Icons.widgets_outlined, 'products'),
          _buildImportCard(context, loc.importTemplates, Icons.view_module_outlined, 'templates'),
          _buildImportCard(context, loc.importMachines, Icons.precision_manufacturing_outlined, 'machines'),
          _buildImportCard(context, loc.importOperators, Icons.person_outline, 'operators'),
        ],
      ),
    );
  }

  Widget _buildImportCard(BuildContext context, String title, IconData icon, String type) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pickAndImport(context, type),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(icon, color: AppColors.primary, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
