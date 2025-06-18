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
import 'package:plastic_factory_management/presentation/sales/customer_management_screen.dart';
import 'package:plastic_factory_management/presentation/sales/create_sales_order_screen.dart';
import 'package:plastic_factory_management/presentation/sales/sales_orders_list_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      UserModel? user = await _authService.getCurrentUserFirestoreData();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });

      if (user != null) {
        _animationController.forward();
      }
    } catch (e) {
      print("Error loading user data: $e");
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar(AppLocalizations.of(context)!.errorLoadingUserData);
      _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _signOut() async {
    final shouldSignOut = await _showSignOutDialog();
    if (shouldSignOut == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
      }
    }
  }

  Future<bool?> _showSignOutDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final appLocalizations = AppLocalizations.of(context)!;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            appLocalizations.confirmSignOut,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          content: Text(
            appLocalizations.areYouSureSignOut,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(appLocalizations.cancel),
            ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(appLocalizations.signOut),
          ),
        ],
          actionsAlignment: MainAxisAlignment.spaceEvenly,
        );
      },
    );
  }

  Widget _buildModuleButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    String? subtitle,
    bool isComingSoon = false,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.1),
                    color.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isComingSoon ? null : onPressed,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            size: 32,
                            color: isComingSoon ? Colors.grey : color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isComingSoon ? Colors.grey : Colors.black87,
                            height: 1.3,
                          ),
                          textDirection: TextDirection.rtl,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              height: 1.2,
                            ),
                            textDirection: TextDirection.rtl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (isComingSoon) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "قريباً",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _getModulesForRole(AppLocalizations appLocalizations) {
    if (_currentUser == null) return [];

    final UserRole role = _currentUser!.userRoleEnum;
    List<Widget> modules = [];

    // Define color scheme for different modules
    final Map<String, Color> moduleColors = {
      'production': const Color(0xFF1565C0),
      'inventory': const Color(0xFF2E7D32),
      'machinery': const Color(0xFF6A1B9A),
      'maintenance': const Color(0xFFEF6C00),
      'sales': const Color(0xFFD32F2F),
      'management': const Color(0xFF5D4037),
    };

    // Modules for Factory Manager (مدير المصنع) - Full Access
    if (role == UserRole.factoryManager) {
      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.productionOrderManagement,
        subtitle: "إدارة وتتبع الطلبات",
        icon: Icons.factory,
        color: moduleColors['production']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.productionOrdersListRoute),
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.rawMaterials,
        subtitle: "إدارة المخزون",
        icon: Icons.warehouse,
        color: moduleColors['inventory']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.rawMaterialsRoute),
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.productCatalog,
        subtitle: "كتالوج المنتجات",
        icon: Icons.category,
        color: moduleColors['inventory']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.productCatalogRoute),
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.machineProfiles,
        subtitle: "ملفات الآلات",
        icon: Icons.precision_manufacturing,
        color: moduleColors['machinery']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.machineProfilesRoute),
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.operatorProfiles,
        subtitle: "ملفات المشغلين",
        icon: Icons.people,
        color: moduleColors['machinery']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.operatorProfilesRoute),
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.maintenanceProgram,
        subtitle: "برنامج الصيانة",
        icon: Icons.build,
        color: moduleColors['maintenance']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.maintenanceProgramRoute),
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.salesModule,
        subtitle: "إدارة المبيعات",
        icon: Icons.shopping_cart,
        color: moduleColors['sales']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.salesOrdersListRoute),
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: "إدارة المستخدمين",
        subtitle: "صلاحيات المستخدمين",
        icon: Icons.manage_accounts,
        color: moduleColors['management']!,
        onPressed: () {},
        isComingSoon: true,
      ));
    }

    // Modules for Production Manager (مدير الإنتاج)
    if (role == UserRole.productionManager) {
      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.productionOrderManagement,
        subtitle: "طلبات الإنتاج",
        icon: Icons.production_quantity_limits,
        color: moduleColors['production']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.productionOrdersListRoute),
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.rawMaterials,
        subtitle: "المواد الخام",
        icon: Icons.warehouse,
        color: moduleColors['inventory']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.rawMaterialsRoute),
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.productCatalog,
        subtitle: "كتالوج المنتجات",
        icon: Icons.category,
        color: moduleColors['inventory']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.productCatalogRoute),
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.productionWorkflowTracking,
        subtitle: "تتبع سير العمل",
        icon: Icons.timeline,
        color: moduleColors['production']!,
        onPressed: () {},
        isComingSoon: true,
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.machineProfiles,
        subtitle: "ملفات الآلات",
        icon: Icons.precision_manufacturing,
        color: moduleColors['machinery']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.machineProfilesRoute),
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.salesOrders,
        subtitle: "طلبات المبيعات",
        icon: Icons.shopping_cart,
        color: moduleColors['sales']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.salesOrdersListRoute),
      ));
    }

    // Modules for Production Order Preparer (مسؤول إعداد طلبات الإنتاج)
    if (role == UserRole.productionOrderPreparer) {
      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.createOrder,
        subtitle: "إنشاء طلب جديد",
        icon: Icons.create_new_folder,
        color: moduleColors['production']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.createProductionOrderRoute),
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.productionOrderManagement,
        subtitle: "إدارة الطلبات",
        icon: Icons.production_quantity_limits,
        color: moduleColors['production']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.productionOrdersListRoute),
      ));
    }

    // Modules for Mold Installation Supervisor (مشرف تركيب القوالب)
    if (role == UserRole.moldInstallationSupervisor) {
      modules.add(_buildModuleButton(
        context: context,
        title: "مهام تركيب القوالب",
        subtitle: "تركيب وصيانة القوالب",
        icon: Icons.extension,
        color: moduleColors['machinery']!,
        onPressed: () {},
        isComingSoon: true,
      ));
    }

    // Modules for Production Shift Supervisor (مشرف الوردية / مشرف الإنتاج)
    if (role == UserRole.productionShiftSupervisor) {
      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.productionWorkflowTracking,
        subtitle: "تتبع سير العمل",
        icon: Icons.timeline,
        color: moduleColors['production']!,
        onPressed: () {},
        isComingSoon: true,
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: "مهام الإنتاج",
        subtitle: "إدارة المهام اليومية",
        icon: Icons.work,
        color: moduleColors['production']!,
        onPressed: () {},
        isComingSoon: true,
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.rawMaterials,
        subtitle: "المواد الخام",
        icon: Icons.warehouse,
        color: moduleColors['inventory']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.rawMaterialsRoute),
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.productCatalog,
        subtitle: "كتالوج المنتجات",
        icon: Icons.category,
        color: moduleColors['inventory']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.productCatalogRoute),
      ));
    }

    // Modules for Machine Operator (مشغل المكينة)
    if (role == UserRole.machineOperator) {
      modules.add(_buildModuleButton(
        context: context,
        title: "مهامي الحالية",
        subtitle: "المهام المكلف بها",
        icon: Icons.content_cut,
        color: moduleColors['production']!,
        onPressed: () {},
        isComingSoon: true,
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.machineProfiles,
        subtitle: "ملفات الآلات",
        icon: Icons.precision_manufacturing,
        color: moduleColors['machinery']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.machineProfilesRoute),
      ));
    }

    // Modules for Maintenance Manager (مسؤول الصيانة)
    if (role == UserRole.maintenanceManager) {
      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.maintenanceProgram,
        subtitle: "برنامج الصيانة",
        icon: Icons.build,
        color: moduleColors['maintenance']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.maintenanceProgramRoute),
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.machineProfiles,
        subtitle: "ملفات الآلات",
        icon: Icons.precision_manufacturing,
        color: moduleColors['machinery']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.machineProfilesRoute),
      ));
    }

    // Modules for Sales Representative (مندوب المبيعات)
    if (role == UserRole.salesRepresentative) {
      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.productCatalog,
        subtitle: "كتالوج المنتجات",
        icon: Icons.view_carousel,
        color: moduleColors['inventory']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.productCatalogRoute),
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.customerManagement,
        subtitle: "إدارة العملاء",
        icon: Icons.groups,
        color: moduleColors['sales']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.customerManagementRoute),
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.createSalesOrder,
        subtitle: "إنشاء طلب مبيعات",
        icon: Icons.add_shopping_cart,
        color: moduleColors['sales']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.createSalesOrderRoute),
      ));

      modules.add(_buildModuleButton(
        context: context,
        title: appLocalizations.mySalesHistory,
        subtitle: "سجل مبيعاتي",
        icon: Icons.history,
        color: moduleColors['sales']!,
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.salesOrdersListRoute),
      ));
    }

    return modules;
  }

  Widget _buildWelcomeHeader() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "أهلاً بك، ${_currentUser!.name}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentUser!.userRoleEnum.toArabicString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "متصل",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiCard(BuildContext context, String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textDirection: TextDirection.rtl,
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(String text) {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildTaskCard(String text) {
    return Card(
      child: ListTile(
        title: Text(
          text,
          textDirection: TextDirection.rtl,
        ),
        trailing: const Icon(Icons.check_circle_outline),
      ),
    );
  }

  Widget _buildDashboardForRole(UserRole role) {
    List<Widget> kpis = [];
    List<Widget> alerts = [];
    List<Widget> tasks = [];

    if (role == UserRole.factoryManager) {
      kpis = [
        _buildKpiCard(context, 'إجمالي طلبات الإنتاج', '0'),
        _buildKpiCard(context, 'عدد طلبات المبيعات', '0'),
        _buildKpiCard(context, 'إجمالي عدد الآلات', '0'),
        _buildKpiCard(context, 'عدد المواد الخام تحت حد الخطر', '0'),
      ];
      alerts = [
        _buildAlertCard('مواد خام تحتاج لإعادة طلب'),
        _buildAlertCard('آلات تحتاج صيانة عاجلة'),
        _buildAlertCard('طلبات إنتاج/مبيعات عالقة'),
      ];
      tasks = [
        _buildTaskCard('مراجعة طلبات الإنتاج المعلقة للموافقة'),
        _buildTaskCard('مراجعة طلبات الصيانة'),
      ];
    } else if (role == UserRole.productionManager) {
      kpis = [
        _buildKpiCard(context, 'عدد طلبات الإنتاج المعلقة', '0'),
        _buildKpiCard(context, 'عدد الطلبات قيد الإنتاج', '0'),
        _buildKpiCard(context, 'نسبة إكمال الإنتاج', '0%'),
      ];
      alerts = [
        _buildAlertCard('نقص في المواد الخام لطلبات مجدولة'),
        _buildAlertCard('تأخير في مراحل الإنتاج'),
      ];
      tasks = [
        _buildTaskCard('مراجعة طلبات الإنتاج الجديدة للموافقة/الرفض'),
      ];
    } else if (role == UserRole.salesRepresentative) {
      kpis = [
        _buildKpiCard(context, 'عدد العملاء المسجلين', '0'),
        _buildKpiCard(context, 'عدد طلبات المبيعات المعلقة', '0'),
        _buildKpiCard(context, 'إجمالي قيمة المبيعات الشهرية', '0'),
      ];
      alerts = [
        _buildAlertCard('طلبات مبيعات بانتظار التوريد'),
      ];
      tasks = [
        _buildTaskCard('متابعة طلبات المبيعات الخاصة به'),
      ];
    } else if (role == UserRole.maintenanceManager) {
      kpis = [
        _buildKpiCard(context, 'عدد مهام الصيانة المجدولة', '0'),
        _buildKpiCard(context, 'عدد الآلات تحت الصيانة', '0'),
        _buildKpiCard(context, 'عدد مهام الصيانة المكتملة', '0'),
      ];
      alerts = [
        _buildAlertCard('آلات تحتاج صيانة عاجلة'),
        _buildAlertCard('مهام صيانة فائتة'),
      ];
      tasks = [
        _buildTaskCard('جدولة صيانة جديدة'),
        _buildTaskCard('متابعة مهام الصيانة قيد التقدم'),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('المؤشرات الرئيسية', textDirection: TextDirection.rtl,
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: kpis,
        ),
        const SizedBox(height: 16),
        if (alerts.isNotEmpty) ...[
          const Text('التنبيهات', textDirection: TextDirection.rtl,
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Column(children: alerts),
          const SizedBox(height: 16),
        ],
        if (tasks.isNotEmpty) ...[
          const Text('المهام', textDirection: TextDirection.rtl,
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Column(children: tasks),
        ],
      ],
    );
  }

  Widget _buildDashboardContent() {
    if (_currentUser == null) {
      return const SizedBox.shrink();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            _buildDashboardForRole(_currentUser!.userRoleEnum),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "نظام إدارة مصنع المنتجات البلاستيكية",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications
            },
            tooltip: appLocalizations.notifications,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _signOut,
            tooltip: appLocalizations.signOut,
          ),
        ],
      ),
      drawer: _currentUser == null ? null : _buildDrawer(appLocalizations),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              appLocalizations.loadingData,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : _currentUser == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            const Text(
              "خطأ في تحميل بيانات المستخدم",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "يرجى إعادة تسجيل الدخول",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute),
              child: const Text("إعادة تسجيل الدخول"),
            ),
          ],
        ),
      )
          : _buildDashboardContent(),
      ),
    );
  }

  Widget _buildDrawer(AppLocalizations appLocalizations) {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[100],
                        child: Icon(
                          Icons.person,
                          size: 48,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentUser!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _currentUser!.userRoleEnum.toArabicString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.home_rounded,
                  title: "الرئيسية",
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.dashboard_rounded,
                  title: appLocalizations.dashboard,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to dashboard
                  },
                  isComingSoon: true,
                ),
                _buildDrawerItem(
                  icon: Icons.analytics_rounded,
                  title: appLocalizations.reportsAndStatistics,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to reports
                  },
                  isComingSoon: true,
                ),
                _buildDrawerItem(
                  icon: Icons.settings_rounded,
                  title: appLocalizations.settings,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to settings
                  },
                  isComingSoon: true,
                ),
                _buildDrawerItem(
                  icon: Icons.help_rounded,
                  title: appLocalizations.helpAndSupport,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to help
                  },
                  isComingSoon: true,
                ),
                const Divider(height: 32),
                _buildDrawerItem(
                  icon: Icons.logout_rounded,
                  title: appLocalizations.signOut,
                  onTap: () {
                    Navigator.pop(context);
                    _signOut();
                  },
                  isDestructive: true,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      appLocalizations.statusConnected,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${appLocalizations.version} 1.0.0',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isComingSoon = false,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? Colors.red[600]
            : isComingSoon
            ? Colors.grey[400]
            : Colors.grey[700],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDestructive
                    ? Colors.red[600]
                    : isComingSoon
                    ? Colors.grey[400]
                    : Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          if (isComingSoon) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "قريباً",
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.orange[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: isComingSoon ? null : onTap,
      dense: true,
    );
  }
}