// plastic_factory_management/lib/presentation/quality/quality_inspection_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/data/models/quality_check_model.dart';
import 'package:plastic_factory_management/domain/usecases/quality_usecases.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';

import 'quality_check_form_screen.dart';

class QualityInspectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final useCases = Provider.of<QualityUseCases>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.qualityModule),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QualityCheckFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<QualityCheckModel>>(
        stream: useCases.getQualityChecks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final checks = snapshot.data ?? [];
          if (checks.isEmpty) {
            return Center(child: Text(loc.noData));
          }
          return ListView.builder(
            itemCount: checks.length,
            itemBuilder: (context, index) {
              final check = checks[index];
              return ListTile(
                title: Text(check.productName, textDirection: TextDirection.rtl),
                subtitle: Text(
                  '${loc.rejectedQuantity}: ${check.rejectedQuantity}',
                  textDirection: TextDirection.rtl,
                ),
                trailing: Text(
                  check.createdAt.toDate().toString().split(' ').first,
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
