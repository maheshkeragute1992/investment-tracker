class Investment {
  final int? id;
  final String type;
  final String name;
  final double amount;
  final DateTime startDate;
  final DateTime? maturityDate;
  final double? interestRate;
  final String status;
  final Map<String, dynamic>? additionalData;

  Investment({
    this.id,
    required this.type,
    required this.name,
    required this.amount,
    required this.startDate,
    this.maturityDate,
    this.interestRate,
    this.status = 'Active',
    this.additionalData,
  });

  // Convert Investment to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'amount': amount,
      'start_date': startDate.millisecondsSinceEpoch,
      'maturity_date': maturityDate?.millisecondsSinceEpoch,
      'interest_rate': interestRate,
      'status': status,
      'additional_data': additionalData != null 
          ? _mapToString(additionalData!) 
          : null,
    };
  }

  // Create Investment from Map (database)
  factory Investment.fromMap(Map<String, dynamic> map) {
    return Investment(
      id: map['id'],
      type: map['type'],
      name: map['name'],
      amount: map['amount'].toDouble(),
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date']),
      maturityDate: map['maturity_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['maturity_date'])
          : null,
      interestRate: map['interest_rate']?.toDouble(),
      status: map['status'] ?? 'Active',
      additionalData: map['additional_data'] != null 
          ? _stringToMap(map['additional_data'])
          : null,
    );
  }

  // Helper method to convert Map to String for storage
  static String _mapToString(Map<String, dynamic> map) {
    return map.entries
        .map((e) => '${e.key}:${e.value}')
        .join('|');
  }

  // Helper method to convert String back to Map
  static Map<String, dynamic> _stringToMap(String str) {
    final Map<String, dynamic> result = {};
    if (str.isEmpty) return result;
    
    final pairs = str.split('|').where((pair) => pair.isNotEmpty).toList();
    for (final pair in pairs) {
      final keyValue = pair.split(':');
      if (keyValue.length >= 2) {
        final key = keyValue[0];
        final value = keyValue.sublist(1).join(':'); // Handle values with colons
        result[key] = value;
      }
    }
    return result;
  }

  // Copy with method for updates
  Investment copyWith({
    int? id,
    String? type,
    String? name,
    double? amount,
    DateTime? startDate,
    DateTime? maturityDate,
    double? interestRate,
    String? status,
    Map<String, dynamic>? additionalData,
  }) {
    return Investment(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      maturityDate: maturityDate ?? this.maturityDate,
      interestRate: interestRate ?? this.interestRate,
      status: status ?? this.status,
      additionalData: additionalData != null 
          ? Map<String, dynamic>.from(additionalData)
          : this.additionalData != null 
              ? Map<String, dynamic>.from(this.additionalData!)
              : null,
    );
  }

  @override
  String toString() {
    return 'Investment{id: $id, type: $type, name: $name, amount: $amount, startDate: $startDate, maturityDate: $maturityDate, interestRate: $interestRate, status: $status}';
  }
}

// Specific investment type classes for better type safety
class FixedDeposit extends Investment {
  final String bankName;
  final double maturityAmount;

  FixedDeposit({
    super.id,
    required super.name,
    required super.amount,
    required super.startDate,
    required super.maturityDate,
    required super.interestRate,
    required this.bankName,
    required this.maturityAmount,
    super.status,
  }) : super(
    type: 'Fixed Deposit',
    additionalData: {
      'bank_name': bankName,
      'maturity_amount': maturityAmount.toString(),
    },
  );
}

class SIPInvestment extends Investment {
  final String schemeName;
  final double monthlyAmount;
  final double? currentNAV;
  final double? currentValue;

  SIPInvestment({
    super.id,
    required super.name,
    required super.amount,
    required super.startDate,
    required this.schemeName,
    required this.monthlyAmount,
    this.currentNAV,
    this.currentValue,
    super.status,
  }) : super(
    type: 'SIP/Mutual Fund',
    additionalData: {
      'scheme_name': schemeName,
      'monthly_amount': monthlyAmount.toString(),
      'current_nav': currentNAV?.toString() ?? '',
      'current_value': currentValue?.toString() ?? '',
    },
  );
}

class PPFInvestment extends Investment {
  final double annualContribution;
  final int year;
  final double totalBalance;

  PPFInvestment({
    super.id,
    required super.name,
    required super.amount,
    required super.startDate,
    required this.annualContribution,
    required this.year,
    required this.totalBalance,
    super.status,
  }) : super(
    type: 'PPF',
    additionalData: {
      'annual_contribution': annualContribution.toString(),
      'year': year.toString(),
      'total_balance': totalBalance.toString(),
    },
  );
}

class NPSInvestment extends Investment {
  final double contributionAmount;
  final String tier;
  final double? expectedCorpus;

  NPSInvestment({
    super.id,
    required super.name,
    required super.amount,
    required super.startDate,
    required this.contributionAmount,
    required this.tier,
    this.expectedCorpus,
    super.status,
  }) : super(
    type: 'NPS',
    additionalData: {
      'contribution_amount': contributionAmount.toString(),
      'tier': tier,
      'expected_corpus': expectedCorpus?.toString() ?? '',
    },
  );
}

class SGBInvestment extends Investment {
  final int units;
  final double issuePrice;
  final DateTime issueDate;
  final double? currentValue;

  SGBInvestment({
    super.id,
    required super.name,
    required super.amount,
    required super.startDate,
    required super.maturityDate,
    required this.units,
    required this.issuePrice,
    required this.issueDate,
    this.currentValue,
    super.status,
  }) : super(
    type: 'Sovereign Gold Bond',
    additionalData: {
      'units': units.toString(),
      'issue_price': issuePrice.toString(),
      'issue_date': issueDate.millisecondsSinceEpoch.toString(),
      'current_value': currentValue?.toString() ?? '',
    },
  );
}

class RecurringDeposit extends Investment {
  final double monthlyAmount;
  final int tenureMonths;
  final double maturityValue;

  RecurringDeposit({
    super.id,
    required super.name,
    required super.amount,
    required super.startDate,
    required super.maturityDate,
    required super.interestRate,
    required this.monthlyAmount,
    required this.tenureMonths,
    required this.maturityValue,
    super.status,
  }) : super(
    type: 'Recurring Deposit',
    additionalData: {
      'monthly_amount': monthlyAmount.toString(),
      'tenure_months': tenureMonths.toString(),
      'maturity_value': maturityValue.toString(),
    },
  );
}

class LoanToFriend extends Investment {
  final String friendName;
  final double originalAmount;
  final double outstandingAmount;
  final List<Map<String, dynamic>> repayments;

  LoanToFriend({
    super.id,
    required super.name,
    required this.friendName,
    required this.originalAmount,
    required this.outstandingAmount,
    required super.startDate,
    required super.interestRate,
    required this.repayments,
    super.status,
  }) : super(
    type: 'Loan to Friend',
    amount: outstandingAmount,
    additionalData: {
      'friend_name': friendName,
      'original_amount': originalAmount.toString(),
      'outstanding_amount': outstandingAmount.toString(),
      'repayments': repayments.map((r) => '${r['date']}:${r['amount']}').join('|'),
    },
  );
}