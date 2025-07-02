import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/theme/app_colors.dart';

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
      // TODO: Parse [excel] according to [type] and save to Firestore
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fileImportedSuccessfully)),
      );
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
