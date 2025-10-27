# Indian Investment Tracker

A comprehensive Flutter mobile application for tracking Indian financial instruments including Fixed Deposits, SIP/Mutual Funds, PPF, NPS, Sovereign Gold Bonds, and Recurring Deposits.

## Features

### 🏦 Investment Types Supported
- **Fixed Deposits (FD)**: Track bank FDs with maturity calculations
- **SIP/Mutual Funds**: Monitor monthly SIP investments and returns
- **PPF (Public Provident Fund)**: 15-year investment tracking with tax benefits
- **NPS (National Pension System)**: Retirement planning with Tier I/II accounts
- **Sovereign Gold Bonds (SGB)**: 8-year gold investment tracking
- **Recurring Deposits (RD)**: Monthly deposit schemes with maturity values

### 📊 Core Features
- **Dashboard**: Portfolio overview with total investments, returns, and goal progress
- **Investment Management**: Add, edit, delete, and view all investments
- **Maturity Calendar**: Timeline view of upcoming maturity dates with urgency indicators
- **Financial Goals**: Set and track financial targets with progress monitoring
- **Notifications**: Local notifications for maturity reminders (30, 7, 1 day before)
- **Charts & Analytics**: Portfolio allocation, growth charts, and maturity timeline
- **Indian Formatting**: Currency in ₹ with Lakh/Crore notation, DD/MM/YYYY dates

### 🧮 Calculation Engine
- **Compound Interest**: A = P(1 + r/n)^(nt) for FDs/RDs
- **SIP Future Value**: FV = PMT × [((1 + r)^n - 1) / r] × (1 + r)
- **PPF Maturity**: 15-year compounding at current rates (7.1%)
- **CAGR**: [(Ending Value / Beginning Value)^(1/years)] - 1
- **Real-time Calculations**: Current value, returns, and projections

## Screenshots

*Dashboard with portfolio overview and charts*
*Investment list with search and filter options*
*Add investment form with calculation previews*
*Maturity calendar with timeline view*
*Goals tracking with progress indicators*

## Technical Stack

- **Framework**: Flutter 3.10+
- **Database**: SQLite (offline-first)
- **Charts**: Syncfusion Flutter Charts (free community license)
- **Notifications**: Flutter Local Notifications
- **Architecture**: Clean architecture with separation of concerns
- **State Management**: StatefulWidget with proper lifecycle management

## Project Structure

```
lib/
├── main.dart                    # App entry point and navigation
├── models/                      # Data models
│   ├── investment.dart         # Investment model with all types
│   ├── goal.dart              # Financial goals model
│   └── notification.dart      # Notification model
├── screens/                    # UI screens
│   ├── dashboard_screen.dart   # Portfolio overview
│   ├── add_investment_screen.dart # Add/edit investments
│   ├── investment_list_screen.dart # List all investments
│   ├── maturity_calendar_screen.dart # Timeline view
│   └── goals_screen.dart       # Goals management
├── services/                   # Business logic
│   ├── database_service.dart   # SQLite operations
│   ├── calculation_service.dart # Financial calculations
│   └── notification_service.dart # Local notifications
├── widgets/                    # Reusable UI components
│   ├── investment_card.dart    # Investment display card
│   ├── chart_widgets.dart      # Portfolio charts
│   └── goal_progress_widget.dart # Goal progress display
└── utils/                      # Utilities
    ├── constants.dart          # App constants and themes
    └── date_helpers.dart       # Date formatting and calculations
```

## Installation & Setup

### Prerequisites
- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code with Flutter extensions
- Android device/emulator or iOS device/simulator

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd InvestmentTracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### First Run
- The app will automatically create sample data on first launch
- Sample investments include FD, SIP, and PPF examples
- Sample goals for house purchase and retirement are created
- All data is stored locally using SQLite

## Usage Guide

### Adding Investments

1. **Navigate to Add Investment** (+ button in bottom navigation)
2. **Select Investment Type** from the available options
3. **Fill Basic Information**:
   - Investment name (e.g., "SBI Fixed Deposit")
   - Amount invested
   - Start date
   - Interest rate (if applicable)

