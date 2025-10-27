import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/investment_list_screen.dart';
import 'screens/add_investment_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/maturity_calendar_screen.dart';
import 'services/database_service.dart';
import 'utils/constants.dart';
import 'utils/refresh_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InvestmentTrackerApp());
}

class InvestmentTrackerApp extends StatelessWidget {
  const InvestmentTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Investment Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isInitialized = false;
  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey<DashboardScreenState>();
  final GlobalKey<InvestmentListScreenState> _investmentListKey = GlobalKey<InvestmentListScreenState>();

  @override
  void initState() {
    super.initState();
    _initializeApp();
    RefreshNotifier().addListener(_refreshAllScreens);
  }

  @override
  void dispose() {
    RefreshNotifier().removeListener(_refreshAllScreens);
    super.dispose();
  }

  void _refreshAllScreens() {
    _dashboardKey.currentState?.refreshData();
    _investmentListKey.currentState?.refreshData();
  }

  Future<void> _initializeApp() async {
    try {
      final databaseService = DatabaseService();
      final investments = await databaseService.getAllInvestments();
      if (investments.isEmpty) {
        await databaseService.insertSampleData();
      }
      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardScreen(key: _dashboardKey),
          InvestmentListScreen(key: _investmentListKey),
          AddInvestmentScreen(onInvestmentAdded: _onInvestmentAdded),
          const GoalsScreen(),
          const MaturityCalendarScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          // Refresh data when switching to dashboard or investments
          if (index == 0) {
            _dashboardKey.currentState?.refreshData();
          } else if (index == 1) {
            _investmentListKey.currentState?.refreshData();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Investments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
        ],
      ),
    );
  }

  void _onInvestmentAdded() {
    _dashboardKey.currentState?.refreshData();
    _investmentListKey.currentState?.refreshData();
    setState(() => _selectedIndex = 0);
  }
}