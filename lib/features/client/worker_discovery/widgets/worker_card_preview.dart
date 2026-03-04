import 'package:flutter/material.dart';
import 'package:kuryl_kz/features/worker/business_card/models/worker_models.dart';
import 'package:kuryl_kz/features/worker/business_card/widgets/worker_business_card.dart';

class WorkerCardPreview extends StatelessWidget {
  final WorkerModel worker;
  final VoidCallback onTap;

  const WorkerCardPreview({
    super.key,
    required this.worker,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Экранның енін аламыз
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Карта тым кең болып кетпеуі үшін шектеу қоямыз
        constraints: BoxConstraints(
          maxWidth: screenWidth > 400 ? 400 : screenWidth * 0.95,
        ),
        padding: const EdgeInsets.only(bottom: 16.0),
        child: WorkerBusinessCard(
          name: worker.name,
          city: worker.city,
          exp: worker.experienceYears,
          hasBrigade: worker.hasBrigade,
          brigadeSize: worker.brigadeSize?.toString() ?? '',
          specs: worker.specs,
          showShadow: true,
        ),
      ),
    );
  }
}