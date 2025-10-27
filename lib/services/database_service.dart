import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/investment.dart';
import '../models/goal.dart';
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
    final counter = prefs.getInt('goalCounter') ?? 0;
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
    await prefs.setInt('goalCounter', newId);
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

  Future<List<Goal>> getActiveGoals() async {
    final goals = await getAllGoals();
    return goals.where((goal) => !goal.isCompleted).toList();
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

  // Sample data for first run
  Future<void> insertSampleData() async {
    final investments = await getAllInvestments();
    if (investments.isNotEmpty) return;
    
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
    
    await insertInvestment(Investment(
      type: AppConstants.sip,
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
  }
}