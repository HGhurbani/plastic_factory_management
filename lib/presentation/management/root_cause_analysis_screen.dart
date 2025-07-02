import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/domain/usecases/quality_usecases.dart';
import 'package:plastic_factory_management/data/models/quality_check_model.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';

class RootCauseAnalysisScreen extends StatelessWidget {
  const RootCauseAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final qualityUseCases = Provider.of<QualityUseCases>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.rootCauseAnalysis),
        centerTitle: true,
      ),
      body: StreamBuilder<List<QualityCheckModel>>(
        stream: qualityUseCases.getQualityChecks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final checks = snapshot.data ?? [];
          if (checks.isEmpty) {
            return Center(child: Text(loc.noData));
          }
          final Map<String, int> counts = {};
          for (final check in checks) {
            final key = check.defectAnalysis?.trim().isNotEmpty == true
                ? check.defectAnalysis!
                : loc.unknown;
            counts[key] = (counts[key] ?? 0) + 1;
          }
          final entries = counts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                title: Text(entry.key, textDirection: TextDirection.rtl),
                trailing: Text(entry.value.toString()),
              );
            },
          );
        },
      ),
    );
  }
}
