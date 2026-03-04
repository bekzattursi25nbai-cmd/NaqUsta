import 'package:flutter/widgets.dart';
import 'package:kuryl_kz/features/client/home/models/worker_model.dart'
    as client_home;
import 'package:kuryl_kz/features/client/home/screens/worker_detail_screen.dart'
    as client_home;
import 'package:kuryl_kz/features/worker/business_card/models/worker_models.dart';

class WorkerDetailScreen extends StatelessWidget {
  final WorkerModel worker;

  const WorkerDetailScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    final adapted = client_home.WorkerModel(
      id: worker.id,
      name: worker.name,
      avatarUrl: worker.avatarUrl,
      specialty: worker.specs.isNotEmpty ? worker.specs.first : 'Маман',
      price: '${worker.minPrice} ₸',
      city: worker.city,
      experience: '${worker.experienceYears} жыл',
      rating: worker.rating,
      completedOrders: worker.completedJobs,
      reviewCount: 0,
      hasBrigade: worker.hasBrigade,
      tags: worker.specs,
      bio: worker.bio.trim().isEmpty
          ? const <String>['Қосымша ақпарат жоқ.']
          : <String>[worker.bio.trim()],
    );

    return client_home.WorkerDetailScreen(worker: adapted);
  }
}
