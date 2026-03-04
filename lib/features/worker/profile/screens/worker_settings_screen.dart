import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';

class WorkerSettingsScreen extends StatefulWidget {
  const WorkerSettingsScreen({super.key});

  @override
  State<WorkerSettingsScreen> createState() => _WorkerSettingsScreenState();
}

class _WorkerSettingsScreenState extends State<WorkerSettingsScreen> {
  bool _notifications = true;
  bool _sound = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: appBarBackButton(context),
        title: const Text("Баптаулар", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text("Жалпы", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildSwitchTile("Хабарламалар", "Жаңа тапсырыс туралы хабарлау", _notifications, (v) => setState(() => _notifications = v)),
            const SizedBox(height: 10),
            _buildSwitchTile("Дыбыс", "Қосымша дыбыстары", _sound, (v) => setState(() => _sound = v)),
            
            const SizedBox(height: 30),
            const Text("Қолдау", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildActionTile("Құпиялылық саясаты"),
            const SizedBox(height: 10),
            _buildActionTile("Қолдану ережелері"),
            const SizedBox(height: 10),
            _buildActionTile("Бағдарлама туралы", subtitle: "Версия 1.0.0"),
            
            const SizedBox(height: 40),
            Center(
              child: Text(
                "NaqUsta Worker App",
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        value: value,
        activeThumbColor: Colors.blue, // Theme color
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile(String title, {String? subtitle}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}
