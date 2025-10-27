import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/investment.dart';
import '../models/goal.dart';
import '../models/notification.dart';
import '../utils/constants.dart';

class DatabaseService {
  static SharedPreferences? _prefs;
  static final DatabaseService _instance = DatabaseService._internal();
  
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Investment CRUD Operations
  Future<int> insertInvestment(Investment investment) async {
    final prefs = await _storage;
    final investments = await getAllInvestments();
    final counter = prefs.getInt('counter') ?? 0;
    final newId = counter + 1;
    
    final newInvestment = Investment(
      id: newId,
      type: investment.type,
      name: investment.name,
      amount: investment.amount,
      startDate: investment.startDate,
      maturityDate: investment.maturityDate,
      interestRate: investment.interestRate,
      status: investment.status,
      additionalData: investment.additionalData,
    );
    
    investments.add(newInvestment);
    final jsonList = investments.map((inv) => inv.toMap()).toList();
    await prefs.setString('investments', json.encode(jsonList));
    await prefs.setInt('counter', newId);
    return newId;
  }

  Future<List<Investment>> getAllInvestments() async {
    final prefs = await _storage;
    final jsonString = prefs.getString('investments') ?? '[]';
    final List<dynamic> jsonList = json.decode(jsonString);
    final investments = jsonList.map((json) => Investment.fromMap(json)).toList();
    investments.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    return investments;
  }

  Future<List<Investment>> getInvestmentsByType(String type) async {
    final investments = await getAllInvestments();
    return investments.where((inv) => inv.type == type).toList();
  }

  Future<List<Investment>> getActiveInvestments() async {
    final investments = await getAllInvestments();
    return investments.where((inv) => inv.status == 'Active').toList();
  }

