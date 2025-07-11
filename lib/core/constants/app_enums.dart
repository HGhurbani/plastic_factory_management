// plastic_factory_management/lib/core/constants/app_enums.dart

enum UserRole {
  factoryManager, // مدير المصنع
  productionManager, // مدير الإنتاج
  operationsOfficer, // مسؤول العمليات
  productionOrderPreparer, // مسؤول إعداد طلبات الإنتاج
  moldInstallationSupervisor, // مشرف تركيب القوالب
  productionShiftSupervisor, // مشرف الوردية / مشرف الإنتاج
  machineOperator, // مشغل المكينة
  maintenanceManager, // مسؤول الصيانة
  salesRepresentative, // مندوب المبيعات
  qualityInspector, // مراقب الجودة
  inventoryManager, // أمين المخزن
  accountant, // المحاسب
  driver, // سائق التوصيل
  unknown, // دور غير معروف
}

extension UserRoleExtension on UserRole {
  /// يحول قيمة الدور إلى نص عربي مناسب للعرض.
  String toArabicString() {
    switch (this) {
      case UserRole.factoryManager:
        return 'مدير المصنع';
      case UserRole.productionManager:
        return 'مدير الإنتاج';
      case UserRole.operationsOfficer:
        return 'مسؤول العمليات';
      case UserRole.productionOrderPreparer:
        return 'مسؤول إعداد طلبات الإنتاج';
      case UserRole.moldInstallationSupervisor:
        return 'مشرف تركيب القوالب';
      case UserRole.productionShiftSupervisor:
        return 'مشرف الوردية / مشرف الإنتاج';
      case UserRole.machineOperator:
        return 'مشغل المكينة';
      case UserRole.maintenanceManager:
        return 'مسؤول الصيانة';
      case UserRole.salesRepresentative:
        return 'مندوب المبيعات';
      case UserRole.qualityInspector:
        return 'مراقب الجودة';
      case UserRole.inventoryManager:
        return 'أمين المخزن';
      case UserRole.accountant:
        return 'المحاسب';
      case UserRole.driver:
        return 'سائق التوصيل';
      case UserRole.unknown:
      default:
        return 'غير معروف';
    }
  }

  /// يحول سلسلة نصية (من Firestore مثلاً) إلى قيمة الدور المقابلة.
  static UserRole fromString(String? roleString) {
    if (roleString == null) return UserRole.unknown;
    switch (roleString) {
      case 'factory_manager':
        return UserRole.factoryManager;
      case 'production_manager':
        return UserRole.productionManager;
      case 'operations_officer':
        return UserRole.operationsOfficer;
      case 'production_order_preparer':
        return UserRole.productionOrderPreparer;
      case 'mold_installation_supervisor':
        return UserRole.moldInstallationSupervisor;
      case 'production_shift_supervisor':
        return UserRole.productionShiftSupervisor;
      case 'machine_operator':
        return UserRole.machineOperator;
      case 'maintenance_manager':
        return UserRole.maintenanceManager;
      case 'sales_representative':
        return UserRole.salesRepresentative;
      case 'quality_inspector':
        return UserRole.qualityInspector;
      case 'inventory_manager':
        return UserRole.inventoryManager;
      case 'accountant':
        return UserRole.accountant;
      case 'driver':
        return UserRole.driver;
      default:
        return UserRole.unknown;
    }
  }

  /// يحول قيمة الدور إلى سلسلة نصية للاستخدام في Firestore (مثل 'factory_manager').
  String toFirestoreString() {
    switch (this) {
      case UserRole.factoryManager:
        return 'factory_manager';
      case UserRole.productionManager:
        return 'production_manager';
      case UserRole.operationsOfficer:
        return 'operations_officer';
      case UserRole.productionOrderPreparer:
        return 'production_order_preparer';
      case UserRole.moldInstallationSupervisor:
        return 'mold_installation_supervisor';
      case UserRole.productionShiftSupervisor:
        return 'production_shift_supervisor';
      case UserRole.machineOperator:
        return 'machine_operator';
      case UserRole.maintenanceManager:
        return 'maintenance_manager';
      case UserRole.salesRepresentative:
        return 'sales_representative';
      case UserRole.qualityInspector:
        return 'quality_inspector';
      case UserRole.inventoryManager:
        return 'inventory_manager';
      case UserRole.accountant:
        return 'accountant';
      case UserRole.driver:
        return 'driver';
      case UserRole.unknown:
      default:
        return 'unknown';
    }
  }
}

enum TransportMode { company, external }

extension TransportModeExtension on TransportMode {
  String toArabicString() {
    switch (this) {
      case TransportMode.company:
        return 'شركة';
      case TransportMode.external:
        return 'خارجي';
    }
  }

  String toFirestoreString() => name;

  static TransportMode fromString(String value) {
    return TransportMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransportMode.company,
    );
  }
}

enum FactoryElementType { rawMaterial, colorant, productionInput, custom }

extension FactoryElementTypeExtension on FactoryElementType {
  String toArabicString() {
    switch (this) {
      case FactoryElementType.rawMaterial:
        return 'مواد خام';
      case FactoryElementType.colorant:
        return 'ملونات';
      case FactoryElementType.productionInput:
        return 'مدخلات إنتاج';
      case FactoryElementType.custom:
        return 'مخصص';
    }
  }

  String toFirestoreString() => name;

  static FactoryElementType fromString(String value) {
    return FactoryElementType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FactoryElementType.custom,
    );
  }
}

enum OrderType { sales, production }

extension OrderTypeExtension on OrderType {
  String toFirestoreString() => name;

  static OrderType fromString(String value) {
    return OrderType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderType.sales,
    );
  }
}

enum QualityApprovalStatus { approved, rejected }

extension QualityApprovalStatusExtension on QualityApprovalStatus {
  String toFirestoreString() => name;

  static QualityApprovalStatus fromString(String value) {
    return QualityApprovalStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => QualityApprovalStatus.approved,
    );
  }
}