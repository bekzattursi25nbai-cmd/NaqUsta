import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/theme/app_theme.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';
import 'package:kuryl_kz/core/widgets/app_buttons.dart';
import 'package:kuryl_kz/core/widgets/app_text_field.dart';

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Theme(
      data: AppTheme.clientDark(),
        child: Scaffold(
          appBar: AppBar(
            leading: appBarBackButton(context),
            title: const Text("Жаңа тапсырыс"),
          ),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
            children: [
              const Text("Жұмыс түрін таңдаңыз", style: AppTypography.h3),
              const SizedBox(height: 10),
              // категориялар UI осында
              const SizedBox(height: 20),
              AppTextField(
                label: "Атауы",
                hint: "Не істеу керек?",
                controller: _titleController,
              ),
              const SizedBox(height: 15),
              AppTextField(
                label: "Сипаттама",
                hint: "Толық сипаттамасы",
                controller: _descController,
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              AppPrimaryButton(
                label: "Жариялау",
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
