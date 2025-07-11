// plastic_factory_management/lib/presentation/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:plastic_factory_management/presentation/auth/login_screen.dart';
import 'package:plastic_factory_management/presentation/auth/terms_of_use_screen.dart';
import 'package:plastic_factory_management/presentation/home/home_screen.dart';
import 'package:plastic_factory_management/presentation/production/create_production_order_screen.dart';
import 'package:plastic_factory_management/presentation/production/production_orders_list_screen.dart';
import 'package:plastic_factory_management/presentation/production/production_board_screen.dart';
import 'package:plastic_factory_management/presentation/inventory/raw_materials_screen.dart';
import 'package:plastic_factory_management/presentation/inventory/product_catalog_screen.dart'; // يمكن إعادة استخدامها
import 'package:plastic_factory_management/presentation/inventory/templates_screen.dart';
import 'package:plastic_factory_management/presentation/machinery/machine_profiles_screen.dart';
import 'package:plastic_factory_management/presentation/machinery/operator_profiles_screen.dart';
import 'package:plastic_factory_management/presentation/machinery/mold_installation_tasks_screen.dart';
import 'package:plastic_factory_management/presentation/maintenance/maintenance_program_screen.dart';
import 'package:plastic_factory_management/presentation/sales/customer_management_screen.dart'; // استيراد جديد
import 'package:plastic_factory_management/presentation/sales/create_sales_order_screen.dart'; // استيراد جديد
import 'package:plastic_factory_management/presentation/sales/sales_orders_list_screen.dart'; // استيراد جديد
import 'package:plastic_factory_management/presentation/quality/quality_inspection_screen.dart';
import 'package:plastic_factory_management/presentation/quality/quality_approval_screen.dart';
import 'package:plastic_factory_management/presentation/inventory/inventory_management_screen.dart';
import 'package:plastic_factory_management/presentation/inventory/inventory_adjustment_screen.dart';
import 'package:plastic_factory_management/presentation/inventory/inventory_add_item_screen.dart';
import 'package:plastic_factory_management/presentation/inventory/factory_elements_screen.dart';
import 'package:plastic_factory_management/presentation/inventory/warehouse_requests_screen.dart';
import 'package:plastic_factory_management/presentation/accounting/accounting_screen.dart';
import 'package:plastic_factory_management/presentation/accounting/payments_screen.dart';
import 'package:plastic_factory_management/presentation/accounting/purchases_screen.dart';
import 'package:plastic_factory_management/presentation/accounting/spare_part_requests_screen.dart';
import 'package:plastic_factory_management/presentation/notifications/notifications_screen.dart';
import 'package:plastic_factory_management/presentation/management/user_management_screen.dart';
import 'package:plastic_factory_management/presentation/management/user_activity_logs_screen.dart';
import 'package:plastic_factory_management/presentation/management/returns_screen.dart';
import 'package:plastic_factory_management/presentation/management/delivery_screen.dart';
import 'package:plastic_factory_management/presentation/management/reports_screen.dart';
import 'package:plastic_factory_management/presentation/management/root_cause_analysis_screen.dart';
import 'package:plastic_factory_management/presentation/management/procurement_screen.dart';
import 'package:plastic_factory_management/presentation/management/documents_center_screen.dart';
import 'package:plastic_factory_management/presentation/management/excel_import_screen.dart';


