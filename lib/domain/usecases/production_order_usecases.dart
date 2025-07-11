// plastic_factory_management/lib/domain/usecases/production_order_usecases.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plastic_factory_management/data/models/production_order_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/data/models/machine_model.dart';
import 'package:plastic_factory_management/data/models/sales_order_model.dart';
import 'package:plastic_factory_management/data/models/inventory_balance_model.dart';
import 'package:plastic_factory_management/data/repositories/production_order_repository.dart';
import 'package:plastic_factory_management/core/services/file_upload_service.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';
import 'notification_usecases.dart';
import 'user_usecases.dart';
import 'inventory_usecases.dart';
import 'dart:io'; // لاستخدام File

class ProductionOrderUseCases {
  final ProductionOrderRepository repository;
  final NotificationUseCases notificationUseCases;
  final UserUseCases userUseCases;
  final InventoryUseCases inventoryUseCases;
  final FileUploadService _uploadService = FileUploadService();

  ProductionOrderUseCases(
      this.repository, this.notificationUseCases, this.userUseCases, this.inventoryUseCases);

  Stream<List<ProductionOrderModel>> getProductionOrders() {
    return repository.getProductionOrders();
  }

  Stream<List<ProductionOrderModel>> getPendingProductionOrders() {
    return repository.getPendingProductionOrders();
  }

  // New: Get orders assigned to a specific supervisor/operator
  Stream<List<ProductionOrderModel>> getAssignedProductionOrders(String userUid) {
    // This requires a Firestore query on workflowStages which is complex.
    // A better approach might be:
    // 1. Have a top-level field `assignedToUid` on the order for the current active stage.
    // 2. Use Cloud Functions to listen to workflowStages changes and update `assignedToUid`.
    // For now, we'll fetch all and filter client-side, or assume `currentStage` implies assignment.
    // Example (less efficient for large datasets):
    return repository.getProductionOrders().map((orders) {
      return orders.where((order) {
        // Find the current active stage if applicable and check assignment
        final currentActiveStage = order.workflowStages.firstWhere(
                (stage) => stage.stageName == order.currentStage && stage.status == 'pending',
            orElse: () => ProductionWorkflowStage(stageName: '', status: '')); // Dummy stage if not found
        return currentActiveStage.assignedToUid == userUid ||
            (order.currentStage == 'استلام مشرف تركيب القوالب' && currentActiveStage.status == 'pending');
        // This logic needs to be robustly defined based on YOUR workflow
      }).toList();
    });
  }

  // Orders awaiting mold installation supervisor receipt
  Stream<List<ProductionOrderModel>> getOrdersAwaitingMoldInstallation() {
    return repository.getProductionOrders().map((orders) {
      return orders.where((order) =>
          order.currentStage == 'استلام مشرف تركيب القوالب' &&
          order.status == ProductionOrderStatus.approved).toList();
    });
  }

  Future<ProductionOrderModel?> getProductionOrderById(String orderId) {
    return repository.getProductionOrderById(orderId);
  }

