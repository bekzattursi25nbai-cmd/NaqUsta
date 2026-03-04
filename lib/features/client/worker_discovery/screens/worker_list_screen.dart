import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';
import '../widgets/worker_card_preview.dart';
import 'worker_detail_screen.dart';
import 'package:kuryl_kz/features/worker/business_card/models/worker_models.dart';
import 'package:kuryl_kz/features/worker/business_card/models/worker_category_model.dart';

class WorkerListScreen extends StatelessWidget {
  final WorkerCategoryModel category;

  const WorkerListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(category.name, style: const TextStyle(color: Colors.white)),
        leading: appBarBackButton(context),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('workers').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Шеберлер жүктелмеді.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allWorkers = snapshot.data!.docs
                .map((doc) => WorkerModel.fromMap(doc.data(), doc.id))
                .toList();

            final workers = category.id == 'all'
                ? allWorkers
                : allWorkers.where((worker) {
                    final id = category.id.trim().toLowerCase();
                    final name = category.name.trim().toLowerCase();
                    final tags = <String>[
                      ...worker.categories,
                      ...worker.specs,
                    ].map((item) => item.trim().toLowerCase()).toList();
                    return tags.contains(id) || tags.contains(name);
                  }).toList();

            if (workers.isEmpty) {
              return const Center(
                child: Text(
                  'Бұл санатта шеберлер әзірге жоқ.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: workers.length,
              itemBuilder: (context, index) {
                final worker = workers[index];
                return WorkerCardPreview(
                  worker: worker,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkerDetailScreen(worker: worker),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
