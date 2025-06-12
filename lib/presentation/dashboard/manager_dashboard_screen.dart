import 'package:flutter/material.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final bool isTablet = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.managementDashboard),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: isTablet ? 2 : 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _buildCard(
              context,
              icon: Icons.assessment,
              title: appLocalizations.productionEfficiency,
              value: '85%',
            ),
            _buildCard(
              context,
              icon: Icons.electric_bolt,
              title: appLocalizations.machineElectricityUsage,
              value: '1200 kWh',
            ),
            _buildCard(
              context,
              icon: Icons.check_circle,
              title: appLocalizations.qualityReports,
              value: '3 pending',
            ),
            _buildCard(
              context,
              icon: Icons.local_shipping,
              title: appLocalizations.salesStatus,
              value: '12 orders',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context,
      {required IconData icon, required String title, required String value}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.blueGrey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(color: Colors.grey[700]),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
