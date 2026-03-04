import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WorkerCategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final bool isPopular;

  const WorkerCategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    this.isPopular = false,
  });
}

// Mock Data
final List<WorkerCategoryModel> mockCategories = [
  const WorkerCategoryModel(id: 'roof', name: 'Крыша', icon: LucideIcons.home, isPopular: true),
  const WorkerCategoryModel(id: 'concrete', name: 'Бетон', icon: LucideIcons.layoutGrid),
  const WorkerCategoryModel(id: 'weld', name: 'Сварка', icon: LucideIcons.flame),
  const WorkerCategoryModel(id: 'elect', name: 'Электрик', icon: LucideIcons.zap),
  const WorkerCategoryModel(id: 'plumb', name: 'Су', icon: LucideIcons.droplet),
  const WorkerCategoryModel(id: 'demo', name: 'Бұзу', icon: LucideIcons.hammer),
  const WorkerCategoryModel(id: 'doors', name: 'Есік', icon: LucideIcons.doorOpen),
  const WorkerCategoryModel(id: 'all', name: 'Бәрі', icon: LucideIcons.menu),
];