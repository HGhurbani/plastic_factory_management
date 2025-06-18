import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/data/models/sales_order_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/usecases/sales_usecases.dart';

class WarehouseRequestsScreen extends StatefulWidget {
  const WarehouseRequestsScreen({Key? key}) : super(key: key);

  @override
  _WarehouseRequestsScreenState createState() => _WarehouseRequestsScreenState();
}

class _WarehouseRequestsScreenState extends State<WarehouseRequestsScreen> {
  void _showWarehouseDocDialog(BuildContext context, SalesUseCases useCases,
      AppLocalizations appLocalizations, SalesOrderModel order, UserModel storekeeper) {
    final TextEditingController notesController =
        TextEditingController(text: order.warehouseNotes);
    List<XFile> pickedImages = [];
    final ImagePicker picker = ImagePicker();

    Future<void> pickImages() async {
      final images = await picker.pickMultiImage();
      if (images != null) {
        pickedImages.addAll(images);
      }
    }

    Future<void> captureImage() async {
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        pickedImages.add(image);
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(appLocalizations.warehouseDocumentation),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(labelText: appLocalizations.enterNotes),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        await captureImage();
                        setState(() {});
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: Text(appLocalizations.camera),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await pickImages();
                        setState(() {});
                      },
                      icon: const Icon(Icons.photo),
                      label: Text(appLocalizations.gallery),
                    ),
                  ],
                ),
                Wrap(
                  children: pickedImages
                      .map((e) => Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.file(
                              File(e.path),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ))
                      .toList(),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(appLocalizations.sendToProduction),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await useCases.documentWarehouseSupply(
                    order: order,
                    storekeeper: storekeeper,
                    notes: notesController.text.trim(),
                    attachments: pickedImages.map((e) => File(e.path)).toList(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(appLocalizations.supplySaved)),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.errorSavingSupply}: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesUseCases = Provider.of<SalesUseCases>(context);
    final appLocalizations = AppLocalizations.of(context)!;
    final currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(appLocalizations.warehouseRequests),
          centerTitle: true,
        ),
        body: const Center(child: Text('لا يمكن عرض الطلبات بدون بيانات المستخدم.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.warehouseRequests),
        centerTitle: true,
      ),
      body: StreamBuilder<List<SalesOrderModel>>(
        stream: salesUseCases.getSalesOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل الطلبات: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('لا توجد طلبات حالياً.'));
          }

          final orders = snapshot.data!
              .where((o) =>
                  o.status == SalesOrderStatus.warehouseProcessing &&
                  o.warehouseManagerUid == currentUser?.uid)
              .toList();

          if (orders.isEmpty) {
            return Center(child: Text('لا توجد طلبات حالياً.'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  title: Text(
                    'طلب العميل: ${order.customerName}',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${appLocalizations.totalAmount}: \$${order.totalAmount.toStringAsFixed(2)}",
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                      Text(
                        "${appLocalizations.salesRepresentative}: ${order.salesRepresentativeName}",
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    child: Text(appLocalizations.prepareOrder),
                    onPressed: () => _showWarehouseDocDialog(
                        context, salesUseCases, appLocalizations, order, currentUser!),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
