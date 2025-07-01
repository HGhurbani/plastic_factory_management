// plastic_factory_management/lib/core/constants/app_enums.dart

enum UserRole {
  factoryManager, // مدير المصنع
  productionManager, // مدير الإنتاج
  operationsOfficer, // مسؤول العمليات
  moldInstallationSupervisor, // مشرف تركيب القوالب
  productionShiftSupervisor, // مشرف الوردية / مشرف الإنتاج
  machineOperator, // مشغل المكينة
  maintenanceManager, // مسؤول الصيانة
  salesRepresentative, // مندوب المبيعات
  qualityInspector, // مراقب الجودة
  inventoryManager, // أمين المخزن
  accountant, // المحاسب
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
      case UserRole.unknown:
      default:
        return 'unknown';
    }
  }
}