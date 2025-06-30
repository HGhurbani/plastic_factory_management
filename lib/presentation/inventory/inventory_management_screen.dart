// plastic_factory_management/lib/presentation/inventory/inventory_management_screen.dart

import 'package:flutter/material.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/presentation/routes/app_router.dart';

class InventoryManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.inventoryModule),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.warehouse),
              label: Text(appLocalizations.rawMaterials),
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRouter.rawMaterialsRoute),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.category),
              label: Text(appLocalizations.productCatalog),
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRouter.productCatalogRoute),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.view_module),
              label: Text(appLocalizations.templates),
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRouter.templatesRoute),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.local_shipping),
              label: Text(appLocalizations.warehouseRequests),
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRouter.warehouseRequestsRoute),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('استلام المنتجات الجاهزة', textDirection: TextDirection.rtl),
              onPressed: () {},
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('صرف طلبات المبيعات', textDirection: TextDirection.rtl),
              onPressed: () {},
            ),

          ],
        ),
      ),
    );
  }
}
