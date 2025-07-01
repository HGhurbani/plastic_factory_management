import 'package:flutter/material.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/presentation/routes/app_router.dart';

class ProductionBoardScreen extends StatelessWidget {
  const ProductionBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.productionBoard),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: Text(
              appLocalizations.issueProductionOrders,
              textDirection: TextDirection.rtl,
            ),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.createProductionOrderRoute);
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: Text(
              appLocalizations.trackDefectsShifts,
              textDirection: TextDirection.rtl,
            ),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.productionOrdersListRoute);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment_turned_in_outlined),
            title: Text(
              appLocalizations.logMoldReceipt,
              textDirection: TextDirection.rtl,
            ),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.productionOrdersListRoute);
            },
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'هنا يمكن لمدير المصنع متابعة مهام الإنتاج وإصدار الأوامر.',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}
