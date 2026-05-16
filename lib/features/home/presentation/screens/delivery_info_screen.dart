import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../checkout/presentation/widgets/timeslot_selector.dart';

class DeliveryInfoScreen extends StatelessWidget {
  const DeliveryInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Info')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Pickup options', style: AppTextStyles.heading(size: 24)),
          const SizedBox(height: 12),
          const PkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoLine(
                    icon: Icons.schedule_outlined,
                    title: 'Scheduled campus pickup',
                    body: 'Reserve a weekly pickup window while checking out.'),
                SizedBox(height: 12),
                _InfoLine(
                    icon: Icons.flash_on_outlined,
                    title: 'ASAP downtown pickup',
                    body:
                        'Admins schedule ASAP orders after the order is placed.'),
                SizedBox(height: 12),
                _InfoLine(
                    icon: Icons.payments_outlined,
                    title: 'Payment',
                    body:
                        'Venmo, Zelle, PayPal, cash, store credit, and trade credit follow the store settings currently enabled.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Upcoming scheduled windows',
              style: AppTextStyles.heading(size: 18)),
          const SizedBox(height: 10),
          const TimeslotSelector(value: null, onChanged: _ignoreSelection),
        ],
      ),
    );
  }

  static void _ignoreSelection(Object? value) {}
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(
      {required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.pkmnBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.heading(size: 15)),
              const SizedBox(height: 3),
              Text(body, style: AppTextStyles.body(size: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
