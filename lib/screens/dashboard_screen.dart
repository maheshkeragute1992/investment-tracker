import 'package:flutter/material.dart';
import '../models/investment.dart';
import '../models/goal.dart';
import '../services/database_service.dart';
import '../services/calculation_service.dart';
import '../widgets/chart_widgets.dart';
import '../utils/constants.dart';
import '../utils/date_helpers.dart';
import '../utils/refresh_notifier.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  void refreshData() {
    _loadData();
  }


  final DatabaseService _databaseService = DatabaseService();
  List<Investment> _investments = [];
  List<Goal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    RefreshNotifier().addListener(refreshData);
  }

  @override
  void dispose() {
    RefreshNotifier().removeListener(refreshData);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final investments = await _databaseService.getActiveInvestments();
      final goals = await _databaseService.getActiveGoals();
      
      print('Dashboard loaded ${investments.length} investments');
      for (final inv in investments) {
        print('Investment: ${inv.name} - ${inv.type} - ${inv.amount}');
      }
      
      setState(() {
        _investments = investments;
        _goals = goals;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPortfolioSummary(),
                    const SizedBox(height: 16),
                    _buildQuickStats(),
                    const SizedBox(height: 16),
                    if (_investments.isNotEmpty) ...[
                      PortfolioChart(investments: _investments),
                      const SizedBox(height: 16),
                      MaturityTimeline(investments: _investments),
                      const SizedBox(height: 16),
                    ],
                    _buildGoalsSummary(),
                    const SizedBox(height: 16),
                    _buildRecentActivity(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPortfolioSummary() {
    double totalInvested = 0;
    double totalCurrentValue = 0;
    
    for (final investment in _investments) {
      totalInvested += investment.amount;
      totalCurrentValue += CalculationService.calculateCurrentValue(investment);
    }
    
    final totalReturns = totalCurrentValue - totalInvested;
    final returnPercentage = totalInvested > 0 ? (totalReturns / totalInvested) * 100 : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Portfolio Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Total Invested',
                    DateHelpers.formatCurrency(totalInvested),
                    Icons.trending_up,
                    AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Current Value',
                    DateHelpers.formatCurrency(totalCurrentValue),
                    Icons.account_balance,
                    AppConstants.secondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Total Returns',
                    DateHelpers.formatCurrency(totalReturns),
                    Icons.show_chart,
                    totalReturns >= 0 ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Return %',
                    '${returnPercentage.toStringAsFixed(2)}%',
                    Icons.percent,
                    returnPercentage >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final activeInvestments = _investments.length;
    final upcomingMaturities = _investments
        .where((inv) => inv.maturityDate != null && 
                       DateHelpers.daysBetween(DateTime.now(), inv.maturityDate!) <= 30)
        .length;
    final activeGoals = _goals.length;
    final completedGoals = _goals.where((goal) => goal.isCompleted).length;

    return Row(
      children: [
        Expanded(
          child: _buildQuickStatCard(
            context,
            'Active\nInvestments',
            activeInvestments.toString(),
            Icons.trending_up,
            AppConstants.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatCard(
            context,
            'Maturing\nSoon',
            upcomingMaturities.toString(),
            Icons.schedule,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatCard(
            context,
            'Active\nGoals',
            activeGoals.toString(),
            Icons.flag,
            AppConstants.secondaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatCard(
            context,
            'Completed\nGoals',
            completedGoals.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsSummary() {
    if (_goals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.flag_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No Goals Set',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Set financial goals to track your progress',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final totalTargetAmount = _goals.fold<double>(0, (sum, goal) => sum + goal.targetAmount);
    final totalProgress = _goals.fold<double>(0, (sum, goal) => sum + goal.currentProgress);
    final overallProgress = totalTargetAmount > 0 ? (totalProgress / totalTargetAmount) * 100 : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Goals Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Progress',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${overallProgress.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: overallProgress >= 50 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: overallProgress / 100,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                overallProgress >= 50 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildGoalStat(
                    context,
                    'Target Amount',
                    DateHelpers.formatCurrency(totalTargetAmount),
                  ),
                ),
                Expanded(
                  child: _buildGoalStat(
                    context,
                    'Achieved',
                    DateHelpers.formatCurrency(totalProgress),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalStat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final recentInvestments = _investments.take(3).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Investments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentInvestments.isEmpty)
              const Center(
                child: Text('No recent investments'),
              )
            else
              Column(
                children: recentInvestments.map((investment) => 
                  _buildRecentInvestmentItem(context, investment)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentInvestmentItem(BuildContext context, Investment investment) {
    final currentValue = investment.amount;
    final returns = currentValue - investment.amount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getInvestmentColor(investment.type),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investment.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${investment.type} • ${DateHelpers.formatCurrency(investment.amount)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateHelpers.formatCurrency(currentValue),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                returns >= 0 ? '+${DateHelpers.formatCurrency(returns)}' : DateHelpers.formatCurrency(returns),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: returns >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getInvestmentColor(String type) {
    switch (type) {
      case AppConstants.fixedDeposit:
        return AppConstants.fdColor;
      case AppConstants.sip:
        return AppConstants.sipColor;
      case AppConstants.ppf:
        return AppConstants.ppfColor;
      case AppConstants.nps:
        return AppConstants.npsColor;
      case AppConstants.sgb:
        return AppConstants.sgbColor;
      case AppConstants.recurringDeposit:
        return AppConstants.rdColor;
      default:
        return AppConstants.primaryColor;
    }
  }
}