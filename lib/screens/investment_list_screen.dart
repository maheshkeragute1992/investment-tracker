import 'package:flutter/material.dart';
import '../models/investment.dart';
import '../services/database_service.dart';
import '../widgets/investment_card.dart';
import '../utils/constants.dart';
import '../utils/refresh_notifier.dart';
import 'add_investment_screen.dart';

class InvestmentListScreen extends StatefulWidget {
  const InvestmentListScreen({super.key});

  @override
  State<InvestmentListScreen> createState() => InvestmentListScreenState();
}

class InvestmentListScreenState extends State<InvestmentListScreen> {
  void refreshData() {
    _loadInvestments();
  }

  final DatabaseService _databaseService = DatabaseService();
  List<Investment> _investments = [];
  List<Investment> _filteredInvestments = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<String> _filterOptions = [
    'All',
    ...AppConstants.investmentTypes,
  ];

  @override
  void initState() {
    super.initState();
    _loadInvestments();
    RefreshNotifier().addListener(refreshData);
  }

  @override
  void dispose() {
    RefreshNotifier().removeListener(refreshData);
    super.dispose();
  }

  Future<void> _loadInvestments() async {
    setState(() => _isLoading = true);
    
    try {
      final investments = await _databaseService.getAllInvestments();
      setState(() {
        _investments = investments;
        _applyFilters();
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

  void _applyFilters() {
    List<Investment> filtered = _investments;

    if (_selectedFilter != 'All') {
      filtered = filtered.where((inv) => inv.type == _selectedFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((inv) =>
          inv.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inv.type.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    setState(() {
      _filteredInvestments = filtered;
    });
  }

  Future<void> _deleteInvestment(Investment investment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Investment'),
        content: Text('Are you sure you want to delete "${investment.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteInvestment(investment.id!);
        RefreshNotifier().notifyDataChanged();
        await _loadInvestments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Investment deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting investment: $e')),
          );
        }
      }
    }
  }

  Future<void> _editInvestment(Investment investment) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddInvestmentScreen(investment: investment),
      ),
    );

    if (result == true) {
      await _loadInvestments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Investments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => const AddInvestmentScreen(),
                ),
              );
              if (result == true) {
                await _loadInvestments();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search investments...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filterOptions.length,
                    itemBuilder: (context, index) {
                      final option = _filterOptions[index];
                      final isSelected = _selectedFilter == option;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(option),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = option;
                            });
                            _applyFilters();
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredInvestments.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadInvestments,
                        child: ListView.builder(
                          itemCount: _filteredInvestments.length,
                          itemBuilder: (context, index) {
                            final investment = _filteredInvestments[index];
                            return InvestmentCard(
                              investment: investment,
                              onTap: investment.type == AppConstants.loanToFriend 
                                  ? () => _loadInvestments() // Refresh when returning from loan details
                                  : () => _showInvestmentDetails(investment),
                            );
                          },
                        ),
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
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'All'
                  ? 'No investments found'
                  : 'No investments yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'All'
                  ? 'Try adjusting your search or filter'
                  : 'Start by adding your first investment',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty && _selectedFilter == 'All') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) => const AddInvestmentScreen(),
                    ),
                  );
                  if (result == true) {
                    await _loadInvestments();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Investment'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showInvestmentDetails(Investment investment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(investment.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${investment.type}'),
            Text('Amount: ₹${investment.amount.toStringAsFixed(0)}'),
            Text('Start Date: ${investment.startDate.day}/${investment.startDate.month}/${investment.startDate.year}'),
            if (investment.maturityDate != null)
              Text('Maturity: ${investment.maturityDate!.day}/${investment.maturityDate!.month}/${investment.maturityDate!.year}'),
            if (investment.interestRate != null)
              Text('Interest Rate: ${investment.interestRate}%'),
            Text('Status: ${investment.status}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editInvestment(investment);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteInvestment(investment);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}