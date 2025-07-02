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
import '../../theme/app_colors.dart';
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

    return Directionality(
      textDirection: TextDirection.rtl, // هذا صحيح وموجود
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.reports),
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
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
              onPressed: () => Navigator.of(context)
                  .pushNamed(AppRouter.rootCauseAnalysisRoute),
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
      ),
    );
  }

  Widget _buildKpi(String label, int value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textDirection: TextDirection.rtl, // احتفظ بهذا لضمان اتجاه الصف RTL
          children: [
            // الأيقونة ستظهر الآن على اليمين
            CircleAvatar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: Icon(icon),
            ),
            // الأرقام والنصوص ستظهر الآن على اليسار
            Column(
              crossAxisAlignment: CrossAxisAlignment.end, // غيّر هذا إلى .start ليكون محاذيًا لليسار
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(label),
              ],
            ),
          ],
        ),
      ),
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
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildKpi(loc.totalOrders, orders.length, Icons.format_list_numbered),
            _buildKpi(loc.completed, completed, Icons.check_circle_outline),
            _buildKpi(loc.inProduction, inProd, Icons.factory_outlined),
          ],
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
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildKpi(loc.scheduledMaintenance, scheduled.length, Icons.schedule),
                _buildKpi(loc.completedMaintenance, completed.length, Icons.build_outlined),
              ],
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
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildKpi(loc.totalOrders, orders.length, Icons.shopping_cart_outlined),
            _buildKpi(loc.fulfilled, fulfilled, Icons.done_all_outlined),
          ],
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
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildKpi(loc.rawMaterials, materials.length, Icons.warehouse_outlined),
                _buildKpi(loc.productCatalog, products.length, Icons.category_outlined),
              ],
            );
          },
        );
      },
    );
  }
}