  // Use case to create a new production order
  Future<ProductionOrderModel> createProductionOrder({
    required ProductModel selectedProduct,
    required int requiredQuantity,
    MachineModel? selectedMachine,
    required UserModel orderPreparer, // Pass the current user model
    required UserModel moldSupervisor,
    String? salesOrderId,
  }) async {
    for (final material in selectedProduct.billOfMaterials) {
      final needed = material.quantityPerUnit * requiredQuantity;
      final available = await inventoryUseCases.getAvailableQuantity(
          material.materialId, InventoryItemType.rawMaterial);
      if (available < needed) {
        throw Exception('INSUFFICIENT_STOCK');
      }
    }
    // Define the initial workflow stages
    final List<ProductionWorkflowStage> initialWorkflow = [
      ProductionWorkflowStage(
        stageName: 'إعداد الطلب',
        status: 'completed',
        assignedToUid: orderPreparer.uid,
        assignedToName: orderPreparer.name,
        completedAt: Timestamp.now(),
        notes: 'تم إعداد الطلب بواسطة ${orderPreparer.name}.',
      ),
      ProductionWorkflowStage(
        stageName: 'انتظار الموافقة',
        status: 'pending', // المدير لم يوافق بعد
        assignedToUid: null, // لا يوجد مسؤول محدد في هذه المرحلة
        assignedToName: null,
      ),
    ];

    final batchNumber = DateTime.now().millisecondsSinceEpoch.toString();
    final newOrder = ProductionOrderModel(
      id: '', // Firestore will generate this
      productId: selectedProduct.id,
      productName: selectedProduct.name,
      requiredQuantity: requiredQuantity,
      batchNumber: batchNumber,
      templateId: null,
      templateName: null,
      machineId: selectedMachine?.id,
      machineName: selectedMachine?.name,
      moldSupervisorUid: moldSupervisor.uid,
      moldSupervisorName: moldSupervisor.name,
      shiftSupervisorUid: null,
      shiftSupervisorName: null,
      orderPreparerUid: orderPreparer.uid,
      orderPreparerName: orderPreparer.name,
      orderPreparerRole: orderPreparer.userRoleEnum.toFirestoreString(),
      status: ProductionOrderStatus.pending, // الحالة الإجمالية للطلب هي 'قيد الانتظار'
      createdAt: Timestamp.now(),
      currentStage: 'انتظار الموافقة', // المرحلة النشطة الحالية
      workflowStages: initialWorkflow,
    );
    final createdOrder = await repository.createProductionOrder(newOrder);

    if (orderPreparer.userRoleEnum == UserRole.operationsOfficer) {
      await approveProductionOrder(createdOrder, orderPreparer);

      final storekeepers =
          await userUseCases.getUsersByRole(UserRole.inventoryManager);
      for (final sk in storekeepers) {
        await notificationUseCases.sendNotification(
          userId: sk.uid,
          title: 'تم إنشاء طلب إنتاج',
          message:
              'يرجى تجهيز المواد للطلب رقم ${createdOrder.batchNumber}',
        );
      }
    }

    return createdOrder;
  }

  // Create production orders from a sales order (one per item)
  Future<void> createProductionOrdersFromSalesOrder(
      SalesOrderModel order, UserModel preparer) async {
    for (int i = 0; i < order.orderItems.length; i++) {
      final item = order.orderItems[i];
      final List<ProductionWorkflowStage> initialWorkflow = [
        ProductionWorkflowStage(
          stageName: 'إعداد الطلب',
          status: 'completed',
          assignedToUid: preparer.uid,
          assignedToName: preparer.name,
          completedAt: Timestamp.now(),
          notes: 'تم إعداد الطلب من طلب المبيعات.',
        ),
        ProductionWorkflowStage(
          stageName: 'انتظار الموافقة',
          status: 'pending',
          assignedToUid: null,
          assignedToName: null,
        ),
      ];

      final newOrder = ProductionOrderModel(
        id: '',
        productId: item.productId,
        productName: item.productName,
        requiredQuantity: item.quantity,
      batchNumber: '${order.id}-$i',
      salesOrderId: order.id,
      moldSupervisorUid: order.moldSupervisorUid,
      moldSupervisorName: order.moldSupervisorName,
      shiftSupervisorUid: order.shiftSupervisorUid,
      shiftSupervisorName: order.shiftSupervisorName,
      orderPreparerUid: preparer.uid,
      orderPreparerName: preparer.name,
      orderPreparerRole: preparer.userRoleEnum.toFirestoreString(),
      status: ProductionOrderStatus.pending,
        createdAt: Timestamp.now(),
        currentStage: 'انتظار الموافقة',
        workflowStages: initialWorkflow,
      );
      await repository.createProductionOrder(newOrder);
    }
  }

