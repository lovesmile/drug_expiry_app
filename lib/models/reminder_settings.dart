class ReminderSettings {
  final bool reminder30Days;
  final String time30Days;
  final bool reminder7Days;
  final String time7Days;
  final bool reminder3Days;
  final String time3Days;
  final bool reminderExpired;
  final String timeExpired;

  ReminderSettings({
    this.reminder30Days = true,
    this.time30Days = '20:00',
    this.reminder7Days = true,
    this.time7Days = '09:00',
    this.reminder3Days = true,
    this.time3Days = '09:00',
    this.reminderExpired = true,
    this.timeExpired = '09:00',
  });

  Map<String, dynamic> toMap() {
    return {
      'reminder_30_days': reminder30Days ? 1 : 0,
      'time_30_days': time30Days,
      'reminder_7_days': reminder7Days ? 1 : 0,
      'time_7_days': time7Days,
      'reminder_3_days': reminder3Days ? 1 : 0,
      'time_3_days': time3Days,
      'reminder_expired': reminderExpired ? 1 : 0,
      'time_expired': timeExpired,
    };
  }

  factory ReminderSettings.fromMap(Map<String, dynamic> map) {
    return ReminderSettings(
      reminder30Days: map['reminder_30_days'] == 1,
      time30Days: map['time_30_days'] as String? ?? '20:00',
      reminder7Days: map['reminder_7_days'] == 1,
      time7Days: map['time_7_days'] as String? ?? '09:00',
      reminder3Days: map['reminder_3_days'] == 1,
      time3Days: map['time_3_days'] as String? ?? '09:00',
      reminderExpired: map['reminder_expired'] == 1,
      timeExpired: map['time_expired'] as String? ?? '09:00',
    );
  }

  ReminderSettings copyWith({
    bool? reminder30Days,
    String? time30Days,
    bool? reminder7Days,
    String? time7Days,
    bool? reminder3Days,
    String? time3Days,
    bool? reminderExpired,
    String? timeExpired,
  }) {
    return ReminderSettings(
      reminder30Days: reminder30Days ?? this.reminder30Days,
      time30Days: time30Days ?? this.time30Days,
      reminder7Days: reminder7Days ?? this.reminder7Days,
      time7Days: time7Days ?? this.time7Days,
      reminder3Days: reminder3Days ?? this.reminder3Days,
      time3Days: time3Days ?? this.time3Days,
      reminderExpired: reminderExpired ?? this.reminderExpired,
      timeExpired: timeExpired ?? this.timeExpired,
    );
  }
}
