import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/api_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../shop/data/shop_repository.dart';

const _dayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
];

class TimeslotSelector extends ConsumerWidget {
  const TimeslotSelector(
      {required this.value,
      required this.onChanged,
      this.emptyMessage,
      super.key});

  final TimeslotSelection? value;
  final ValueChanged<TimeslotSelection?> onChanged;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(recurringTimeslotsProvider);
    final settings = ref.watch(storeSettingsProvider);

    if (settings.valueOrNull?.ordersDisabled == true) {
      return const PkCard(
          child: Text('Orders are not being accepted right now.'));
    }

    return slots.when(
      loading: () => const Center(
          child: Padding(
              padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (error, stackTrace) => PkCard(child: Text('$error')),
      data: (items) {
        if (items.isEmpty) {
          return PkCard(
              child: Text(emptyMessage ??
                  'No pickup timeslots are currently available.'));
        }
        return Column(
          children: [
            if (settings.valueOrNull?.isOoo == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PkCard(
                  child: Text(
                      'The shop is out of office until ${settings.valueOrNull?.oooUntil ?? 'soon'}. Showing the next available pickup windows.'),
                ),
              ),
            ...items.map((slot) {
              final pickupDate =
                  slot.pickupDate ?? _nextDateForDay(slot.dayOfWeek);
              final selected = value?.recurringTimeslotId == slot.id &&
                  value?.pickupDate == pickupDate;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: slot.isFull
                      ? null
                      : () => onChanged(selected
                          ? null
                          : TimeslotSelection(
                              recurringTimeslotId: slot.id,
                              pickupDate: pickupDate)),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: selected ? AppColors.pkmnBlueLight : Colors.white,
                      border: Border.all(
                          color: selected
                              ? AppColors.pkmnBlue
                              : AppColors.pkmnBorder,
                          width: selected ? 2 : 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${_dayNames[slot.dayOfWeek]} • ${_formatDate(pickupDate)}',
                                    style: AppTextStyles.label(
                                        color: AppColors.pkmnBlueDark)),
                                const SizedBox(height: 4),
                                Text(
                                    '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}',
                                    style: AppTextStyles.heading(size: 15)),
                                if (slot.location.isNotEmpty)
                                  Text(slot.location,
                                      style: AppTextStyles.body(size: 12)),
                              ],
                            ),
                          ),
                          Text(slot.isFull ? 'FULL' : '${slot.spotsLeft} left',
                              style: AppTextStyles.label(
                                  color: slot.isFull
                                      ? AppColors.pkmnRed
                                      : AppColors.pkmnBlue)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  String _nextDateForDay(int dayOfWeek) {
    final now = DateTime.now();
    final current = (now.weekday + 6) % 7;
    var diff = dayOfWeek - current;
    if (diff <= 0) diff += 7;
    final target =
        DateTime(now.year, now.month, now.day).add(Duration(days: diff));
    return DateFormat('yyyy-MM-dd').format(target);
  }

  String _formatDate(String value) =>
      DateFormat('MMM d').format(DateTime.parse(value));

  String _formatTime(String value) {
    final pieces = value.split(':').map(int.parse).toList();
    final date = DateTime(2026, 1, 1, pieces[0], pieces[1]);
    return DateFormat('h:mm a').format(date);
  }
}
