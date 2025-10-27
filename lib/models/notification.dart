class InvestmentNotification {
  final int? id;
  final int investmentId;
  final String title;
  final String message;
  final DateTime notificationDate;
  final String type;
  final bool isRead;
  final bool isScheduled;
  final DateTime createdDate;

  InvestmentNotification({
    this.id,
    required this.investmentId,
    required this.title,
    required this.message,
    required this.notificationDate,
    required this.type,
    this.isRead = false,
    this.isScheduled = false,
    DateTime? createdDate,
  }) : createdDate = createdDate ?? DateTime.now();

  // Convert Notification to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'investment_id': investmentId,
      'title': title,
      'message': message,
      'notification_date': notificationDate.millisecondsSinceEpoch,
      'type': type,
      'is_read': isRead ? 1 : 0,
      'is_scheduled': isScheduled ? 1 : 0,
      'created_date': createdDate.millisecondsSinceEpoch,
    };
  }

  // Create Notification from Map (database)
  factory InvestmentNotification.fromMap(Map<String, dynamic> map) {
    return InvestmentNotification(
      id: map['id'],
      investmentId: map['investment_id'],
      title: map['title'],
      message: map['message'],
      notificationDate: DateTime.fromMillisecondsSinceEpoch(map['notification_date']),
      type: map['type'],
      isRead: map['is_read'] == 1,
      isScheduled: map['is_scheduled'] == 1,
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['created_date']),
    );
  }

  // Check if notification is due
  bool get isDue {
    return DateTime.now().isAfter(notificationDate) && !isRead;
  }

  // Check if notification is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(notificationDate.add(const Duration(days: 1))) && !isRead;
  }

  // Copy with method for updates
  InvestmentNotification copyWith({
    int? id,
    int? investmentId,
    String? title,
    String? message,
    DateTime? notificationDate,
    String? type,
    bool? isRead,
    bool? isScheduled,
    DateTime? createdDate,
  }) {
    return InvestmentNotification(
      id: id ?? this.id,
      investmentId: investmentId ?? this.investmentId,
      title: title ?? this.title,
      message: message ?? this.message,
      notificationDate: notificationDate ?? this.notificationDate,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      isScheduled: isScheduled ?? this.isScheduled,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  @override
  String toString() {
    return 'InvestmentNotification{id: $id, investmentId: $investmentId, title: $title, type: $type, notificationDate: $notificationDate, isRead: $isRead}';
  }
}

// Notification types
class NotificationTypes {
  static const String maturity30Days = 'maturity_30_days';
  static const String maturity7Days = 'maturity_7_days';
  static const String maturity1Day = 'maturity_1_day';
  static const String maturityToday = 'maturity_today';
  static const String sipDue = 'sip_due';
  static const String goalDeadline = 'goal_deadline';
  static const String ppfContribution = 'ppf_contribution';
  static const String npsContribution = 'nps_contribution';

  static const List<String> all = [
    maturity30Days,
    maturity7Days,
    maturity1Day,
    maturityToday,
    sipDue,
    goalDeadline,
    ppfContribution,
    npsContribution,
  ];

  // Get user-friendly notification type names
  static String getDisplayName(String type) {
    switch (type) {
      case maturity30Days:
        return 'Maturity in 30 Days';
      case maturity7Days:
        return 'Maturity in 7 Days';
      case maturity1Day:
        return 'Maturity Tomorrow';
      case maturityToday:
        return 'Maturity Today';
      case sipDue:
        return 'SIP Due';
      case goalDeadline:
        return 'Goal Deadline';
      case ppfContribution:
        return 'PPF Contribution Reminder';
      case npsContribution:
        return 'NPS Contribution Reminder';
      default:
        return 'Investment Reminder';
    }
  }

  // Get notification priority
  static int getPriority(String type) {
    switch (type) {
      case maturityToday:
        return 5;
      case maturity1Day:
        return 4;
      case maturity7Days:
        return 3;
      case maturity30Days:
        return 2;
      case sipDue:
      case goalDeadline:
        return 2;
      case ppfContribution:
      case npsContribution:
        return 1;
      default:
        return 1;
    }
  }
}