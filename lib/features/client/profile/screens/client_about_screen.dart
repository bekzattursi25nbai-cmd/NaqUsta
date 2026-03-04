import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';

class ClientAboutScreen extends StatelessWidget {
  const ClientAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: appBarBackButton(context),
        title: const Text('Қосымша туралы'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _card(title: 'Quryl App', value: 'v1.0.2 (Build 402)'),
            const SizedBox(height: 12),
            _card(
              title: 'Қызмет көрсету шарттары',
              value:
                  'TODO: terms screen/backend link дайын болғанда толықтырылады.',
            ),
            const SizedBox(height: 12),
            _card(
              title: 'Құпиялылық саясаты',
              value:
                  'TODO: privacy policy backend/legal контентімен интеграция жасалады.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.body),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.caption),
        ],
      ),
    );
  }
}
