// plastic_factory_management/lib/domain/usecases/sales_usecases.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/data/models/customer_model.dart';
import 'package:plastic_factory_management/data/models/sales_order_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/machine_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/repositories/sales_repository.dart';
import 'dart:io';
import 'dart:typed_data';
import 'notification_usecases.dart';
import 'user_usecases.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';
import 'package:plastic_factory_management/core/services/file_upload_service.dart';
import 'inventory_usecases.dart';
import 'package:plastic_factory_management/data/models/inventory_balance_model.dart';

class SalesUseCases {
  final SalesRepository repository;
  final NotificationUseCases notificationUseCases;
  final UserUseCases userUseCases;

  SalesUseCases(this.repository, this.notificationUseCases, this.userUseCases);

  // --- Customer Use Cases ---

  Stream<List<CustomerModel>> getCustomers() {
    return repository.getCustomers();
  }

  Future<void> addCustomer({
    required String name,
    required String contactPerson,
    required String phone,
    String? email,
    String? address,
    double creditLimit = 0.0,
    double currentDebt = 0.0,
  }) async {
    final newCustomer = CustomerModel(
      id: '', // Firestore will generate
      name: name,
      contactPerson: contactPerson,
      phone: phone,
      email: email,
      address: address,
      creditLimit: creditLimit,
      currentDebt: currentDebt,
      createdAt: Timestamp.now(),
    );
    await repository.addCustomer(newCustomer);
  }

  Future<void> updateCustomer({
    required String id,
    required String name,
    required String contactPerson,
    required String phone,
    String? email,
    String? address,
    double? creditLimit,
    double? currentDebt,
  }) async {
    final existing = await repository.getCustomerById(id);
    final updatedCustomer = CustomerModel(
      id: id,
      name: name,
      contactPerson: contactPerson,
      phone: phone,
      email: email,
      address: address,
      creditLimit: creditLimit ?? existing?.creditLimit ?? 0.0,
      currentDebt: currentDebt ?? existing?.currentDebt ?? 0.0,
      createdAt: existing?.createdAt ?? Timestamp.now(), // Preserve creation date
    );
    await repository.updateCustomer(updatedCustomer);
  }

  Future<void> deleteCustomer(String customerId) async {
    await repository.deleteCustomer(customerId);
  }

  // --- Sales Order Use Cases ---

  Stream<List<SalesOrderModel>> getSalesOrders({String? salesRepUid}) {
    if (salesRepUid != null) {
      return repository.getSalesOrdersBySalesRepresentative(salesRepUid);
    }
    return repository.getSalesOrders();
  }

  Future<void> createSalesOrder({
    required CustomerModel customer,
    required UserModel salesRepresentative,
    required List<SalesOrderItem> orderItems,
    required double totalAmount,
    File? customerSignatureFile,
    Uint8List? customerSignatureBytes,
    required InventoryUseCases inventoryUseCases,
  }) async {
    for (final item in orderItems) {
      final available = await inventoryUseCases.getAvailableQuantity(
          item.productId, InventoryItemType.finishedProduct);
      if (available < item.quantity) {
        throw Exception('INSUFFICIENT_STOCK');
      }
    }
    final newOrder = SalesOrderModel(
      id: '', // Firestore will generate
      customerId: customer.id,
      customerName: customer.name,
      salesRepresentativeUid: salesRepresentative.uid,
      salesRepresentativeName: salesRepresentative.name,
      orderItems: orderItems,
      totalAmount: totalAmount,
      status: SalesOrderStatus.pendingApproval, // Initial status awaiting accountant
      createdAt: Timestamp.now(),
    );
    await repository.addSalesOrder(
      newOrder,
      signatureFile: customerSignatureFile,
      signatureBytes: customerSignatureBytes,
    );

    // Notify accountants for financial approval
    final accountants = await userUseCases.getUsersByRole(UserRole.accountant);
    for (final acc in accountants) {
      await notificationUseCases.sendNotification(
        userId: acc.uid,
        title: 'طلب مبيعات جديد',
        message:
            'قام ${salesRepresentative.name} بإنشاء طلب مبيعات للعميل ${customer.name}',
      );
    }
  }

  Future<void> updateSalesOrderStatus(String orderId, SalesOrderStatus newStatus) async {
    final order = await repository.getSalesOrders().first.then((orders) => orders.firstWhere((o) => o.id == orderId));
    if (order != null) {
      final updatedOrder = order.copyWith(status: newStatus);
      await repository.updateSalesOrder(updatedOrder);
    }
  }

  // Mark a sales order as delivered (fulfilled)
  Future<void> markOrderDelivered(SalesOrderModel order) async {
    final updatedOrder = order.copyWith(status: SalesOrderStatus.fulfilled);
    await repository.updateSalesOrder(updatedOrder);
  }

