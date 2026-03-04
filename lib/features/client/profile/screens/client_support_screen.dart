import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';

class ClientSupportScreen extends StatelessWidget {
  const ClientSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: appBarBackButton(context),
        title: const Text('Қолдау және FAQ'),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: const [
            _FaqCard(
              question: 'Қалай тапсырыс беремін?',
              answer:
                  'Басты беттен қызметті таңдаңыз, сипаттама толтырып жариялаңыз.',
            ),
            SizedBox(height: 12),
            _FaqCard(
              question: 'Тапсырысымды қалай тоқтатамын?',
              answer:
                  'Тапсырыстарым бөлімінде белсенді өтінімді ашып статусын өзгертіңіз.',
            ),
            SizedBox(height: 12),
            _FaqCard(
              question: 'Қауіпсіз төлем қалай жұмыс істейді?',
              answer:
                  'Billing интеграциясы толық қосылғаннан кейін төлемдер осы бетте көрсетіледі.',
            ),
            SizedBox(height: 20),
            _SupportContactCard(),
          ],
        ),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqCard({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
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
          Text(question, style: AppTypography.body),
          const SizedBox(height: 8),
          Text(answer, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _SupportContactCard extends StatelessWidget {
  const _SupportContactCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(CupertinoIcons.chat_bubble_2, color: AppColors.gold),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Қолдау: support@kuryl.kz\nЖұмыс уақыты: 09:00 - 18:00',
              style: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }
}
