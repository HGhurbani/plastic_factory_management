// plastic_factory_management/lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:plastic_factory_management/firebase_options.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';

import 'package:plastic_factory_management/core/services/auth_service.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';

// استيرادات Production Order
import 'package:plastic_factory_management/data/datasources/production_order_datasource.dart';
import 'package:plastic_factory_management/data/repositories/production_order_repository_impl.dart';
import 'package:plastic_factory_management/domain/usecases/production_order_usecases.dart';

// استيرادات Inventory
import 'package:plastic_factory_management/data/datasources/inventory_datasource.dart';
import 'package:plastic_factory_management/data/repositories/inventory_repository_impl.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';

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
// استيرادات Notifications
import 'package:plastic_factory_management/data/datasources/notification_datasource.dart';
import 'package:plastic_factory_management/data/repositories/notification_repository_impl.dart';
import 'package:plastic_factory_management/domain/usecases/notification_usecases.dart';
// استيرادات User Management
import 'package:plastic_factory_management/data/datasources/user_datasource.dart';
import 'package:plastic_factory_management/data/repositories/user_repository_impl.dart';
import 'package:plastic_factory_management/domain/usecases/user_usecases.dart';


import 'package:plastic_factory_management/presentation/auth/login_screen.dart';
import 'package:plastic_factory_management/presentation/home/home_screen.dart';
import 'package:plastic_factory_management/presentation/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
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
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.blueGrey[800],
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(),
            labelStyle: TextStyle(color: Colors.blueGrey[700]),
            floatingLabelStyle: TextStyle(color: Colors.blueGrey[900]),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          fontFamily: GoogleFonts.tajawal().fontFamily,
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