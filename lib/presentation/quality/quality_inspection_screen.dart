// plastic_factory_management/lib/presentation/quality/quality_inspection_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:plastic_factory_management/data/models/quality_check_model.dart';
import 'package:plastic_factory_management/domain/usecases/quality_usecases.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/theme/app_colors.dart';

import 'quality_check_form_screen.dart';

class QualityInspectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final useCases = Provider.of<QualityUseCases>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.qualityChecks),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QualityCheckFormScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final check = checks[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                              const Icon(Icons.fact_check, color: AppColors.primary, size: 28),
                              const SizedBox(width: 8),
                              Text(
                                check.productName,
                                textDirection: TextDirection.rtl,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            intl.DateFormat('yyyy-MM-dd').format(check.createdAt.toDate()),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      _buildInfoRow(loc.inspectProductDelivery, check.inspectedQuantity.toString(), icon: Icons.inventory_2),
                      _buildInfoRow(loc.rejectedQuantity, check.rejectedQuantity.toString(), icon: Icons.highlight_remove_outlined),
                      _buildInfoRow(loc.shiftSupervisor, check.shiftSupervisorName, icon: Icons.supervisor_account_outlined),
                      _buildInfoRow(loc.qualityInspector, check.qualityInspectorName, icon: Icons.verified_user_outlined),
                      if (check.defectAnalysis != null && check.defectAnalysis!.trim().isNotEmpty)
                        _buildInfoRow(loc.defectAnalysis, check.defectAnalysis!, icon: Icons.report_problem_outlined),
                    ],
                  ),
                ),
              );
            },
          );
        },
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
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
}
