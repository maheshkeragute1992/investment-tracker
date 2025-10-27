import 'package:flutter/material.dart';

class AppConstants {
  // App Colors
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color secondaryColor = Color(0xFF388E3C);
  static const Color accentColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFD32F2F);
  
  // Investment Type Colors
  static const Color fdColor = Color(0xFF2196F3);
  static const Color sipColor = Color(0xFF4CAF50);
  static const Color ppfColor = Color(0xFF9C27B0);
  static const Color npsColor = Color(0xFF607D8B);
  static const Color sgbColor = Color(0xFFFF9800);
  static const Color rdColor = Color(0xFF00BCD4);
  
  // Investment Types
  static const String fixedDeposit = 'Fixed Deposit';
  static const String sip = 'SIP/Mutual Fund';
  static const String ppf = 'PPF';
  static const String nps = 'NPS';
  static const String sgb = 'Sovereign Gold Bond';
  static const String recurringDeposit = 'Recurring Deposit';
  
  static const List<String> investmentTypes = [
    fixedDeposit,
    sip,
    ppf,
    nps,
    sgb,
    recurringDeposit,
  ];
  
  // Database
  static const String dbName = 'investment_tracker.db';
  static const int dbVersion = 1;
  
  // Table Names
  static const String investmentsTable = 'investments';
  static const String goalsTable = 'goals';
  static const String notificationsTable = 'notifications';
  
  // Notification IDs
  static const int maturityNotificationId = 1000;
  
  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  // Currency
  static const String currencySymbol = '₹';
  
  // PPF Constants
  static const double ppfInterestRate = 7.1;
  static const int ppfTenure = 15;
  static const double ppfMaxContribution = 150000;
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
  );
}