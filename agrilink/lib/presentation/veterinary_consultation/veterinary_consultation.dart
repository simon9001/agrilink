import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/active_consultation_card.dart';
import './widgets/appointment_calendar.dart';
import './widgets/appointment_confirmation_card.dart';
import './widgets/emergency_consultation_button.dart';
import './widgets/past_consultation_card.dart';
import './widgets/service_selection_card.dart';
import './widgets/time_slot_selector.dart';
import './widgets/veterinarian_profile_card.dart';

class VeterinaryConsultation extends StatefulWidget {
  const VeterinaryConsultation({Key? key}) : super(key: key);

  @override
  State<VeterinaryConsultation> createState() => _VeterinaryConsultationState();
}

class _VeterinaryConsultationState extends State<VeterinaryConsultation>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Mock data for veterinarians
  final List<Map<String, dynamic>> veterinarians = [
    {
      "id": 1,
      "name": "Dr. Sarah Mitchell",
      "specialization": "Large Animal Veterinarian",
      "rating": 4.8,
      "isAvailable": true,
      "photo":
          "https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&h=400&fit=crop&crop=face",
      "experience": "12 years",
      "location": "Rural Veterinary Clinic"
    },
    {
      "id": 2,
      "name": "Dr. Michael Rodriguez",
      "specialization": "Livestock Health Specialist",
      "rating": 4.9,
      "isAvailable": false,
      "photo":
          "https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400&h=400&fit=crop&crop=face",
      "experience": "15 years",
      "location": "Agricultural Health Center"
    }
  ];

  // Mock data for consultation services
  final List<Map<String, dynamic>> consultationServices = [
    {
      "id": 1,
      "title": "Video Consultation",
      "description":
          "Live video call with veterinarian for livestock health assessment",
      "price": "\$45",
      "duration": "30 minutes",
      "icon": "video_call"
    },
    {
      "id": 2,
      "title": "Phone Consultation",
      "description": "Voice call consultation for immediate health concerns",
      "price": "\$25",
      "duration": "20 minutes",
      "icon": "phone"
    },
    {
      "id": 3,
      "title": "Farm Visit",
      "description": "On-site veterinary examination and treatment",
      "price": "\$120",
      "duration": "2 hours",
      "icon": "location_on"
    },
    {
      "id": 4,
      "title": "Emergency Call",
      "description": "Immediate emergency consultation available 24/7",
      "price": "\$80",
      "duration": "45 minutes",
      "icon": "emergency"
    }
  ];

  // Mock data for active consultations
  final List<Map<String, dynamic>> activeConsultations = [
    {
      "id": 1,
      "vetName": "Dr. Sarah Mitchell",
      "vetPhoto":
          "https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&h=400&fit=crop&crop=face",
      "serviceType": "Video Consultation",
      "scheduledTime": "Today, 3:30 PM",
      "appointmentTime": "2025-08-30T15:30:00.000Z"
    }
  ];

  // Mock data for past consultations
  final List<Map<String, dynamic>> pastConsultations = [
    {
      "id": 1,
      "vetName": "Dr. Michael Rodriguez",
      "vetPhoto":
          "https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400&h=400&fit=crop&crop=face",
      "serviceType": "Farm Visit",
      "date": "August 25, 2025",
      "diagnosis":
          "Diagnosed mild respiratory infection in cattle. Prescribed antibiotics and recommended improved ventilation in barn.",
      "cost": "\$120"
    },
    {
      "id": 2,
      "vetName": "Dr. Sarah Mitchell",
      "vetPhoto":
          "https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&h=400&fit=crop&crop=face",
      "serviceType": "Video Consultation",
      "date": "August 20, 2025",
      "diagnosis":
          "Nutritional deficiency in goats. Recommended dietary supplements and mineral blocks.",
      "cost": "\$45"
    }
  ];

  // Available dates for appointments (next 30 days, excluding weekends)
  late List<DateTime> availableDates;

  // Available time slots
  final List<String> timeSlots = [
    "09:00 AM",
    "10:00 AM",
    "11:00 AM",
    "02:00 PM",
    "03:00 PM",
    "04:00 PM",
    "05:00 PM"
  ];

  // State variables
  int selectedVeterinarianIndex = 0;
  int? selectedServiceIndex;
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  String? selectedTimeSlot;
  Map<String, dynamic>? appointmentDetails;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateAvailableDates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generateAvailableDates() {
    availableDates = [];
    final DateTime now = DateTime.now();
    for (int i = 1; i <= 30; i++) {
      final DateTime date = now.add(Duration(days: i));
      // Exclude weekends for regular appointments
      if (date.weekday != DateTime.saturday &&
          date.weekday != DateTime.sunday) {
        availableDates.add(date);
      }
    }
  }

  void _onServiceSelected(int index) {
    setState(() {
      selectedServiceIndex = index;
      selectedTimeSlot = null;
      appointmentDetails = null;
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      selectedDate = date;
      selectedTimeSlot = null;
      appointmentDetails = null;
    });
  }

  void _onTimeSlotSelected(String timeSlot) {
    setState(() {
      selectedTimeSlot = timeSlot;
      _generateAppointmentDetails();
    });
  }

  void _generateAppointmentDetails() {
    if (selectedServiceIndex != null && selectedTimeSlot != null) {
      final selectedVet = veterinarians[selectedVeterinarianIndex];
      final selectedService = consultationServices[selectedServiceIndex!];

      setState(() {
        appointmentDetails = {
          "vetName": selectedVet['name'],
          "serviceType": selectedService['title'],
          "date":
              "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
          "time": selectedTimeSlot,
          "duration": selectedService['duration'],
          "cost": selectedService['price']
        };
      });
    }
  }

  void _bookConsultation() {
    if (appointmentDetails != null) {
      // Navigate to payment methods
      Navigator.pushNamed(context, '/payment-methods');

      Fluttertoast.showToast(
        msg: "Redirecting to payment...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _joinCall() {
    Fluttertoast.showToast(
      msg: "Connecting to video call...",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _downloadPrescription() {
    Fluttertoast.showToast(
      msg: "Downloading prescription...",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _bookFollowUp() {
    setState(() {
      _tabController.animateTo(0);
    });

    Fluttertoast.showToast(
      msg: "Booking follow-up consultation...",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleEmergencyConsultation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              CustomIconWidget(
                iconName: 'emergency',
                color: Colors.red,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Emergency Consultation',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'This will connect you immediately with an available veterinarian for emergency consultation. Emergency consultation fee is \$80.',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/payment-methods');
                Fluttertoast.showToast(
                  msg: "Connecting to emergency vet...",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(
                'Connect Now',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  List<String> _getAvailableTimeSlotsForDate(DateTime date) {
    // Return empty list for past dates
    if (date.isBefore(DateTime.now())) {
      return [];
    }

    // For today, filter out past time slots
    if (date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year) {
      final now = DateTime.now();
      return timeSlots.where((slot) {
        final hour = int.parse(slot.split(':')[0]);
        final isPM = slot.contains('PM');
        final adjustedHour =
            isPM && hour != 12 ? hour + 12 : (hour == 12 && !isPM ? 0 : hour);
        return adjustedHour > now.hour;
      }).toList();
    }

    // For future dates, return all slots
    return timeSlots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Veterinary Consultation',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/user-profile'),
            icon: CustomIconWidget(
              iconName: 'person',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Book Appointment'),
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Emergency consultation button
          Container(
            padding: EdgeInsets.all(4.w),
            child: EmergencyConsultationButton(
              onPressed: _handleEmergencyConsultation,
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Book Appointment Tab
                SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Veterinarian profile
                      VeterinarianProfileCard(
                        veterinarian: veterinarians[selectedVeterinarianIndex],
                      ),

                      SizedBox(height: 3.h),

                      // Service selection
                      Text(
                        'Select Consultation Type',
                        style:
                            AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),

                      ...consultationServices.asMap().entries.map((entry) {
                        final index = entry.key;
                        final service = entry.value;
                        return ServiceSelectionCard(
                          service: service,
                          isSelected: selectedServiceIndex == index,
                          onTap: () => _onServiceSelected(index),
                        );
                      }).toList(),

                      if (selectedServiceIndex != null) ...[
                        SizedBox(height: 3.h),

                        // Calendar
                        AppointmentCalendar(
                          selectedDate: selectedDate,
                          onDateSelected: _onDateSelected,
                          availableDates: availableDates,
                        ),

                        SizedBox(height: 3.h),

                        // Time slots
                        TimeSlotSelector(
                          timeSlots:
                              _getAvailableTimeSlotsForDate(selectedDate),
                          selectedTimeSlot: selectedTimeSlot,
                          onTimeSlotSelected: _onTimeSlotSelected,
                        ),

                        if (appointmentDetails != null) ...[
                          SizedBox(height: 3.h),

                          // Appointment confirmation
                          AppointmentConfirmationCard(
                            appointmentDetails: appointmentDetails!,
                          ),

                          SizedBox(height: 3.h),

                          // Book consultation button
                          SizedBox(
                            width: double.infinity,
                            height: 6.h,
                            child: ElevatedButton(
                              onPressed: _bookConsultation,
                              child: Text(
                                'Book Consultation',
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],

                      SizedBox(height: 4.h),
                    ],
                  ),
                ),

                // Active Consultations Tab
                activeConsultations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'event_available',
                              color: Colors.grey,
                              size: 64,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'No Active Consultations',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Book a consultation to see it here',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(4.w),
                        itemCount: activeConsultations.length,
                        itemBuilder: (context, index) {
                          return ActiveConsultationCard(
                            consultation: activeConsultations[index],
                            onJoinCall: _joinCall,
                          );
                        },
                      ),

                // Past Consultations Tab
                pastConsultations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'history',
                              color: Colors.grey,
                              size: 64,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'No Consultation History',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Your completed consultations will appear here',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(4.w),
                        itemCount: pastConsultations.length,
                        itemBuilder: (context, index) {
                          return PastConsultationCard(
                            consultation: pastConsultations[index],
                            onDownloadPrescription: _downloadPrescription,
                            onBookFollowUp: _bookFollowUp,
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
