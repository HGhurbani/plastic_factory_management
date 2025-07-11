// plastic_factory_management/lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:plastic_factory_management/theme/app_colors.dart';

import 'package:plastic_factory_management/firebase_options.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';

import 'package:plastic_factory_management/core/services/auth_service.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';

// استيرادات Production Order
import 'package:plastic_factory_management/data/datasources/production_order_datasource.dart';
import 'package:plastic_factory_management/data/repositories/production_order_repository_impl.dart';
import 'package:plastic_factory_management/domain/usecases/production_order_usecases.dart';
import 'package:plastic_factory_management/data/datasources/production_daily_log_datasource.dart';
import 'package:plastic_factory_management/data/repositories/production_daily_log_repository_impl.dart';
import 'package:plastic_factory_management/domain/usecases/production_daily_log_usecases.dart';
import 'package:plastic_factory_management/data/datasources/shift_handover_datasource.dart';
import 'package:plastic_factory_management/data/repositories/shift_handover_repository_impl.dart';
import 'package:plastic_factory_management/domain/usecases/shift_handover_usecases.dart';

// استيرادات Inventory
import 'package:plastic_factory_management/data/datasources/inventory_datasource.dart';
import 'package:plastic_factory_management/data/repositories/inventory_repository_impl.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';
import 'package:plastic_factory_management/data/datasources/factory_element_datasource.dart';
import 'package:plastic_factory_management/data/repositories/factory_element_repository_impl.dart';
import 'package:plastic_factory_management/domain/usecases/factory_element_usecases.dart';

// استيرادات Machinery & Operator
import 'package:plastic_factory_management/data/datasources/machinery_operator_datasource.dart';
import 'package:plastic_factory_management/data/repositories/machinery_operator_repository_impl.dart';
import 'package:plastic_factory_management/domain/usecases/machinery_operator_usecases.dart';

// استيرادات Maintenance
import 'package:plastic_factory_management/data/datasources/maintenance_datasource.dart';
import 'package:plastic_factory_management/data/repositories/maintenance_repository_impl.dart';
import 'package:plastic_factory_management/domain/usecases/maintenance_usecases.dart';

// استيرادات Sales (جديد)
import 'package:plastic_factory_management/data/datasources/sales_datasource.dart'; // استيراد جديد
import 'package:plastic_factory_management/data/repositories/sales_repository_impl.dart'; // استيراد جديد
import 'package:plastic_factory_management/domain/usecases/sales_usecases.dart'; // استيراد جديد
import 'package:plastic_factory_management/data/datasources/financial_datasource.dart';
import 'package:plastic_factory_management/data/repositories/financial_repository_impl.dart';
import 'package:plastic_factory_management/domain/usecases/financial_usecases.dart';
import 'package:plastic_factory_management/data/datasources/quality_datasource.dart';
import 'package:plastic_factory_management/data/repositories/quality_repository_impl.dart';
import 'package:plastic_factory_management/domain/usecases/quality_usecases.dart';
import 'package:plastic_factory_management/data/datasources/procurement_datasource.dart';
import 'package:plastic_factory_management/data/repositories/procurement_repository_impl.dart';
import 'package:plastic_factory_management/domain/usecases/procurement_usecases.dart';
import 'package:plastic_factory_management/data/datasources/returns_datasource.dart';
import 'package:plastic_factory_management/data/repositories/returns_repository_impl.dart';
import 'package:plastic_factory_management/domain/usecases/returns_usecases.dart';
// استيرادات Notifications
import 'package:plastic_factory_management/data/datasources/notification_datasource.dart';
import 'package:plastic_factory_management/data/repositories/notification_repository_impl.dart';
import 'package:plastic_factory_management/domain/usecases/notification_usecases.dart';
// استيرادات User Management
import 'package:plastic_factory_management/data/datasources/user_datasource.dart';
import 'package:plastic_factory_management/data/repositories/user_repository_impl.dart';
import 'package:plastic_factory_management/domain/usecases/user_usecases.dart';
import 'package:plastic_factory_management/data/datasources/user_activity_log_datasource.dart';
import 'package:plastic_factory_management/data/repositories/user_activity_log_repository_impl.dart';
import 'package:plastic_factory_management/domain/usecases/user_activity_log_usecases.dart';


import 'package:plastic_factory_management/presentation/auth/login_screen.dart';
import 'package:plastic_factory_management/presentation/home/home_screen.dart';
import 'package:plastic_factory_management/presentation/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _configureFirestore();
  runApp(MyApp());
}

