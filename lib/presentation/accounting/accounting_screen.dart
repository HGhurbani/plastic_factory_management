// plastic_factory_management/lib/presentation/accounting/accounting_screen.dart

import 'package:flutter/material.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/presentation/routes/app_router.dart';

class AccountingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.accountingModule),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'يمكن للمحاسب هنا مراجعة واعتماد طلبات المبيعات ومتابعة التقارير المالية.',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: Text(appLocalizations.salesOrders),
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRouter.salesOrdersListRoute),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: Text(appLocalizations.sparePartRequests),
              onPressed: () {},
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('التحقق من الموازنات', textDirection: TextDirection.rtl),
              onPressed: () {},
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.payments_outlined),
              label: Text(appLocalizations.paymentsManagement),
              onPressed: () {},
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.shopping_cart_checkout),
              label: Text(appLocalizations.purchasesManagement),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
