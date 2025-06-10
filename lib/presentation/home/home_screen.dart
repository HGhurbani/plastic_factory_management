// plastic_factory_management/lib/presentation/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/core/services/auth_service.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';
import 'package:plastic_factory_management/presentation/routes/app_router.dart';
import 'package:plastic_factory_management/presentation/production/create_production_order_screen.dart';
import 'package:plastic_factory_management/presentation/production/production_orders_list_screen.dart';
import 'package:plastic_factory_management/presentation/inventory/raw_materials_screen.dart';
import 'package:plastic_factory_management/presentation/inventory/product_catalog_screen.dart';
import 'package:plastic_factory_management/presentation/machinery/machine_profiles_screen.dart';
import 'package:plastic_factory_management/presentation/machinery/operator_profiles_screen.dart';
import 'package:plastic_factory_management/presentation/maintenance/maintenance_program_screen.dart';
import 'package:plastic_factory_management/presentation/sales/customer_management_screen.dart'; // استيراد جديد
import 'package:plastic_factory_management/presentation/sales/create_sales_order_screen.dart'; // استيراد جديد
import 'package:plastic_factory_management/presentation/sales/sales_orders_list_screen.dart'; // استيراد جديد


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      UserModel? user = await _authService.getCurrentUserFirestoreData();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading user data: $e");
      setState(() {
        _isLoading = false;
      });
      _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
      }
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
    }
  }

  Widget _buildModuleButton(
      BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _getModulesForRole(AppLocalizations appLocalizations) {
    if (_currentUser == null) return [];

    final UserRole role = _currentUser!.userRoleEnum;
    List<Widget> modules = [];

    // Modules for Factory Manager (مدير المصنع) - Full Access
    if (role == UserRole.factoryManager) {
      modules.add(_buildModuleButton(context, appLocalizations.productionOrderManagement, Icons.factory, () {
        Navigator.of(context).pushNamed(AppRouter.productionOrdersListRoute);
      }));
      modules.add(_buildModuleButton(context, appLocalizations.rawMaterials, Icons.warehouse, () {
        Navigator.of(context).pushNamed(AppRouter.rawMaterialsRoute);
      }));
      modules.add(_buildModuleButton(context, appLocalizations.productCatalog, Icons.category, () {
        Navigator.of(context).pushNamed(AppRouter.productCatalogRoute);
      }));
      modules.add(_buildModuleButton(context, appLocalizations.machineProfiles, Icons.precision_manufacturing, () {
        Navigator.of(context).pushNamed(AppRouter.machineProfilesRoute);
      }));
      modules.add(_buildModuleButton(context, appLocalizations.operatorProfiles, Icons.people, () {
        Navigator.of(context).pushNamed(AppRouter.operatorProfilesRoute);
      }));
      modules.add(_buildModuleButton(context, appLocalizations.maintenanceProgram, Icons.build, () {
        Navigator.of(context).pushNamed(AppRouter.maintenanceProgramRoute);
      }));
      modules.add(_buildModuleButton(context, appLocalizations.salesModule, Icons.shopping_cart, () {
        Navigator.of(context).pushNamed(AppRouter.salesOrdersListRoute); // توجيه جديد
      }));
      modules.add(_buildModuleButton(context, "إدارة المستخدمين", Icons.manage_accounts, () { /* */ }));
    }

    // Modules for Production Manager (مدير الإنتاج)
    if (role == UserRole.productionManager) {
      modules.add(_buildModuleButton(context, appLocalizations.productionOrderManagement, Icons.production_quantity_limits, () {
        Navigator.of(context).pushNamed(AppRouter.productionOrdersListRoute);
      }));
      modules.add(_buildModuleButton(context, appLocalizations.rawMaterials, Icons.warehouse, () {
        Navigator.of(context).pushNamed(AppRouter.rawMaterialsRoute);
      }));
      modules.add(_buildModuleButton(context, appLocalizations.productCatalog, Icons.category, () {
        Navigator.of(context).pushNamed(AppRouter.productCatalogRoute);
      }));
      modules.add(_buildModuleButton(context, appLocalizations.productionWorkflowTracking, Icons.timeline, () { /* */ }));
      modules.add(_buildModuleButton(context, appLocalizations.machineProfiles, Icons.precision_manufacturing, () {
        Navigator.of(context).pushNamed(AppRouter.machineProfilesRoute);
      }));
      modules.add(_buildModuleButton(context, appLocalizations.salesOrders, Icons.shopping_cart, () {
        Navigator.of(context).pushNamed(AppRouter.salesOrdersListRoute); // يمكنهم رؤية طلبات المبيعات
      }));
    }

    // Modules for Production Order Preparer (مسؤول إعداد طلبات الإنتاج)
    if (role == UserRole.productionOrderPreparer) {
      modules.add(_buildModuleButton(context, appLocalizations.createOrder, Icons.create_new_folder, () {
        Navigator.of(context).pushNamed(AppRouter.createProductionOrderRoute);
      }));
      modules.add(_buildModuleButton(context, appLocalizations.productionOrderManagement, Icons.production_quantity_limits, () {
        Navigator.of(context).pushNamed(AppRouter.productionOrdersListRoute);
      }));
    }

    // Modules for Mold Installation Supervisor (مشرف تركيب القوالب)
    if (role == UserRole.moldInstallationSupervisor) {
      modules.add(_buildModuleButton(context, "مهام تركيب القوالب", Icons.extension, () { /* */ }));
    }

    // Modules for Production Shift Supervisor (مشرف الوردية / مشرف الإنتاج)
    if (role == UserRole.productionShiftSupervisor) {
      modules.add(_buildModuleButton(context, appLocalizations.productionWorkflowTracking, Icons.timeline, () { /* */ }));
      modules.add(_buildModuleButton(context, "مهام الإنتاج", Icons.work, () { /* */ }));
      modules.add(_buildModuleButton(context, appLocalizations.rawMaterials, Icons.warehouse, () {
        Navigator.of(context).pushNamed(AppRouter.rawMaterialsRoute);
      }));
      modules.add(_buildModuleButton(context, appLocalizations.productCatalog, Icons.category, () {
        Navigator.of(context).pushNamed(AppRouter.productCatalogRoute);
      }));
    }

    // Modules for Machine Operator (مشغل المكينة)
    if (role == UserRole.machineOperator) {
      modules.add(_buildModuleButton(context, "مهامي الحالية", Icons.content_cut, () { /* */ }));
      modules.add(_buildModuleButton(context, appLocalizations.machineProfiles, Icons.precision_manufacturing, () {
        Navigator.of(context).pushNamed(AppRouter.machineProfilesRoute);
      }));
    }

    // Modules for Maintenance Manager (مسؤول الصيانة)
    if (role == UserRole.maintenanceManager) {
      modules.add(_buildModuleButton(context, appLocalizations.maintenanceProgram, Icons.build, () {
        Navigator.of(context).pushNamed(AppRouter.maintenanceProgramRoute);
      }));
      modules.add(_buildModuleButton(context, appLocalizations.machineProfiles, Icons.precision_manufacturing, () {
        Navigator.of(context).pushNamed(AppRouter.machineProfilesRoute);
      }));
    }

    // Modules for Sales Representative (مندوب المبيعات)
    if (role == UserRole.salesRepresentative) {
      modules.add(_buildModuleButton(context, appLocalizations.productCatalog, Icons.view_carousel, () {
        Navigator.of(context).pushNamed(AppRouter.productCatalogRoute);
      }));
      modules.add(_buildModuleButton(context, appLocalizations.customerManagement, Icons.groups, () {
        Navigator.of(context).pushNamed(AppRouter.customerManagementRoute); // توجيه جديد
      }));
      modules.add(_buildModuleButton(context, appLocalizations.createSalesOrder, Icons.add_shopping_cart, () { // توجيه جديد
        Navigator.of(context).pushNamed(AppRouter.createSalesOrderRoute);
      }));
      modules.add(_buildModuleButton(context, appLocalizations.mySalesHistory, Icons.history, () {
        Navigator.of(context).pushNamed(AppRouter.salesOrdersListRoute); // توجيه جديد (يمكن استخدام نفس قائمة الطلبات مع فلتر)
      }));
    }

    return modules;
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text("نظام إدارة مصنع المنتجات البلاستيكية"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: appLocalizations.signOut,
          ),
        ],
      ),
      drawer: _currentUser == null
          ? null
          : Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 40, color: Theme.of(context).primaryColor),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _currentUser!.name,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.right,
                  ),
                  Text(
                    _currentUser!.userRoleEnum.toArabicString(),
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text("الرئيسية", textDirection: TextDirection.rtl),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("الإعدادات", textDirection: TextDirection.rtl),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(appLocalizations.signOut, textDirection: TextDirection.rtl),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _currentUser == null
          ? Center(child: Text("خطأ في تحميل بيانات المستخدم. يرجى إعادة تسجيل الدخول."))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "أهلاً بك، ${_currentUser!.name}!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            Text(
              "دورك: ${_currentUser!.userRoleEnum.toArabicString()}",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 24),
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: _getModulesForRole(appLocalizations),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}