  // Use case to approve a production order
  Future<void> approveProductionOrder(
    ProductionOrderModel order,
    UserModel approver, {
    String? notes,
    List<File>? attachments,
  }) async {
    final updatedWorkflow = List<ProductionWorkflowStage>.from(order.workflowStages);

    // Upload attachments if provided
    List<String> uploaded = [];
    if (attachments != null && attachments.isNotEmpty) {
      for (final file in attachments) {
        final url = await _uploadService.uploadFile(
          file,
          'production_approval/${order.id}_${DateTime.now().microsecondsSinceEpoch}.jpg',
        );
        if (url != null) uploaded.add(url);
      }
    }

    // 1. Update the 'pending_approval' stage to 'completed'
    final pendingApprovalIndex = updatedWorkflow.indexWhere(
          (stage) => stage.stageName == 'انتظار الموافقة' && stage.status == 'pending',
    );

    if (pendingApprovalIndex != -1) {
      final currentStage = updatedWorkflow[pendingApprovalIndex];
      updatedWorkflow[pendingApprovalIndex] = currentStage.copyWith(
        status: 'completed',
        completedAt: Timestamp.now(),
        notes: notes?.isNotEmpty == true
            ? notes
            : 'تمت الموافقة على الطلب بواسطة ${approver.name}.',
        attachments: [...currentStage.attachments, ...uploaded],
      );
    } else {
      // Handle case where 'pending_approval' stage isn't found or not pending
      print("Warning: 'انتظار الموافقة' stage not found or not pending for approval.");
      return;
    }

    // 2. Add the next stage: 'استلام مشرف تركيب القوالب'
    updatedWorkflow.add(
      ProductionWorkflowStage(
        stageName: 'استلام مشرف تركيب القوالب',
        status: 'pending', // مشرف تركيب القوالب يحتاج لاستلامها
        // assignedToUid: // يمكن تعيينه هنا إذا كان هناك مشرف افتراضي
        // assignedToName:
      ),
    );

    final updatedOrder = order.copyWith(
      status: ProductionOrderStatus.approved,
      approvedByUid: approver.uid,
      approvedAt: Timestamp.now(),
      currentStage: 'استلام مشرف تركيب القوالب', // تعيين المرحلة الحالية للطلب
      workflowStages: updatedWorkflow,
    );
    await repository.updateProductionOrder(updatedOrder);

    // Notify mold installation supervisors about new stage
    final supervisors =
        await userUseCases.getUsersByRole(UserRole.moldInstallationSupervisor);
    for (final sup in supervisors) {
      await notificationUseCases.sendNotification(
        userId: sup.uid,
        title: 'تم اعتماد طلب الإنتاج',
        message:
            'يرجى استلام القالب للطلب رقم ${updatedOrder.batchNumber}',
      );
    }

    // TODO: هنا يمكن تفعيل Cloud Function لجرد المواد الأولية وتخصيصها.
    // هذا الجزء يتطلب منطقًا معقدًا قد لا يتم التعامل معه بالكامل في هذا الكود.
    // يمكن لـ Cloud Function الاستماع لتغيير حالة الطلب إلى 'approved' ثم خصم المواد من المخزون.
  }

  // Use case to reject a production order
  Future<void> rejectProductionOrder(ProductionOrderModel order, UserModel approver, String reason) async {
    final updatedWorkflow = List<ProductionWorkflowStage>.from(order.workflowStages);

    // Update the 'pending_approval' stage to 'failed' or 'rejected'
    final pendingApprovalIndex = updatedWorkflow.indexWhere(
          (stage) => stage.stageName == 'انتظار الموافقة' && stage.status == 'pending',
    );

    if (pendingApprovalIndex != -1) {
      updatedWorkflow[pendingApprovalIndex] = updatedWorkflow[pendingApprovalIndex].copyWith(
        status: 'failed',
        completedAt: Timestamp.now(),
        notes: 'تم الرفض بواسطة ${approver.name}. السبب: $reason',
      );
    }

    final updatedOrder = order.copyWith(
      status: ProductionOrderStatus.rejected,
      rejectionReason: reason,
      approvedByUid: approver.uid,
      approvedAt: Timestamp.now(),
      currentStage: 'rejected',
      workflowStages: updatedWorkflow,
    );
    await repository.updateProductionOrder(updatedOrder);

    await notificationUseCases.sendNotification(
      userId: order.orderPreparerUid,
      title: 'تم رفض طلب الإنتاج',
      message: 'تم رفض طلب إنتاج ${order.productName}. السبب: $reason',
    );
  }

