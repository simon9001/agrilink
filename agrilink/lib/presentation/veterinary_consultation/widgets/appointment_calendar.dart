import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/app_export.dart';

class AppointmentCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final List<DateTime> availableDates;

  const AppointmentCalendar({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.availableDates,
  }) : super(key: key);

  @override
  State<AppointmentCalendar> createState() => _AppointmentCalendarState();
}

class _AppointmentCalendarState extends State<AppointmentCalendar> {
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedDate;
  }

  bool _isDateAvailable(DateTime date) {
    return widget.availableDates
        .any((availableDate) => isSameDay(availableDate, date));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Date',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          TableCalendar<DateTime>(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(widget.selectedDate, day),
            availableGestures: AvailableGestures.all,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle:
                  AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ) ??
                      const TextStyle(),
              leftChevronIcon: CustomIconWidget(
                iconName: 'chevron_left',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              rightChevronIcon: CustomIconWidget(
                iconName: 'chevron_right',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ) ??
                  const TextStyle(),
              weekendStyle: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ) ??
                  const TextStyle(),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle:
                  AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                      ) ??
                      const TextStyle(),
              holidayTextStyle:
                  AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                      ) ??
                      const TextStyle(),
              selectedDecoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              defaultDecoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              weekendDecoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              disabledDecoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: AppTheme.getSuccessColor(true),
                shape: BoxShape.circle,
              ),
            ),
            enabledDayPredicate: (day) {
              return day.isAfter(
                      DateTime.now().subtract(const Duration(days: 1))) &&
                  _isDateAvailable(day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (_isDateAvailable(selectedDay)) {
                setState(() {
                  _focusedDay = focusedDay;
                });
                widget.onDateSelected(selectedDay);
              }
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) {
              return _isDateAvailable(day) ? [day] : [];
            },
          ),
        ],
      ),
    );
  }
}
