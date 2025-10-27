class Goal {
  final int? id;
  final String name;
  final double targetAmount;
  final DateTime targetDate;
  final double currentProgress;
  final String description;
  final String category;
  final DateTime createdDate;
  final bool isCompleted;

  Goal({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.targetDate,
    this.currentProgress = 0.0,
    this.description = '',
    this.category = 'General',
    DateTime? createdDate,
    this.isCompleted = false,
  }) : createdDate = createdDate ?? DateTime.now();

  // Convert Goal to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'target_amount': targetAmount,
      'target_date': targetDate.millisecondsSinceEpoch,
      'current_progress': currentProgress,
      'description': description,
      'category': category,
      'created_date': createdDate.millisecondsSinceEpoch,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  // Create Goal from Map (database)
  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      name: map['name'],
      targetAmount: map['target_amount'].toDouble(),
      targetDate: DateTime.fromMillisecondsSinceEpoch(map['target_date']),
      currentProgress: map['current_progress']?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['created_date']),
      isCompleted: map['is_completed'] == 1,
    );
  }

  // Calculate progress percentage
  double get progressPercentage {
    if (targetAmount == 0) return 0.0;
    return (currentProgress / targetAmount * 100).clamp(0.0, 100.0);
  }

  // Calculate remaining amount
  double get remainingAmount {
    return (targetAmount - currentProgress).clamp(0.0, targetAmount);
  }

  // Calculate days remaining
  int get daysRemaining {
    final now = DateTime.now();
    if (targetDate.isBefore(now)) return 0;
    return targetDate.difference(now).inDays;
  }

  // Check if goal is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(targetDate) && !isCompleted;
  }

  // Calculate monthly savings required
  double get monthlySavingsRequired {
    if (isCompleted || daysRemaining <= 0) return 0.0;
    final monthsRemaining = daysRemaining / 30.44; // Average days per month
    if (monthsRemaining <= 0) return remainingAmount;
    return remainingAmount / monthsRemaining;
  }

  // Copy with method for updates
  Goal copyWith({
    int? id,
    String? name,
    double? targetAmount,
    DateTime? targetDate,
    double? currentProgress,
    String? description,
    String? category,
    DateTime? createdDate,
    bool? isCompleted,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      currentProgress: currentProgress ?? this.currentProgress,
      description: description ?? this.description,
      category: category ?? this.category,
      createdDate: createdDate ?? this.createdDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  String toString() {
    return 'Goal{id: $id, name: $name, targetAmount: $targetAmount, targetDate: $targetDate, currentProgress: $currentProgress, isCompleted: $isCompleted}';
  }
}

// Predefined goal categories
class GoalCategories {
  static const String retirement = 'Retirement';
  static const String education = 'Education';
  static const String house = 'House Purchase';
  static const String car = 'Car Purchase';
  static const String vacation = 'Vacation';
  static const String emergency = 'Emergency Fund';
  static const String wedding = 'Wedding';
  static const String business = 'Business';
  static const String general = 'General';

  static const List<String> all = [
    retirement,
    education,
    house,
    car,
    vacation,
    emergency,
    wedding,
    business,
    general,
  ];
}