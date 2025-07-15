import 'package:flutter/material.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/presentation/routes/app_router.dart';

class ProductionBoardScreen extends StatelessWidget {
  const ProductionBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    final List<_BoardOption> options = [
      _BoardOption(
        title: appLocalizations.issueProductionOrders,
        icon: Icons.add_circle_outline,
        routeName: AppRouter.createProductionOrderRoute,
      ),
      _BoardOption(
        title: appLocalizations.trackDefectsShifts,
        icon: Icons.analytics_outlined,
        routeName: AppRouter.productionOrdersListRoute,
      ),
      // _BoardOption(
      //   title: appLocalizations.logMoldReceipt,
      //   icon: Icons.assignment_turned_in_outlined,
      //   routeName: AppRouter.productionOrdersListRoute,
      // ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.productionBoard),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: options.length + 1,
        itemBuilder: (context, index) {
          if (index == options.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              // child: Center(
              //   child: Text(
              //     'هنا يمكن لمدير المصنع متابعة مهام الإنتاج وإصدار الأوامر.',
              //     textAlign: TextAlign.center,
              //     textDirection: TextDirection.rtl,
              //   ),
              // ),
            );
          }

          final option = options[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pushNamed(option.routeName),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(option.icon, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option.title,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_left),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BoardOption {
  final String title;
  final IconData icon;
  final String routeName;

  const _BoardOption({
    required this.title,
    required this.icon,
    required this.routeName,
  });
}