  // Accountant approves a sales order
  Future<void> approveSalesOrder(SalesOrderModel order, UserModel accountant, {String? notes}) async {
    final customer = await repository.getCustomerById(order.customerId);
    if (customer != null) {
      final newDebt = customer.currentDebt + order.totalAmount;
      if (customer.creditLimit > 0 && newDebt > customer.creditLimit) {
        throw Exception('CREDIT_LIMIT_EXCEEDED');
      }
      await repository.updateCustomer(customer.copyWith(currentDebt: newDebt));
    }

    final updatedOrder = order.copyWith(
      status: SalesOrderStatus.pendingFulfillment,
      approvedByUid: accountant.uid,
      approvedByName: accountant.name,
      approvedAt: Timestamp.now(),
      approvalNotes: notes,
      rejectionReason: null,
      moldTasksEnabled: false,
    );
    await repository.updateSalesOrder(updatedOrder);

    final managers = await userUseCases.getUsersByRole(UserRole.factoryManager);
    for (final m in managers) {
      await notificationUseCases.sendNotification(
        userId: m.uid,
        title: 'تم اعتماد طلب مبيعات',
        message: 'اعتمد المحاسب الطلب للعميل ${order.customerName}',
      );
    }

    // Notify operations officers and production order preparers to assign warehouse
    final opsOfficers =
        await userUseCases.getUsersByRole(UserRole.operationsOfficer);
    final preparers =
        await userUseCases.getUsersByRole(UserRole.productionOrderPreparer);
    final recipients = [...opsOfficers, ...preparers];
    for (final user in recipients) {
      await notificationUseCases.sendNotification(
        userId: user.uid,
        title: 'طلب مبيعات بانتظار التوجيه للمخزن',
        message: 'يرجى تحديد أمين المخزن لطلب العميل ${order.customerName}',
      );
    }

    // Notify mold installation supervisors to start their tasks
    final moldSupervisors =
        await userUseCases.getUsersByRole(UserRole.moldInstallationSupervisor);
    for (final sup in moldSupervisors) {
      await notificationUseCases.sendNotification(
        userId: sup.uid,
        title: 'طلب تركيب قوالب جديد',
        message: 'يرجى متابعة طلب العميل ${order.customerName}',
      );
    }
  }

  // Accountant rejects a sales order
  Future<void> rejectSalesOrder(SalesOrderModel order, UserModel accountant, String reason) async {
    final updatedOrder = order.copyWith(
      status: SalesOrderStatus.rejected,
      approvedByUid: accountant.uid,
      approvedByName: accountant.name,
      approvedAt: Timestamp.now(),
      rejectionReason: reason,
      moldTasksEnabled: false,
    );
    await repository.updateSalesOrder(updatedOrder);

    final salesRep = await userUseCases.getUserById(order.salesRepresentativeUid);
    if (salesRep != null) {
      await notificationUseCases.sendNotification(
        userId: salesRep.uid,
        title: 'تم رفض طلب المبيعات',
        message: 'تم رفض طلب العميل ${order.customerName}. السبب: $reason',
      );
    }
  }

  // Production order preparer initiates supply to warehouse
  Future<void> initiateSupply(
      SalesOrderModel order,
      UserModel preparer,
      UserModel storekeeper, {
      String? notes,
    }) async {
    final updated = order.copyWith(
      status: SalesOrderStatus.warehouseProcessing,
      warehouseManagerUid: storekeeper.uid,
      warehouseManagerName: storekeeper.name,
      operationsNotes: notes ?? order.operationsNotes,
    );
    await repository.updateSalesOrder(updated);

    await notificationUseCases.sendNotification(
      userId: storekeeper.uid,
      title: 'طلب توريد جديد',
      message: 'الرجاء تجهيز طلب العميل ${order.customerName}',
    );
  }

  // Warehouse manager documents supply and sets delivery time
  Future<void> documentWarehouseSupply({
    required SalesOrderModel order,
    required UserModel storekeeper,
    String? notes,
    List<File>? attachments,
    DateTime? deliveryTime,
  }) async {
    List<String> uploaded = List<String>.from(order.warehouseImages);
    if (attachments != null && attachments.isNotEmpty) {
      for (final file in attachments) {
        final url = await FileUploadService().uploadFile(
          file,
          'warehouse_docs/${order.id}_${DateTime.now().microsecondsSinceEpoch}.jpg',
        );
        if (url != null) uploaded.add(url);
      }
    }
    final updated = order.copyWith(
      warehouseNotes: notes ?? order.warehouseNotes,
      warehouseImages: uploaded,
      warehouseManagerUid: storekeeper.uid,
      warehouseManagerName: storekeeper.name,
      deliveryTime: deliveryTime != null
          ? Timestamp.fromDate(deliveryTime)
          : order.deliveryTime,
      status: SalesOrderStatus.awaitingOperationsForward,
    );
    await repository.updateSalesOrder(updated);
  }

