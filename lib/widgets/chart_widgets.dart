import 'package:flutter/material.dart';
import '../models/investment.dart';
import '../utils/constants.dart';
import '../utils/date_helpers.dart';

class PortfolioChart extends StatelessWidget {
  final List<Investment> investments;

  const PortfolioChart({
    super.key,
    required this.investments,
  });

  @override
  Widget build(BuildContext context) {
    if (investments.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No investments to display'),
        ),
      );
    }

    final typeCount = <String, int>{};
    for (final investment in investments) {
      typeCount[investment.type] = (typeCount[investment.type] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Portfolio Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...typeCount.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getTypeColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${entry.key}: ${entry.value} investments'),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
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

class MaturityTimeline extends StatelessWidget {
  final List<Investment> investments;

  const MaturityTimeline({
    super.key,
    required this.investments,
  });

  @override
  Widget build(BuildContext context) {
    final upcomingMaturities = investments
        .where((inv) => inv.maturityDate != null && 
                       inv.maturityDate!.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.maturityDate!.compareTo(b.maturityDate!));

    if (upcomingMaturities.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Upcoming Maturities',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('No upcoming maturities'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Maturities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...upcomingMaturities.take(5).map((investment) => 
              _buildMaturityItem(context, investment)),
          ],
        ),
      ),
    );
  }

  Widget _buildMaturityItem(BuildContext context, Investment investment) {
    final daysToMaturity = DateHelpers.daysBetween(
      DateTime.now(),
      investment.maturityDate!,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getTypeColor(investment.type),
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
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${DateHelpers.formatDate(investment.maturityDate!)} • ${DateHelpers.formatCurrency(investment.amount)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getDaysColor(daysToMaturity).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${daysToMaturity}d',
              style: TextStyle(
                color: _getDaysColor(daysToMaturity),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
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

  Color _getDaysColor(int days) {
    if (days <= 7) return Colors.red;
    if (days <= 30) return Colors.orange;
    return Colors.green;
  }
}