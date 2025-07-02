import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/data/models/maintenance_log_model.dart';
import 'package:plastic_factory_management/data/models/production_order_model.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/sales_order_model.dart';
import 'package:plastic_factory_management/domain/usecases/maintenance_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/production_order_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/sales_usecases.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import '../routes/app_router.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final productionUseCases = Provider.of<ProductionOrderUseCases>(context);
    final maintenanceUseCases = Provider.of<MaintenanceUseCases>(context);
    final salesUseCases = Provider.of<SalesUseCases>(context);
    final inventoryUseCases = Provider.of<InventoryUseCases>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.reports),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.productionDashboard),
            Tab(text: loc.maintenanceDashboard),
            Tab(text: loc.salesDashboard),
            Tab(text: loc.inventoryDashboard),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: loc.rootCauseAnalysis,
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRouter.rootCauseAnalysisRoute),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductionTab(productionUseCases, loc),
          _buildMaintenanceTab(maintenanceUseCases, loc),
          _buildSalesTab(salesUseCases, loc),
          _buildInventoryTab(inventoryUseCases, loc),
        ],
      ),
    );
  }

  Widget _buildKpi(String label, int value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, textDirection: TextDirection.rtl, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildProductionTab(
      ProductionOrderUseCases useCases, AppLocalizations loc) {
    return StreamBuilder<List<ProductionOrderModel>>(
      stream: useCases.getProductionOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data ?? [];
        final completed = orders
            .where((o) => o.status == ProductionOrderStatus.completed)
            .length;
        final inProd = orders
            .where((o) => o.status == ProductionOrderStatus.inProduction)
            .length;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKpi(loc.totalOrders, orders.length),
              _buildKpi(loc.completed, completed),
              _buildKpi(loc.inProduction, inProd),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMaintenanceTab(
      MaintenanceUseCases useCases, AppLocalizations loc) {
    return StreamBuilder<List<MaintenanceLogModel>>(
      stream: useCases.getScheduledMaintenance(),
      builder: (context, scheduledSnap) {
        if (scheduledSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final scheduled = scheduledSnap.data ?? [];
        return StreamBuilder<List<MaintenanceLogModel>>(
          stream: useCases.getCompletedMaintenance(),
          builder: (context, completedSnap) {
            if (completedSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final completed = completedSnap.data ?? [];
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildKpi(loc.scheduledMaintenance, scheduled.length),
                  _buildKpi(loc.completedMaintenance, completed.length),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSalesTab(SalesUseCases useCases, AppLocalizations loc) {
    return StreamBuilder<List<SalesOrderModel>>(
      stream: useCases.getSalesOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data ?? [];
        final fulfilled =
            orders.where((o) => o.status == SalesOrderStatus.fulfilled).length;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKpi(loc.totalOrders, orders.length),
              _buildKpi(loc.fulfilled, fulfilled),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInventoryTab(InventoryUseCases useCases, AppLocalizations loc) {
    return StreamBuilder<List<RawMaterialModel>>(
      stream: useCases.getRawMaterials(),
      builder: (context, rawSnap) {
        if (rawSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final materials = rawSnap.data ?? [];
        return StreamBuilder<List<ProductModel>>(
          stream: useCases.getProducts(),
          builder: (context, prodSnap) {
            if (prodSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final products = prodSnap.data ?? [];
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildKpi(loc.rawMaterials, materials.length),
                  _buildKpi(loc.productCatalog, products.length),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