  /// Operations officer forwards order to mold supervisor after review
  Future<void> forwardToMoldSupervisor(
      SalesOrderModel order,
      UserModel operationsOfficer, {
      UserModel? supervisor,
      String? notes,
      MachineModel? machine,
    }) async {
    final updated = order.copyWith(
      status: SalesOrderStatus.awaitingMoldApproval,
      operationsNotes: notes ?? order.operationsNotes,
      machineId: machine?.id ?? order.machineId,
      machineName: machine?.name ?? order.machineName,
      moldSupervisorUid: supervisor?.uid ?? order.moldSupervisorUid,
      moldSupervisorName: supervisor?.name ?? order.moldSupervisorName,
    );
    await repository.updateSalesOrder(updated);

    if (supervisor != null) {
      await notificationUseCases.sendNotification(
        userId: supervisor.uid,
        title: 'طلب بانتظار اعتماد القوالب',
        message: 'يرجى مراجعة طلب العميل ${order.customerName}',
      );
    } else {
      final supervisors =
          await userUseCases.getUsersByRole(UserRole.moldInstallationSupervisor);
      for (final sup in supervisors) {
        await notificationUseCases.sendNotification(
          userId: sup.uid,
          title: 'طلب بانتظار اعتماد القوالب',
          message: 'يرجى مراجعة طلب العميل ${order.customerName}',
        );
      }
    }
  }

  Future<void> scheduleDelivery({
    required SalesOrderModel order,
    required DateTime deliveryTime,
    required TransportMode transportMode,
    String? driverUid,
    String? driverName,
  }) async {
    final updated = order.copyWith(
      deliveryTime: Timestamp.fromDate(deliveryTime),
      transportMode: transportMode,
      driverUid: driverUid,
      driverName: driverName,
    );
    await repository.updateSalesOrder(updated);
  }

  // Production manager approves supply
  Future<void> approveSupply(SalesOrderModel order, UserModel manager,
      InventoryUseCases inventoryUseCases) async {
    final updated = order.copyWith(
      status: SalesOrderStatus.fulfilled,
      productionManagerUid: manager.uid,
      productionManagerName: manager.name,
      productionRejectionReason: null,
    );
    await repository.updateSalesOrder(updated);

    final rep = await userUseCases.getUserById(order.salesRepresentativeUid);
    if (rep != null) {
      await notificationUseCases.sendNotification(
        userId: rep.uid,
        title: 'تم اعتماد توريد الطلب',
        message: 'تم اعتماد توريد طلب العميل ${order.customerName}',
      );
    }

    for (final item in order.orderItems) {
      await inventoryUseCases.adjustInventoryWithNotification(
        itemId: item.productId,
        itemName: item.productName,
        type: InventoryItemType.finishedProduct,
        delta: -item.quantity.toDouble(),
      );
    }
  }

  // Production manager rejects supply and sends back to warehouse
  Future<void> rejectSupply(
      SalesOrderModel order, UserModel manager, String reason) async {
    final updated = order.copyWith(
      status: SalesOrderStatus.warehouseProcessing,
      productionManagerUid: manager.uid,
      productionManagerName: manager.name,
      productionRejectionReason: reason,
    );
    await repository.updateSalesOrder(updated);

    if (order.warehouseManagerUid != null) {
      await notificationUseCases.sendNotification(
        userId: order.warehouseManagerUid!,
        title: 'رفض طلب الإنتاج',
        message:
            'تم رفض بدء إنتاج طلب العميل ${order.customerName}. السبب: $reason',
      );
    }
  }

  // Mold supervisor approves order and enables mold tasks
  Future<void> approveMoldTasks(SalesOrderModel order, UserModel supervisor) async {
    if (order.moldTasksEnabled) return;
    final updated = order.copyWith(
      moldTasksEnabled: true,
      moldSupervisorUid: supervisor.uid,
      moldSupervisorName: supervisor.name,
      moldSupervisorApprovedAt: Timestamp.now(),
    );
    await repository.updateSalesOrder(updated);

    await notificationUseCases.sendNotification(
      userId: supervisor.uid,
      title: 'تم اعتماد مهام التركيب',
      message: 'تم اعتماد طلب العميل ${order.customerName}' ,
    );
  }

  // Mold installer adds documentation
  Future<void> addMoldInstallationDocs({
    required SalesOrderModel order,
    String? notes,
    List<File>? attachments,
  }) async {
    List<String> uploaded = List<String>.from(order.moldInstallationImages);
    if (attachments != null && attachments.isNotEmpty) {
      for (final file in attachments) {
        final url = await FileUploadService().uploadFile(
          file,
          'sales_mold_docs/${order.id}_${DateTime.now().microsecondsSinceEpoch}.jpg',
        );
        if (url != null) uploaded.add(url);
      }
    }
    final updatedOrder = order.copyWith(
      moldInstallationNotes: notes ?? order.moldInstallationNotes,
      moldInstallationImages: uploaded,
    );
    await repository.updateSalesOrder(updatedOrder);
  }

  Future<void> deleteSalesOrder(String orderId) async {
    await repository.deleteSalesOrder(orderId);
  }

  Future<SalesOrderModel?> getSalesOrderById(String orderId) {
    return repository.getSalesOrderById(orderId);
  }

  // --- Product Catalog for Sales Reps ---
  Stream<List<ProductModel>> getProductCatalogForSales() {
    return repository.getAllProducts(); // Reusing the product model from inventory
  }
}