  // --- NEW WORKFLOW METHODS ---

  // Use case for a supervisor to accept responsibility for a stage (Handoff)
  Future<void> acceptStageResponsibility({
    required ProductionOrderModel order,
    required String stageName,
    required UserModel responsibleUser,
    String? signatureImageUrl, // Optional digital signature
    String? notes,
    List<File>? attachments, // Optional file attachments (e.g., photos)
  }) async {
    final updatedWorkflow = List<ProductionWorkflowStage>.from(order.workflowStages);

    // Find the stage to update
    final stageIndex = updatedWorkflow.indexWhere(
          (stage) => stage.stageName == stageName && stage.status == 'pending',
    );

    if (stageIndex == -1) {
      throw Exception('Stage "$stageName" not found or not pending for acceptance.');
    }

    // Upload attachments to external server
    List<String> uploadedAttachmentUrls = [];
    if (attachments != null && attachments.isNotEmpty) {
      for (File file in attachments) {
        final url = await _uploadService.uploadFile(
          file,
          'production_attachments/${order.id}/${stageName}_${DateTime.now().microsecondsSinceEpoch}.jpg',
        );
        if (url != null) {
          uploadedAttachmentUrls.add(url);
        }
      }
    }

    // Update the stage
    final currentStage = updatedWorkflow[stageIndex];
    updatedWorkflow[stageIndex] = currentStage.copyWith(
      status: 'accepted', // or 'in_progress' if starting work immediately
      assignedToUid: responsibleUser.uid,
      assignedToName: responsibleUser.name,
      acceptedAt: Timestamp.now(),
      signatureImageUrl: signatureImageUrl,
      notes: notes,
      attachments: [...currentStage.attachments, ...uploadedAttachmentUrls], // Add new attachments
    );

    ProductionOrderStatus newStatus = order.status;
    if (stageName == 'بدء الإنتاج') {
      newStatus = ProductionOrderStatus.inProduction;
    }

    final updatedOrder = order.copyWith(
      workflowStages: updatedWorkflow,
      currentStage: stageName,
      status: newStatus,
    );
    await repository.updateProductionOrder(updatedOrder);
  }

  // Use case for a supervisor to reject a pending stage
  Future<void> rejectStage({
    required ProductionOrderModel order,
    required String stageName,
    required UserModel responsibleUser,
    required String reason,
  }) async {
    final updatedWorkflow = List<ProductionWorkflowStage>.from(order.workflowStages);

    // Find the stage to update
    final stageIndex = updatedWorkflow.indexWhere(
      (stage) => stage.stageName == stageName && stage.status == 'pending',
    );
    if (stageIndex == -1) {
      throw Exception('Stage "$stageName" not found or not pending for rejection.');
    }

    updatedWorkflow[stageIndex] = updatedWorkflow[stageIndex].copyWith(
      status: 'failed',
      completedAt: Timestamp.now(),
      notes: 'تم الرفض بواسطة ${responsibleUser.name}. السبب: $reason',
    );

    final updatedOrder = order.copyWith(
      status: ProductionOrderStatus.rejected,
      rejectionReason: reason,
      workflowStages: updatedWorkflow,
      currentStage: stageName,
    );
    await repository.updateProductionOrder(updatedOrder);

    await notificationUseCases.sendNotification(
      userId: order.orderPreparerUid,
      title: 'تم رفض مرحلة في الطلب',
      message: 'تم رفض مرحلة $stageName للطلب رقم ${order.batchNumber}. السبب: $reason',
    );
  }