class AppRouter {
  static const String loginRoute = '/';
  static const String homeRoute = '/home';
  static const String termsRoute = '/terms';
  static const String createProductionOrderRoute = '/production/create';
  static const String productionOrdersListRoute = '/production/list';
  static const String productionBoardRoute = '/production/board';
  static const String rawMaterialsRoute = '/inventory/raw_materials';
  static const String productCatalogRoute = '/inventory/product_catalog';
  static const String templatesRoute = '/inventory/templates';
  static const String machineProfilesRoute = '/machinery/machines';
  static const String operatorProfilesRoute = '/machinery/operators';
  static const String moldInstallationTasksRoute = '/machinery/mold_tasks';
  static const String maintenanceProgramRoute = '/maintenance/program';
  static const String customerManagementRoute = '/sales/customers'; // مسار جديد
  static const String createSalesOrderRoute = '/sales/orders/create'; // مسار جديد
  static const String salesOrdersListRoute = '/sales/orders/list'; // مسار جديد
  static const String qualityInspectionRoute = '/quality/inspections';
  static const String qualityApprovalRoute = '/quality/approval';
  static const String inventoryManagementRoute = '/inventory/management';
  static const String inventoryAdjustmentRoute = '/inventory/adjustment';
  static const String inventoryAddItemRoute = '/inventory/add_item';
  static const String factoryElementsRoute = '/inventory/factory_elements';
  static const String warehouseRequestsRoute = '/inventory/warehouse_requests';
  static const String accountingRoute = '/accounting';
  static const String paymentsRoute = '/accounting/payments';
  static const String purchasesRoute = '/accounting/purchases';
  static const String sparePartRequestsRoute = '/accounting/spare_requests';
  static const String userManagementRoute = '/management/users';
  static const String userActivityLogsRoute = '/management/user_activity_logs';
  static const String returnsRoute = '/management/returns';
  static const String deliveryRoute = '/management/delivery';
  static const String reportsRoute = '/management/reports';
  static const String procurementRoute = '/management/procurement';
  static const String documentsCenterRoute = '/management/documents';
  static const String excelImportRoute = '/management/excel_import';
  static const String rootCauseAnalysisRoute = '/management/root_cause';
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
      case productionBoardRoute:
        return MaterialPageRoute(builder: (_) => const ProductionBoardScreen());
      case rawMaterialsRoute:
        return MaterialPageRoute(builder: (_) => RawMaterialsScreen());
      case productCatalogRoute:
        return MaterialPageRoute(builder: (_) => ProductCatalogScreen());
      case templatesRoute:
        return MaterialPageRoute(builder: (_) => const TemplatesScreen());
      case machineProfilesRoute:
        return MaterialPageRoute(builder: (_) => MachineProfilesScreen());
      case operatorProfilesRoute:
        return MaterialPageRoute(builder: (_) => OperatorProfilesScreen());
      case moldInstallationTasksRoute:
        return MaterialPageRoute(builder: (_) => MoldInstallationTasksScreen());
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
      case qualityApprovalRoute:
        return MaterialPageRoute(builder: (_) => const QualityApprovalScreen());
      case inventoryManagementRoute:
        return MaterialPageRoute(builder: (_) => InventoryManagementScreen());
      case inventoryAdjustmentRoute:
        return MaterialPageRoute(builder: (_) => const InventoryAdjustmentScreen());
      case inventoryAddItemRoute:
        return MaterialPageRoute(builder: (_) => const InventoryAddItemScreen());
      case factoryElementsRoute:
        return MaterialPageRoute(builder: (_) => const FactoryElementsScreen());
      case warehouseRequestsRoute:
        return MaterialPageRoute(builder: (_) => WarehouseRequestsScreen());
      case accountingRoute:
        return MaterialPageRoute(builder: (_) => AccountingScreen());
      case paymentsRoute:
        return MaterialPageRoute(builder: (_) => const PaymentsScreen());
      case purchasesRoute:
        return MaterialPageRoute(builder: (_) => const PurchasesScreen());
      case sparePartRequestsRoute:
        return MaterialPageRoute(builder: (_) => const SparePartRequestsScreen());
      case userManagementRoute:
        return MaterialPageRoute(builder: (_) => UserManagementScreen());
      case userActivityLogsRoute:
        return MaterialPageRoute(builder: (_) => const UserActivityLogsScreen());
      case returnsRoute:
        return MaterialPageRoute(builder: (_) => ReturnsScreen());
      case deliveryRoute:
        return MaterialPageRoute(builder: (_) => DeliveryScreen());
      case reportsRoute:
        return MaterialPageRoute(builder: (_) => ReportsScreen());
      case rootCauseAnalysisRoute:
        return MaterialPageRoute(builder: (_) => RootCauseAnalysisScreen());
      case procurementRoute:
        return MaterialPageRoute(builder: (_) => ProcurementScreen());
      case documentsCenterRoute:
        return MaterialPageRoute(builder: (_) => DocumentsCenterScreen());
      case excelImportRoute:
        return MaterialPageRoute(builder: (_) => const ExcelImportScreen());
      case termsRoute:
        final uid = settings.arguments as String;
        return MaterialPageRoute(
            builder: (_) => TermsOfUseScreen(uid: uid));
      case notificationsRoute:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      default:
        return MaterialPageRoute(builder: (_) => Text('Error: Unknown route \${settings.name}'));
    }
  }
}