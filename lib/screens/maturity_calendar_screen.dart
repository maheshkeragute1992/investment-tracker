import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/investment.dart';
import '../services/database_service.dart';
import '../services/calculation_service.dart';
import '../utils/constants.dart';
import '../utils/date_helpers.dart';

class MaturityCalendarScreen extends StatefulWidget {
  const MaturityCalendarScreen({super.key});

  @override
  State<MaturityCalendarScreen> createState() => _MaturityCalendarScreenState();
}

class _MaturityCalendarScreenState extends State<MaturityCalendarScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Investment> _investments = [];
  bool _isLoading = true;
  String _selectedTimeframe = 'All';

  final List<String> _timeframeOptions = [
    'All',
    'Next 30 Days',
    'Next 90 Days',
    'Next 6 Months',
    'Next 1 Year',
  ];

  @override
  void initState() {
    super.initState();
    _loadInvestments();
  }

  Future<void> _loadInvestments() async {
    setState(() => _isLoading = true);
    
    try {
      final investments = await _databaseService.getActiveInvestments();
      // Filter only investments with maturity dates
      final investmentsWithMaturity = investments
          .where((inv) => inv.maturityDate != null)
          .toList();
      
      setState(() {
        _investments = investmentsWithMaturity;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading investments: $e')),
        );
      }
    }
  }

  List<Investment> _getFilteredInvestments() {
    final now = DateTime.now();
    
    switch (_selectedTimeframe) {
      case 'Next 30 Days':
        return _investments.where((inv) {
          final daysToMaturity = DateHelpers.daysBetween(now, inv.maturityDate!);
          return daysToMaturity >= 0 && daysToMaturity <= 30;
        }).toList();
        
      case 'Next 90 Days':
        return _investments.where((inv) {
          final daysToMaturity = DateHelpers.daysBetween(now, inv.maturityDate!);
          return daysToMaturity >= 0 && daysToMaturity <= 90;
        }).toList();
        
      case 'Next 6 Months':
        return _investments.where((inv) {
          final daysToMaturity = DateHelpers.daysBetween(now, inv.maturityDate!);
          return daysToMaturity >= 0 && daysToMaturity <= 180;
        }).toList();
        
      case 'Next 1 Year':
        return _investments.where((inv) {
          final daysToMaturity = DateHelpers.daysBetween(now, inv.maturityDate!);
          return daysToMaturity >= 0 && daysToMaturity <= 365;
        }).toList();
        
      default:
        return _investments;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredInvestments = _getFilteredInvestments();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maturity Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvestments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Timeframe',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _timeframeOptions.length,
                    itemBuilder: (context, index) {
                      final option = _timeframeOptions[index];
                      final isSelected = _selectedTimeframe == option;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(option),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedTimeframe = option;
                            });
                          },
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          selectedColor: Theme.of(context).colorScheme.primaryContainer,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Summary Cards
          if (!_isLoading) _buildSummaryCards(filteredInvestments),
          
          // Investment List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredInvestments.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadInvestments,
                        child: _buildMaturityList(filteredInvestments),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<Investment> investments) {
    final now = DateTime.now();
    
    // Categorize investments by urgency
    final maturingToday = investments.where((inv) => 
        DateHelpers.daysBetween(now, inv.maturityDate!) == 0).length;
    
    final maturingThisWeek = investments.where((inv) {
      final days = DateHelpers.daysBetween(now, inv.maturityDate!);
      return days > 0 && days <= 7;
    }).length;
    
    final maturingThisMonth = investments.where((inv) {
      final days = DateHelpers.daysBetween(now, inv.maturityDate!);
      return days > 7 && days <= 30;
    }).length;
    
    final totalMaturityValue = investments.fold<double>(0, (sum, inv) {
      return sum + CalculationService.calculateProjectedMaturity(inv);
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Today',
                  maturingToday.toString(),
                  Icons.today,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'This Week',
                  maturingThisWeek.toString(),
                  Icons.date_range,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'This Month',
                  maturingThisMonth.toString(),
                  Icons.calendar_month,
                  Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Maturity Value',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          DateHelpers.formatCurrency(totalMaturityValue),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
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

  Widget _buildMaturityList(List<Investment> investments) {
    // Sort investments by maturity date
    final sortedInvestments = List<Investment>.from(investments)
      ..sort((a, b) => a.maturityDate!.compareTo(b.maturityDate!));

    // Group investments by month
    final groupedInvestments = <String, List<Investment>>{};
    
    for (final investment in sortedInvestments) {
      final monthYear = DateFormat('MMMM yyyy').format(investment.maturityDate!);
      groupedInvestments.putIfAbsent(monthYear, () => []).add(investment);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: groupedInvestments.length,
      itemBuilder: (context, index) {
        final monthYear = groupedInvestments.keys.elementAt(index);
        final monthInvestments = groupedInvestments[monthYear]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                monthYear,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ...monthInvestments.map((investment) => 
                _buildMaturityItem(context, investment)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildMaturityItem(BuildContext context, Investment investment) {
    final now = DateTime.now();
    final daysToMaturity = DateHelpers.daysBetween(now, investment.maturityDate!);
    final maturityValue = CalculationService.calculateProjectedMaturity(investment);
    final returns = maturityValue - investment.amount;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getInvestmentColor(investment.type),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    investment.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildUrgencyChip(context, daysToMaturity),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              investment.type,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getInvestmentColor(investment.type),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Matures on ${DateHelpers.formatDate(investment.maturityDate!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildValueColumn(
                    context,
                    'Invested',
                    DateHelpers.formatCurrency(investment.amount),
                  ),
                ),
                Expanded(
                  child: _buildValueColumn(
                    context,
                    'Maturity Value',
                    DateHelpers.formatCurrency(maturityValue),
                  ),
                ),
                Expanded(
                  child: _buildValueColumn(
                    context,
                    'Returns',
                    DateHelpers.formatCurrency(returns),
                    valueColor: returns >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            
            if (investment.interestRate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.percent,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Interest Rate: ${investment.interestRate!.toStringAsFixed(2)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValueColumn(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildUrgencyChip(BuildContext context, int daysToMaturity) {
    Color chipColor;
    String chipText;
    IconData? chipIcon;

    if (daysToMaturity < 0) {
      chipColor = Colors.red;
      chipText = 'Overdue';
      chipIcon = Icons.warning;
    } else if (daysToMaturity == 0) {
      chipColor = Colors.red;
      chipText = 'Today';
      chipIcon = Icons.today;
    } else if (daysToMaturity <= 7) {
      chipColor = Colors.orange;
      chipText = '${daysToMaturity}d';
      chipIcon = Icons.schedule;
    } else if (daysToMaturity <= 30) {
      chipColor = Colors.amber;
      chipText = '${daysToMaturity}d';
    } else if (daysToMaturity <= 90) {
      chipColor = Colors.blue;
      chipText = '${(daysToMaturity / 30).round()}m';
    } else {
      chipColor = Colors.green;
      final months = (daysToMaturity / 30).round();
      chipText = months > 12 ? '${(months / 12).round()}y' : '${months}m';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chipIcon != null) ...[
            Icon(chipIcon, size: 12, color: chipColor),
            const SizedBox(width: 4),
          ],
          Text(
            chipText,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedTimeframe == 'All' 
                  ? 'No investments with maturity dates'
                  : 'No investments maturing in $_selectedTimeframe',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedTimeframe == 'All'
                  ? 'Add investments with maturity dates to see them here'
                  : 'Try selecting a different timeframe',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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