  // Use case to mark a stage as started (e.g., machine operator starts work)
  Future<void> startProductionStage({
    required ProductionOrderModel order,
    required String stageName,
    required UserModel responsibleUser,
    String? machineId,
  }) async {
    final updatedWorkflow = List<ProductionWorkflowStage>.from(order.workflowStages);
    final stageIndex = updatedWorkflow.indexWhere(
          (stage) => stage.stageName == stageName && stage.status == 'accepted', // Assume stage was accepted
    );

    if (stageIndex == -1) {
      throw Exception('Stage "$stageName" not found or not accepted for starting.');
    }

    final currentStage = updatedWorkflow[stageIndex];
    updatedWorkflow[stageIndex] = currentStage.copyWith(
      status: 'in_progress',
      startedAt: Timestamp.now(),
      machineId: machineId, // Assign machine if applicable
    );

    final updatedOrder = order.copyWith(
      workflowStages: updatedWorkflow,
      currentStage: stageName,
      status: ProductionOrderStatus.inProduction, // Overall status
    );
    await repository.updateProductionOrder(updatedOrder);
  }


  // Use case to mark a stage as completed (e.g., mold installation finished, production batch finished)
  Future<void> completeProductionStage({
    required ProductionOrderModel order,
    required String stageName,
    required UserModel responsibleUser,
    String? notes,
    List<File>? attachments,
    String? delayReason, // If there was a delay
    double? actualTimeMinutes, // Actual time spent on this stage
    UserModel? shiftSupervisor,
  }) async {
    final updatedWorkflow = List<ProductionWorkflowStage>.from(order.workflowStages);
    final stageIndex = updatedWorkflow.indexWhere(
      (stage) => stage.stageName == stageName &&
          (stage.status == 'accepted' || stage.status == 'in_progress'),
    );

    // Upload attachments to external server
    List<String> uploadedAttachmentUrls = [];
    if (attachments != null && attachments.isNotEmpty) {
      for (File file in attachments) {
        final url = await _uploadService.uploadFile(
          file,
          'production_attachments/${order.id}/${stageName}_${DateTime.now().microsecondsSinceEpoch}.jpg',
        );
        if (url != null) {
          uploadedAttachmentUrls.add(url);
        }
      }
    }

    if (stageIndex == -1) {
      updatedWorkflow.add(ProductionWorkflowStage(
        stageName: stageName,
        status: 'completed',
        assignedToUid: responsibleUser.uid,
        assignedToName: responsibleUser.name,
        completedAt: Timestamp.now(),
        notes: notes,
        attachments: uploadedAttachmentUrls,
        delayReason: delayReason,
        actualTimeMinutes: actualTimeMinutes,
      ));
    } else {
      final currentStage = updatedWorkflow[stageIndex];
      updatedWorkflow[stageIndex] = currentStage.copyWith(
        status: 'completed',
        completedAt: Timestamp.now(),
        notes: notes,
        attachments: [...currentStage.attachments, ...uploadedAttachmentUrls],
        delayReason: delayReason,
        actualTimeMinutes: actualTimeMinutes,
      );
    }

    // Determine the next stage and update overall order status
    String nextStageName = '';
    ProductionOrderStatus newOverallStatus = order.status;

    if (stageName == 'تركيب القالب') {
      nextStageName = 'بدء الإنتاج';
      updatedWorkflow.add(ProductionWorkflowStage(
        stageName: nextStageName,
        status: 'pending',
        assignedToUid: shiftSupervisor?.uid,
        assignedToName: shiftSupervisor?.name,
      ));
    } else if (stageName == 'تسليم القالب لمشرف الإنتاج') {
      nextStageName = 'بدء الإنتاج';
      updatedWorkflow.add(ProductionWorkflowStage(stageName: nextStageName, status: 'pending'));
    } else if (stageName == 'بدء الإنتاج' && order.requiredQuantity > 0) { // Assuming this means a batch completed
      // This is where more complex batch logic would go. For simplicity,
      // let's assume 'بدء الإنتاج' completion means moving to 'انتهاء الإنتاج'.
      nextStageName = 'انتهاء الإنتاج';
      updatedWorkflow.add(ProductionWorkflowStage(stageName: nextStageName, status: 'pending'));
      newOverallStatus = ProductionOrderStatus.inProduction; // Still in production until all batches/steps are done
    } else if (stageName == 'انتهاء الإنتاج') {
      nextStageName = 'تسليم للمخزون';
      updatedWorkflow.add(ProductionWorkflowStage(stageName: nextStageName, status: 'pending'));
      newOverallStatus = ProductionOrderStatus.completed; // Overall order completed
    } else if (stageName == 'تسليم للمخزون') {
      newOverallStatus = ProductionOrderStatus.completed;
      nextStageName = 'مكتمل'; // No further stages
      await inventoryUseCases.adjustInventoryWithNotification(
        itemId: order.productId,
        itemName: order.productName,
        type: InventoryItemType.finishedProduct,
        delta: order.requiredQuantity.toDouble(),
      );
    }

    final updatedOrder = order.copyWith(
      workflowStages: updatedWorkflow,
      currentStage: nextStageName, // Update overall current stage
      status: newOverallStatus,
      shiftSupervisorUid: shiftSupervisor?.uid ?? order.shiftSupervisorUid,
      shiftSupervisorName: shiftSupervisor?.name ?? order.shiftSupervisorName,
    );
    await repository.updateProductionOrder(updatedOrder);

    // Notify next responsible role
    UserRole? nextRole;
    if (stageName == 'تركيب القالب') {
      nextRole = UserRole.productionShiftSupervisor;
    } else if (stageName == 'تسليم القالب لمشرف الإنتاج') {
      nextRole = UserRole.productionShiftSupervisor;
    } else if (stageName == 'بدء الإنتاج') {
      nextRole = UserRole.productionShiftSupervisor;
    } else if (stageName == 'انتهاء الإنتاج') {
      nextRole = UserRole.inventoryManager;
    }

    if (nextRole != null) {
      final users = await userUseCases.getUsersByRole(nextRole);
      for (final u in users) {
        await notificationUseCases.sendNotification(
          userId: u.uid,
          title: 'مرحلة جديدة في الإنتاج',
          message:
              'تم انتقال الطلب رقم ${updatedOrder.batchNumber} إلى مرحلة $nextStageName',
        );
      }
    }

    // TODO: Trigger Cloud Function for inventory update when 'تسليم للمخزون' is completed
  }

