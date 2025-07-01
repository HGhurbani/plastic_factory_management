import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/data/models/spare_part_model.dart';
import 'package:plastic_factory_management/domain/usecases/inventory_usecases.dart';

class SparePartsScreen extends StatelessWidget {
  const SparePartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final useCases = Provider.of<InventoryUseCases>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('قطع الغيار'),
      ),
      body: StreamBuilder<List<SparePartModel>>(
        stream: useCases.getSpareParts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final parts = snapshot.data!;
          return ListView.builder(
            itemCount: parts.length,
            itemBuilder: (context, index) {
              final part = parts[index];
              return ListTile(
                title: Text(part.name),
                subtitle: Text(part.code),
              );
            },
          );
        },
      ),
    );
  }
}
