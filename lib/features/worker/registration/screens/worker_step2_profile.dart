import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/widgets/safe_button_text.dart';
import 'package:kuryl_kz/features/worker/widgets/brigade_toggle.dart';
import 'package:kuryl_kz/features/worker/widgets/worker_input_field.dart';

class WorkerStep2Profile extends StatefulWidget {
  final VoidCallback onFinish;
  final Function(String name, String location, String age, int exp, String bio, bool hasBrigade) onUpdate;

  const WorkerStep2Profile({super.key, required this.onFinish, required this.onUpdate});

  @override
  State<WorkerStep2Profile> createState() => _WorkerStep2ProfileState();
}

class _WorkerStep2ProfileState extends State<WorkerStep2Profile> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  int experienceYears = 3;
  bool hasBrigade = false;

  void _updateParent() {
    widget.onUpdate(
      _nameController.text.trim(),
      _locationController.text.trim(),
      _ageController.text.trim(),
      experienceYears,
      _bioController.text.trim(),
      hasBrigade,
    );
  }

  void _validateAndFinish() {
    _updateParent();
    
    // ҚАТАҢ ТЕКСЕРУ
    if (_nameController.text.isEmpty) {
      _snack("Аты-жөніңізді жазыңыз"); return;
    }
    if (_locationController.text.isEmpty) {
      _snack("Тұратын жеріңізді көрсетіңіз"); return;
    }
    if (_ageController.text.isEmpty) {
      _snack("Жасыңызды көрсетіңіз"); return;
    }

    widget.onFinish();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // МИНИМАЛИСТІК HEADER (Карточканың орнына)
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                    child: const Icon(Icons.engineering, size: 40, color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  const Text("Жеке мәліметтер", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text("Профильді толтырыңыз", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            _label("АТЫ-ЖӨНІҢІЗ"),
            WorkerInputField(
              controller: _nameController,
              hintText: "Мысалы: Бекзат Тургинбай",
              prefixIcon: Icons.person_outline,
              onChanged: (v) => setState(() => _updateParent()),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label("ТҰРАТЫН ЖЕР"),
                    WorkerInputField(
                      controller: _locationController,
                      hintText: "Аудан/Ауыл",
                      prefixIcon: Icons.location_on_outlined,
                      onChanged: (v) => setState(() => _updateParent()),
                    ),
                  ]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label("ЖАСЫҢЫЗ"),
                    WorkerInputField(
                      controller: _ageController,
                      hintText: "25",
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (v) => setState(() => _updateParent()),
                    ),
                  ]),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _label("СТАЖ (ЖЫЛ)"),
            Container(
              height: 56,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: () { if(experienceYears > 0) setState(() { experienceYears--; _updateParent(); }); }, icon: const Icon(Icons.remove, color: Colors.grey)),
                  Text("$experienceYears", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () { setState(() { experienceYears++; _updateParent(); }); }, icon: const Icon(Icons.add, color: Colors.grey)),
                ],
              ),
            ),

            const SizedBox(height: 16),
            _label("ҚОСЫМША АҚПАРАТ"),
            WorkerInputField(
              controller: _bioController,
              hintText: "Жұмыс туралы қысқаша...",
              maxLines: 3,
              onChanged: (v) => _updateParent(),
            ),

            const SizedBox(height: 24),
            
            BrigadeToggle(
              value: hasBrigade,
              onChanged: (val) => setState(() { hasBrigade = val; _updateParent(); }),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _validateAndFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E), 
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                child: const SafeButtonText(
                  "Тіркелуді аяқтау",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 8, left: 4), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)));
}