  Stream<List<ProductModel>> getProductsForSelection() {
    return repository.getProducts();
  }

  // Mark production order as delivered after quality inspection
  Future<void> markOrderDelivered(
      ProductionOrderModel order, UserModel inspector) async {
    final updatedWorkflow = List<ProductionWorkflowStage>.from(order.workflowStages)
      ..add(ProductionWorkflowStage(
        stageName: 'تم فحص الجودة والتسليم',
        status: 'completed',
        assignedToUid: inspector.uid,
        assignedToName: inspector.name,
        completedAt: Timestamp.now(),
      ));

    final updatedOrder = order.copyWith(
      status: ProductionOrderStatus.completed,
      currentStage: 'مكتمل',
      workflowStages: updatedWorkflow,
    );
    await repository.updateProductionOrder(updatedOrder);

    await inventoryUseCases.adjustInventoryWithNotification(
      itemId: order.productId,
      itemName: order.productName,
      type: InventoryItemType.finishedProduct,
      delta: order.requiredQuantity.toDouble(),
    );
  }

  Future<ProductModel?> getProductById(String productId) {
    return repository.getProductById(productId);
  }

  /// Update the shift supervisor responsible for a production order
  Future<void> updateShiftSupervisor(
      ProductionOrderModel order, UserModel supervisor) async {
    final updated = order.copyWith(
      shiftSupervisorUid: supervisor.uid,
      shiftSupervisorName: supervisor.name,
      status: order.status == ProductionOrderStatus.inProduction
          ? order.status
          : ProductionOrderStatus.inProduction,
    );
    await repository.updateProductionOrder(updated);

    await notificationUseCases.sendNotification(
      userId: supervisor.uid,
      title: 'تم اسناد طلب انتاج جديد',
      message: 'يرجى متابعة أمر الإنتاج رقم ${order.batchNumber}',
    );
  }}