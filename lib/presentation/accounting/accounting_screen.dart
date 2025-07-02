// plastic_factory_management/lib/presentation/accounting/accounting_screen.dart

import 'package:flutter/material.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/presentation/routes/app_router.dart';
import 'package:plastic_factory_management/theme/app_colors.dart';

class AccountingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final List<_AccountingOption> options = [
      _AccountingOption(
        icon: Icons.receipt_long,
        label: appLocalizations.salesOrders,
        route: AppRouter.salesOrdersListRoute,
      ),
      _AccountingOption(
        icon: Icons.check_circle_outline,
        label: appLocalizations.sparePartRequests,
        route: AppRouter.sparePartRequestsRoute,
      ),
      _AccountingOption(
        icon: Icons.account_balance_wallet_outlined,
        label: 'التحقق من الموازنات',
        route: null,
      ),
      _AccountingOption(
        icon: Icons.payments_outlined,
        label: appLocalizations.paymentsManagement,
        route: AppRouter.paymentsRoute,
      ),
      _AccountingOption(
        icon: Icons.shopping_cart_checkout,
        label: appLocalizations.purchasesManagement,
        route: AppRouter.purchasesRoute,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.accountingModule),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'يمكن للمحاسب هنا مراجعة واعتماد طلبات المبيعات ومتابعة التقارير المالية.',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 24),
          ...options.map((o) => _buildOptionCard(context, o)).toList(),
        ],
      ),
    );
  }
}

class _AccountingOption {
  final IconData icon;
  final String label;
  final String? route;

  _AccountingOption({required this.icon, required this.label, this.route});
}

Widget _buildOptionCard(BuildContext context, _AccountingOption option) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: option.route == null
          ? null
          : () => Navigator.of(context).pushNamed(option.route!),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            Icon(option.icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    ),
  );
}