4. **Complete Type-Specific Fields**:
   - **FD**: Bank name, maturity date
   - **SIP**: Scheme name, monthly SIP amount
   - **PPF**: Annual contribution (max ₹1,50,000)
   - **NPS**: Tier selection, monthly contribution
   - **SGB**: Units, issue price, maturity date
   - **RD**: Bank name, monthly amount, tenure

5. **Review Calculations**: Preview maturity amounts and returns
6. **Save**: Investment is added with automatic notification scheduling

### Setting Financial Goals

1. **Go to Goals Tab** in bottom navigation
2. **Add New Goal** using the + button
3. **Enter Goal Details**:
   - Goal name (e.g., "House Down Payment")
   - Category (Retirement, Education, House, etc.)
   - Target amount
   - Target date
   - Current progress (optional)
   - Description

4. **Track Progress**: Update progress regularly to monitor achievement
5. **View Insights**: Monthly savings required, days remaining, completion percentage

### Monitoring Investments

- **Dashboard**: View portfolio summary, allocation charts, and recent activity
- **Investment List**: Search, filter by type, view detailed information
- **Maturity Calendar**: See upcoming maturities with urgency indicators
- **Notifications**: Receive alerts 30, 7, and 1 day before maturity

## Financial Calculations

### Fixed Deposit Maturity
```
A = P(1 + r/n)^(nt)
Where:
- A = Maturity Amount
- P = Principal
- r = Annual Interest Rate
- n = Compounding Frequency (4 for quarterly)
- t = Time in years
```

### SIP Future Value
```
FV = PMT × [((1 + r)^n - 1) / r] × (1 + r)
Where:
- FV = Future Value
- PMT = Monthly Payment
- r = Monthly Return Rate
- n = Number of months
```

### PPF Maturity (15 years)
```
Annual contributions compounded at 7.1% for 15 years
Each year's contribution compounds for remaining years
```

### CAGR Calculation
```
CAGR = [(Ending Value / Beginning Value)^(1/years)] - 1
```

## Data Management

### Local Storage
- All data stored in SQLite database
- Offline-first approach - no internet required
- Automatic database creation and migration
- Sample data inserted on first run

### Data Export
- Export investment data to CSV format
- Backup functionality using device storage
- Data can be shared via standard sharing options

### Database Schema

**Investments Table**:
- id, type, name, amount, start_date, maturity_date
- interest_rate, status, additional_data, timestamps

**Goals Table**:
- id, name, target_amount, target_date, current_progress
- description, category, created_date, is_completed, timestamps

**Notifications Table**:
- id, investment_id, title, message, notification_date
- type, is_read, is_scheduled, timestamps

## Customization

### Adding New Investment Types
1. Add new type constant in `constants.dart`
2. Extend Investment model with new fields
3. Update calculation service with new formulas
4. Add UI form fields in `add_investment_screen.dart`
5. Update color scheme and icons

### Modifying Calculations
- Edit formulas in `calculation_service.dart`
- Update preview calculations in add investment screen
- Ensure backward compatibility with existing data

### Theming
- Modify colors in `constants.dart`
- Update Material Design 3 theme in `AppTheme`
- Customize investment type colors

## Troubleshooting

### Common Issues

1. **Build Errors**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Database Issues**
   - Clear app data to reset database
   - Check SQLite version compatibility

3. **Notification Issues**
   - Ensure notification permissions are granted
   - Check device notification settings

4. **Chart Display Issues**
   - Verify Syncfusion license (free community)
   - Check data format for charts

### Performance Optimization
- Database queries are indexed for performance
- Charts use efficient data structures
- Images and assets are optimized
- Lazy loading for large lists

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/new-feature`)
3. Commit changes (`git commit -am 'Add new feature'`)
4. Push to branch (`git push origin feature/new-feature`)
5. Create Pull Request

### Development Guidelines
- Follow Flutter/Dart style guide
- Add comments for complex financial calculations
- Write unit tests for calculation functions
- Update documentation for new features

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This application is for personal financial tracking only. Investment calculations are based on standard formulas and may not reflect actual returns. Always consult with financial advisors for investment decisions.

## Support

For issues, feature requests, or questions:
- Create an issue on GitHub
- Check existing documentation
- Review calculation formulas for accuracy

---

**Made with ❤️ for Indian investors**

Track your investments, achieve your financial goals! 🎯💰