// plastic_factory_management/lib/presentation/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:plastic_factory_management/presentation/auth/login_screen.dart';
import 'package:plastic_factory_management/presentation/home/home_screen.dart';
import 'package:plastic_factory_management/presentation/production/create_production_order_screen.dart';
import 'package:plastic_factory_management/presentation/production/production_orders_list_screen.dart';
import 'package:plastic_factory_management/presentation/inventory/raw_materials_screen.dart';
import 'package:plastic_factory_management/presentation/inventory/product_catalog_screen.dart'; // يمكن إعادة استخدامها
import 'package:plastic_factory_management/presentation/machinery/machine_profiles_screen.dart';
import 'package:plastic_factory_management/presentation/machinery/operator_profiles_screen.dart';
import 'package:plastic_factory_management/presentation/maintenance/maintenance_program_screen.dart';
import 'package:plastic_factory_management/presentation/sales/customer_management_screen.dart'; // استيراد جديد
import 'package:plastic_factory_management/presentation/sales/create_sales_order_screen.dart'; // استيراد جديد
import 'package:plastic_factory_management/presentation/sales/sales_orders_list_screen.dart'; // استيراد جديد
import 'package:plastic_factory_management/presentation/quality/quality_inspection_screen.dart';
import 'package:plastic_factory_management/presentation/inventory/inventory_management_screen.dart';
import 'package:plastic_factory_management/presentation/inventory/warehouse_requests_screen.dart';
import 'package:plastic_factory_management/presentation/accounting/accounting_screen.dart';
import 'package:plastic_factory_management/presentation/notifications/notifications_screen.dart';
import 'package:plastic_factory_management/presentation/management/user_management_screen.dart';


class AppRouter {
  static const String loginRoute = '/';
  static const String homeRoute = '/home';
  static const String createProductionOrderRoute = '/production/create';
  static const String productionOrdersListRoute = '/production/list';
  static const String rawMaterialsRoute = '/inventory/raw_materials';
  static const String productCatalogRoute = '/inventory/product_catalog';
  static const String machineProfilesRoute = '/machinery/machines';
  static const String operatorProfilesRoute = '/machinery/operators';
  static const String maintenanceProgramRoute = '/maintenance/program';
  static const String customerManagementRoute = '/sales/customers'; // مسار جديد
  static const String createSalesOrderRoute = '/sales/orders/create'; // مسار جديد
  static const String salesOrdersListRoute = '/sales/orders/list'; // مسار جديد
  static const String qualityInspectionRoute = '/quality/inspections';
  static const String inventoryManagementRoute = '/inventory/management';
  static const String warehouseRequestsRoute = '/inventory/warehouse_requests';
  static const String accountingRoute = '/accounting';
  static const String userManagementRoute = '/management/users';
  static const String notificationsRoute = '/notifications';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case homeRoute:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case createProductionOrderRoute:
        return MaterialPageRoute(builder: (_) => CreateProductionOrderScreen());
      case productionOrdersListRoute:
        return MaterialPageRoute(builder: (_) => ProductionOrdersListScreen());
      case rawMaterialsRoute:
        return MaterialPageRoute(builder: (_) => RawMaterialsScreen());
      case productCatalogRoute:
        return MaterialPageRoute(builder: (_) => ProductCatalogScreen());
      case machineProfilesRoute:
        return MaterialPageRoute(builder: (_) => MachineProfilesScreen());
      case operatorProfilesRoute:
        return MaterialPageRoute(builder: (_) => OperatorProfilesScreen());
      case maintenanceProgramRoute:
        return MaterialPageRoute(builder: (_) => MaintenanceProgramScreen());
      case customerManagementRoute: // إضافة المسار الجديد
        return MaterialPageRoute(builder: (_) => CustomerManagementScreen());
      case createSalesOrderRoute: // إضافة المسار الجديد
        return MaterialPageRoute(builder: (_) => CreateSalesOrderScreen());
      case salesOrdersListRoute: // إضافة المسار الجديد
        return MaterialPageRoute(builder: (_) => SalesOrdersListScreen());
      case qualityInspectionRoute:
        return MaterialPageRoute(builder: (_) => QualityInspectionScreen());
      case inventoryManagementRoute:
        return MaterialPageRoute(builder: (_) => InventoryManagementScreen());
      case warehouseRequestsRoute:
        return MaterialPageRoute(builder: (_) => WarehouseRequestsScreen());
      case accountingRoute:
        return MaterialPageRoute(builder: (_) => AccountingScreen());
      case userManagementRoute:
        return MaterialPageRoute(builder: (_) => UserManagementScreen());
      case notificationsRoute:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      default:
        return MaterialPageRoute(builder: (_) => Text('Error: Unknown route \${settings.name}'));
    }
  }
}