Future<void> _configureFirestore() async {
  if (kIsWeb) {
    await FirebaseFirestore.instance.enablePersistence(const PersistenceSettings(synchronizeTabs: true));
  } else {
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
  }
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        StreamProvider<User?>.value(
          value: AuthService().user,
          initialData: null,
        ),
        StreamProvider<UserModel?>.value(
          initialData: null,
          value: FirebaseAuth.instance.authStateChanges().asyncMap((user) async {
            if (user != null) {
              return await AuthService().getCurrentUserFirestoreData();
            }
            return null;
          }),
        ),
        // توفير Notifications Dependencies
        Provider<NotificationDatasource>(
          create: (_) => NotificationDatasource(),
        ),
        Provider<NotificationRepositoryImpl>(
          create: (context) => NotificationRepositoryImpl(
            Provider.of<NotificationDatasource>(context, listen: false),
          ),
        ),
        Provider<NotificationUseCases>(
          create: (context) => NotificationUseCases(
            Provider.of<NotificationRepositoryImpl>(context, listen: false),
          ),
        ),
        // توفير User Management Dependencies
        Provider<UserDatasource>(
          create: (_) => UserDatasource(),
        ),
        Provider<UserRepositoryImpl>(
          create: (context) => UserRepositoryImpl(
            Provider.of<UserDatasource>(context, listen: false),
          ),
        ),
        Provider<UserUseCases>(
          create: (context) => UserUseCases(
            Provider.of<UserRepositoryImpl>(context, listen: false),
          ),
        ),
        // توفير User Activity Log Dependencies
        Provider<UserActivityLogDatasource>(
          create: (_) => UserActivityLogDatasource(),
        ),
        Provider<UserActivityLogRepositoryImpl>(
          create: (context) => UserActivityLogRepositoryImpl(
            Provider.of<UserActivityLogDatasource>(context, listen: false),
          ),
        ),
        Provider<UserActivityLogUseCases>(
          create: (context) => UserActivityLogUseCases(
            Provider.of<UserActivityLogRepositoryImpl>(context, listen: false),
          ),
        ),
        // توفير Inventory Dependencies
        Provider<InventoryDatasource>(
          create: (_) => InventoryDatasource(),
        ),
        Provider<InventoryRepositoryImpl>(
          create: (context) => InventoryRepositoryImpl(
            Provider.of<InventoryDatasource>(context, listen: false),
          ),
        ),
        Provider<InventoryUseCases>(
          create: (context) => InventoryUseCases(
            Provider.of<InventoryRepositoryImpl>(context, listen: false),
            Provider.of<NotificationUseCases>(context, listen: false),
            Provider.of<UserUseCases>(context, listen: false),
          ),
        ),
        // توفير Factory Elements Dependencies
        Provider<FactoryElementDatasource>(
          create: (_) => FactoryElementDatasource(),
        ),
        Provider<FactoryElementRepositoryImpl>(
          create: (context) => FactoryElementRepositoryImpl(
            Provider.of<FactoryElementDatasource>(context, listen: false),
          ),
        ),
        Provider<FactoryElementUseCases>(
          create: (context) => FactoryElementUseCases(
            Provider.of<FactoryElementRepositoryImpl>(context, listen: false),
          ),
        ),
        // توفير Production Order Dependencies
        Provider<ProductionOrderDatasource>(
          create: (_) => ProductionOrderDatasource(),
        ),
        Provider<ProductionOrderRepositoryImpl>(
          create: (context) => ProductionOrderRepositoryImpl(
            Provider.of<ProductionOrderDatasource>(context, listen: false),
          ),
        ),
        Provider<ProductionOrderUseCases>(
          create: (context) => ProductionOrderUseCases(
            Provider.of<ProductionOrderRepositoryImpl>(context, listen: false),
            Provider.of<NotificationUseCases>(context, listen: false),
            Provider.of<UserUseCases>(context, listen: false),
            Provider.of<InventoryUseCases>(context, listen: false),
          ),
        ),
        // توفير Production Daily Log Dependencies
        Provider<ProductionDailyLogDatasource>(
          create: (_) => ProductionDailyLogDatasource(),
        ),
        Provider<ProductionDailyLogRepositoryImpl>(
          create: (context) => ProductionDailyLogRepositoryImpl(
            Provider.of<ProductionDailyLogDatasource>(context, listen: false),
          ),
        ),
        Provider<ProductionDailyLogUseCases>(
          create: (context) => ProductionDailyLogUseCases(
            Provider.of<ProductionDailyLogRepositoryImpl>(context, listen: false),
          ),
        ),
        // Shift Handover dependencies
        Provider<ShiftHandoverDatasource>(
          create: (_) => ShiftHandoverDatasource(),
        ),
        Provider<ShiftHandoverRepositoryImpl>(
          create: (context) => ShiftHandoverRepositoryImpl(
            Provider.of<ShiftHandoverDatasource>(context, listen: false),
          ),
        ),
        Provider<ShiftHandoverUseCases>(
          create: (context) => ShiftHandoverUseCases(
            Provider.of<ShiftHandoverRepositoryImpl>(context, listen: false),
          ),
        ),
        // توفير Machinery & Operator Dependencies
        Provider<MachineryOperatorDatasource>(
          create: (_) => MachineryOperatorDatasource(),
        ),
        Provider<MachineryOperatorRepositoryImpl>(
          create: (context) => MachineryOperatorRepositoryImpl(
            Provider.of<MachineryOperatorDatasource>(context, listen: false),
          ),
        ),
        Provider<MachineryOperatorUseCases>(
          create: (context) => MachineryOperatorUseCases(
            Provider.of<MachineryOperatorRepositoryImpl>(context, listen: false),
          ),
        ),
        // توفير Maintenance Dependencies
        Provider<MaintenanceDatasource>(
          create: (_) => MaintenanceDatasource(),
        ),
        Provider<MaintenanceRepositoryImpl>(
          create: (context) => MaintenanceRepositoryImpl(
            Provider.of<MaintenanceDatasource>(context, listen: false),
          ),
        ),
        Provider<MaintenanceUseCases>(
          create: (context) => MaintenanceUseCases(
            Provider.of<MaintenanceRepositoryImpl>(context, listen: false),
            Provider.of<InventoryUseCases>(context, listen: false),
            Provider.of<MachineryOperatorUseCases>(context, listen: false),
          ),
        ),
        // توفير Sales Dependencies (جديد)
        Provider<SalesDatasource>(
          create: (_) => SalesDatasource(),
        ),
        Provider<SalesRepositoryImpl>(
          create: (context) => SalesRepositoryImpl(
            Provider.of<SalesDatasource>(context, listen: false),
          ),
        ),
        Provider<SalesUseCases>(
          create: (context) => SalesUseCases(
            Provider.of<SalesRepositoryImpl>(context, listen: false),
            Provider.of<NotificationUseCases>(context, listen: false),
            Provider.of<UserUseCases>(context, listen: false),
          ),
        ),
        // Financial dependencies
        Provider<FinancialDatasource>(
          create: (_) => FinancialDatasource(),
        ),
        Provider<FinancialRepositoryImpl>(
          create: (context) => FinancialRepositoryImpl(
            Provider.of<FinancialDatasource>(context, listen: false),
          ),
        ),
        Provider<FinancialUseCases>(
          create: (context) => FinancialUseCases(
            Provider.of<FinancialRepositoryImpl>(context, listen: false),
            Provider.of<SalesRepositoryImpl>(context, listen: false),
          ),
        ),
        // Procurement dependencies
        Provider<ProcurementDatasource>(
          create: (_) => ProcurementDatasource(),
        ),
        Provider<ProcurementRepositoryImpl>(
          create: (context) => ProcurementRepositoryImpl(
            Provider.of<ProcurementDatasource>(context, listen: false),
          ),
        ),
        Provider<ProcurementUseCases>(
          create: (context) => ProcurementUseCases(
            Provider.of<ProcurementRepositoryImpl>(context, listen: false),
            Provider.of<InventoryUseCases>(context, listen: false),
          ),
        ),
        // Quality Control dependencies
        Provider<QualityDatasource>(
          create: (_) => QualityDatasource(),
        ),
        Provider<QualityRepositoryImpl>(
          create: (context) => QualityRepositoryImpl(
            Provider.of<QualityDatasource>(context, listen: false),
          ),
        ),
        Provider<QualityUseCases>(
          create: (context) => QualityUseCases(
            Provider.of<QualityRepositoryImpl>(context, listen: false),
          ),
        ),
        // Returns dependencies
        Provider<ReturnsDatasource>(
          create: (_) => ReturnsDatasource(),
        ),
        Provider<ReturnsRepositoryImpl>(
          create: (context) => ReturnsRepositoryImpl(
            Provider.of<ReturnsDatasource>(context, listen: false),
          ),
        ),
        Provider<ReturnsUseCases>(
          create: (context) => ReturnsUseCases(
            Provider.of<ReturnsRepositoryImpl>(context, listen: false),
            Provider.of<SalesUseCases>(context, listen: false),
            Provider.of<InventoryUseCases>(context, listen: false),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Plastic & Household Products Factory Management System',
        locale: const Locale('ar'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar', ''),
          Locale('en', ''),
        ],
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
        theme: ThemeData(
          primarySwatch: AppColors.primarySwatch,
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: AppColors.primarySwatch,
          ).copyWith(secondary: AppColors.dark),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.dark,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            labelStyle: TextStyle(color: AppColors.dark),
            floatingLabelStyle: TextStyle(color: AppColors.dark),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          fontFamily: 'Tajawal',
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: AppRouter.loginRoute,
        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<User?>(context);

    if (firebaseUser == null) {
      return LoginScreen();
    } else {
      return HomeScreen();
    }
  }
}