  Future<Investment?> getInvestmentById(int id) async {
    final investments = await getAllInvestments();
    try {
      return investments.firstWhere((inv) => inv.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> updateInvestment(Investment investment) async {
    final prefs = await _storage;
    final investments = await getAllInvestments();
    final index = investments.indexWhere((inv) => inv.id == investment.id);
    if (index != -1) {
      investments[index] = investment;
      final jsonList = investments.map((inv) => inv.toMap()).toList();
      await prefs.setString('investments', json.encode(jsonList));
      return 1;
    }
    return 0;
  }

  Future<int> deleteInvestment(int id) async {
    final prefs = await _storage;
    final investments = await getAllInvestments();
    final initialLength = investments.length;
    investments.removeWhere((inv) => inv.id == id);
    if (investments.length < initialLength) {
      final jsonList = investments.map((inv) => inv.toMap()).toList();
      await prefs.setString('investments', json.encode(jsonList));
      return 1;
    }
    return 0;
  }

  // Goal CRUD Operations
  Future<int> insertGoal(Goal goal) async {
    final prefs = await _storage;
    final goals = await getAllGoals();
    final counter = prefs.getInt('counter') ?? 0;
    final newId = counter + 1;
    
    final newGoal = Goal(
      id: newId,
      name: goal.name,
      targetAmount: goal.targetAmount,
      targetDate: goal.targetDate,
      currentProgress: goal.currentProgress,
      description: goal.description,
      category: goal.category,
      createdDate: goal.createdDate,
      isCompleted: goal.isCompleted,
    );
    
    goals.add(newGoal);
    final jsonList = goals.map((g) => g.toMap()).toList();
    await prefs.setString('goals', json.encode(jsonList));
    await prefs.setInt('counter', newId);
    return newId;
  }

  Future<List<Goal>> getAllGoals() async {
    final prefs = await _storage;
    final jsonString = prefs.getString('goals') ?? '[]';
    final List<dynamic> jsonList = json.decode(jsonString);
    final goals = jsonList.map((json) => Goal.fromMap(json)).toList();
    goals.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    return goals;
  }

  Future<int> updateGoal(Goal goal) async {
    final prefs = await _storage;
    final goals = await getAllGoals();
    final index = goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      goals[index] = goal;
      final jsonList = goals.map((g) => g.toMap()).toList();
      await prefs.setString('goals', json.encode(jsonList));
      return 1;
    }
    return 0;
  }

  Future<int> deleteGoal(int id) async {
    final prefs = await _storage;
    final goals = await getAllGoals();
    final initialLength = goals.length;
    goals.removeWhere((g) => g.id == id);
    if (goals.length < initialLength) {
      final jsonList = goals.map((g) => g.toMap()).toList();
      await prefs.setString('goals', json.encode(jsonList));
      return 1;
    }
    return 0;
  }
}
    final map = goal.toMap();
    map['created_at'] = DateTime.now().millisecondsSinceEpoch;
    map['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    return await db.insert(AppConstants.goalsTable, map);
  }

  Future<List<Goal>> getAllGoals() async {
    if (kIsWeb) {
      final prefs = await _webStorage;
      final jsonString = prefs.getString('goals') ?? '[]';
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Goal.fromMap(json)).toList();
    }
    
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.goalsTable,
      orderBy: 'target_date ASC',
    );
    return List.generate(maps.length, (i) => Goal.fromMap(maps[i]));
  }

  Future<List<Goal>> getActiveGoals() async {
    if (kIsWeb) {
      final goals = await getAllGoals();
      return goals.where((goal) => !goal.isCompleted).toList();
    }
    
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.goalsTable,
      where: 'is_completed = ?',
      whereArgs: [0],
      orderBy: 'target_date ASC',
    );
    return List.generate(maps.length, (i) => Goal.fromMap(maps[i]));
  }

  Future<Goal?> getGoalById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.goalsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Goal.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateGoal(Goal goal) async {
    if (kIsWeb) {
      final prefs = await _webStorage;
      final goals = await getAllGoals();
      final index = goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        goals[index] = goal;
        final jsonList = goals.map((g) => g.toMap()).toList();
        await prefs.setString('goals', json.encode(jsonList));
        return 1;
      }
      return 0;
    }
    
    final db = await database;
    final map = goal.toMap();
    map['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    return await db.update(
      AppConstants.goalsTable,
      map,
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteGoal(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.goalsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Notification CRUD Operations
  Future<int> insertNotification(InvestmentNotification notification) async {
    final db = await database;
    final map = notification.toMap();
    map['created_at'] = DateTime.now().millisecondsSinceEpoch;
    map['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    return await db.insert(AppConstants.notificationsTable, map);
  }

  Future<List<InvestmentNotification>> getAllNotifications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.notificationsTable,
      orderBy: 'notification_date DESC',
    );
    return List.generate(maps.length, (i) => InvestmentNotification.fromMap(maps[i]));
  }

  Future<List<InvestmentNotification>> getUnreadNotifications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.notificationsTable,
      where: 'is_read = ?',
      whereArgs: [0],
      orderBy: 'notification_date DESC',
    );
    return List.generate(maps.length, (i) => InvestmentNotification.fromMap(maps[i]));
  }

  Future<int> markNotificationAsRead(int id) async {
    final db = await database;
    return await db.update(
      AppConstants.notificationsTable,
      {
        'is_read': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteNotification(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.notificationsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Analytics and Reports
  Future<Map<String, double>> getInvestmentSummary() async {
    if (kIsWeb) {
      final investments = await getActiveInvestments();
      final Map<String, double> summary = {};
      
      for (final investment in investments) {
        summary[investment.type] = (summary[investment.type] ?? 0) + investment.amount;
      }
      
      return summary;
    }
    
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        type,
        SUM(amount) as total_amount,
        COUNT(*) as count
      FROM ${AppConstants.investmentsTable}
      WHERE status = 'Active'
      GROUP BY type
    ''');

    final Map<String, double> summary = {};
    for (final row in result) {
      summary[row['type'] as String] = (row['total_amount'] as num).toDouble();
    }
    return summary;
  }

  Future<List<Investment>> getUpcomingMaturities(int days) async {
    if (kIsWeb) {
      final investments = await getActiveInvestments();
      final futureDate = DateTime.now().add(Duration(days: days));
      
      return investments.where((inv) => 
        inv.maturityDate != null && 
        inv.maturityDate!.isBefore(futureDate)
      ).toList();
    }
    
    final db = await database;
    final futureDate = DateTime.now().add(Duration(days: days));
    
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.investmentsTable,
      where: 'maturity_date IS NOT NULL AND maturity_date <= ? AND status = ?',
      whereArgs: [futureDate.millisecondsSinceEpoch, 'Active'],
      orderBy: 'maturity_date ASC',
    );
    return List.generate(maps.length, (i) => Investment.fromMap(maps[i]));
  }

  // Data Export
  Future<List<Map<String, dynamic>>> exportInvestmentsData() async {
    final db = await database;
    return await db.query(AppConstants.investmentsTable);
  }

  Future<List<Map<String, dynamic>>> exportGoalsData() async {
    final db = await database;
    return await db.query(AppConstants.goalsTable);
  }

  // Database Maintenance
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(AppConstants.notificationsTable);
    await db.delete(AppConstants.goalsTable);
    await db.delete(AppConstants.investmentsTable);
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Insert sample data for testing
  Future<void> insertSampleData() async {
    if (kIsWeb) {
      final investments = await getAllInvestments();
      if (investments.isNotEmpty) return;
      
      await insertInvestment(Investment(
        type: 'Fixed Deposit',
        name: 'SBI Fixed Deposit',
        amount: 100000,
        startDate: DateTime.now().subtract(const Duration(days: 365)),
        maturityDate: DateTime.now().add(const Duration(days: 730)),
        interestRate: 6.5,
        additionalData: {
          'bank_name': 'State Bank of India',
          'maturity_amount': '113000',
        },
      ));
      
      await insertInvestment(Investment(
        type: 'SIP',
        name: 'HDFC Top 100 Fund',
        amount: 60000,
        startDate: DateTime.now().subtract(const Duration(days: 365)),
        additionalData: {
          'scheme_name': 'HDFC Top 100 Fund',
          'monthly_amount': '5000',
          'current_nav': '650',
          'current_value': '72000',
        },
      ));
      
      await insertGoal(Goal(
        name: 'House Down Payment',
        targetAmount: 2000000,
        targetDate: DateTime.now().add(const Duration(days: 1825)),
        currentProgress: 500000,
        description: 'Save for house down payment',
        category: 'House',
      ));
      
      await insertGoal(Goal(
        name: 'Retirement Fund',
        targetAmount: 10000000,
        targetDate: DateTime.now().add(const Duration(days: 10950)),
        currentProgress: 1000000,
        description: 'Build retirement corpus',
        category: 'Retirement',
      ));
      return;
    }
    // Sample Fixed Deposit
    await insertInvestment(Investment(
      type: AppConstants.fixedDeposit,
      name: 'SBI Fixed Deposit',
      amount: 100000,
      startDate: DateTime.now().subtract(const Duration(days: 365)),
      maturityDate: DateTime.now().add(const Duration(days: 730)),
      interestRate: 6.5,
      additionalData: {
        'bank_name': 'State Bank of India',
        'maturity_amount': '113000',
      },
    ));

    // Sample SIP
    await insertInvestment(Investment(
      type: AppConstants.sip,
      name: 'HDFC Top 100 Fund',
      amount: 60000, // 5000 * 12 months
      startDate: DateTime.now().subtract(const Duration(days: 365)),
      additionalData: {
        'scheme_name': 'HDFC Top 100 Fund',
        'monthly_amount': '5000',
        'current_nav': '650',
        'current_value': '72000',
      },
    ));

    // Sample PPF
    await insertInvestment(Investment(
      type: AppConstants.ppf,
      name: 'PPF Account - SBI',
      amount: 150000,
      startDate: DateTime.now().subtract(const Duration(days: 365)),
      additionalData: {
        'annual_contribution': '150000',
        'year': '1',
        'total_balance': '160650',
      },
    ));

    // Sample Goal
    await insertGoal(Goal(
      name: 'House Down Payment',
      targetAmount: 2000000,
      targetDate: DateTime.now().add(const Duration(days: 1825)), // 5 years
      currentProgress: 500000,
      description: 'Save for house down payment',
      category: GoalCategories.house,
    ));

    // Sample Goal - Retirement
    await insertGoal(Goal(
      name: 'Retirement Fund',
      targetAmount: 10000000,
      targetDate: DateTime.now().add(const Duration(days: 10950)), // 30 years
      currentProgress: 1000000,
      description: 'Build retirement corpus',
      category: GoalCategories.retirement,
    ));
  }
}